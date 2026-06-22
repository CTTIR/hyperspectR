make_cube <- function() {
  hs_simulate_cube(rows = 6, cols = 6, wavelengths = seq(500, 600, by = 10),
                   noise_sd = 0.01, seed = 17)
}

endmembers <- function(cube) {
  cbind(tissue = cube$data[2, 2, ], background = cube$data[5, 5, ])
}

test_that("hs_unmix_nnls returns abundance maps (nnls present)", {
  skip_if_not_installed("nnls")
  cube <- make_cube()
  result <- hs_unmix_nnls(cube, endmembers(cube))
  expect_s3_class(result, "hsi_unmix")
  expect_equal(dim(result$abundances), c(6, 6, 2))
  expect_equal(dim(result$rmse), c(6, 6))
  expect_true(all(result$abundances >= 0))
})

test_that("hs_unmix_nnls sum_to_one constraint", {
  skip_if_not_installed("nnls")
  cube <- make_cube()
  result <- hs_unmix_nnls(cube, endmembers(cube), sum_to_one = TRUE)
  expect_s3_class(result, "hsi_unmix")
})

test_that("hs_unmix_nnls optim fallback (no nnls)", {
  cube <- make_cube()
  testthat::local_mocked_bindings(
    requireNamespace = function(package, ...) {
      if (package == "nnls") return(FALSE)
      TRUE
    },
    .package = "base"
  )
  result <- hs_unmix_nnls(cube, endmembers(cube))
  expect_s3_class(result, "hsi_unmix")
  expect_true(all(result$abundances >= -1e-6))
})

test_that("hs_unmix_nnls optim fallback with sum_to_one", {
  cube <- make_cube()
  testthat::local_mocked_bindings(
    requireNamespace = function(package, ...) {
      if (package == "nnls") return(FALSE)
      TRUE
    },
    .package = "base"
  )
  result <- hs_unmix_nnls(cube, endmembers(cube), sum_to_one = TRUE)
  expect_s3_class(result, "hsi_unmix")
})

test_that("hs_unmix_nnls accepts data.frame input", {
  skip_if_not_installed("nnls")
  cube <- make_cube()
  em <- as.data.frame(endmembers(cube))
  result <- hs_unmix_nnls(cube, em)
  expect_s3_class(result, "hsi_unmix")
  expect_length(result$endmember_names, 2)
})

test_that("hs_unmix_nnls auto-names unnamed matrix endmembers", {
  skip_if_not_installed("nnls")
  cube <- make_cube()
  em <- unname(endmembers(cube))
  result <- hs_unmix_nnls(cube, em)
  expect_true(any(grepl("endmember_", result$endmember_names)))
})

test_that("hs_unmix_nnls rejects band mismatch", {
  cube <- make_cube()
  expect_error(hs_unmix_nnls(cube, matrix(1, 3, 2)), "must match")
})

test_that("hs_beer_lambert estimates StO2 and total Hb", {
  cube <- make_cube()
  fit <- hs_beer_lambert(cube)
  expect_s3_class(fit, "hsi_chromophore_fit")
  expect_true(is.matrix(fit$sto2))
  expect_true(is.matrix(fit$total_hb))
  expect_equal(fit$chromophores, c("HbO2", "Hb"))
})

test_that("hs_beer_lambert with single chromophore has no StO2", {
  cube <- make_cube()
  fit <- hs_beer_lambert(cube, chromophores = "HbO2")
  expect_null(fit$sto2)
})

test_that("hs_beer_lambert errors with too few bands in range", {
  cube <- make_cube()
  expect_error(hs_beer_lambert(cube, wavelength_range = c(500, 505)),
               "at least 2 bands")
})

test_that("hs_beer_lambert handles absorbance input directly", {
  cube <- make_cube()
  ab <- hs_absorbance(cube)
  ab$data <- ab$data * 5  # push out of reflectance-like range
  fit <- hs_beer_lambert(ab)
  expect_s3_class(fit, "hsi_chromophore_fit")
})

test_that("unmix functions validate cube", {
  expect_error(hs_unmix_nnls(list(), matrix(1, 2, 2)), "hsi_cube")
  expect_error(hs_beer_lambert(list()), "hsi_cube")
})
