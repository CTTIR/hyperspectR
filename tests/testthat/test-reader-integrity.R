test_that("cube spectral metadata is a numeric vector with exact fields", {
  data <- array(1:12, c(2, 3, 2))
  for (bad in list(factor(c("500", "600")), c("500", "600"),
                  matrix(c(500, 600), 1), list(500, 600), c(500 + 1i, 600))) {
    expect_error(hsi_cube(data, bad), "numeric vector")
    expect_error(hsi_cube(data, c(500, 600), fwhm = bad), "numeric vector")
  }
  x <- hsi_cube(data, c(500, 600))
  for (field in c("data", "wavelengths", "metadata")) {
    malformed <- x
    names(malformed)[names(malformed) == field] <- paste0(field, "_backup")
    expect_error(.validate_cube(malformed), "exact")
    expect_error(as.data.frame(malformed), "exact")
  }
  x$wavelengths <- matrix(c(500, 600), 1)
  expect_error(.validate_cube(x), "numeric vector")
  x <- hsi_cube(data, c(500, 600))
  x$fwhm <- NULL
  x$fwhm_backup <- c(10, 20)
  expect_error(.validate_cube(x), "exact")
})

test_that("named dimensions preserve valid spatial masks and caller arrays", {
  data <- array(1:12, c(2, 3, 2))
  names(dim(data)) <- c("row", "column", "band")
  mask <- matrix(c(TRUE, FALSE, TRUE, TRUE, FALSE, TRUE), 2, 3)
  before <- serialize(list(data, mask), NULL)
  x <- hsi_cube(data, c(500, 600), mask = mask)
  expect_identical(x$data, data)
  expect_identical(x$mask, mask)
  expect_equal(hs_roi_stats(x, matrix(TRUE, 2, 3))$n_pixels, c(4L, 4L))
  expect_identical(serialize(list(data, mask), NULL), before)
})

test_that("spectral sorting and reverse selection retain quality-pixel identity", {
  data <- array(c(30, 31, 10, 11, 20, 21), c(2, 1, 3))
  flags <- data == 20
  fields <- c("calibration_invalid", "calibration_clipped", "calibration_saturated", "absorbance_clipped")
  metadata <- setNames(rep(list(flags), length(fields)), fields)
  before <- serialize(list(data, metadata), NULL)
  expect_warning(x <- hsi_cube(data, c(700, 500, 600), fwhm = c(30, 10, 20),
                               metadata = metadata), "sorting")
  expect_equal(x$fwhm, c(10, 20, 30))
  for (field in fields) expect_identical(x$metadata[[field]], x$data == 20)
  expect_warning(y <- x[2:1, , 3:1], "sorting")
  expect_equal(as.vector(y$data), c(11, 10, 21, 20, 31, 30))
  for (field in fields) expect_identical(y$metadata[[field]], y$data == 20)
  expect_identical(serialize(list(data, metadata), NULL), before)
})

test_that("archived quality flags retain their source grid through spatial selection", {
  flag <- array(seq_len(18) %% 4 == 0, c(2, 3, 3))
  record <- list(wavelengths = c(500, 600, 700), flags = list(calibration_invalid = flag))
  x <- hsi_cube(array(1:12, c(2, 3, 2)), c(550, 650),
                metadata = list(source_spectral_qc = list(record)))
  y <- suppressWarnings(x[2:1, 3:2, 2:1])
  expect_identical(y$metadata$source_spectral_qc[[1]]$wavelengths, record$wavelengths)
  expect_identical(y$metadata$source_spectral_qc[[1]]$flags$calibration_invalid,
                   flag[2:1, 3:2, , drop = FALSE])
  expect_identical(x$metadata$source_spectral_qc[[1]], record)
  bad <- x
  bad$metadata$source_spectral_qc[[1]]$flags$calibration_invalid <- array(TRUE, c(2, 3, 2))
  expect_error(.validate_cube(bad), "source wavelength grid")
  bad$metadata$source_spectral_qc[[1]]$flags <- list(unrecognized = flag)
  expect_error(.validate_cube(bad), "named quality flags")
  bad$metadata$source_spectral_qc <- "invalid"
  expect_error(.validate_cube(bad), "list of records")
})

test_that("polygon winding and cyclic vertex order select the same pixel centers", {
  x <- hsi_cube(array(1:25, c(5, 5, 1)), 500)
  vertices <- rbind(c(1, 1), c(5, 1), c(1, 5))
  expected <- outer(1:5, 1:5, function(row, col) row + col < 6)
  for (order in list(1:3, 3:1, c(2, 3, 1), c(1, 3, 2))) {
    roi <- hs_roi_polygon(x, vertices[order, ])
    expect_identical(roi$mask, expected)
    expect_equal(hs_roi_stats(x, roi)$mean, mean(x$data[, , 1][expected]))
  }
})

test_that("ENVI int32 lower endpoint is a value, not implicit missingness", {
  dir <- withr::local_tempdir()
  for (endian in c("little", "big")) {
    path <- file.path(dir, endian)
    writeLines(c("ENVI", "samples = 2", "lines = 1", "bands = 1", "data type = 3",
                 "interleave = bsq", paste0("byte order = ", if (endian == "little") 0 else 1),
                 "wavelength = {500}"), paste0(path, ".hdr"))
    bytes <- list(c(0, 0, 0, 128), c(255, 255, 255, 127))
    if (endian == "big") bytes <- lapply(bytes, rev)
    writeBin(as.raw(unlist(bytes)), paste0(path, ".dat"))
    x <- hs_read_envi(paste0(path, ".hdr"), verbose = FALSE)
    expect_identical(as.vector(x$data), c(-2147483648, 2147483647))
    out <- hs_write_envi(x, file.path(dir, paste0(endian, "-out")), data_type = 3L, verbose = FALSE)
    expect_identical(readBin(out[2], "raw", 8), as.raw(c(0, 0, 0, 128, 255, 255, 255, 127)))
  }
})

test_that("ENVI integer header fields are checked before coercion", {
  dir <- withr::local_tempdir()
  path <- file.path(dir, "malformed")
  fields <- c(samples = "1", lines = "1", bands = "1", `data type` = "4",
              interleave = "bsq", `byte order` = "0", `header offset` = "0", wavelength = "{500}")
  writeBin(rep(as.raw(0), 16), paste0(path, ".dat"))
  for (field in c("samples", "lines", "bands", "data type", "byte order", "header offset")) {
    bad <- fields
    bad[field] <- paste0(bad[field], ".5")
    writeLines(c("ENVI", paste(names(bad), bad, sep = " = ")), paste0(path, ".hdr"))
    expect_error(hs_read_envi(paste0(path, ".hdr"), verbose = FALSE), field)
  }
  fields["wavelength"] <- "{500"
  writeLines(c("ENVI", paste(names(fields), fields, sep = " = ")), paste0(path, ".hdr"))
  expect_error(hs_read_envi(paste0(path, ".hdr"), verbose = FALSE), "Unterminated")
})

test_that("ENVI declared no-data is excluded in both readers and statistics", {
  dir <- withr::local_tempdir()
  backends <- c("builtin", if (requireNamespace("terra", quietly = TRUE)) "terra")
  for (ignore in c(-9999, -9999.1)) {
    path <- file.path(dir, paste0("missing", abs(ignore)))
    writeLines(c("ENVI", "samples = 3", "lines = 2", "bands = 2", "data type = 4",
                 "interleave = bip", "byte order = 1", "wavelength = {500,600}",
                 paste0("data ignore value = ", ignore)), paste0(path, ".hdr"))
    expected <- array(c(11, 21, 12, 22, 13, 23, 111, 121, 112, 122, 113, 123), c(2, 3, 2))
    expected[2, 3, 2] <- NA_real_
    wire <- numeric()
    for (row in 1:2) for (col in 1:3) for (band in 1:2) {
      value <- expected[row, col, band]
      wire <- c(wire, if (is.na(value)) ignore else value)
    }
    writeBin(wire, paste0(path, ".dat"), size = 4, endian = "big")
    for (backend in backends) {
      x <- suppressWarnings(hs_read_envi(paste0(path, ".hdr"), backend = backend, verbose = FALSE))
      expect_equal(x$data, expected)
      stats <- hs_roi_stats(x, matrix(TRUE, 2, 3))
      expect_identical(stats$n_pixels, c(6L, 5L))
      expect_equal(stats$mean, c(mean(expected[, , 1]), mean(expected[, , 2], na.rm = TRUE)))
    }
  }
})

test_that("float32 range failure preserves existing ENVI and float64 is lossless", {
  dir <- withr::local_tempdir()
  path <- file.path(dir, "cube")
  targets <- paste0(path, c(".hdr", ".dat"))
  for (target in targets) writeBin(charToRaw(basename(target)), target)
  before <- lapply(targets, function(p) readBin(p, "raw", file.size(p)))
  for (value in c(1e39, -1e39, 1e-50)) {
    x <- hsi_cube(array(c(value, NA), c(1, 2, 1)), 500)
    expect_error(hs_write_envi(x, path, verbose = FALSE), "float32")
    expect_identical(lapply(targets, function(p) readBin(p, "raw", file.size(p))), before)
    out <- hs_write_envi(x, file.path(dir, "double"), data_type = 5, verbose = FALSE)
    expect_identical(hs_read_envi(out[1], verbose = FALSE)$data, x$data)
  }
})

test_that("TIFF encoder failure leaves the previous completed output intact", {
  skip_if_not_installed("terra")
  dir <- withr::local_tempdir()
  path <- file.path(dir, "cube.tif")
  writeBin(charToRaw("previous output"), path)
  before <- readBin(path, "raw", file.size(path))
  local_mocked_bindings(writeRaster = function(x, filename, ...) {
    writeBin(charToRaw("partial output"), filename)
    stop("encoder failed after opening its destination")
  }, .package = "terra")
  expect_error(hs_write_tiff(hsi_cube(array(1:6, c(2, 3, 1)), 500), path, verbose = FALSE), "encoder failed")
  expect_identical(readBin(path, "raw", file.size(path)), before)
  expect_identical(list.files(dir), "cube.tif")
})

test_that("TIFF float64 preserves finite double precision, extremes and mask geometry", {
  skip_if_not_installed("terra")
  dir <- withr::local_tempdir()
  path <- file.path(dir, "cube.tif")
  data <- array(c(1e39, -1e39, 1e-50, pi, 1 + 2^-40, 99), c(2, 3, 1))
  mask <- matrix(c(TRUE, TRUE, TRUE, TRUE, TRUE, FALSE), 2, 3)
  x <- hsi_cube(data, 500, mask = mask)
  before <- serialize(x, NULL)
  hs_write_tiff(x, path, verbose = FALSE)
  actual <- hs_read_tiff(path, wavelengths = 500, verbose = FALSE)
  expected <- data
  expected[2, 3, 1] <- NA_real_
  expect_identical(is.na(actual$data), is.na(expected))
  expect_identical(actual$data[!is.na(expected)], expected[!is.na(expected)])
  expect_identical(terra::datatype(terra::rast(path)), "FLT8S")
  expect_identical(serialize(x, NULL), before)
})

test_that("display stretches preserve finite endpoints at tiny and extreme scales", {
  for (scale in c(1e-12, 1e-300, 1e308)) {
    expect_equal(.linear_stretch(c(-scale, 0, scale), c(0, 1)), c(0, .5, 1))
  }
  expect_identical(.linear_stretch(matrix(c(NA, 4, 4, 4), 2)), matrix(c(NA, .5, .5, .5), 2))
})

test_that("PNG maps endpoints without an absolute epsilon and keeps invalid pixels black", {
  dir <- withr::local_tempdir()
  for (scale in c(1e-12, 1e308)) {
    path <- file.path(dir, "colors.png")
    colors <- NULL
    local_mocked_bindings(rasterImage = function(image, ...) { colors <<- image }, .package = "graphics")
    hs_export_png(matrix(c(-scale, 0, scale, NA), 2, 2), path, palette = "magma")
    expected <- matrix(c(viridisLite::magma(256)[c(1, 129, 256)], "#000000"), 2, 2)
    expect_identical(as.matrix(colors), expected)
    expect_true(file.exists(path))
  }
})

test_that("PNG validation and encoder failure preserve files and graphics devices", {
  dir <- withr::local_tempdir()
  path <- file.path(dir, "cube.png")
  writeBin(charToRaw("previous output"), path)
  before <- readBin(path, "raw", file.size(path))
  devices <- grDevices::dev.list()
  expect_error(hs_export_png(matrix(1:4, 2), path, range = c(2, 1)), "range")
  expect_error(hs_export_png(matrix(1:4, 2), path, width = .5), "whole")
  local_mocked_bindings(rasterImage = function(...) stop("render failed"), .package = "graphics")
  expect_error(hs_export_png(matrix(1:4, 2), path), "render failed")
  expect_identical(readBin(path, "raw", file.size(path)), before)
  expect_identical(grDevices::dev.list(), devices)
  expect_identical(list.files(dir), "cube.png")
})

test_that("Cubert measurement indices are rejected before dependency or SDK access", {
  local_mocked_bindings(check_installed = function(...) stop("dependency probe reached"), .package = "rlang")
  for (index in list(1.9, 0, -1, NA_real_, Inf, c(1, 2), "1", 1 + 1i,
                    .Machine$integer.max + 1)) {
    expect_error(hs_read_cubert("unused.cu3s", index = index, verbose = FALSE), "positive integer")
  }
})

test_that("Cubert session bounds precede measurement access and exact indices survive", {
  skip_if_not_installed("cuvis.r")
  dir <- withr::local_tempdir()
  path <- file.path(dir, "synthetic.cu3s")
  writeLines("synthetic placeholder", path)
  cube <- array(5000, c(1, 2, 2))
  attr(cube, "wavelengths") <- c(500, 600)
  seen <- integer()
  local_mocked_bindings(
    cuvis_init = function(...) invisible(NULL),
    cuvis_session = function(...) list(1, 2),
    cuvis_get_measurement = function(session, index) { seen <<- c(seen, index); "measurement" },
    cuvis_get_metadata = function(...) list(),
    cuvis_processing_context = function(...) "context",
    cuvis_reprocess = function(...) invisible(NULL),
    cuvis_get_cube = function(...) cube,
    .package = "cuvis.r"
  )
  expect_error(hs_read_cubert(path, index = 3, verbose = FALSE), "exceeds")
  expect_identical(seen, integer())
  result <- hs_read_cubert(path, index = 2, verbose = FALSE)
  expect_identical(seen, 2L)
  expect_identical(result$metadata$measurement_index, 2L)
})
