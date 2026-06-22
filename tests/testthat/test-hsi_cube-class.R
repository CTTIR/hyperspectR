test_that("hsi_cube constructs with defaults", {
  cube <- hsi_cube(array(0.5, c(4, 4, 3)), c(500, 600, 700))
  expect_s3_class(cube, "hsi_cube")
  expect_equal(dim(cube), c(4, 4, 3))
  expect_null(cube$fwhm)
  expect_null(cube$mask)
})

test_that("scalar fwhm is recycled to all bands", {
  cube <- hsi_cube(array(0.5, c(2, 2, 3)), c(500, 600, 700), fwhm = 10)
  expect_equal(cube$fwhm, rep(10, 3))
})

test_that("non-numeric data errors", {
  expect_error(hsi_cube("x", c(1, 2, 3)), "must be numeric")
})

test_that("non-3D array errors", {
  expect_error(hsi_cube(matrix(1, 4, 4), c(1, 2, 3)), "3D array")
})

test_that("wavelength length mismatch errors", {
  expect_error(hsi_cube(array(0.5, c(4, 4, 3)), c(500, 600)), "must match")
})

test_that("non-list metadata errors", {
  expect_error(
    hsi_cube(array(0.5, c(2, 2, 3)), c(500, 600, 700), metadata = 1),
    "must be a list"
  )
})

test_that("fwhm length mismatch errors", {
  expect_error(
    hsi_cube(array(0.5, c(2, 2, 3)), c(500, 600, 700), fwhm = c(1, 2)),
    "must match"
  )
})

test_that("bad mask type errors", {
  expect_error(
    hsi_cube(array(0.5, c(2, 2, 3)), c(500, 600, 700), mask = 1),
    "logical matrix"
  )
})

test_that("mask dimension mismatch errors", {
  expect_error(
    hsi_cube(array(0.5, c(4, 4, 3)), c(500, 600, 700),
             mask = matrix(TRUE, 2, 2)),
    "dimensions"
  )
})

test_that("unsorted wavelengths trigger sort + warning", {
  expect_warning(
    cube <- hsi_cube(array(seq_len(2 * 2 * 3), c(2, 2, 3)), c(700, 500, 600)),
    "monotonically"
  )
  expect_equal(cube$wavelengths, c(500, 600, 700))
})

test_that("valid mask is preserved", {
  m <- matrix(c(TRUE, FALSE, TRUE, FALSE), 2, 2)
  cube <- hsi_cube(array(0.5, c(2, 2, 3)), c(500, 600, 700), mask = m)
  expect_identical(cube$mask, m)
})

test_that("constructor output is a regression-stable structure", {
  cube <- hsi_cube(array(0.5, c(2, 2, 2)), c(500, 600))
  expect_snapshot_value(names(cube), style = "json2")
})
