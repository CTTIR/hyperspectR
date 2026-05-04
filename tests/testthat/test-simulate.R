test_that("hs_simulate_cube generates valid cube", {
  cube <- hs_simulate_cube(rows = 10, cols = 10, seed = 42)
  expect_s3_class(cube, "hsi_cube")
  expect_equal(dim(cube)[1:2], c(10, 10))
  expect_true(all(cube$data >= 0 & cube$data <= 1))
})

test_that("hs_simulate_cube is reproducible with seed", {
  c1 <- hs_simulate_cube(rows = 5, cols = 5, seed = 123)
  c2 <- hs_simulate_cube(rows = 5, cols = 5, seed = 123)
  expect_equal(c1$data, c2$data)
})

test_that("hs_example_cube returns 30x30x61 cube", {
  cube <- hs_example_cube()
  expect_equal(dim(cube), c(30, 30, 61))
  expect_equal(range(cube$wavelengths), c(430, 910))
})

test_that("hs_simulate_cube respects custom wavelengths", {
  wl <- seq(500, 700, by = 10)
  cube <- hs_simulate_cube(rows = 5, cols = 5, wavelengths = wl)
  expect_equal(cube$wavelengths, wl)
  expect_equal(dim(cube)[3], length(wl))
})
