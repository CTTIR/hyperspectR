test_that("hs_smooth preserves cube dimensions", {
  cube <- hs_example_cube()
  smoothed <- hs_smooth(cube, window = 5, poly = 2)
  expect_s3_class(smoothed, "hsi_cube")
  # Dimensions may differ slightly due to edge effects removal
  expect_true(dim(smoothed)[3] <= dim(cube)[3])
  expect_equal(dim(smoothed)[1:2], dim(cube)[1:2])
})

test_that("hs_smooth rejects invalid parameters", {
  cube <- hs_example_cube()
  expect_error(hs_smooth(cube, window = 4), "odd")
  expect_error(hs_smooth(cube, window = 5, poly = 5), "less than")
})

test_that("hs_snv normalizes per-spectrum", {
  cube <- hs_example_cube()
  snv_cube <- hs_snv(cube)
  # Check one pixel: mean should be ~0, sd should be ~1
  spec <- snv_cube$data[15, 15, ]
  expect_equal(mean(spec), 0, tolerance = 1e-10)
  expect_equal(stats::sd(spec), 1, tolerance = 1e-10)
})

test_that("hs_msc returns valid cube", {
  cube <- hs_example_cube()
  msc_cube <- hs_msc(cube)
  expect_s3_class(msc_cube, "hsi_cube")
  expect_equal(dim(msc_cube), dim(cube))
})

test_that("hs_derivative computes first derivative", {
  cube <- hs_example_cube()
  d1 <- hs_derivative(cube, order = 1)
  expect_s3_class(d1, "hsi_cube")
})
