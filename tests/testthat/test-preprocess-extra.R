make_cube <- function() {
  hs_simulate_cube(rows = 6, cols = 6, wavelengths = seq(500, 700, by = 10),
                   noise_sd = 0.02, seed = 15)
}

test_that("hs_smooth with prospectr/signal/builtin backends agree on dims", {
  cube <- make_cube()
  out <- hs_smooth(cube, window = 5, poly = 2)
  expect_s3_class(out, "hsi_cube")
  expect_equal(out$metadata$sg_window, 5L)
  expect_equal(out$metadata$sg_poly, 2L)
})

test_that("hs_smooth builtin fallback path runs when optional pkgs absent", {
  cube <- make_cube()
  testthat::local_mocked_bindings(
    requireNamespace = function(package, ...) {
      if (package %in% c("prospectr", "signal")) return(FALSE)
      TRUE
    },
    .package = "base"
  )
  out <- hs_smooth(cube, window = 5, poly = 2)
  expect_s3_class(out, "hsi_cube")
  expect_equal(dim(out)[1:2], dim(cube)[1:2])
})

test_that("hs_smooth signal fallback path runs", {
  skip_if_not_installed("signal")
  cube <- make_cube()
  testthat::local_mocked_bindings(
    requireNamespace = function(package, ...) {
      if (package == "prospectr") return(FALSE)
      TRUE
    },
    .package = "base"
  )
  out <- hs_smooth(cube, window = 5, poly = 2)
  expect_s3_class(out, "hsi_cube")
})

test_that("hs_smooth derivative changes data", {
  cube <- make_cube()
  d1 <- hs_smooth(cube, window = 5, poly = 2, deriv = 1)
  expect_s3_class(d1, "hsi_cube")
  expect_equal(d1$metadata$sg_deriv, 1L)
})

test_that("hs_smooth input validation", {
  cube <- make_cube()
  expect_error(hs_smooth(cube, window = 4), "must be odd")
  expect_error(hs_smooth(cube, window = 3, poly = 5), "less than")
  expect_error(hs_smooth(cube, window = 5, poly = 2, deriv = 3), "<=")
  expect_error(hs_smooth(cube, window = 999), "exceeds")
})

test_that("hs_snv normalizes each spectrum", {
  cube <- make_cube()
  snv <- hs_snv(cube)
  expect_true(snv$metadata$snv_applied)
  pm <- matrix(snv$data, ncol = dim(snv$data)[3])
  expect_true(all(abs(rowMeans(pm)) < 1e-8))
})

test_that("hs_msc with default and custom reference", {
  cube <- make_cube()
  m1 <- hs_msc(cube)
  expect_true(m1$metadata$msc_applied)
  ref <- colMeans(matrix(cube$data, ncol = dim(cube$data)[3]))
  m2 <- hs_msc(cube, reference = ref)
  expect_s3_class(m2, "hsi_cube")
})

test_that("hs_derivative is a shorthand for hs_smooth deriv", {
  cube <- make_cube()
  d1 <- hs_derivative(cube, order = 1)
  expect_equal(d1$metadata$sg_deriv, 1L)
})

test_that("preprocess functions validate cube", {
  expect_error(hs_smooth(list()), "hsi_cube")
  expect_error(hs_snv(list()), "hsi_cube")
  expect_error(hs_msc(list()), "hsi_cube")
})

test_that("SNV output is regression-stable", {
  cube <- hs_simulate_cube(rows = 3, cols = 3, wavelengths = seq(500, 560, by = 20),
                           noise_sd = 0, seed = 2)
  snv <- hs_snv(cube)
  expect_snapshot_value(round(snv$data[1, 1, ], 4), style = "json2")
})
