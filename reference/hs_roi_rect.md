# Define Rectangular ROI

Creates a rectangular region of interest on an HSI cube.

## Usage

``` r
hs_roi_rect(cube, x_range, y_range)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- x_range:

  Numeric vector of length 2 (column indices, min and max).

- y_range:

  Numeric vector of length 2 (row indices, min and max).

## Value

A list with class `"hsi_roi"` containing the mask and bounds.

## Examples

``` r
cube <- hs_example_cube()
roi <- hs_roi_rect(cube, x_range = c(5, 15), y_range = c(5, 15))
sum(roi$mask)
#> [1] 121
```
