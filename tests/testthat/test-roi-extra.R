make_cube <- function() {
  hs_simulate_cube(rows = 10, cols = 10, wavelengths = seq(500, 600, by = 20),
                   noise_sd = 0, seed = 16)
}

test_that("hs_roi_rect creates a clamped rectangular mask", {
  cube <- make_cube()
  roi <- hs_roi_rect(cube, x_range = c(3, 7), y_range = c(2, 6))
  expect_s3_class(roi, "hsi_roi")
  expect_equal(roi$type, "rectangle")
  expect_equal(sum(roi$mask), 5 * 5)
})

test_that("hs_roi_rect clamps out-of-bounds ranges", {
  cube <- make_cube()
  roi <- hs_roi_rect(cube, x_range = c(-5, 50), y_range = c(-5, 50))
  expect_equal(sum(roi$mask), 100)
})

test_that("hs_roi_polygon marks interior pixels", {
  cube <- make_cube()
  verts <- matrix(c(2, 2, 8, 2, 8, 8, 2, 8), ncol = 2, byrow = TRUE)
  roi <- hs_roi_polygon(cube, verts)
  expect_s3_class(roi, "hsi_roi")
  expect_equal(roi$type, "polygon")
  expect_gt(sum(roi$mask), 0)
})

test_that("hs_roi_polygon accepts data.frame vertices", {
  cube <- make_cube()
  verts <- data.frame(x = c(2, 8, 8, 2), y = c(2, 2, 8, 8))
  roi <- hs_roi_polygon(cube, verts)
  expect_gt(sum(roi$mask), 0)
})

test_that("hs_roi_polygon rejects non-2-column vertices", {
  cube <- make_cube()
  expect_error(hs_roi_polygon(cube, matrix(1, 3, 3)), "2 columns")
})

test_that("hs_roi_stats from roi object", {
  cube <- make_cube()
  roi <- hs_roi_rect(cube, c(3, 7), c(3, 7))
  stats <- hs_roi_stats(cube, roi)
  expect_s3_class(stats, "tbl_df")
  expect_equal(nrow(stats), dim(cube)[3])
  expect_true(all(c("mean", "sd", "median", "min", "max", "n_pixels") %in% names(stats)))
  expect_equal(unique(stats$n_pixels), 25L)
})

test_that("hs_roi_stats from logical mask", {
  cube <- make_cube()
  mask <- matrix(FALSE, 10, 10)
  mask[1:3, 1:3] <- TRUE
  stats <- hs_roi_stats(cube, mask)
  expect_equal(unique(stats$n_pixels), 9L)
})

test_that("hs_roi_stats warns on empty ROI", {
  cube <- make_cube()
  empty <- matrix(FALSE, 10, 10)
  expect_warning(stats <- hs_roi_stats(cube, empty), "no pixels")
  expect_true(all(is.na(stats$mean)))
  expect_equal(unique(stats$n_pixels), 0L)
})

test_that("hs_roi_stats rejects bad roi argument", {
  cube <- make_cube()
  expect_error(hs_roi_stats(cube, "bad"), "hsi_roi")
})

test_that("roi functions validate cube", {
  expect_error(hs_roi_rect(list(), c(1, 2), c(1, 2)), "hsi_cube")
  expect_error(hs_roi_polygon(list(), matrix(1, 2, 2)), "hsi_cube")
  expect_error(hs_roi_stats(list(), matrix(TRUE, 2, 2)), "hsi_cube")
})
