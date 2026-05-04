test_that("hs_unmix_nnls returns correct structure", {
  cube <- hs_simulate_cube(rows = 5, cols = 5,
                           wavelengths = seq(430, 510, by = 8),
                           seed = 42)
  em <- cbind(
    tissue = cube$data[2, 2, ],
    background = cube$data[4, 4, ]
  )
  result <- hs_unmix_nnls(cube, em)
  expect_s3_class(result, "hsi_unmix")
  expect_equal(dim(result$abundances), c(5, 5, 2))
  expect_true(all(result$abundances >= 0))
  expect_true(is.matrix(result$rmse))
})

test_that("hs_beer_lambert returns sto2", {
  cube <- hs_example_cube()
  fit <- hs_beer_lambert(cube)
  expect_s3_class(fit, "hsi_chromophore_fit")
  expect_true(!is.null(fit$sto2))
  expect_true(is.matrix(fit$sto2))
})
