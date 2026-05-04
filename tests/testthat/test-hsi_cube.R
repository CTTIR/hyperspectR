test_that("hsi_cube constructor creates valid object", {
  data <- array(runif(10 * 10 * 5), dim = c(10, 10, 5))
  wl <- c(500, 550, 600, 650, 700)
  cube <- hsi_cube(data, wl)

  expect_s3_class(cube, "hsi_cube")
  expect_equal(dim(cube), c(10, 10, 5))
  expect_equal(cube$wavelengths, wl)
  expect_null(cube$fwhm)
  expect_null(cube$mask)
})

test_that("hsi_cube validates inputs", {
  expect_error(hsi_cube(data = "not_array", wavelengths = 1:10))
  expect_error(hsi_cube(data = array(1, c(5, 5, 3)), wavelengths = 1:5))
  expect_error(hsi_cube(data = array(1, c(5, 5, 3)), wavelengths = 1:3,
                         mask = matrix(TRUE, 3, 3)))
})

test_that("hsi_cube accepts fwhm", {
  data <- array(1, dim = c(5, 5, 3))
  cube <- hsi_cube(data, 1:3, fwhm = 25)
  expect_equal(cube$fwhm, rep(25, 3))
})

test_that("print.hsi_cube works", {
  cube <- hs_example_cube()
  # cli output goes to messages, not stdout
  expect_message(print(cube), "hsi_cube")
  expect_message(print(cube), "Dimensions")
})

test_that("summary.hsi_cube works", {
  cube <- hs_example_cube()
  s <- summary(cube)
  expect_type(s, "list")
  expect_equal(s$dimensions, dim(cube))
  expect_length(s$band_means, dim(cube)[3])
})

test_that("dim.hsi_cube returns correct dimensions", {
  cube <- hs_example_cube()
  expect_equal(dim(cube), c(30, 30, 61))
})

test_that("subsetting preserves class", {
  cube <- hs_example_cube()
  sub <- cube[1:5, 1:5, ]
  expect_s3_class(sub, "hsi_cube")
  expect_equal(dim(sub), c(5, 5, length(cube$wavelengths)))
})

test_that("subsetting bands works", {
  cube <- hs_example_cube()
  sub <- cube[, , 1:10]
  expect_equal(dim(sub)[3], 10)
  expect_equal(sub$wavelengths, cube$wavelengths[1:10])
})

test_that("as.data.frame.hsi_cube works in wide format", {
  cube <- hs_example_cube()
  sub <- cube[1:3, 1:3, 1:3]
  df <- as.data.frame(sub)
  expect_true(is.data.frame(df))
  expect_equal(nrow(df), 9)
  expect_true("x" %in% names(df))
})

test_that("as.data.frame.hsi_cube works in long format", {
  cube <- hs_example_cube()
  sub <- cube[1:3, 1:3, 1:3]
  df <- as.data.frame(sub, long = TRUE)
  expect_equal(nrow(df), 9 * 3)
  expect_true("wavelength" %in% names(df))
  expect_true("value" %in% names(df))
})
