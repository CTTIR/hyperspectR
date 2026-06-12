# Compute ROI Statistics

Computes per-band spectral statistics within a region of interest.

## Usage

``` r
hs_roi_stats(cube, roi)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- roi:

  An `hsi_roi` object (from
  [`hs_roi_rect()`](https://cttir.github.io/hyperspectR/reference/hs_roi_rect.md)
  or
  [`hs_roi_polygon()`](https://cttir.github.io/hyperspectR/reference/hs_roi_polygon.md)),
  or a logical mask matrix.

## Value

A [tibble::tibble](https://tibble.tidyverse.org/reference/tibble.html)
with columns `wavelength`, `mean`, `sd`, `median`, `min`, `max`,
`n_pixels`.

## Examples

``` r
cube <- hs_example_cube()
roi <- hs_roi_rect(cube, x_range = c(5, 15), y_range = c(5, 15))
stats <- hs_roi_stats(cube, roi)
head(stats)
#> # A tibble: 6 × 7
#>   wavelength   mean      sd median    min    max n_pixels
#>        <dbl>  <dbl>   <dbl>  <dbl>  <dbl>  <dbl>    <int>
#> 1        430 0.0494 0.00894 0.0494 0.0298 0.0705      121
#> 2        438 0.0883 0.00977 0.0878 0.0633 0.115       121
#> 3        446 0.176  0.00919 0.175  0.151  0.199       121
#> 4        454 0.298  0.00970 0.298  0.267  0.322       121
#> 5        462 0.394  0.00966 0.395  0.363  0.421       121
#> 6        470 0.438  0.0104  0.438  0.414  0.463       121
```
