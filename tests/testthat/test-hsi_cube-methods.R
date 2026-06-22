make_cube <- function() {
  hs_simulate_cube(rows = 8, cols = 8, wavelengths = seq(500, 600, by = 20),
                   noise_sd = 0, seed = 1)
}

test_that("print returns invisibly and shows summary", {
  cube <- make_cube()
  msgs <- testthat::capture_messages(out <- print(cube))
  expect_true(any(grepl("hsi_cube", msgs)))
  expect_identical(out, cube)
})

test_that("print handles cube with mask and fwhm", {
  cube <- make_cube()
  msgs <- testthat::capture_messages(print(cube))
  expect_true(any(grepl("FWHM", msgs)))
  expect_true(any(grepl("valid pixels", msgs)))
})

test_that("print handles cube without fwhm, mask, or metadata", {
  cube <- hsi_cube(array(0.5, c(3, 3, 2)), c(500, 600))
  msgs <- testthat::capture_messages(print(cube))
  expect_true(any(grepl("Data range", msgs)))
})

test_that("summary returns expected fields", {
  cube <- make_cube()
  s <- summary(cube)
  expect_s3_class(s, "summary.hsi_cube")
  expect_equal(s$n_bands, dim(cube)[3])
  expect_equal(length(s$band_means), dim(cube)[3])
  expect_equal(s$n_total_pixels, 64)
})

test_that("summary n_valid_pixels respects mask", {
  cube <- make_cube()
  cube$mask <- matrix(c(TRUE, FALSE), nrow = 8, ncol = 8)
  s <- summary(cube)
  expect_equal(s$n_valid_pixels, sum(cube$mask))
})

test_that("dim returns three dimensions", {
  expect_equal(dim(make_cube()), c(8, 8, 6))
})

test_that("subset preserves class and reduces dims", {
  cube <- make_cube()
  sub <- cube[1:4, 1:3, 1:2]
  expect_s3_class(sub, "hsi_cube")
  expect_equal(dim(sub), c(4, 3, 2))
  expect_equal(length(sub$wavelengths), 2)
})

test_that("subset with missing indices keeps full dimension", {
  cube <- make_cube()
  sub <- cube[, , 1:2]
  expect_equal(dim(sub), c(8, 8, 2))
})

test_that("subset preserves mask and fwhm subsetting", {
  cube <- make_cube()
  cube$mask <- matrix(TRUE, 8, 8)
  sub <- cube[1:3, 1:3, ]
  expect_equal(dim(sub$mask), c(3, 3))
  expect_equal(length(sub$fwhm), dim(cube)[3])
})

test_that("as.data.frame wide format has band columns", {
  cube <- make_cube()
  df <- as.data.frame(cube[1:2, 1:2, ])
  expect_true(all(c("x", "y") %in% names(df)))
  expect_equal(nrow(df), 4)
  expect_true(any(grepl("^band_", names(df))))
})

test_that("as.data.frame long format reshapes", {
  cube <- make_cube()
  df <- as.data.frame(cube[1:2, 1:2, ], long = TRUE)
  expect_equal(names(df), c("x", "y", "wavelength", "value"))
  expect_equal(nrow(df), 2 * 2 * dim(cube)[3])
})

test_that("as_tibble produces a tibble", {
  cube <- make_cube()
  tb <- as_tibble.hsi_cube(cube[1:2, 1:2, ])
  expect_s3_class(tb, "tbl_df")
})

test_that("long data.frame is regression-stable", {
  cube <- hs_simulate_cube(rows = 2, cols = 2, wavelengths = c(500, 600),
                           noise_sd = 0, seed = 5)
  df <- as.data.frame(cube, long = TRUE)
  expect_snapshot_value(round(df$value, 4), style = "json2")
})
