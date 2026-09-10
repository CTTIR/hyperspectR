test_that("F03/F20/F21: plot coordinates and wavelengths match source pixels", {
  x <- hsi_cube(array(seq_len(18), c(2, 3, 3)), c(460, 550, 640))
  p <- hs_plot_image(x, band = 1)$data
  expect_equal(p$value, x$data[cbind(p$y, p$x, 1)])
  index <- hs_plot_index(x$data[, , 1])$data
  expect_equal(index$value, x$data[cbind(index$y, index$x, 1)])
  set.seed(42)
  spectra <- hs_plot_spectra(x, pixels = "random", n = 2)$data
  expect_equal(spectra$wavelength, rep(x$wavelengths, 2))
  expect_equal(diff(spectra$value[1:3]), c(6, 6))
  expect_s3_class(hs_plot_image(x[1, , ], band = 1), "ggplot")
  expect_s3_class(hs_plot_rgb(x[, 1, ]), "ggplot")
})

test_that("F04/F08/F17/F23: independent ENVI fixture preserves values and rejects corruption", {
  dir <- withr::local_tempdir()
  path <- file.path(dir, "fixture")
  expected <- array(c(11, 21, 12, 22, 13, 23, 111, 121, 112, 122, 113, 123), c(2, 3, 2))
  for (interleave in c("bsq", "bil", "bip")) for (endian in c("little", "big")) {
    hdr <- c("ENVI", "samples = 3", "lines = 2", "bands = 2", "data type = 4",
             paste0("interleave = ", interleave), paste0("byte order = ", if (endian == "little") 0 else 1), "header offset = 4",
             "wavelength units = Micrometers", "wavelength = {0.5, 0.6}", "fwhm = {0.01, 0.02}")
    writeLines(hdr, paste0(path, ".hdr"))
    # Independent wire traversal: row/column/band loops in ENVI order.
    values <- numeric()
    if (interleave == "bsq") for (b in 1:2) for (r in 1:2) for (c in 1:3) values <- c(values, expected[r, c, b])
    if (interleave == "bil") for (r in 1:2) for (b in 1:2) for (c in 1:3) values <- c(values, expected[r, c, b])
    if (interleave == "bip") for (r in 1:2) for (c in 1:3) for (b in 1:2) values <- c(values, expected[r, c, b])
    con <- file(paste0(path, ".dat"), "wb")
    writeBin(as.raw(1:4), con)
    writeBin(values, con, size = 4, endian = endian)
    close(con)
    x <- hs_read_envi(paste0(path, ".hdr"), verbose = FALSE)
    expect_equal(x$data, expected)
    expect_equal(x$fwhm, c(10, 20))
    if (requireNamespace("terra", quietly = TRUE)) {
      expect_equal(suppressWarnings(hs_read_envi(paste0(path, ".hdr"), backend = "terra", verbose = FALSE))$data, expected)
    }
  }
  writeBin(as.double(1), paste0(path, ".dat"), size = 4)
  expect_error(hs_read_envi(paste0(path, ".hdr"), verbose = FALSE), "Truncated")
  for (type in c(13L, 14L, 15L)) {
    target <- file.path(dir, paste0("unsupported", type))
    expect_error(hs_write_envi(x, target, data_type = type, verbose = FALSE), "Unsupported")
    expect_false(file.exists(paste0(target, ".hdr")))
  }
})

test_that("F04: TIFF reader and writer agree with an independent matrix view", {
  skip_if_not_installed("terra")
  path <- tempfile(fileext = ".tif")
  withr::defer(unlink(path))
  expected <- matrix(c(11, 21, 12, 22, 13, 23), 2, 3)
  raster <- terra::rast(nrows = 2, ncols = 3)
  terra::values(raster) <- as.vector(t(expected))
  terra::writeRaster(raster, path, overwrite = TRUE)
  expect_equal(hs_read_tiff(path, 500, verbose = FALSE)$data[, , 1], expected)
  x <- hsi_cube(array(expected, c(2, 3, 1)), 500)
  hs_write_tiff(x, path, verbose = FALSE)
  expect_equal(unname(as.matrix(terra::rast(path), wide = TRUE)), expected)
})

test_that("F02/F13: optional SG backends have common support, sign and units", {
  x <- hsi_cube(array(rep(seq(0, 80, 10)^2, each = 2), c(1, 2, 9)), seq(500, 580, 10))
  for (backend in c("prospectr", "signal")) {
    if (!requireNamespace(backend, quietly = TRUE)) next
    for (deriv in 0:2) {
      reference <- hs_smooth(x, deriv = deriv)
      actual <- hs_smooth(x, deriv = deriv, backend = backend)
      expect_equal(actual$data, reference$data, tolerance = 1e-8)
      expect_equal(actual$wavelengths, reference$wavelengths)
    }
  }
})

test_that("staged ENVI replacement restores the previous pair on a publish failure", {
  dir <- withr::local_tempdir()
  targets <- file.path(dir, c("cube.hdr", "cube.dat"))
  staged <- file.path(dir, c("new-header", "new-data"))
  writeLines("old-header", targets[1])
  writeLines("old-data", targets[2])
  writeLines("new-header", staged[1])
  writeLines("new-data", staged[2])
  rename <- base::file.rename
  local_mocked_bindings(file.rename = function(from, to) {
    if (identical(from, staged[2])) return(FALSE)
    rename(from, to)
  }, .package = "base")
  expect_error(.publish_file_pair(staged, targets), "Cannot publish")
  expect_equal(readLines(targets[1]), "old-header")
  expect_equal(readLines(targets[2]), "old-data")
})

test_that("header-like and ambiguous ENVI companions are rejected", {
  dir <- withr::local_tempdir()
  path <- file.path(dir, "cube")
  cube <- hsi_cube(array(1:4, c(2, 1, 2)), c(500, 600))
  files <- hs_write_envi(cube, path, verbose = FALSE)
  file.copy(files[1], path)
  expect_equal(hs_read_envi(files[1], verbose = FALSE)$data, cube$data)
  file.copy(files[2], paste0(path, ".img"))
  expect_error(hs_read_envi(files[1], verbose = FALSE), "Ambiguous")
  expect_equal(hs_read_envi(files[2], verbose = FALSE)$data, cube$data)
})

test_that("unknown ENVI wavelengths stay unknown through export", {
  dir <- withr::local_tempdir()
  cube <- hsi_cube(array(1:4, c(2, 1, 2)), 1:2, metadata = list(wavelengths_known = FALSE))
  files <- hs_write_envi(cube, file.path(dir, "unknown"), verbose = FALSE)
  restored <- hs_read_envi(files[1], verbose = FALSE)
  expect_false(restored$metadata$wavelengths_known)
  expect_error(hs_ndi(restored, 1, 2), "Measured wavelengths")
  expect_error(hs_plot_image(restored, wavelength = 1), "Measured wavelengths")
  expect_s3_class(hs_plot_image(restored, band = 1), "ggplot")
})

test_that("wide integer payloads are rejected before lossy decoding", {
  dir <- withr::local_tempdir()
  for (type in c(13, 14, 15)) {
    path <- file.path(dir, paste0("wide", type))
    writeLines(c("ENVI", "samples = 1", "lines = 1", "bands = 1", paste0("data type = ", type),
                 "interleave = bsq", "byte order = 0", "wavelength = {500}"), paste0(path, ".hdr"))
    writeBin(as.raw(rep(255, if (type == 13) 4 else 8)), paste0(path, ".dat"))
    expect_error(hs_read_envi(paste0(path, ".hdr"), verbose = FALSE), "Unsupported ENVI data type")
  }
})
