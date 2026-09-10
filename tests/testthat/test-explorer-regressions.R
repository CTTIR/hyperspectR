wait_for_worker <- function(session, job) {
  deadline <- Sys.time() + 30
  while (identical(job$status(), "Running") && Sys.time() < deadline) {
    Sys.sleep(.05)
    session$elapse(250)
    session$flushReact()
  }
  expect_equal(job$status(), "Complete")
}

explorer_environment <- function() {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  env <- new.env(parent = globalenv())
  path <- system.file("shiny", "hyperspectR", package = "hyperspectR")
  for (file in list.files(file.path(path, "modules"), pattern = "\\.R$", full.names = TRUE)) sys.source(file, envir = env)
  env
}

test_that("F09/F11: full explorer UI sources and processed cube persists", {
  env <- explorer_environment()
  path <- system.file("shiny", "hyperspectR", "app.R", package = "hyperspectR")
  expect_error(sys.source(path, envir = env), NA)
  shiny::testServer(env$server, {
    session$flushReact()
    original <- cube_rv$cube
    cube_rv$cube <- hs_snv(original)
    session$flushReact()
    expect_equal(cube_rv$cube$metadata$processing_mode, "snv")
    expect_equal(cube_rv$original_cube$data, original$data)
  })
})

test_that("F12: index and analysis results are invalidated when inputs change", {
  env <- explorer_environment()
  rv <- shiny::reactiveValues(cube = hs_example_cube())
  shiny::testServer(env$mod_indices_server, args = list(cube_rv = rv), {
    session$setInputs(index_type = "ndi", ndi_band1 = 540, ndi_band2 = 660, compute = 1)
    wait_for_worker(session, job)
    expect_equal(index_result()$type, "ndi")
    session$setInputs(index_type = "thi")
    expect_null(index_result())
    session$setInputs(compute = 2)
    wait_for_worker(session, job)
    expect_equal(index_result()$type, "thi")
    rv$cube <- rv$cube[1:2, 1:3, ]
    session$flushReact()
    expect_null(index_result())
  })
  shiny::testServer(env$mod_analysis_server, args = list(cube_rv = rv), {
    session$setInputs(analysis_type = "pca", n_components = 2, run = 1)
    wait_for_worker(session, job)
    expect_s3_class(analysis_result(), "hsi_pca")
    session$setInputs(n_components = 1)
    expect_null(analysis_result())
  })
})

test_that("F10/F24/F25: upload requires paired ENVI files and export contains the pair", {
  env <- explorer_environment()
  dir <- withr::local_tempdir()
  cube <- hs_example_cube()[1:2, 1:3, 1:3]
  files <- hs_write_envi(cube, file.path(dir, "source"), verbose = FALSE)
  uploaded <- file.path(dir, c("0", "1"))
  file.copy(files, uploaded)
  info <- data.frame(name = c("source.hdr", "source.dat"), datapath = uploaded)
  expect_error(env$.read_uploaded_cube(info[1, ]), "companion")
  restored <- env$.read_uploaded_cube(info)
  expect_equal(restored$data, cube$data, tolerance = 1e-6)
  if (nzchar(Sys.which("zip"))) {
    archive <- file.path(dir, "download-without-extension")
    env$.write_envi_archive(cube, archive)
    expect_setequal(utils::unzip(archive, list = TRUE)$Name, c("cube.hdr", "cube.dat", "provenance.rds"))
    target <- file.path(dir, "unzipped")
    utils::unzip(archive, exdir = target)
    expect_equal(hs_read_envi(file.path(target, "cube.hdr"), verbose = FALSE)$data, cube$data, tolerance = 1e-6)
  }
  if (requireNamespace("terra", quietly = TRUE)) {
    tif <- file.path(dir, "cube.tif")
    hs_write_tiff(cube, tif, verbose = FALSE)
    info <- data.frame(name = "cube.tif", datapath = tif)
    expect_error(env$.read_uploaded_cube(info), "wavelength")
    expect_equal(env$.read_uploaded_cube(info, paste(cube$wavelengths, collapse = ","))$data, cube$data, tolerance = 1e-6)
  }
})


test_that("cancelling a background operation preserves the current cube", {
  env <- explorer_environment()
  original <- hs_example_cube()
  rv <- shiny::reactiveValues(cube = original, original_cube = original)
  shiny::testServer(env$mod_processing_server, args = list(cube_rv = rv), {
    session$setInputs(method = "smooth", sg_window = 5, sg_poly = 2, apply = 1)
    expect_equal(job$status(), "Running")
    session$setInputs(cancel = 1)
    expect_equal(job$status(), "Cancelled")
    session$elapse(500)
    expect_equal(rv$cube$data, original$data)
  })
})
