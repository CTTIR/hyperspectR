test_that("hs_pca returns correct structure", {
  cube <- hs_example_cube()
  pca <- hs_pca(cube, n_components = 3)
  expect_s3_class(pca, "hsi_pca")
  expect_equal(dim(pca$scores), c(30, 30, 3))
  expect_equal(nrow(pca$loadings), dim(cube)[3])
  expect_length(pca$variance_explained, 3)
  expect_true(all(pca$variance_explained >= 0))
  expect_true(sum(pca$variance_explained) <= 1)
})

test_that("hs_mnf returns correct structure", {
  cube <- hs_example_cube()
  mnf <- hs_mnf(cube, n_components = 3)
  expect_s3_class(mnf, "hsi_mnf")
  expect_equal(dim(mnf$scores), c(30, 30, 3))
})

test_that("hs_umap requires uwot", {
  skip_if_not_installed("uwot")
  cube <- hs_simulate_cube(rows = 10, cols = 10, seed = 42)
  umap_res <- hs_umap(cube, n_components = 2)
  expect_s3_class(umap_res, "hsi_umap")
  expect_equal(dim(umap_res$scores)[3], 2)
})
