test_that("plot arguments are validated before use", {
  cube <- hs_simulate_cube(rows = 7, cols = 6, wavelengths = seq(500, 580, by = 20), seed = 1)
  expect_error(hs_plot_spectra(cube, pixels = c("mean", "random")), "must be 'mean', 'random'")
  expect_error(hs_plot_spectra(cube, pixels = "median"), "must be 'mean', 'random'")
  expect_error(hs_plot_spectra(cube, pixels = NA_character_), "must be 'mean', 'random'")
  expect_error(hs_plot_spectra(cube, show_sd = NA), "show_sd")
  expect_error(hs_plot_spectra(cube, show_sd = "yes"), "show_sd")
  # A numeric flag worked before the validation was added.
  expect_length(hs_plot_spectra(cube, show_sd = 1)$layers, 2L)
  expect_length(hs_plot_spectra(cube, show_sd = 0)$layers, 1L)
  expect_error(hs_plot_image(cube, band = "a"), "valid band index")
  expect_error(hs_plot_image(cube, band = c(1, 2)), "valid band index")
  expect_error(hs_plot_image(cube, band = NA_real_), "valid band index")
  expect_error(hs_plot_image(cube, band = 6), "valid band index")
  expect_error(hs_plot_image(cube, wavelength = "a"), "finite scalar")
  expect_error(hs_plot_index(matrix(letters[1:4], 2, 2)), "numeric matrix")
  expect_error(hs_plot_index(matrix(numeric(), 0, 2)), "numeric matrix")
  expect_error(hs_plot_index(matrix(1:4, 2, 2), range = c(0, Inf)), "range")
  expect_error(hs_plot_index(matrix(1:4, 2, 2), range = "wide"), "range")
  expect_error(hs_plot_index(matrix(1:4, 2, 2), range = 1), "range")
  # One-sided and reversed ranges keep working as they did before validation.
  fills <- function(...) {
    ggplot2::ggplot_build(hs_plot_index(matrix(1:4, 2, 2), ...))$data[[1L]]$fill
  }
  expect_identical(fills(range = c(4, 1)), fills(range = c(1, 4)))
  expect_identical(fills(range = c(1, NA)), fills(range = c(1, 4)))
  expect_identical(fills(range = c(NA, NA)), fills())
  expect_length(unique(fills(range = c(0, NA))), 4L)
  expect_s3_class(hs_plot_index(matrix(1:4, 2, 2), range = c(2, 2)), "ggplot")
  # Logical matrices were accepted before the validation was added.
  flags <- hs_plot_index(matrix(c(TRUE, FALSE, NA, TRUE), 2, 2))
  expect_identical(flags$data$value, c(1, 0, NA, 1))
  expect_no_error(ggplot2::ggplot_build(hs_plot_index(matrix(NA, 2, 2))))
  expect_error(hs_plot_index(list(1, 2)), "numeric matrix")
  expect_s3_class(hs_plot_index(matrix(1:4, 2, 2), range = c(0, 10)), "ggplot")
})

test_that("the TWI warning names the bands that were requested", {
  cube <- hsi_cube(array(0.5, c(2, 2, 3)), c(500, 550, 600))
  expect_warning(result <- hs_twi(cube), "880-910 nm or 830-870 nm")
  expect_true(all(is.na(result)))
  expect_warning(hs_twi(cube, numerator = c(955, 980), denominator = c(880, 900)),
                 "955-980 nm or 880-900 nm")
})

test_that("spectral plots label the value axis and use colour-blind-safe pixel colours", {
  cube <- hs_simulate_cube(rows = 7, cols = 6, wavelengths = seq(500, 580, by = 20), seed = 1)
  expect_identical(hs_plot_spectra(cube)$labels$y, "Reflectance")
  expect_identical(hs_plot_spectra(cube)$labels$x, "Wavelength (nm)")
  expect_identical(.value_label(hs_absorbance(cube)), "Absorbance")
  expect_identical(.value_label(hs_snv(cube)), "SNV-scaled value")
  plain <- hsi_cube(array(0.5, c(2, 2, 3)), c(500, 550, 600))
  expect_identical(.value_label(plain), "Spectral value")
  plain$metadata$processing_mode <- "unknown"
  expect_identical(.value_label(plain), "Spectral value")
  plain$metadata$processing_mode <- "custom_units"
  expect_identical(.value_label(plain), "Custom units")
  plain$metadata$wavelengths_known <- FALSE
  expect_identical(hs_plot_spectra(plain, pixels = "random", n = 2)$labels$x, "Band index")

  pixels <- data.frame(x = c(5, 1, 3), y = c(2, 7, 4))
  p <- hs_plot_spectra(cube, pixels = pixels)
  expect_identical(levels(p$data$pixel_id), c("(5,2)", "(1,7)", "(3,4)"))
  built <- ggplot2::ggplot_build(p)$data[[1L]]
  expect_identical(unique(built$colour), .qualitative_colors(3L))
  expect_identical(.qualitative_colors(8L),
    unname(grDevices::palette.colors(8L, palette = "Okabe-Ito"))[c(1, 2, 3, 4, 6, 7, 8, 5)])
  expect_length(unique(.qualitative_colors(12L)), 12L)
  many <- expand.grid(x = 1:3, y = 1:3)
  expect_s3_class(hs_plot_spectra(cube, pixels = many), "ggplot")
})

test_that("the research panel uses a near-square grid by default", {
  cube <- hs_simulate_cube(rows = 6, cols = 6, seed = 1)
  layout_cols <- function(p) p$patches$layout$ncol
  expect_identical(layout_cols(hs_plot_clinical(cube)), 2)
  expect_identical(layout_cols(hs_plot_clinical(cube, indices = "sto2")), 2)
  expect_identical(layout_cols(hs_plot_clinical(cube, indices = c("sto2", "npi", "thi", "twi"))), 3)
  expect_identical(layout_cols(hs_plot_clinical(cube, ncol = 4)), 4)
  expect_error(hs_plot_clinical(cube, ncol = 0), "ncol")
  expect_error(hs_plot_clinical(cube, ncol = c(1, 2)), "ncol")
  expect_error(hs_plot_clinical(cube, ncol = "two"), "ncol")
})
