# The vectorized internals must reproduce the scalar reference algorithms
# they replaced, value for value.

irregular_cube <- function() {
  set.seed(11)
  data <- array(stats::runif(7 * 6 * 5), c(7, 6, 5))
  data[2, 3, 4] <- NA
  data[5, 1, 1] <- Inf
  mask <- matrix(TRUE, 7, 6)
  mask[7, 6] <- FALSE
  hsi_cube(data, c(500, 520, 540, 560, 580), mask = mask)
}

test_that("pixel matrices of a band subset match the full reshaped cube", {
  cube <- irregular_cube()
  reference <- function(cube, bands) {
    x <- matrix(cube$data, nrow = prod(dim(cube$data)[1:2]))[, bands, drop = FALSE]
    x[!is.finite(x)] <- NA_real_
    x[!as.vector(cube$mask), ] <- NA_real_
    x
  }
  expect_identical(.pixel_matrix(cube), reference(cube, 1:5))
  for (bands in list(1L, 4L, c(2L, 5L), 5:1)) {
    expect_identical(.pixel_matrix(cube, bands), reference(cube, bands))
    expect_identical(.valid_pixels(cube, bands), rowSums(is.na(reference(cube, bands))) == 0L)
  }
  integer_cube <- hsi_cube(array(1:8, c(2, 2, 2)), c(500, 600))
  expect_type(.pixel_matrix(integer_cube, 2L), "double")
  expect_identical(.band_matrix(integer_cube, 2L), matrix(c(5, 6, 7, 8), 2, 2))
})

test_that("band labels stay unique on grids finer than 1 nm", {
  expect_identical(.band_labels(c(500, 549.6, 600.4)), c("band_500", "band_550", "band_600"))
  expect_identical(.band_labels(c(500.2, 500.4, 501)), c("band_500.2", "band_500.4", "band_501"))
  fine <- hsi_cube(array(seq_len(12) / 12, c(2, 2, 3)), c(500.2, 500.4, 501))
  wide <- as.data.frame(fine)
  expect_identical(names(wide), c("x", "y", "band_500.2", "band_500.4", "band_501"))
  expect_false(anyDuplicated(names(summary(fine)$band_means)) > 0L)
  expect_identical(names(summary(fine)$band_sds), c("500.2", "500.4", "501"))
  em <- hs_endmembers(fine, data.frame(x = 1, y = 2))
  expect_identical(colnames(em), c("band_500.2", "band_500.4", "band_501"))
  # Whole-nm names are unchanged.
  coarse <- hsi_cube(array(1, c(2, 2, 2)), c(500, 600))
  expect_identical(names(as.data.frame(coarse)), c("x", "y", "band_500", "band_600"))
  expect_identical(names(summary(coarse)$band_means), c("500", "600"))
})

test_that("polygon ROIs match the scalar ray-casting reference", {
  scalar <- function(px, py, poly_x, poly_y) {
    inside <- FALSE
    n <- length(poly_x)
    j <- n
    for (i in seq_len(n)) {
      if ((poly_y[i] > py) != (poly_y[j] > py)) {
        edge <- if (poly_y[i] < poly_y[j]) c(i, j) else c(j, i)
        weight <- .normalize_range(py, poly_y[edge])
        crossing <- (1 - weight) * poly_x[edge[1]] + weight * poly_x[edge[2]]
        if (px < crossing) inside <- !inside
      }
      j <- i
    }
    inside
  }
  cube <- hsi_cube(array(0.5, c(13, 17, 2)), c(500, 600))
  polygons <- list(
    concave = cbind(x = c(2, 15, 15, 9, 9, 2), y = c(2, 2, 12, 12, 6, 6)),
    fractional = cbind(x = c(1.5, 16.2, 8.1, 3.3), y = c(0.4, 5.5, 12.9, 9.5)),
    on_pixel_centers = cbind(x = c(3, 10, 10, 3), y = c(3, 3, 9, 9)),
    outside = cbind(x = c(-5, 30, 30, -5), y = c(-5, -5, 30, 30))
  )
  for (vertices in polygons) {
    expected <- outer(seq_len(13), seq_len(17), Vectorize(function(row, col) {
      scalar(col, row, vertices[, 1], vertices[, 2])
    }))
    expect_identical(hs_roi_polygon(cube, vertices)$mask, expected)
    reversed <- vertices[rev(seq_len(nrow(vertices))), ]
    expect_identical(hs_roi_polygon(cube, reversed)$mask, expected)
  }
  expect_identical(.point_in_polygon(3, 3, c(1, 5, 5, 1), c(1, 1, 5, 5), 4L), TRUE)
  expect_identical(.point_in_polygon(numeric(), numeric(), c(1, 5, 5), c(1, 1, 5), 3L),
                   logical())
})

test_that("ROI statistics match the per-band reference", {
  cube <- irregular_cube()
  cube$metadata$repair_mask <- matrix(rep(c(TRUE, FALSE, FALSE), 14), 7, 6)
  roi <- matrix(FALSE, 7, 6)
  roi[2:7, 1:6] <- TRUE
  result <- hs_roi_stats(cube, roi)
  valid <- roi & cube$mask
  for (b in seq_len(5)) {
    band <- cube$data[, , b]
    band[!is.finite(band) | !cube$mask] <- NA
    values <- band[valid]
    values <- values[!is.na(values)]
    expect_identical(result$n_pixels[b], length(values))
    expect_identical(result$mean[b], mean(values))
    expect_identical(result$sd[b], stats::sd(values))
    expect_identical(result$median[b], stats::median(values))
    expect_identical(result$min[b], min(values))
    expect_identical(result$max[b], max(values))
    expect_identical(result$valid_fraction[b], length(values) / sum(roi))
    expect_identical(result$n_repaired_pixels[b],
                     sum(valid & cube$metadata$repair_mask & !is.na(band)))
  }
  expect_identical(result$n_roi_pixels, rep(sum(roi), 5))
  expect_identical(result$n_pixels, c(34L, 35L, 35L, 34L, 35L))
  all_missing <- cube
  all_missing$data[, , 3] <- NA
  empty_band <- hs_roi_stats(all_missing, roi)[3, c("mean", "sd", "median", "min", "max")]
  expect_true(all(is.na(empty_band)))
})

test_that("SAM assigns the first of tied endmembers and honours the threshold", {
  cube <- irregular_cube()
  em <- rbind(first = cube$data[1, 1, ], twin = 2 * cube$data[1, 1, ], other = cube$data[4, 4, ])
  result <- hs_sam(cube, em, threshold = 0.2)
  angles <- matrix(result$angle_map, ncol = 3)
  valid <- .valid_pixels(cube)
  expected <- rep(NA_character_, nrow(angles))
  for (i in which(valid)) {
    closest <- which.min(angles[i, ])
    expected[i] <- if (angles[i, closest] <= 0.2) rownames(em)[closest] else "unclassified"
  }
  expect_identical(as.vector(result$class_map), expected)
  expect_identical(result$class_map[1, 1], "first")
  expect_false("twin" %in% result$class_map)
  expect_true(all(c("first", "other", "unclassified") %in% result$class_map))
  expect_true(all(is.na(result$class_map[cbind(c(2, 5, 7), c(3, 1, 6))])))
  exact <- hs_sam(cube, em, threshold = 0)
  expect_identical(exact$class_map[4, 4], "other")
})

test_that("the simulator fills each region with one noise-free spectrum", {
  cube <- hs_simulate_cube(rows = 9, cols = 7, n_regions = 5, noise_sd = 0, seed = 5)
  regions <- cube$metadata$region_map
  pixels <- matrix(cube$data, nrow = 63)
  for (region in seq_len(5)) {
    members <- which(regions == region)
    expect_gt(length(members), 0L)
    reference <- pixels[members[1L], ]
    expect_identical(pixels[members, , drop = FALSE],
                     matrix(reference, length(members), length(reference), byrow = TRUE))
  }
  expect_equal(range(cube$data), c(0.05, 0.7), tolerance = 1e-8)
  noisy <- hs_simulate_cube(rows = 9, cols = 7, n_regions = 5, noise_sd = 0.01, seed = 5)
  withr::with_seed(5, noise <- array(stats::rnorm(9 * 7 * 61, sd = 0.01), c(9, 7, 61)))
  expect_identical(noisy$data, pmin(pmax(cube$data + noise, 0), 1))
})
