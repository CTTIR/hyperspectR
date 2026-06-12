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

  Logical. Show mean +/- SD ribbon. Default `TRUE` when
  `pixels = "mean"`.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
cube <- hs_example_cube()
hs_plot_spectra(cube)

```
