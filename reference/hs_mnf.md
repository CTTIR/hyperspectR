# Minimum Noise Fraction Transform

Orders components by signal-to-noise ratio rather than variance.
Estimates noise covariance from spatial first-differences.

## Usage

``` r
hs_mnf(cube, n_components = 5L)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- n_components:

  Integer. Number of components. Default `5`.

## Value

A list with class `"hsi_mnf"` (same structure as
[`hs_pca()`](https://cttir.github.io/hyperspectR/reference/hs_pca.md)).

## Examples

``` r
cube <- hs_example_cube()
mnf <- hs_mnf(cube, n_components = 3)
dim(mnf$scores)
#> [1] 30 30  3
```
