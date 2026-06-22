make_cube <- function() {
  hs_simulate_cube(rows = 8, cols = 8, wavelengths = seq(500, 600, by = 10),
                   noise_sd = 0.02, seed = 6)
}

test_that("hs_pca returns ordered variance", {
  cube <- make_cube()
  pca <- hs_pca(cube, n_components = 3)
  expect_s3_class(pca, "hsi_pca")
  expect_equal(dim(pca$scores), c(8, 8, 3))
  expect_equal(length(pca$variance_explained), 3)
  expect_true(all(diff(pca$variance_explained) <= 1e-8))
})

test_that("hs_pca with scale = TRUE", {
  cube <- make_cube()
  pca <- hs_pca(cube, n_components = 2, scale = TRUE)
  expect_false(isFALSE(pca$scale))
})

test_that("hs_pca caps components at band count", {
  cube <- make_cube()
  pca <- hs_pca(cube, n_components = 999)
  expect_lte(dim(pca$scores)[3], dim(cube)[3])
})

test_that("hs_mnf returns hsi_mnf object", {
  cube <- make_cube()
  mnf <- hs_mnf(cube, n_components = 3)
  expect_s3_class(mnf, "hsi_mnf")
  expect_equal(dim(mnf$scores), c(8, 8, 3))
  expect_equal(length(mnf$variance_explained), 3)
})

test_that("hs_umap embeds via uwot", {
  skip_if_not_installed("uwot")
  cube <- make_cube()
  result <- hs_umap(cube, n_components = 2, n_neighbors = 5)
  expect_s3_class(result, "hsi_umap")
  expect_equal(dim(result$scores), c(8, 8, 2))
})

test_that("hs_umap without pca pre-reduction", {
  skip_if_not_installed("uwot")
  cube <- make_cube()
  result <- hs_umap(cube, n_components = 2, n_neighbors = 5, pca_pre = NULL)
  expect_s3_class(result, "hsi_umap")
})

test_that("hs_umap errors without uwot", {
  cube <- make_cube()
  testthat::local_mocked_bindings(
    requireNamespace = function(...) FALSE, .package = "base"
  )
  expect_error(hs_umap(cube), "uwot")
})

test_that("reduce functions validate cube", {
  expect_error(hs_pca(list()), "hsi_cube")
  expect_error(hs_mnf(list()), "hsi_cube")
  expect_error(hs_umap(list()), "hsi_cube")
})
