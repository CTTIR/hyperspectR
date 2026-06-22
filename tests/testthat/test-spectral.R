make_cube <- function() {
  hs_simulate_cube(rows = 6, cols = 5, wavelengths = seq(500, 600, by = 10),
                   noise_sd = 0, seed = 4)
}

test_that("hs_absorbance converts and tags metadata", {
  cube <- make_cube()
  ab <- hs_absorbance(cube)
  expect_s3_class(ab, "hsi_cube")
  expect_equal(ab$metadata$processing_mode, "absorbance")
  expect_equal(dim(ab), dim(cube))
})

test_that("hs_absorbance clamps non-positive reflectance", {
  cube <- make_cube()
  cube$data[1, 1, 1] <- 0
  cube$data[1, 1, 2] <- -0.5
  ab <- hs_absorbance(cube, floor = 1e-4)
  expect_true(all(is.finite(ab$data)))
  expect_equal(ab$data[1, 1, 1], -log10(1e-4))
})

test_that("hs_continuum_removal division returns values <= ~1", {
  cube <- make_cube()
  cr <- hs_continuum_removal(cube, method = "division")
  expect_s3_class(cr, "hsi_cube")
  expect_equal(cr$metadata$continuum_removed, "division")
  expect_true(all(cr$data <= 1 + 1e-6, na.rm = TRUE))
})

test_that("hs_continuum_removal subtraction returns values <= ~0", {
  cube <- make_cube()
  cr <- hs_continuum_removal(cube, method = "subtraction")
  expect_equal(cr$metadata$continuum_removed, "subtraction")
  expect_true(all(cr$data <= 1e-6, na.rm = TRUE))
})

test_that("hs_continuum_removal rejects unknown method", {
  expect_error(hs_continuum_removal(make_cube(), method = "bad"))
})

test_that("hs_resample linear changes band count", {
  cube <- make_cube()
  target <- seq(510, 590, by = 5)
  res <- hs_resample(cube, target)
  expect_equal(length(res$wavelengths), length(target))
  expect_equal(dim(res)[3], length(target))
  expect_false(is.null(res$fwhm))
})

test_that("hs_resample spline method works", {
  cube <- make_cube()
  target <- seq(510, 590, by = 20)
  res <- hs_resample(cube, target, method = "spline")
  expect_equal(length(res$wavelengths), length(target))
})

test_that("hs_resample rejects unknown method", {
  expect_error(hs_resample(make_cube(), c(520, 560), method = "nope"))
})

test_that("hs_resample drops fwhm when input lacks it", {
  cube <- make_cube()
  cube$fwhm <- NULL
  res <- hs_resample(cube, seq(520, 580, by = 10))
  expect_null(res$fwhm)
})

test_that("continuum-removed output is regression-stable", {
  cube <- hs_simulate_cube(rows = 3, cols = 3, wavelengths = seq(500, 560, by = 20),
                           noise_sd = 0, seed = 8)
  cr <- hs_continuum_removal(cube, "division")
  expect_snapshot_value(round(cr$data[1, 1, ], 4), style = "json2")
})

test_that("validation propagates through spectral functions", {
  expect_error(hs_absorbance(list()), "hsi_cube")
  expect_error(hs_continuum_removal(list()), "hsi_cube")
  expect_error(hs_resample(list(), c(500, 600)), "hsi_cube")
})
