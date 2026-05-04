test_that("ENVI round-trip preserves data", {
  skip_if_not_installed("withr")
  cube <- hs_simulate_cube(rows = 10, cols = 10,
                           wavelengths = seq(430, 510, by = 8),
                           seed = 42)
  dir <- withr::local_tempdir()
  hs_write_envi(cube, file.path(dir, "test"), verbose = FALSE)

  expect_true(file.exists(file.path(dir, "test.hdr")))
  expect_true(file.exists(file.path(dir, "test.dat")))

  cube2 <- hs_read_envi(file.path(dir, "test.hdr"), backend = "builtin",
                         verbose = FALSE)
  expect_equal(dim(cube2), dim(cube))
  expect_equal(cube2$wavelengths, cube$wavelengths)
  expect_equal(cube2$data, cube$data, tolerance = 1e-5)
})

test_that("hs_example_files creates valid files", {
  skip_if_not_installed("withr")
  dir <- withr::local_tempdir()
  hdr_path <- hs_example_files(dir = dir)
  expect_true(file.exists(hdr_path))

  cube <- hs_read_envi(hdr_path, backend = "builtin", verbose = FALSE)
  expect_s3_class(cube, "hsi_cube")
})

test_that("hs_read_cube auto-detects ENVI", {
  skip_if_not_installed("withr")
  dir <- withr::local_tempdir()
  hdr_path <- hs_example_files(dir = dir)
  cube <- hs_read_cube(hdr_path, backend = "builtin", verbose = FALSE)
  expect_s3_class(cube, "hsi_cube")
})

test_that("hs_export_png writes file", {
  skip_if_not_installed("withr")
  cube <- hs_example_cube()
  dir <- withr::local_tempdir()
  path <- file.path(dir, "test.png")
  hs_export_png(cube$data[, , 30], path)
  expect_true(file.exists(path))
})

test_that("hs_read_envi errors on missing file", {
  expect_error(hs_read_envi("nonexistent.hdr"))
})

test_that("hs_read_cube errors on unsupported format", {
  skip_if_not_installed("withr")
  dir <- withr::local_tempdir()
  path <- file.path(dir, "test.xyz")
  writeLines("test", path)
  expect_error(hs_read_cube(path), "Unsupported")
})
