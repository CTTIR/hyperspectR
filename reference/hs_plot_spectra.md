# Plot Spectral Profiles

Displays spectral profiles from an HSI cube. Can show mean spectrum,
random pixel spectra, or spectra from specific pixel locations.

## Usage

``` r
hs_plot_spectra(cube, pixels = "mean", n = 100L, show_sd = TRUE)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- pixels:

  Character or data.frame. `"mean"` for spatial mean, `"random"` for
  random pixel sample, or a data.frame with columns `x` and `y`. Default
  `"mean"`.

- n:

  Integer. Number of random spectra if `pixels = "random"`. Default
  `100`.

- show_sd:

  Logical. Show the mean +/- SD ribbon. Default `TRUE`; used only when
  `pixels = "mean"`.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object. The value axis is labelled with the cube's processing mode (for
example "Reflectance"). Spectra of selected pixels are drawn in the
colour-blind-safe Okabe-Ito palette for up to eight pixels and in
viridis colours beyond that, with the legend in the order the pixels
were supplied.

## Examples

``` r
cube <- hs_example_cube()
hs_plot_spectra(cube)

hs_plot_spectra(cube, pixels = data.frame(x = c(5, 25), y = c(5, 25)))

```
