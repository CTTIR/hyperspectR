test_that("F16: wavelength sorting keeps FWHM attached to its band", {
  expect_warning(x <- hsi_cube(array(rep(c(6, 5, 4), each = 4), c(2, 2, 3)),
                              c(600, 500, 400), fwhm = c(60, 50, 40)), "sorting")
  expect_equal(x$data[1, 1, ], c(4, 5, 6))
  expect_equal(x$fwhm, c(40, 50, 60))
  expect_error(hsi_cube(array(1, c(1, 1, 2)), c(500, 500)), "unique")
  expect_error(hsi_cube(array(1, c(1, 1, 2)), c(500, NA)), "finite")
  expect_error(hsi_cube(array(1, c(1, 1, 2)), c(500, 600), fwhm = -1), "positive")
  expect_error(hsi_cube(array(1, c(0, 1, 2)), c(500, 600)), "positive")
})

test_that("F07/F21: ROI statistics omit invalid pixels and preserve narrow images", {
  x <- hsi_cube(array(rep(c(1, 1, 1, 100), 2), c(2, 2, 2)), c(500, 600),
                mask = matrix(c(TRUE, TRUE, TRUE, FALSE), 2))
  s <- hs_roi_stats(x, matrix(TRUE, 2, 2))
  expect_equal(s$mean, c(1, 1))
  expect_equal(s$n_pixels, c(3L, 3L))
  expect_equal(summary(x)$band_means, c(`500` = 1, `600` = 1))
  expect_equal(dim(hs_ndi(x[1, , ], 500, 600)), c(1L, 2L))
  expect_error(hs_roi_stats(x, matrix(TRUE, 3, 3)), "dimensions")
})

test_that("F02/F13: SG retains true centers and differentiates in wavelength units", {
  wl <- seq(500, 580, 10)
  x <- hsi_cube(array(rep(wl - 500, each = 4), c(2, 2, 9)), wl, fwhm = seq_len(9))
  out <- hs_smooth(x, window = 5)
  expect_equal(out$wavelengths, wl[3:7])
  expect_equal(out$fwhm, 3:7)
  expect_equal(out$data[1, 1, ], c(20, 30, 40, 50, 60), tolerance = 1e-9)
  expect_equal(as.vector(hs_derivative(x)$data), rep(1, 20), tolerance = 1e-9)
  x$data <- x$data^2
  expect_equal(as.vector(hs_derivative(x, order = 2)$data), rep(2, 20), tolerance = 1e-9)
  x$wavelengths[2] <- 511
  expect_error(hs_smooth(x), "uniform")
})

test_that("F15/F18/F19: reference alignment and bad-pixel neighbors are correct", {
  x <- hsi_cube(array(1, c(3, 3, 2)), c(500, 600))
  ref <- hsi_cube(array(1, c(3, 3, 2)), c(600, 700))
  expect_error(hs_white_normalize(x, ref), "wavelength")
  x$data[2, 2, ] <- 999
  y <- hs_fix_bad_pixels(x)
  expect_equal(y$data[2, 2, ], c(1, 1))
  expect_true(y$metadata$repair_mask[2, 2])
  x$data[, , 1] <- x$data[, , 2] <- matrix(c(1, 2, 3, 4, 999, 6, 7, 8, 9), 3)
  expect_equal(hs_fix_bad_pixels(x, method = "mean")$data[2, 2, ], c(5, 5))
})

test_that("adjacent defects are detected before either is repaired", {
  cube <- hsi_cube(array(1, c(4, 4, 2)), c(500, 600))
  cube$data[2, 2:3, ] <- 999
  fixed <- hs_fix_bad_pixels(cube, method = "mean")
  expect_equal(fixed$data, array(1, c(4, 4, 2)))
  expect_equal(sum(fixed$metadata$repair_mask), 2)
})

test_that("calibration reports denominator, saturation and compatibility QC", {
  cube <- hsi_cube(array(c(100, 65535, 100), c(3, 1, 1)), 500)
  white <- hsi_cube(array(c(200, 200, 1e-12), c(3, 1, 1)), 500)
  dark <- array(0, c(3, 1, 1))
  result <- hs_calibrate(cube, dark, white, saturation = 65535, clamp = FALSE)
  expect_equal(result$data[1, 1, 1], .5)
  expect_true(all(is.na(result$data[2:3, 1, 1])))
  expect_true(result$metadata$calibration_saturated[2, 1, 1])
  expect_true(result$metadata$calibration_invalid[3, 1, 1])
  expect_true(result$metadata$saturation_checked)
  expect_setequal(result$metadata$calibration_compatibility_unknown, c("integration_time", "gain", "sensor_id"))
})
