make_cube <- function() {
  hs_simulate_cube(rows = 8, cols = 8, wavelengths = seq(430, 910, by = 16),
                   noise_sd = 0.01, seed = 13)
}

test_that("hs_plot_clinical builds a patchwork panel", {
  p <- hs_plot_clinical(make_cube())
  expect_s3_class(p, "patchwork")
})

test_that("hs_plot_clinical without background masking", {
  p <- hs_plot_clinical(make_cube(), mask_background = FALSE)
  expect_s3_class(p, "patchwork")
})

test_that("hs_plot_clinical warns and skips unknown index", {
  expect_warning(
    hs_plot_clinical(make_cube(), indices = c("sto2", "bogus")),
    "Unknown index"
  )
})

test_that("hs_plot_clinical skips all-NA index (TWI on short range)", {
  cube <- hs_simulate_cube(rows = 6, cols = 6, wavelengths = seq(500, 700, by = 20),
                           noise_sd = 0, seed = 1)
  warnings <- character()
  p <- withCallingHandlers(hs_plot_clinical(cube, indices = c("sto2", "twi")),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    })
  expect_length(warnings, 2)
  expect_match(warnings[1], "Required wavelength bands not available")
  expect_match(warnings[2], "all NA")
  expect_s3_class(p, "patchwork")
})

test_that("research panels retain incomplete-coverage warnings", {
  cube <- hs_example_cube()[1:2, 1:3, ]
  cube <- cube[, , which(cube$wavelengths <= 850)]
  expect_warning(panel <- hs_plot_clinical(cube, indices = "npi"), "does not fully cover NPI")
  expect_s3_class(panel, "patchwork")
})

test_that("hs_plot_index renders each palette", {
  cube <- make_cube()
  sto2 <- hs_sto2(cube)
  for (pal in c("sto2", "perfusion", "hemoglobin", "water", "default")) {
    p <- hs_plot_index(sto2, title = "X", palette = pal)
    expect_s3_class(p, "ggplot")
  }
})

test_that("hs_plot_index applies mask", {
  cube <- make_cube()
  sto2 <- hs_sto2(cube)
  mask <- matrix(TRUE, nrow(sto2), ncol(sto2))
  mask[1:2, ] <- FALSE
  p <- hs_plot_index(sto2, mask = mask)
  expect_s3_class(p, "ggplot")
})

test_that("hs_plot_index rejects non-matrix", {
  expect_error(hs_plot_index(1:5), "must be a numeric matrix")
})

test_that("hs_plot_clinical validates cube", {
  expect_error(hs_plot_clinical(list()), "hsi_cube")
})
