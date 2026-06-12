# Plot Single-Band Spatial Image

Displays a single spectral band as a spatial image using a pseudocolor
palette.

## Usage

``` r
hs_plot_image(cube, wavelength = NULL, band = NULL, palette = "viridis")
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- wavelength:

  Numeric. Center wavelength to display (nearest band selected). Default
  `NULL`.

- band:

  Integer. Band index. Alternative to `wavelength`. Default `NULL`.

- palette:

  Character. Color palette name. Default `"viridis"`.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object using
[`ggplot2::geom_raster()`](https://ggplot2.tidyverse.org/reference/geom_tile.html).

## Examples

``` r
cube <- hs_example_cube()
hs_plot_image(cube, wavelength = 550)

```
