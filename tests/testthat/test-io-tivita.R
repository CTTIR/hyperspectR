# Tests for the TIVITA reader. The heavy lifting lives in tivis.r; these check
# the hyperspectR side of the boundary -- hsi_cube construction, metadata
# mapping, and the .dat dispatch, which is ambiguous between ENVI and TIVITA.

test_that("hs_read_tivita errors when tivis.r is unavailable", {
  testthat::local_mocked_bindings(
    check_installed = function(...) rlang::abort("The package \"tivis.r\" is required"),
    .package = "rlang"
  )
  expect_error(
    suppressMessages(hs_read_tivita("anything_SpecCube.dat", verbose = FALSE)),
    "tivis.r"
  )
})

test_that("hs_read_tivita errors on a missing file", {
  skip_if_not_installed("tivis.r")
  expect_error(
    hs_read_tivita("definitely_missing_SpecCube.dat", verbose = FALSE),
    "File not found"
  )
})

test_that("hs_read_tivita returns an hsi_cube with the wavelength axis", {
  skip_if_not_installed("tivis.r")
  f <- tivis.r::tivis_example_file()

  cube <- hs_read_tivita(f, verbose = FALSE)
  expect_s3_class(cube, "hsi_cube")
  # tivis.r returns (rows, cols, bands); hsi_cube uses the same convention
  expect_equal(dim(cube), c(12L, 16L, 8L))
  expect_equal(cube$wavelengths, tivis.r::tivis_get_wavelengths(8L))
  # the wavelengths belong to the cube, not to the underlying array as well
  expect_null(attr(cube$data, "wavelengths"))
})

test_that("band selection propagates through to the cube", {
  skip_if_not_installed("tivis.r")
  f <- tivis.r::tivis_example_file()

  sub <- hs_read_tivita(f, bands = c(2L, 4L), verbose = FALSE)
  expect_equal(dim(sub)[3], 2L)
  expect_equal(sub$wavelengths, tivis.r::tivis_get_wavelengths(8L)[c(2, 4)])
})

test_that("metadata is populated even when no meta.log exists", {
  skip_if_not_installed("tivis.r")
  f <- tivis.r::tivis_example_file()
  cube <- hs_read_tivita(f, verbose = FALSE)

  expect_equal(cube$metadata$source, "TIVITA")
  expect_equal(cube$metadata$file, f)
  # the bundled fixture has no sibling log, so these degrade to NA rather
  # than erroring
  expect_true(is.na(cube$metadata$camera_id) ||
                is.character(cube$metadata$camera_id))
})

test_that(".is_tivita_file recognises the container by content", {
  skip_if_not_installed("tivis.r")
  expect_true(.is_tivita_file(tivis.r::tivis_example_file()))

  # a file whose header does not predict its size is not a TIVITA cube
  tmp <- tempfile(fileext = ".dat")
  on.exit(unlink(tmp), add = TRUE)
  con <- file(tmp, "wb")
  writeBin(as.integer(c(640L, 480L, 100L)), con, size = 4L, endian = "big")
  writeBin(numeric(4), con, size = 4L, endian = "big")
  close(con)
  expect_false(.is_tivita_file(tmp))

  expect_false(.is_tivita_file(tempfile()))
})

test_that("hs_read_cube routes an ambiguous .dat by content", {
  skip_if_not_installed("tivis.r")
  skip_if_not_installed("withr")

  # a TIVITA .dat with no sibling .hdr must reach the TIVITA reader, not the
  # ENVI reader (which used to be the unconditional destination and aborted
  # with a confusing "Header file not found")
  dir <- withr::local_tempdir()
  f <- file.path(dir, "2020_01_02_03_04_05_SpecCube.dat")
  file.copy(tivis.r::tivis_example_file(), f)

  cube <- hs_read_cube(f, verbose = FALSE)
  expect_s3_class(cube, "hsi_cube")
  expect_equal(dim(cube), c(12L, 16L, 8L))
})

test_that("an unidentifiable .dat is rejected with guidance", {
  skip_if_not_installed("withr")
  dir <- withr::local_tempdir()
  f <- file.path(dir, "mystery.dat")
  writeBin(raw(64), f)

  expect_error(hs_read_cube(f), "Cannot determine the format")
})
