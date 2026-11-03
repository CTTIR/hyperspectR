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
    expect_match(output$index_plot$alt, "Normalized difference index map")
    session$setInputs(index_type = "thi")
    expect_null(index_result())
    expect_equal(job$status(), "Ready")
    session$setInputs(compute = 2)
    wait_for_worker(session, job)
    expect_equal(index_result()$type, "thi")
    rv$cube <- rv$cube[1:2, 1:3, ]
    session$flushReact()
    expect_null(index_result())
    expect_equal(job$status(), "Ready")
  })
  shiny::testServer(env$mod_analysis_server, args = list(cube_rv = rv), {
    session$setInputs(analysis_type = "pca", n_components = 2, run = 1)
    wait_for_worker(session, job)
    expect_s3_class(analysis_result(), "hsi_pca")
    expect_match(output$result_plot$alt, "Principal-component score maps", fixed = TRUE)
    session$setInputs(n_components = 1)
    expect_null(analysis_result())
    expect_equal(job$status(), "Ready")
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

test_that("processing completion, reset, and new-source statuses remain accurate", {
  env <- explorer_environment()
  original <- hs_example_cube()[1:2, 1:3, ]
  rv <- shiny::reactiveValues(cube = original, original_cube = original)
  shiny::testServer(env$mod_processing_server, args = list(cube_rv = rv), {
    session$setInputs(method = "snv", apply = 1)
    wait_for_worker(session, job)
    expect_equal(rv$cube$metadata$processing_mode, "snv")
    expect_equal(job$status(), "Complete")
    expect_match(output$before_after$alt, "Current-cube spatial mean spectrum", fixed = TRUE)
    session$setInputs(reset = 1)
    expect_equal(job$status(), "Ready")
    expect_equal(rv$cube$data, original$data)
    session$setInputs(apply = 2)
    wait_for_worker(session, job)
    rv$cube <- original[1, , ]
    session$flushReact()
    expect_equal(job$status(), "Ready")
    expect_equal(dim(rv$cube$data), c(1, 3, 61))
  })
})

test_that("viewer and PNG export share masked current selection and reject stale inputs", {
  env <- explorer_environment()
  cube <- hsi_cube(array(seq_len(18) / 20, c(2, 3, 3)), c(500, 550, 600),
    mask = matrix(c(FALSE, rep(TRUE, 5)), 2, 3),
    metadata = list(processing_mode = "reflectance", source_file = "fixture.hdr"))
  saved <- list()
  testthat::local_mocked_bindings(ggsave = function(filename, plot, ...) {
    saved[[length(saved) + 1L]] <<- plot
    writeBin(as.raw(1), filename)
  }, .package = "ggplot2")
  shiny::testServer(function(input, output, session) {
    rv <- shiny::reactiveValues(cube = cube, original_cube = cube)
    viewer <- env$mod_viewer_server("viewer", rv)
    env$mod_export_server("export", rv, viewer)
  }, {
    session$setInputs(`viewer-display_mode` = "band", `viewer-band_slider` = 600,
      `viewer-palette` = "magma", `export-export_format` = "png")
    expect_true(file.exists(output[["export-download_image"]]))
    expect_equal(saved[[1]]$data$value, c(NA, .7, .75, .8, .85, .9))
    expect_match(saved[[1]]$labels$title, "600 nm")
    expect_match(output[["viewer-image_plot"]]$alt, "selected by measured wavelength", fixed = TRUE)
    expect_false(grepl("fixture.hdr", output[["viewer-image_plot"]]$alt, fixed = TRUE))
    expect_equal(saved[[1]]$scales$scales[[1]]$palette(c(0, 1)),
      hs_plot_image(cube, wavelength = 600, palette = "magma")$scales$scales[[1]]$palette(c(0, 1)))
    session$setInputs(`viewer-display_mode` = "rgb", `viewer-r_wl` = 600,
      `viewer-g_wl` = 550, `viewer-b_wl` = 500)
    expect_true(file.exists(output[["export-download_image"]]))
    expect_equal(tail(saved, 1)[[1]]$data$color, hs_plot_rgb(cube, 600, 550, 500)$data$color)
    unknown <- cube
    unknown$wavelengths <- 1:3
    unknown$metadata$wavelengths_known <- FALSE
    rv$cube <- unknown
    session$flushReact()
    expect_error(output[["export-download_image"]], "RGB requires measured wavelengths")
    session$setInputs(`viewer-display_mode` = "band")
    expect_error(output[["export-download_image"]], "Select a band within the current cube")
    session$setInputs(`viewer-band_slider` = 2)
    expect_true(file.exists(output[["export-download_image"]]))
    expect_match(tail(saved, 1)[[1]]$labels$title, "Band 2.*unknown")
    expect_match(output[["viewer-image_plot"]]$alt, "band index; measured wavelengths are unknown", fixed = TRUE)
    expect_equal(tail(saved, 1)[[1]]$data$value, c(NA, .4, .45, .5, .55, .6))
    info <- output[["viewer-cube_info"]]
    expect_match(info, "fixture.hdr")
    expect_match(info, "Band indices: 1-3.*unknown")
    expect_false(grepl("1-3 nm", info, fixed = TRUE))
  })
})

test_that("random and clicked CSV spectra are the displayed source pixels", {
  env <- explorer_environment()
  cube <- hsi_cube(array(seq_len(18) / 20, c(2, 3, 3)), c(500, 550, 600),
    mask = matrix(c(FALSE, rep(TRUE, 5)), 2, 3))
  cube$data[2, 2, 1] <- Inf
  rv <- shiny::reactiveValues(cube = cube)
  shiny::testServer(env$mod_spectra_server, args = list(cube_rv = rv), {
    session$setInputs(spectra_mode = "random", n_random = 2, show_sd = TRUE)
    pixels <- selected_pixels()
    expect_match(output$spectra_plot$alt, "Random complete pixel spectra", fixed = TRUE)
    data <- read.csv(output$export_csv)
    expect_equal(nrow(data), 6)
    expect_equal(unique(data[c("x", "y")]), pixels, ignore_attr = TRUE)
    expected <- cube$data[cbind(data$y, data$x, match(data$wavelength, cube$wavelengths))]
    expect_equal(data$value, expected)
    expect_true(all(cube$mask[cbind(data$y, data$x)]))
    expect_true(all(is.finite(data$value)))
    session$setInputs(show_sd = FALSE)
    output$spectra_plot
    expect_equal(selected_pixels(), pixels)
    expect_equal(read.csv(output$export_csv), data)
    replacement <- cube
    replacement$data <- replacement$data * 2
    rv$cube <- replacement
    session$flushReact()
    current <- read.csv(output$export_csv)
    expect_equal(current$value, replacement$data[cbind(current$y, current$x,
      match(current$wavelength, replacement$wavelengths))])
    session$setInputs(spectra_mode = "click", image_click = list(x = 3, y = 1))
    clicked <- read.csv(output$export_csv)
    expect_equal(clicked$x, rep(3, 3))
    expect_equal(clicked$y, rep(1, 3))
    expect_equal(clicked$value, replacement$data[1, 3, ])
    session$setInputs(image_click = list(x = NA_real_, y = 1))
    expect_equal(read.csv(output$export_csv), clicked)
    rv$cube <- cube
    session$flushReact()
    expect_equal(nrow(clicked_pixels()), 0)
    expect_true("mean" %in% names(read.csv(output$export_csv)))
    unknown <- cube
    unknown$wavelengths <- 1:3
    unknown$metadata$wavelengths_known <- FALSE
    rv$cube <- unknown
    session$flushReact()
    expect_match(output$spectra_plot$alt, "band index; measured wavelengths are unknown", fixed = TRUE)
    expect_match(output$click_image$alt, "measured wavelengths are unknown", fixed = TRUE)
  })
})
