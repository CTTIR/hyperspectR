test_that("hs_simulate_cube produces requested dimensions", {
  cube <- hs_simulate_cube(rows = 12, cols = 9, n_regions = 4, seed = 1)
  expect_s3_class(cube, "hsi_cube")
  expect_equal(dim(cube)[1:2], c(12, 9))
  expect_true(all(cube$data >= 0 & cube$data <= 1))
})

test_that("hs_simulate_cube is reproducible by seed", {
  a <- hs_simulate_cube(rows = 8, cols = 8, seed = 99)
  b <- hs_simulate_cube(rows = 8, cols = 8, seed = 99)
  expect_equal(a$data, b$data)
})

test_that("hs_simulate_cube without noise is deterministic baseline", {
  cube <- hs_simulate_cube(rows = 6, cols = 6, noise_sd = 0, seed = 3)
  expect_false(anyNA(cube$data))
})

test_that("hs_simulate_cube stores ground-truth metadata", {
  cube <- hs_simulate_cube(rows = 8, cols = 8, n_regions = 4, seed = 2)
  expect_true(!is.null(cube$metadata$region_map))
  expect_true(!is.null(cube$metadata$sto2_ground_truth))
  expect_equal(length(cube$metadata$sto2_ground_truth), 4)
})

test_that("hs_simulate_cube respects custom wavelengths", {
  wl <- seq(450, 650, by = 25)
  cube <- hs_simulate_cube(rows = 5, cols = 5, wavelengths = wl, seed = 1)
  expect_equal(cube$wavelengths, wl)
})

test_that("hs_example_cube returns a 30x30x61 cube", {
  cube <- hs_example_cube()
  expect_equal(dim(cube), c(30, 30, 61))
})

test_that("hs_example_files writes a readable ENVI pair", {
  skip_if_not_installed("withr")
  dir <- withr::local_tempdir()
  hdr <- hs_example_files(dir = dir)
  expect_true(file.exists(hdr))
  cube <- hs_read_envi(hdr, backend = "builtin", verbose = FALSE)
  expect_s3_class(cube, "hsi_cube")
})

test_that("simulated cube region map is regression-stable", {
  cube <- hs_simulate_cube(rows = 6, cols = 6, n_regions = 4, seed = 42)
  expect_snapshot_value(as.vector(cube$metadata$region_map), style = "json2")
})
