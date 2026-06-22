full_cube <- function() {
  hs_simulate_cube(rows = 8, cols = 8, wavelengths = seq(430, 910, by = 16),
                   noise_sd = 0.01, seed = 14)
}

test_that("hs_sto2 ratio method returns 0-100 matrix", {
  cube <- full_cube()
  sto2 <- hs_sto2(cube)
  expect_true(is.matrix(sto2))
  expect_true(all(sto2 >= 0 & sto2 <= 100, na.rm = TRUE))
})

test_that("hs_sto2 beer_lambert method delegates", {
  cube <- full_cube()
  sto2 <- hs_sto2(cube, method = "beer_lambert")
  expect_true(is.matrix(sto2))
})

test_that("hs_sto2 respects mask (NA in masked pixels)", {
  cube <- full_cube()
  cube$mask <- matrix(TRUE, 8, 8)
  cube$mask[1, ] <- FALSE
  sto2 <- hs_sto2(cube)
  expect_true(all(is.na(sto2[1, ])))
})

test_that("hs_sto2 errors when bands unavailable", {
  cube <- hs_simulate_cube(rows = 4, cols = 4, wavelengths = c(430, 450),
                           noise_sd = 0, seed = 1)
  expect_error(suppressWarnings(hs_sto2(cube)), "not available")
})

test_that("hs_npi and hs_thi return 0-100 maps", {
  cube <- full_cube()
  expect_true(all(hs_npi(cube) >= 0 & hs_npi(cube) <= 100, na.rm = TRUE))
  expect_true(all(hs_thi(cube) >= 0 & hs_thi(cube) <= 100, na.rm = TRUE))
})

test_that("hs_npi errors when bands unavailable", {
  cube <- hs_simulate_cube(rows = 4, cols = 4, wavelengths = c(430, 450),
                           noise_sd = 0, seed = 1)
  expect_error(suppressWarnings(hs_npi(cube)), "not available")
})

test_that("hs_twi returns NA matrix with warning on short range", {
  cube <- hs_simulate_cube(rows = 4, cols = 4, wavelengths = seq(500, 700, by = 20),
                           noise_sd = 0, seed = 1)
  expect_warning(twi <- hs_twi(cube), "not available")
  expect_true(all(is.na(twi)))
})

test_that("hs_twi computes when range permits", {
  cube <- full_cube()
  twi <- suppressWarnings(hs_twi(cube))
  expect_true(is.matrix(twi))
})

test_that("hs_ndi with center wavelengths", {
  cube <- full_cube()
  ndi <- hs_ndi(cube, band1 = 540, band2 = 660)
  expect_true(all(ndi >= -1 & ndi <= 1, na.rm = TRUE))
})

test_that("hs_ndi with range bands", {
  cube <- full_cube()
  ndi <- hs_ndi(cube, band1 = c(530, 550), band2 = c(650, 670))
  expect_true(is.matrix(ndi))
})

test_that("hs_clinical_indices returns named list", {
  cube <- full_cube()
  idx <- hs_clinical_indices(cube)
  expect_equal(names(idx), c("sto2", "npi", "thi", "twi"))
  expect_true(all(vapply(idx, is.matrix, logical(1))))
})

test_that("index functions validate cube", {
  expect_error(hs_sto2(list()), "hsi_cube")
  expect_error(hs_npi(list()), "hsi_cube")
  expect_error(hs_thi(list()), "hsi_cube")
  expect_error(hs_twi(list()), "hsi_cube")
  expect_error(hs_ndi(list(), 500, 600), "hsi_cube")
  expect_error(hs_clinical_indices(list()), "hsi_cube")
})

test_that("hs_sto2 output is regression-stable", {
  cube <- hs_simulate_cube(rows = 4, cols = 4, wavelengths = seq(430, 910, by = 40),
                           noise_sd = 0, seed = 1)
  sto2 <- hs_sto2(cube)
  expect_snapshot_value(round(as.vector(sto2), 2), style = "json2")
})
