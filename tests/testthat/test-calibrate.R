test_that("hs_calibrate produces reflectance in [0, 1]", {
  raw <- hs_simulate_cube(rows = 10, cols = 10, noise_sd = 0, seed = 1)
  dark <- hsi_cube(data = array(0.01, dim(raw$data)),
                   wavelengths = raw$wavelengths)
  white <- hsi_cube(data = array(0.99, dim(raw$data)),
                    wavelengths = raw$wavelengths)
  cal <- hs_calibrate(raw, dark, white)
  expect_true(all(cal$data >= 0 & cal$data <= 1))
  expect_true(cal$metadata$calibrated)
})

test_that("hs_dark_correct subtracts dark", {
  cube <- hs_simulate_cube(rows = 5, cols = 5,
                           wavelengths = seq(430, 470, by = 8),
                           noise_sd = 0, seed = 1)
  dark <- hsi_cube(data = array(0.05, dim(cube$data)),
                   wavelengths = cube$wavelengths)
  corrected <- hs_dark_correct(cube, dark)
  expect_true(all(corrected$data <= cube$data))
})

test_that("hs_white_normalize divides by white", {
  cube <- hs_simulate_cube(rows = 5, cols = 5,
                           wavelengths = seq(430, 470, by = 8),
                           noise_sd = 0, seed = 1)
  white <- hsi_cube(data = array(0.9, dim(cube$data)),
                    wavelengths = cube$wavelengths)
  norm <- hs_white_normalize(cube, white)
  expect_s3_class(norm, "hsi_cube")
})

test_that("hs_fix_bad_pixels corrects outliers", {
  cube <- hs_simulate_cube(rows = 10, cols = 10,
                           wavelengths = seq(430, 510, by = 8),
                           noise_sd = 0, seed = 1)
  # Introduce a hot pixel
  cube$data[5, 5, ] <- 999
  fixed <- hs_fix_bad_pixels(cube, threshold = 3)
  expect_true(all(fixed$data[5, 5, ] < 100))
  expect_true(fixed$metadata$bad_pixels_fixed >= 1)
})
