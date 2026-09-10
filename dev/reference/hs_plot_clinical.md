# Research HSI Panel Display

Displays RGB, fitted hemoglobin fraction and dimensionless band ratios.
These research outputs are not equivalent to vendor clinical indices.

## Usage

``` r
hs_plot_clinical(
  cube,
  indices = c("sto2", "npi", "thi"),
  mask_background = TRUE,
  threshold = 0.05,
  ncol = NULL
)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/dev/reference/hsi_cube.md)
  object with reflectance data.

- indices:

  Character vector. Which indices to display. Default
  `c("sto2", "npi", "thi")`. TWI is included only if wavelengths permit.

- mask_background:

  Logical. Mask non-tissue pixels. Default `TRUE`.

- threshold:

  Numeric. Masking threshold on mean reflectance. Default `0.05`.

- ncol:

  Integer. Number of panel columns. Default `NULL` (auto).

## Value

A `patchwork` composite
[ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
cube <- hs_example_cube()
hs_plot_clinical(cube)

```
