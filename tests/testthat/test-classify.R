test_that("hs_sam classifies pixels", {
  cube <- hs_example_cube()
  em <- rbind(
    healthy = cube$data[5, 5, ],
    ischemic = cube$data[25, 5, ]
  )
  result <- hs_sam(cube, em, threshold = 0.5)
  expect_s3_class(result, "hsi_classification")
  expect_true(is.matrix(result$class_map))
  expect_equal(dim(result$class_map), dim(cube)[1:2])
  expect_true(all(result$class_map %in% c("healthy", "ischemic", "unclassified")))
})

test_that("hs_sam rejects mismatched endmembers", {
  cube <- hs_example_cube()
  em <- matrix(1, nrow = 2, ncol = 5)
  expect_error(hs_sam(cube, em), "must match")
})

test_that("hs_endmembers extracts spectra", {
  cube <- hs_example_cube()
  pixels <- data.frame(x = c(5, 25), y = c(5, 25))
  em <- hs_endmembers(cube, pixels, labels = c("a", "b"))
  expect_equal(nrow(em), 2)
  expect_equal(ncol(em), dim(cube)[3])
  expect_equal(rownames(em), c("a", "b"))
})
