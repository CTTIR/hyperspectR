test_that("hs_write_envi writes hdr and dat with fwhm", {
  skip_if_not_installed("withr")
  cube <- hs_simulate_cube(rows = 5, cols = 4,
                           wavelengths = seq(500, 540, by = 10),
                           noise_sd = 0, seed = 3)
  dir <- withr::local_tempdir()
  paths <- hs_write_envi(cube, file.path(dir, "c"), verbose = FALSE)
  expect_length(paths, 2)
  expect_true(all(file.exists(paths)))
  hdr <- readLines(paths[1])
  expect_true(any(grepl("^ENVI", hdr)))
  expect_true(any(grepl("fwhm", hdr)))
})

test_that("hs_write_envi without fwhm omits fwhm block", {
  skip_if_not_installed("withr")
  cube <- hsi_cube(array(0.5, c(3, 3, 2)), c(500, 600))
  dir <- withr::local_tempdir()
  paths <- hs_write_envi(cube, file.path(dir, "c"), verbose = FALSE)
  hdr <- readLines(paths[1])
  expect_false(any(grepl("fwhm", hdr)))
})

test_that("hs_write_envi verbose emits messages", {
  skip_if_not_installed("withr")
  cube <- hsi_cube(array(0.5, c(3, 3, 2)), c(500, 600))
  dir <- withr::local_tempdir()
  expect_message(
    hs_write_envi(cube, file.path(dir, "c"), verbose = TRUE),
    "Writing ENVI"
  )
})

test_that("hs_write_envi validates interleave", {
  skip_if_not_installed("withr")
  cube <- hsi_cube(array(0.5, c(3, 3, 2)), c(500, 600))
  dir <- withr::local_tempdir()
  expect_error(
    hs_write_envi(cube, file.path(dir, "c"), interleave = "nope",
                  verbose = FALSE)
  )
})

test_that("hs_write_envi integer data type writes", {
  skip_if_not_installed("withr")
  cube <- hsi_cube(array(2, c(3, 3, 2)), c(500, 600))
  dir <- withr::local_tempdir()
  paths <- hs_write_envi(cube, file.path(dir, "int"), data_type = 2L,
                         verbose = FALSE)
  back <- hs_read_envi(paths[1], backend = "builtin", verbose = FALSE)
  expect_equal(back$data, cube$data, tolerance = 1e-6)
})

test_that("hs_write_tiff writes a file (terra)", {
  skip_if_not_installed("terra")
  skip_if_not_installed("withr")
  cube <- hs_simulate_cube(rows = 4, cols = 4,
                           wavelengths = seq(500, 530, by = 10),
                           noise_sd = 0, seed = 1)
  dir <- withr::local_tempdir()
  path <- file.path(dir, "c.tif")
  out <- hs_write_tiff(cube, path, verbose = FALSE)
  expect_true(file.exists(out))
})

test_that("hs_write_tiff verbose emits message", {
  skip_if_not_installed("terra")
  skip_if_not_installed("withr")
  cube <- hsi_cube(array(0.5, c(3, 3, 2)), c(500, 600))
  dir <- withr::local_tempdir()
  expect_message(
    hs_write_tiff(cube, file.path(dir, "c.tif"), verbose = TRUE),
    "Writing TIFF"
  )
})

test_that("hs_write_tiff errors without terra", {
  skip_if_not_installed("withr")
  cube <- hsi_cube(array(0.5, c(3, 3, 2)), c(500, 600))
  testthat::local_mocked_bindings(
    requireNamespace = function(...) FALSE,
    .package = "base"
  )
  dir <- withr::local_tempdir()
  expect_error(
    hs_write_tiff(cube, file.path(dir, "c.tif"), verbose = FALSE),
    "terra"
  )
})

test_that("hs_export_png writes png for each palette", {
  skip_if_not_installed("withr")
  cube <- hs_example_cube()
  dir <- withr::local_tempdir()
  for (pal in c("viridis", "magma", "inferno", "plasma", "grey", "unknown")) {
    path <- file.path(dir, paste0(pal, ".png"))
    hs_export_png(cube$data[, , 30], path, palette = pal)
    expect_true(file.exists(path))
  }
})

test_that("hs_export_png handles range, dims, and NA pixels", {
  skip_if_not_installed("withr")
  cube <- hs_example_cube()
  dir <- withr::local_tempdir()
  mat <- cube$data[, , 30]
  mat[1, 1] <- NA
  path <- file.path(dir, "ranged.png")
  hs_export_png(mat, path, range = c(0, 1), width = 50, height = 50)
  expect_true(file.exists(path))
})

test_that("hs_export_png rejects non-matrix", {
  expect_error(hs_export_png(1:5, tempfile()), "must be a numeric matrix")
})
