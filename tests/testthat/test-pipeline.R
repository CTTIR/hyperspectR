test_that("batch failures are isolated and resume fingerprints include input changes", {
  dir <- withr::local_tempdir()
  cube <- hs_example_cube()[1:2, 1:2, ]
  files <- hs_write_envi(cube, file.path(dir, "input"), verbose = FALSE)
  manifest <- data.frame(id = c("good", "missing"), path = c(files[1], file.path(dir, "missing.hdr")))
  recipe <- hs_recipe(list(list(method = "smooth", args = list(window = 5))))
  output <- file.path(dir, "output")
  first <- hs_batch(manifest, recipe, output)
  expect_equal(first$status, c("complete", "failed"))
  saved <- readRDS(first$result_file[1])
  expect_equal(saved$result$n_bands, length(cube$wavelengths) - 4L)
  expect_equal(hs_batch(manifest, recipe, output)$status, c("resumed", "failed"))
  cube$data <- cube$data * .9
  hs_write_envi(cube, file.path(dir, "input"), verbose = FALSE)
  expect_equal(hs_batch(manifest, recipe, output)$status[1], "complete")
  expect_false(identical(readRDS(first$result_file[1])$fingerprint, saved$fingerprint))
  expect_true(file.exists(file.path(output, "run-summary.csv")))
})

test_that("MSC references are fitted on training data and reused unchanged", {
  cube <- hs_example_cube()[1:3, 1:3, ]
  recipe <- hs_recipe(list(list(method = "msc")))
  expect_error(hs_process(cube, recipe, learn = FALSE), "training")
  fitted <- hs_process(cube, recipe)
  changed <- cube
  changed$data <- cube$data * 2 + 3
  transformed <- hs_process(changed, fitted$recipe, learn = FALSE)
  expect_equal(transformed$recipe, fitted$recipe)
  expect_equal(transformed$cube$data, fitted$cube$data, tolerance = 1e-8)
})

test_that("group summaries use independent groups and preserve random state", {
  set.seed(7)
  before <- .Random.seed
  data <- data.frame(subject_id = c(rep("a", 100), "b"), value = c(rep(0, 100), 10))
  result <- hs_group_summary(data, bootstrap = 100, seed = 4)
  expect_equal(result$estimate, 5)
  expect_equal(result$n_groups, 2)
  expect_identical(.Random.seed, before)
  expect_true(all(result$interval >= 0 & result$interval <= 10))
})

test_that("grouped classification never shares a subject across a split", {
  skip_if_not_installed("e1071")
  spectra <- rbind(c(1, 2, 1), c(2, 1, 2), c(1.1, 2, 1), c(2.1, 1, 2),
                   c(1, 2.1, 1), c(2, 1.1, 2), c(1, 2, 1.1), c(2, 1, 2.1))
  result <- hs_grouped_evaluate(spectra, c(500, 600, 700), rep(c("a", "b"), 4),
    rep(letters[1:4], each = 2), n_folds = 2, model_args = list(kernel = "linear"), bootstrap = 50)
  expect_true(all(vapply(result$splits, function(split) length(intersect(split$train_groups, split$test_groups)) == 0L, logical(1))))
  expect_equal(result$accuracy, 1)
  expect_false(anyNA(result$predictions$predicted))
})
