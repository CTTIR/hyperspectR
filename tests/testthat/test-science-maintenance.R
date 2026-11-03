test_that("calibration preserves invalid input and intermediate values", {
  values <- c(Inf, -Inf, NA_real_, NaN, -.2, .5, 1.2)
  cube <- hsi_cube(array(values, c(7, 1, 1)), 500)
  original <- cube
  dark <- array(0, dim(cube$data))
  white <- array(1, dim(cube$data))
  for (clamp in c(TRUE, FALSE)) {
    result <- hs_calibrate(cube, dark, white, clamp = clamp)
    expect_true(all(is.na(result$data[1:4, , ])))
    expect_equal(as.vector(result$mask), c(rep(FALSE, 4), rep(TRUE, 3)))
    expect_equal(as.vector(result$metadata$calibration_invalid),
                 c(rep(TRUE, 4), rep(FALSE, 3)))
    expect_equal(as.vector(result$metadata$calibration_clipped),
                 c(rep(FALSE, 4), TRUE, FALSE, TRUE))
    expect_equal(as.vector(result$data[5:7, , ]),
                 if (clamp) c(0, .5, 1) else c(-.2, .5, 1.2))
  }
  expect_identical(cube, original)
  extreme <- hsi_cube(array(1e308, c(1, 1, 1)), 500)
  result <- hs_calibrate(extreme, array(-1e308, c(1, 1, 1)),
                         array(0, c(1, 1, 1)))
  expect_true(is.na(result$data[1]))
  expect_true(result$metadata$calibration_invalid[1])
  expect_false(result$mask[1])
})

test_that("integer sensor subtraction is performed without integer overflow", {
  cube <- hsi_cube(array(0L, c(1, 1, 2)), c(500, 600))
  expect_no_warning(result <- hs_calibrate(cube,
    array(-2000000000L, c(1, 1, 2)), array(2000000000L, c(1, 1, 2))))
  expect_equal(as.vector(result$data), c(.5, .5))
  expect_true(result$mask[1])
})

test_that("spectral angles preserve direction across independent magnitudes", {
  directions <- rbind(c(1, 0, 1), c(0, 1, 0), c(-1, 0, -1),
                      c(0, 0, 0), c(NA, 1, 1))
  endmembers <- rbind(a = c(1, 0, 1), b = c(0, 1, 0))
  expected <- rbind(c(0, pi / 2), c(pi / 2, 0), c(pi, pi / 2))
  for (pixel_scale in c(1e-200, 1, 1e200)) {
    cube <- hsi_cube(array(directions * pixel_scale, c(5, 1, 3)), c(500, 600, 700))
    for (reference_scale in c(1e-200, 1, 1e200)) {
      result <- hs_sam(cube, endmembers * reference_scale, threshold = 0)
      expect_equal(result$angle_map[1:3, 1, ], expected, tolerance = 1e-14)
      expect_equal(as.vector(result$class_map), c("a", "b", "unclassified", NA, NA))
      expect_true(all(is.na(result$angle_map[4:5, 1, ])))
    }
  }
})

test_that("derivative orders are validated before coercion", {
  wavelengths <- seq(500, 580, 10)
  cube <- hsi_cube(array((wavelengths - 500)^2, c(1, 1, 9)), wavelengths)
  for (order in list(1.5, 0, -1, NA_real_, Inf, .Machine$integer.max, "1")) {
    expect_error(hs_derivative(cube, order = order), "positive integer")
  }
  expect_equal(as.vector(hs_derivative(cube, order = 1)$data),
               2 * (wavelengths[3:7] - 500), tolerance = 1e-10)
  expect_equal(as.vector(hs_derivative(cube, order = 2)$data), rep(2, 5),
               tolerance = 1e-10)
})

test_that("saved transforms require the exact ordered preprocessing recipe", {
  pixels <- rbind(c(1, .2, 2, .5, 3), c(2, .5, 3, .8, 2),
                  c(3, 1, 4, 1, 2), c(1, .6, 3, 1.2, 4))
  cube <- hsi_cube(array(pixels, c(4, 1, 5)), seq(500, 540, 10))
  division <- hs_continuum_removal(cube, "division")
  subtraction <- hs_continuum_removal(cube, "subtraction")
  model <- hs_pca(division, 2)
  expect_error(hs_transform(model, subtraction), "preprocessing")
  first <- hs_snv(hs_smooth(cube, window = 3, poly = 1))
  second <- hs_smooth(hs_snv(cube), window = 3, poly = 1)
  expect_error(hs_transform(hs_pca(first, 2), second), "preprocessing")
  held_out <- cube
  held_out$data <- held_out$data * .9
  held_out$metadata$recording_id <- "held-out-recording"
  held_out$metadata$acquisition_time <- "2025-01-01"
  held_out <- hs_continuum_removal(held_out, "division")
  held_out$metadata$history[[1]]$package_version <- "earlier-compatible-version"
  expected <- sweep(matrix(held_out$data, 4, 5), 2, model$center, "-") %*% model$loadings
  expect_equal(hs_transform(model, held_out), array(expected, dim(model$scores)))
  unrelated <- division
  unrelated$metadata$sg_window_backup <- 7
  unrelated$metadata$msc_reference_backup <- rep(99, 5)
  expect_equal(hs_transform(model, unrelated), model$scores)
  legacy <- model
  legacy$feature_contract$schema_version <- NULL
  expect_error(hs_transform(legacy, division), "Refit")
})

test_that("saved classifiers reject incompatible and legacy preprocessing", {
  skip_if_not_installed("e1071")
  pixels <- rbind(c(1, .2, 2, .5, 3), c(2, .5, 3, .8, 2),
                  c(3, 1, 4, 1, 2), c(1, .6, 3, 1.2, 4))
  cube <- hsi_cube(array(pixels, c(4, 1, 5)), seq(500, 540, 10))
  division <- hs_continuum_removal(cube, "division")
  model <- hs_classify_svm(division, matrix(c("a", "a", "b", "b"), 4, 1),
                           kernel = "linear", scale = FALSE)
  expect_equal(hs_predict(model, division), model$class_map)
  expect_error(hs_predict(model, hs_continuum_removal(cube, "subtraction")), "preprocessing")
  model$feature_contract <- NULL
  expect_error(hs_predict(model, division), "Retrain")
})
