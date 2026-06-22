make_cube <- function() {
  hs_simulate_cube(rows = 6, cols = 6, wavelengths = seq(500, 600, by = 20),
                   noise_sd = 0, seed = 5)
}

test_that("hs_calibrate produces reflectance in [0,1] with clamp", {
  cube <- make_cube()
  dark <- hsi_cube(array(0.01, dim(cube$data)), cube$wavelengths)
  white <- hsi_cube(array(0.95, dim(cube$data)), cube$wavelengths)
  cal <- hs_calibrate(cube, dark, white)
  expect_true(all(cal$data >= 0 & cal$data <= 1))
  expect_true(cal$metadata$calibrated)
  expect_equal(cal$metadata$processing_mode, "reflectance")
})

test_that("hs_calibrate without clamp can exceed [0,1]", {
  cube <- make_cube()
  cube$data[1, 1, 1] <- 2
  dark <- hsi_cube(array(0.01, dim(cube$data)), cube$wavelengths)
  white <- hsi_cube(array(0.5, dim(cube$data)), cube$wavelengths)
  cal <- hs_calibrate(cube, dark, white, clamp = FALSE)
  expect_gt(max(cal$data), 1)
})

test_that("hs_calibrate accepts array references", {
  cube <- make_cube()
  cal <- hs_calibrate(cube, array(0.01, dim(cube$data)),
                      array(0.95, dim(cube$data)))
  expect_s3_class(cal, "hsi_cube")
})

test_that("hs_calibrate rejects invalid reference", {
  cube <- make_cube()
  expect_error(hs_calibrate(cube, "bad", array(1, dim(cube$data))),
               "hsi_cube|3D array")
})

test_that("hs_dark_correct subtracts dark", {
  cube <- make_cube()
  dark <- hsi_cube(array(0.1, dim(cube$data)), cube$wavelengths)
  corr <- hs_dark_correct(cube, dark)
  expect_true(corr$metadata$dark_corrected)
  expect_equal(corr$data, cube$data - 0.1)
})

test_that("hs_white_normalize with and without dark", {
  cube <- make_cube()
  white <- hsi_cube(array(0.9, dim(cube$data)), cube$wavelengths)
  dark <- hsi_cube(array(0.05, dim(cube$data)), cube$wavelengths)
  n1 <- hs_white_normalize(cube, white)
  expect_true(n1$metadata$white_normalized)
  n2 <- hs_white_normalize(cube, white, dark)
  expect_true(n2$metadata$white_normalized)
  expect_true(n2$metadata$dark_corrected)
})

test_that("hs_fix_bad_pixels repairs a hot pixel (median and mean)", {
  cube <- make_cube()
  cube$data[3, 3, ] <- 999
  fixed_med <- hs_fix_bad_pixels(cube, threshold = 2, method = "median")
  expect_lt(max(fixed_med$data[3, 3, ]), 900)
  expect_gt(fixed_med$metadata$bad_pixels_fixed, 0)

  fixed_mean <- hs_fix_bad_pixels(cube, threshold = 2, method = "mean")
  expect_lt(max(fixed_mean$data[3, 3, ]), 900)
})

test_that("hs_fix_bad_pixels leaves clean cube unchanged in count", {
  cube <- make_cube()
  fixed <- hs_fix_bad_pixels(cube, threshold = 100)
  expect_equal(fixed$metadata$bad_pixels_fixed, 0L)
})

test_that("calibration functions validate cube", {
  expect_error(hs_calibrate(list(), 1, 1), "hsi_cube")
  expect_error(hs_dark_correct(list(), 1), "hsi_cube")
  expect_error(hs_white_normalize(list(), 1), "hsi_cube")
  expect_error(hs_fix_bad_pixels(list()), "hsi_cube")
})
