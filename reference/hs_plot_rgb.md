# Synthesize RGB Image from Spectral Cube

Creates a pseudo-color RGB composite by mapping three wavelength bands
to the red, green, and blue channels.

## Usage

``` r
hs_plot_rgb(cube, r = 640, g = 550, b = 460, stretch = "linear")
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- r, g, b:

  Numeric. Center wavelengths for R, G, B channels. Defaults: r=640,
  g=550, b=460.

- stretch:

  Character. Histogram stretch: `"linear"` (default), `"none"`.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
cube <- hs_example_cube()
hs_plot_rgb(cube)

```
