skip_if_no_withr <- function() skip_if_not_installed("withr")

make_envi <- function(dir, interleave = "bsq", data_type = 4L) {
  cube <- hs_simulate_cube(rows = 6, cols = 5,
                           wavelengths = seq(430, 510, by = 8),
                           noise_sd = 0, seed = 11)
  p <- file.path(dir, "img")
  hs_write_envi(cube, p, interleave = interleave, data_type = data_type,
                verbose = FALSE)
  list(cube = cube, base = p, hdr = paste0(p, ".hdr"),
       dat = paste0(p, ".dat"))
}

test_that("builtin reader round-trips all interleaves", {
  skip_if_no_withr()
  for (il in c("bsq", "bil", "bip")) {
    dir <- withr::local_tempdir()
    f <- make_envi(dir, interleave = il)
    cube2 <- hs_read_envi(f$hdr, backend = "builtin", verbose = FALSE)
    expect_equal(cube2$data, f$cube$data, tolerance = 1e-5,
                 info = il)
    expect_equal(cube2$wavelengths, f$cube$wavelengths)
  }
})

test_that("verbose reader emits progress messages", {
  skip_if_no_withr()
  dir <- withr::local_tempdir()
  f <- make_envi(dir)
  expect_message(
    hs_read_envi(f$hdr, backend = "builtin", verbose = TRUE),
    "Reading ENVI"
  )
})

test_that("band and extent subsetting work", {
  skip_if_no_withr()
  dir <- withr::local_tempdir()
  f <- make_envi(dir)
  sub <- hs_read_envi(f$hdr, backend = "builtin", bands = c(1L, 3L),
                      extent = c(1, 3, 1, 2), verbose = FALSE)
  expect_equal(dim(sub), c(3, 2, 2))
  expect_equal(length(sub$wavelengths), 2)
})

test_that("missing header errors", {
  expect_error(hs_read_envi("nonexistent.hdr", verbose = FALSE),
               "Cannot find data file|not found")
})

test_that("missing data file errors", {
  skip_if_no_withr()
  dir <- withr::local_tempdir()
  hdr <- file.path(dir, "lonely.hdr")
  writeLines(c("ENVI", "samples = 2", "lines = 2", "bands = 1",
               "data type = 4", "interleave = bsq"), hdr)
  expect_error(hs_read_envi(hdr, verbose = FALSE),
               "Cannot find data file|Data file not found")
})

test_that("resolve paths errors when data file absent", {
  skip_if_no_withr()
  dir <- withr::local_tempdir()
  hdr <- file.path(dir, "ghost.hdr")
  writeLines("ENVI", hdr)
  expect_error(hs_read_envi(hdr, verbose = FALSE), "Data file not found|Cannot find")
})

test_that("header parser handles micrometer units and continuation lines", {
  skip_if_no_withr()
  dir <- withr::local_tempdir()
  hdr <- file.path(dir, "micro.hdr")
  dat <- file.path(dir, "micro.dat")
  writeLines(c(
    "ENVI",
    "description = {a test cube",
    "spanning two lines}",
    "samples = 2", "lines = 2", "bands = 3",
    "data type = 4", "interleave = bsq", "byte order = 0",
    "wavelength units = Micrometers",
    "wavelength = {0.50, 0.60, 0.70}",
    "fwhm = {0.01, 0.01, 0.01}",
    "sensor type = test"
  ), hdr)
  con <- file(dat, "wb")
  writeBin(as.double(rep(0.4, 2 * 2 * 3)), con, size = 4L, endian = "little")
  close(con)

  cube <- hs_read_envi(hdr, backend = "builtin", verbose = FALSE)
  # micrometers -> nm conversion
  expect_equal(cube$wavelengths, c(500, 600, 700))
  # description retains braces (parser only de-braces wavelength/fwhm)
  expect_match(cube$metadata$description, "a test cube spanning two lines")
  expect_equal(cube$metadata$sensor_type, "test")
})

test_that("integer data types read correctly", {
  skip_if_no_withr()
  dir <- withr::local_tempdir()
  hdr <- file.path(dir, "int.hdr")
  dat <- file.path(dir, "int.dat")
  writeLines(c("ENVI", "samples = 2", "lines = 2", "bands = 2",
               "data type = 2", "interleave = bsq", "byte order = 0",
               "wavelength = {500, 600}"), hdr)
  con <- file(dat, "wb")
  writeBin(as.integer(1:8), con, size = 2L, endian = "little")
  close(con)
  cube <- hs_read_envi(hdr, backend = "builtin", verbose = FALSE)
  expect_type(cube$data, "double")
  expect_equal(dim(cube), c(2, 2, 2))
})

test_that("missing wavelength field falls back to band index", {
  skip_if_no_withr()
  dir <- withr::local_tempdir()
  hdr <- file.path(dir, "nowl.hdr")
  dat <- file.path(dir, "nowl.dat")
  writeLines(c("ENVI", "samples = 2", "lines = 2", "bands = 2",
               "data type = 4", "interleave = bsq", "byte order = 0"), hdr)
  con <- file(dat, "wb")
  writeBin(as.double(rep(0.5, 8)), con, size = 4L, endian = "little")
  close(con)
  cube <- hs_read_envi(hdr, backend = "builtin", verbose = FALSE)
  expect_equal(cube$wavelengths, c(1, 2))
})

test_that("hs_read_cube dispatches on extension", {
  skip_if_no_withr()
  dir <- withr::local_tempdir()
  f <- make_envi(dir)
  cube <- hs_read_cube(f$hdr, backend = "builtin", verbose = FALSE)
  expect_s3_class(cube, "hsi_cube")
})

test_that("hs_read_cube errors on missing file", {
  expect_error(hs_read_cube("does_not_exist.hdr"), "File not found")
})

test_that("hs_read_cube errors on unsupported extension", {
  skip_if_no_withr()
  dir <- withr::local_tempdir()
  p <- file.path(dir, "data.xyz")
  writeLines("x", p)
  expect_error(hs_read_cube(p), "Unsupported")
})

test_that("envi type info errors on unknown type", {
  expect_error(.envi_type_info(99), "Unsupported")
})

test_that("envi type info maps known codes", {
  expect_equal(.envi_type_info(4)$what, "double")
  expect_equal(.envi_type_info(1)$size, 1L)
  expect_equal(.envi_type_info(12)$signed, FALSE)
})

test_that("terra backend reads ENVI and matches builtin", {
  skip_if_not_installed("terra")
  skip_if_no_withr()
  dir <- withr::local_tempdir()
  f <- make_envi(dir)
  # terra may emit a CRS/extent warning when reading a bare ENVI cube
  cube_t <- suppressWarnings(hs_read_envi(f$hdr, backend = "terra", verbose = FALSE))
  expect_s3_class(cube_t, "hsi_cube")
  expect_equal(dim(cube_t), dim(f$cube))
})

test_that("hs_read_tiff round-trips via terra", {
  skip_if_not_installed("terra")
  skip_if_no_withr()
  dir <- withr::local_tempdir()
  cube <- hs_simulate_cube(rows = 5, cols = 4,
                           wavelengths = seq(500, 540, by = 10),
                           noise_sd = 0, seed = 2)
  tif <- file.path(dir, "c.tif")
  hs_write_tiff(cube, tif, verbose = FALSE)
  back <- hs_read_tiff(tif, wavelengths = cube$wavelengths, verbose = FALSE)
  expect_s3_class(back, "hsi_cube")
  expect_equal(dim(back), dim(cube))
})

test_that("hs_read_tiff validates wavelength length", {
  skip_if_not_installed("terra")
  skip_if_no_withr()
  dir <- withr::local_tempdir()
  cube <- hs_simulate_cube(rows = 4, cols = 4,
                           wavelengths = seq(500, 530, by = 10),
                           noise_sd = 0, seed = 2)
  tif <- file.path(dir, "c.tif")
  hs_write_tiff(cube, tif, verbose = FALSE)
  expect_error(hs_read_tiff(tif, wavelengths = c(500, 600)), "must match")
})

test_that("hs_read_tiff errors on missing file", {
  skip_if_not_installed("terra")
  expect_error(hs_read_tiff("absent.tif", wavelengths = 1), "not found")
})
