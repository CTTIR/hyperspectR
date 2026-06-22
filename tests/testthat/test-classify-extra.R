make_cube <- function() {
  hs_simulate_cube(rows = 10, cols = 10, wavelengths = seq(500, 600, by = 20),
                   noise_sd = 0.01, seed = 9)
}

make_labels <- function() {
  labels <- matrix(NA_character_, 10, 10)
  labels[1:4, 1:4] <- "class_a"
  labels[7:10, 7:10] <- "class_b"
  labels
}

test_that("hs_sam accepts a data.frame of endmembers", {
  cube <- make_cube()
  em <- as.data.frame(rbind(a = cube$data[2, 2, ], b = cube$data[8, 8, ]))
  result <- hs_sam(cube, em, threshold = 0.5)
  expect_s3_class(result, "hsi_classification")
})

test_that("hs_sam auto-names unnamed endmembers", {
  cube <- make_cube()
  em <- unname(rbind(cube$data[2, 2, ], cube$data[8, 8, ]))
  result <- hs_sam(cube, em, threshold = 1)
  expect_true(any(grepl("class_", result$class_map)))
})

test_that("hs_sam threshold marks unclassified", {
  cube <- make_cube()
  em <- rbind(a = cube$data[2, 2, ])
  result <- hs_sam(cube, em, threshold = 0)
  expect_true(any(result$class_map == "unclassified"))
})

test_that("hs_endmembers works with matrix input", {
  cube <- make_cube()
  em <- hs_endmembers(cube, matrix(c(2, 8, 2, 8), ncol = 2))
  expect_equal(nrow(em), 2)
  expect_true(all(grepl("endmember_", rownames(em))))
})

test_that("hs_classify_svm trains and predicts", {
  skip_if_not_installed("e1071")
  cube <- make_cube()
  result <- hs_classify_svm(cube, make_labels())
  expect_s3_class(result, "hsi_classification")
  expect_equal(dim(result$class_map), c(10, 10))
  expect_true(all(result$class_map %in% c("class_a", "class_b")))
})

test_that("hs_classify_svm honors training_mask", {
  skip_if_not_installed("e1071")
  cube <- make_cube()
  labels <- matrix("class_a", 10, 10)
  labels[6:10, ] <- "class_b"
  mask <- matrix(TRUE, 10, 10)
  mask[5, ] <- FALSE
  result <- hs_classify_svm(cube, labels, training_mask = mask)
  expect_s3_class(result, "hsi_classification")
})

test_that("hs_classify_svm errors with too few labels", {
  skip_if_not_installed("e1071")
  cube <- make_cube()
  labels <- matrix(NA_character_, 10, 10)
  labels[1, 1] <- "x"
  expect_error(hs_classify_svm(cube, labels), "at least 2")
})

test_that("hs_classify_svm errors without e1071", {
  cube <- make_cube()
  testthat::local_mocked_bindings(
    requireNamespace = function(...) FALSE, .package = "base"
  )
  expect_error(hs_classify_svm(cube, make_labels()), "e1071")
})

test_that("hs_classify_rf trains and predicts", {
  skip_if_not_installed("ranger")
  cube <- make_cube()
  result <- hs_classify_rf(cube, make_labels(), num.trees = 50)
  expect_s3_class(result, "hsi_classification")
  expect_equal(dim(result$class_map), c(10, 10))
})

test_that("hs_classify_rf honors training_mask", {
  skip_if_not_installed("ranger")
  cube <- make_cube()
  labels <- matrix("class_a", 10, 10)
  labels[6:10, ] <- "class_b"
  mask <- matrix(TRUE, 10, 10)
  mask[5, ] <- FALSE
  result <- hs_classify_rf(cube, labels, training_mask = mask, num.trees = 50)
  expect_s3_class(result, "hsi_classification")
})

test_that("hs_classify_rf errors without ranger", {
  cube <- make_cube()
  testthat::local_mocked_bindings(
    requireNamespace = function(...) FALSE, .package = "base"
  )
  expect_error(hs_classify_rf(cube, make_labels()), "ranger")
})

test_that("classify functions validate cube", {
  expect_error(hs_classify_svm(list(), make_labels()), "hsi_cube")
  expect_error(hs_classify_rf(list(), make_labels()), "hsi_cube")
  expect_error(hs_endmembers(list(), data.frame(x = 1, y = 1)), "hsi_cube")
})
