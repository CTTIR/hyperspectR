test_that("autoplot.hsi_cube creates ggplot for rgb", {
  cube <- hs_example_cube()
  p <- ggplot2::autoplot(cube, type = "rgb")
  expect_s3_class(p, "gg")
})

test_that("autoplot.hsi_cube creates ggplot for band", {
  cube <- hs_example_cube()
  p <- ggplot2::autoplot(cube, type = "band", wavelength = 550)
  expect_s3_class(p, "gg")
})

test_that("autoplot.hsi_cube creates ggplot for spectra", {
  cube <- hs_example_cube()
  p <- ggplot2::autoplot(cube, type = "spectra")
  expect_s3_class(p, "gg")
})

test_that("hs_plot_spectra works for mean", {
  cube <- hs_example_cube()
  p <- hs_plot_spectra(cube, pixels = "mean")
  expect_s3_class(p, "gg")
})

test_that("hs_plot_spectra works for random", {
  cube <- hs_example_cube()
  p <- hs_plot_spectra(cube, pixels = "random", n = 10)
  expect_s3_class(p, "gg")
})

test_that("hs_plot_image creates ggplot", {
  cube <- hs_example_cube()
  p <- hs_plot_image(cube, wavelength = 550)
  expect_s3_class(p, "gg")
})

test_that("hs_plot_rgb creates ggplot", {
  cube <- hs_example_cube()
  p <- hs_plot_rgb(cube)
  expect_s3_class(p, "gg")
})

test_that("hs_plot_index creates ggplot", {
  cube <- hs_example_cube()
  sto2 <- hs_sto2(cube)
  p <- hs_plot_index(sto2, title = "StO2", palette = "sto2")
  expect_s3_class(p, "gg")
})

test_that("hs_plot_clinical creates patchwork", {
  cube <- hs_example_cube()
  p <- suppressWarnings(hs_plot_clinical(cube))
  expect_s3_class(p, "patchwork")
})

test_that("theme_hsi returns theme", {
  th <- theme_hsi()
  expect_s3_class(th, "theme")
})

test_that("scale_color_wavelength returns scale", {
  s <- scale_color_wavelength()
  expect_s3_class(s, "Scale")
})
