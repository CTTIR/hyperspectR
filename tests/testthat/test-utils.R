test_that(".validate_cube accepts valid cube and rejects others", {
  cube <- hs_simulate_cube(rows = 4, cols = 4, wavelengths = c(500, 600),
                           noise_sd = 0, seed = 1)
  expect_identical(.validate_cube(cube), cube)
  expect_error(.validate_cube(list()), "hsi_cube")
})

test_that(".validate_cube catches structural corruption", {
  cube <- hs_simulate_cube(rows = 4, cols = 4, wavelengths = c(500, 600),
                           noise_sd = 0, seed = 1)
  bad <- cube
  bad$data <- matrix(1, 4, 4)
  expect_error(.validate_cube(bad), "3D array")

  bad2 <- cube
  bad2$wavelengths <- c(500, 600, 700)
  expect_error(.validate_cube(bad2), "must match")

  bad3 <- cube
  bad3$mask <- matrix(TRUE, 2, 2)
  expect_error(.validate_cube(bad3), "dimensions")
})

test_that(".band_index finds nearest wavelength", {
  expect_equal(.band_index(c(500, 550, 600), 540), 2L)
  expect_equal(.band_index(c(500, 550, 600), 700), 3L)
})

test_that(".band_mean handles single, multi, and empty ranges", {
  cube <- hs_simulate_cube(rows = 4, cols = 4, wavelengths = seq(500, 600, by = 25),
                           noise_sd = 0, seed = 1)
  single <- .band_mean(cube, c(498, 502))
  expect_true(is.matrix(single))
  multi <- .band_mean(cube, c(500, 600))
  expect_equal(dim(multi), c(4, 4))
  expect_null(.band_mean(cube, c(1000, 1100)))
})

test_that(".apply_mask sets masked pixels to NA and passes NULL", {
  m <- matrix(1, 3, 3)
  mask <- matrix(c(TRUE, FALSE, TRUE, FALSE, TRUE, FALSE, TRUE, FALSE, TRUE),
                 nrow = 3, ncol = 3)
  out <- .apply_mask(m, mask)
  expect_true(all(is.na(out[!mask])))
  expect_identical(.apply_mask(m, NULL), m)
})

test_that(".check_wavelength_coverage warns when range insufficient", {
  expect_false(suppressWarnings(.check_wavelength_coverage(c(500, 600), c(450, 700), "X")))
  expect_warning(.check_wavelength_coverage(c(500, 600), c(450, 700), "X"))
  expect_true(.check_wavelength_coverage(c(400, 800), c(450, 700), "X"))
})

test_that(".wavelength_to_color covers all hue branches", {
  cols <- .wavelength_to_color(c(350, 400, 430, 470, 500, 540, 600, 660, 720, 800))
  expect_type(cols, "character")
  expect_equal(cols[1], "#333333")  # out of visible range
  expect_true(all(grepl("^#", cols)))
})

test_that(".linear_stretch maps to 0-1 and handles constant input", {
  out <- .linear_stretch(matrix(1:9, 3))
  expect_true(all(out >= 0 & out <= 1))
  const <- .linear_stretch(matrix(5, 3, 3))
  expect_true(all(const == 0.5))
})

test_that(".sg_coefficients produce smoothing weights summing to one", {
  coefs <- .sg_coefficients(5, 2, 0)
  expect_length(coefs, 5)
  expect_equal(sum(coefs), 1, tolerance = 1e-8)
})

test_that(".sg_coefficients first derivative sums to ~zero", {
  coefs <- .sg_coefficients(5, 2, 1)
  expect_equal(sum(coefs), 0, tolerance = 1e-8)
})
