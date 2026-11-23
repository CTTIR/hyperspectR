printed <- function(x) {
  out <- NULL
  msgs <- testthat::capture_messages(out <- withVisible(print(x)))
  list(text = paste(msgs, collapse = ""), value = out$value, visible = out$visible)
}

expect_compact_print <- function(x, patterns) {
  res <- printed(x)
  expect_identical(res$value, x)
  expect_false(res$visible)
  expect_match(res$text, class(x)[1L], fixed = TRUE)
  for (pattern in patterns) expect_match(res$text, pattern, fixed = TRUE)
  # A compact overview, not a dump of every map.
  expect_lt(length(strsplit(res$text, "\n", fixed = TRUE)[[1L]]), 15L)
}

test_that("summary.hsi_cube prints a compact overview", {
  cube <- hs_simulate_cube(rows = 6, cols = 5, wavelengths = seq(500, 600, by = 20),
                           noise_sd = 0, seed = 1)
  cube$mask[1, 1] <- FALSE
  expect_compact_print(summary(cube), c("6 rows x 5 cols x 6 bands", "500-600 nm",
                                        "29/30 (96.7%)", "Band means", "Metadata"))
  bare <- summary(hsi_cube(array(NA_real_, c(2, 2, 2)), c(500, 600)))
  expect_compact_print(bare, c("0/4 (0%)", "[NA, NA]"))
})

test_that("transform results print their size and explained variance", {
  cube <- hs_simulate_cube(rows = 8, cols = 8, noise_sd = 0.01, seed = 2)
  expect_compact_print(hs_pca(cube, n_components = 3),
    c("8 rows x 8 cols x 3 components", "Variance explained", "Centered: TRUE"))
  expect_compact_print(hs_pca(cube, n_components = 7), c("7 components", ", ..."))
  expect_compact_print(hs_mnf(cube, n_components = 2),
    c("2 components", "adjacent pixel pairs"))
  umap <- structure(list(embedding = matrix(c(1, NA, 3, 4, 1, NA, 3, 4), 4, 2),
    scores = array(0, c(2, 2, 2)), n_components = 2L, seed = 1L, dims = c(2L, 2L)),
    class = "hsi_umap")
  expect_compact_print(umap, c("2 rows x 2 cols x 2 components", "3/4 (75%)", "Seed: 1"))
})

test_that("unmixing and chromophore fits print status instead of arrays", {
  cube <- hs_simulate_cube(rows = 6, cols = 6, noise_sd = 0, seed = 3)
  em <- cbind(a = cube$data[1, 1, ], b = cube$data[6, 6, ])
  expect_compact_print(hs_unmix_nnls(cube, em),
    c("6 rows x 6 cols x 2 endmembers", "a, b", "Fit status: ok 36", "Residuals kept: TRUE"))
  expect_compact_print(hs_beer_lambert(cube),
    c("HbO2, Hb", "prahl-hemoglobin-v1", "Input domain: reflectance", "Beer-Lambert model"))
  expect_compact_print(hs_beer_lambert(cube, chromophores = "Hb"), "Chromophores: Hb")
})

test_that("classification, ROI and recipe objects print compactly", {
  cube <- hs_simulate_cube(rows = 6, cols = 6, noise_sd = 0, seed = 3)
  em <- rbind(first = cube$data[1, 1, ], second = cube$data[6, 6, ])
  expect_compact_print(hs_sam(cube, em, threshold = 0.5),
    c("spectral angle mapper", "Angle threshold: 0.5 rad", "first"))
  fitted <- structure(list(class_map = matrix(c("a", "b", NA, "a"), 2, 2),
    model = structure(list(), class = "svm"), training_pixels = 3L),
    class = "hsi_classification")
  expect_compact_print(fitted, c("(svm)", "a 2, b 1", "Unassigned (NA) pixels: 1",
                                 "Training pixels: 3"))
  expect_compact_print(hs_roi_rect(cube, c(2, 4), c(1, 2)),
    c("Type: rectangle", "6/36 (16.7%)", "Columns 2-4, rows 1-2"))
  verts <- cbind(x = c(1, 5, 5), y = c(1, 1, 5))
  expect_compact_print(hs_roi_polygon(cube, verts), c("Type: polygon", "Vertices: 3"))
  recipe <- hs_recipe(list(list(method = "smooth", args = list(window = 5)),
                           list(method = "snv")))
  expect_compact_print(recipe, c("Steps: 2; seed: 1", "1. smooth (window)", "2. snv"))
  expect_compact_print(hs_recipe(), "Steps: 0")
})
