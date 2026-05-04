test_that("hs_roi_rect creates valid ROI", {
  cube <- hs_example_cube()
  roi <- hs_roi_rect(cube, x_range = c(5, 15), y_range = c(5, 15))
  expect_s3_class(roi, "hsi_roi")
  expect_true(is.matrix(roi$mask))
  expect_equal(sum(roi$mask), 11 * 11)
})

test_that("hs_roi_polygon creates valid ROI", {
  cube <- hs_example_cube()
  verts <- matrix(c(5, 15, 15, 5, 5, 5, 15, 15), ncol = 2,
                  dimnames = list(NULL, c("x", "y")))
  roi <- hs_roi_polygon(cube, verts)
  expect_s3_class(roi, "hsi_roi")
  expect_true(sum(roi$mask) > 0)
})

test_that("hs_roi_stats computes per-band statistics", {
  cube <- hs_example_cube()
  roi <- hs_roi_rect(cube, x_range = c(5, 15), y_range = c(5, 15))
  stats_result <- hs_roi_stats(cube, roi)
  expect_s3_class(stats_result, "tbl_df")
  expect_true("wavelength" %in% names(stats_result))
  expect_true("mean" %in% names(stats_result))
  expect_equal(nrow(stats_result), length(cube$wavelengths))
  expect_true(all(stats_result$n_pixels == sum(roi$mask)))
})

test_that("hs_roi_stats accepts logical mask", {
  cube <- hs_example_cube()
  mask <- matrix(FALSE, 30, 30)
  mask[10:20, 10:20] <- TRUE
  stats_result <- hs_roi_stats(cube, mask)
  expect_s3_class(stats_result, "tbl_df")
})
