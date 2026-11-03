make_cube <- function() {
  hs_simulate_cube(rows = 8, cols = 8, wavelengths = seq(430, 700, by = 30),
                   noise_sd = 0.01, seed = 12)
}

expect_ggplot <- function(p) {
  expect_s3_class(p, "ggplot")
  expect_no_error(ggplot2::ggplot_build(p))
}

test_that("hs_plot_spectra mean with sd ribbon", {
  expect_ggplot(hs_plot_spectra(make_cube(), pixels = "mean", show_sd = TRUE))
})

test_that("hs_plot_spectra mean without sd ribbon", {
  expect_ggplot(hs_plot_spectra(make_cube(), pixels = "mean", show_sd = FALSE))
})

test_that("hs_plot_spectra random", {
  set.seed(1)
  expect_ggplot(hs_plot_spectra(make_cube(), pixels = "random", n = 10))
})

test_that("hs_plot_spectra specific pixels", {
  p <- hs_plot_spectra(make_cube(), pixels = data.frame(x = c(2, 5), y = c(2, 5)))
  expect_ggplot(p)
})

test_that("hs_plot_spectra rejects bad pixels arg", {
  expect_error(hs_plot_spectra(make_cube(), pixels = 123), "must be")
})

test_that("hs_plot_image by wavelength and by band", {
  expect_ggplot(hs_plot_image(make_cube(), wavelength = 550))
  expect_ggplot(hs_plot_image(make_cube(), band = 3))
})

test_that("hs_plot_image default band when none given", {
  expect_ggplot(hs_plot_image(make_cube()))
})

test_that("hs_plot_image palettes", {
  for (pal in c("viridis", "magma", "inferno", "plasma", "other")) {
    expect_ggplot(hs_plot_image(make_cube(), band = 2, palette = pal))
  }
})

test_that("hs_plot_rgb linear and none stretch", {
  expect_ggplot(hs_plot_rgb(make_cube()))
  expect_ggplot(hs_plot_rgb(make_cube(), stretch = "none"))
})

test_that("autoplot dispatches all types", {
  cube <- make_cube()
  expect_ggplot(ggplot2::autoplot(cube, type = "rgb"))
  expect_ggplot(ggplot2::autoplot(cube, type = "band"))
  expect_ggplot(ggplot2::autoplot(cube, type = "band", wavelength = 550))
  expect_ggplot(ggplot2::autoplot(cube, type = "spectra"))
})

test_that("theme_hsi returns a theme", {
  expect_s3_class(theme_hsi(), "theme")
  expect_s3_class(theme_hsi(base_size = 14), "theme")
})

test_that("scale_color_wavelength returns a scale", {
  expect_s3_class(scale_color_wavelength(), "Scale")
  expect_s3_class(scale_colour_wavelength(), "Scale")
})

test_that("physical wavelength colours do not depend on the scene range", {
  colours <- function(wavelengths, ...) {
    df <- data.frame(wavelength = wavelengths, value = seq_along(wavelengths))
    ggplot2::ggplot_build(ggplot2::ggplot(df,
      ggplot2::aes(.data$wavelength, .data$value, colour = .data$wavelength)) +
      ggplot2::geom_point() + scale_color_wavelength(...))$data[[1L]]$colour
  }
  expected <- c("#00FF80", "#FFB100")
  expect_equal(colours(c(500, 600)), expected)
  expect_equal(colours(c(500, 600, 380, 780))[1:2], expected)
  expect_equal(colours(c(500, 600), limits = c(500, 600)), expected)
  expect_equal(colours(c(300, 900)), rep("grey50", 2))
  expect_error(scale_color_wavelength(limits = c(600, 500)), "increasing")
})

test_that("plot functions validate cube", {
  expect_error(hs_plot_spectra(list()), "hsi_cube")
  expect_error(hs_plot_image(list()), "hsi_cube")
  expect_error(hs_plot_rgb(list()), "hsi_cube")
})
