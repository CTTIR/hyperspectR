test_that("UMAP retries the older-R PCA failure with unchanged settings", {
  skip_if_not_installed("uwot")
  actual_umap <- uwot::umap
  calls <- list()
  local_mocked_bindings(umap = function(...) {
    args <- list(...)
    calls[[length(calls) + 1L]] <<- args
    if (is.null(args$pca_method)) {
      stop(simpleError("LENGTH or similar applied to NULL object",
                       call = quote(oknum(scale))))
    }
    actual_umap(..., init = "pca")
  }, .package = "uwot")
  cube <- hs_simulate_cube(rows = 8, cols = 8,
                           wavelengths = seq(500, 600, by = 10), seed = 6)
  withr::local_seed(42)
  before <- .Random.seed
  for (pca_pre in list(NULL, 8L)) {
    calls <- list()
    expect_message(result <- hs_umap(cube, n_neighbors = 5L, min_dist = 0.2,
                                     pca_pre = pca_pre, seed = 7L),
                   class = "hyperspectR_umap_pca_fallback")
    expect_identical(.Random.seed, before)
    expect_s3_class(result, "hsi_umap")
    expect_equal(dim(result$embedding), c(64, 2))
    expect_true(all(is.finite(result$embedding)))
    expect_length(calls, 2L)
    expect_null(calls[[1L]]$pca_method)
    expect_identical(calls[[2L]]$pca_method, "svd")
    for (call in calls) {
      expect_identical(call$n_components, 2L)
      expect_identical(call$n_neighbors, 5L)
      expect_identical(call$min_dist, 0.2)
      expect_identical(call$n_threads, 1)
      expect_identical(call$n_sgd_threads, 1)
      expect_false("metric" %in% names(call))
    }
    expect_identical(calls[[1L]][[1L]], calls[[2L]][[1L]])
    expect_message(repeated <- hs_umap(cube, n_neighbors = 5L, min_dist = 0.2,
                                       pca_pre = pca_pre, seed = 7L),
                   class = "hyperspectR_umap_pca_fallback")
    expect_identical(repeated, result)
    expect_identical(.Random.seed, before)
  }
})

test_that("UMAP retains the older dependency signature and its errors", {
  skip_if_not_installed("uwot")
  withr::local_seed(42)
  actual_umap <- uwot::umap
  failure <- NULL
  calls <- 0L
  local_mocked_bindings(umap = function(X, n_components, n_neighbors, min_dist,
                                       n_threads, n_sgd_threads) {
    calls <<- calls + 1L
    if (!is.null(failure)) stop(failure)
    actual_umap(X, n_components = n_components, n_neighbors = n_neighbors,
                 min_dist = min_dist, n_threads = n_threads, n_sgd_threads = n_sgd_threads)
  }, .package = "uwot")
  # Four bands keep this ordinary old-signature case on base PCA even when
  # the installed irlba has the known NULL-input failure. The high-dimensional
  # failure/retry paths are exercised separately above.
  cube <- hs_simulate_cube(rows = 8, cols = 8,
                           wavelengths = seq(500, 600, length.out = 4), seed = 6)
  before <- .Random.seed
  result <- hs_umap(cube, n_neighbors = 5L)
  expect_true(all(is.finite(result$embedding)))
  expect_identical(.Random.seed, before)
  expect_identical(calls, 1L)
  failure <- simpleError("LENGTH or similar applied to NULL object", call = quote(oknum(scale)))
  observed <- tryCatch(hs_umap(cube, n_neighbors = 5L), error = identity)
  expect_identical(observed, failure)
  expect_identical(calls, 2L)
  expect_identical(.Random.seed, before)
})

test_that("UMAP preserves unrelated dependency errors", {
  skip_if_not_installed("uwot")
  withr::local_seed(42)
  cube <- hs_simulate_cube(rows = 8, cols = 8,
                           wavelengths = seq(500, 600, by = 10), seed = 6)
  for (failure in list(
    simpleError("unrelated numerical failure", call = quote(oknum(scale))),
    simpleError("LENGTH or similar applied to NULL object", call = quote(other(scale)))
  )) {
    calls <- 0L
    local_mocked_bindings(umap = function(...) {
      calls <<- calls + 1L
      stop(failure)
    }, .package = "uwot")
    before <- .Random.seed
    observed <- tryCatch(hs_umap(cube, n_neighbors = 5L), error = identity)
    expect_identical(observed, failure)
    expect_identical(calls, 1L)
    expect_identical(.Random.seed, before)
  }
})
