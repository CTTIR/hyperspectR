# Compute Normalized Difference Index (General Purpose)

NDI = (R_band1 - R_band2) / (R_band1 + R_band2). A flexible building
block for any two-band ratio index.

## Usage

``` r
hs_ndi(cube, band1, band2)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- band1:

  Numeric. Center wavelength or range `c(min, max)` for first band.

- band2:

  Numeric. Center wavelength or range `c(min, max)` for second band.

## Value

A numeric matrix with values in `[-1, 1]`.

## Examples

``` r
cube <- hs_example_cube()
ndi <- hs_ndi(cube, band1 = 540, band2 = 660)
range(ndi, na.rm = TRUE)
#> [1] -0.4915291 -0.2375021
```
