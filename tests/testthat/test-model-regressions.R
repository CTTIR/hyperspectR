test_that("F05/F06: pinned reference coefficients and declared domains recover known mixtures", {
  tab <- hs_chromophore_data(wavelength_range = c(500, 600))
  expect_equal(tab$HbO2[1], 20932.8)
  expect_equal(tab$Hb[1], 20862)
  em <- as.matrix(tab[c("HbO2", "Hb")])
  expected <- c(7e-6, 3e-6)
  absorbance <- as.vector(em %*% expected)
  cube <- hsi_cube(array(10^(-absorbance), c(1, 1, length(absorbance))), tab$wavelength,
                   metadata = list(processing_mode = "reflectance"))
  fit <- hs_beer_lambert(cube)
  direct <- hs_beer_lambert(hs_absorbance(cube))
  expect_equal(as.numeric(fit$sto2), 70, tolerance = 1e-7)
  expect_equal(direct$sto2, fit$sto2, tolerance = 1e-7)
  expect_equal(unlist(fit$coefficients), setNames(expected, c("HbO2", "Hb")), tolerance = 1e-9)
  expect_null(fit$concentrations)
  known <- hs_beer_lambert(cube, pathlength_cm = 2)
  expect_equal(unlist(known$concentrations), setNames(expected / 2, c("HbO2", "Hb")), tolerance = 1e-9)
  expect_equal(known$concentration_units, "mol/L")
  cube$metadata <- list()
  expect_error(hs_beer_lambert(cube), "Declare input")
  expect_equal(hs_beer_lambert(cube, input = "reflectance")$sto2, fit$sto2)
  expect_error(hs_beer_lambert(hs_snv(cube)), "incompatible")
  expect_error(hs_chromophore_data("water"), "only")
})

test_that("F01: relative band ratios are scene independent and not oxygen percentages", {
  x <- hsi_cube(array(c(1, 10, 2, 30), c(1, 2, 2)), c(500, 700))
  first <- hs_band_ratio(x, 700, 500)[1, 1]
  x$data[1, 2, ] <- c(999, 9999)
  expect_equal(hs_band_ratio(x, 700, 500)[1, 1], first)
  expect_error(hs_sto2(x, method = "ratio"), "not oxygen saturation")
})

test_that("F07/F14/F21: equality unmixing and missing pixels obey constraints", {
  x <- hsi_cube(array(1, c(1, 2, 2)), c(500, 600), mask = matrix(c(TRUE, FALSE), 1))
  fit <- hs_unmix_nnls(x, diag(2), sum_to_one = TRUE)
  expect_equal(fit$abundances[1, 1, ], c(.5, .5), tolerance = 1e-8)
  expect_true(all(is.na(fit$abundances[1, 2, ])))
  expect_equal(fit$rmse[1, 1], .5)
  expect_equal(fit$status[1, 2], "invalid")
  x$mask <- NULL
  x$data[1, 1, ] <- c(2, .2)
  expect_equal(hs_unmix_nnls(x, diag(2), sum_to_one = TRUE)$abundances[1, 1, ], c(1, 0), tolerance = 1e-8)
  small <- hs_unmix_nnls(x, diag(2), chunk_size = 1, keep_residuals = FALSE)
  large <- hs_unmix_nnls(x, diag(2), chunk_size = 100)
  expect_equal(small$abundances, large$abundances)
  expect_equal(small$rmse, large$rmse)
  expect_null(small$residuals)
  if (requireNamespace("nnls", quietly = TRUE)) expect_equal(hs_unmix_nnls(x, diag(2), backend = "nnls")$abundances, large$abundances)
})

test_that("F07/F22: reduction caps rank, masks invalid data and reuses fitted transforms", {
  x <- hsi_cube(array(c(1:3, 3:1, 1:3, 2:4, 2:4), c(1, 3, 5)), seq(500, 540, 10))
  fit <- hs_pca(x, n_components = 5)
  expect_lte(dim(fit$scores)[3], 2)
  expect_equal(hs_transform(fit, x), fit$scores, tolerance = 1e-8)
  x$mask <- matrix(c(TRUE, TRUE, FALSE), 1)
  x$data[1, 3, ] <- NA_real_
  fit <- hs_pca(x)
  expect_true(all(is.na(fit$scores[1, 3, ])))
  y <- hs_simulate_cube(rows = 5, cols = 4, seed = 8)
  mnf <- hs_mnf(y, n_components = 3)
  expect_equal(hs_transform(mnf, y), mnf$scores, tolerance = 1e-8)
})

test_that("masked classifier pixels never affect training or receive predictions", {
  skip_if_not_installed("e1071")
  cube <- hsi_cube(array(c(1, 2, 1.1, 2.1, 999, 2, 1, 2.1, 1.1, NA, 1, 2, 1, 2, NA), c(5, 1, 3)), c(500, 600, 700), mask = matrix(c(TRUE, TRUE, TRUE, TRUE, FALSE), 5, 1))
  labels <- matrix(c("a", "b", "a", "b", "outlier"), 5, 1)
  model <- hs_classify_svm(cube, labels, kernel = "linear")
  expect_equal(model$training_pixels, 4)
  expect_true(is.na(model$class_map[5, 1]))
  expect_equal(hs_predict(model, cube), model$class_map)
  em <- rbind(a = cube$data[1, 1, ], b = cube$data[2, 1, ])
  expect_true(is.na(hs_sam(cube, em)$class_map[5, 1]))
})

test_that("ideal fractions recover across endpoints and total coefficient scales", {
  reference <- hs_chromophore_data(wavelength_range = c(500, 600))
  cases <- expand.grid(fraction = c(0, .1, .3, .5, .7, .9, 1), total = c(1e-6, 1e-5, 5e-5))
  coefficients <- cbind(cases$fraction * cases$total, (1 - cases$fraction) * cases$total)
  absorbance <- coefficients %*% t(as.matrix(reference[c("HbO2", "Hb")]))
  cube <- hsi_cube(array(10^(-absorbance), c(nrow(cases), 1, nrow(reference))), reference$wavelength,
                   metadata = list(processing_mode = "reflectance"))
  fit <- hs_beer_lambert(cube)
  expect_equal(as.vector(fit$sto2), cases$fraction * 100, tolerance = 1e-4)
  cube$data[] <- 1
  fit <- hs_beer_lambert(cube)
  expect_true(all(is.na(fit$sto2)))
  expect_true(all(fit$status == "no_hemoglobin_signal"))
})

test_that("NNLS reconstruction is stable across scales and rank deficiency", {
  for (scale in c(1e-8, 1, 1e8)) {
    em <- matrix(c(1, 2, 3, 3, 2, 1), 3, 2) * scale
    cube <- hsi_cube(array(as.vector(em %*% c(.2, .7)), c(1, 1, 3)), c(500, 550, 600))
    expect_equal(as.vector(hs_unmix_nnls(cube, em)$abundances), c(.2, .7), tolerance = 1e-8)
  }
  em <- matrix(rep(1:3, 2), 3, 2)
  cube <- hsi_cube(array((1:3) * .25, c(1, 1, 3)), c(500, 550, 600))
  expect_warning(fit <- hs_unmix_nnls(cube, em), "rank deficient")
  expect_equal(sum(fit$abundances), .25, tolerance = 1e-8)
  expect_equal(as.numeric(fit$rmse), 0, tolerance = 1e-8)
})
