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

## References

Green, A. A., Berman, M., Switzer, P. and Craig, M. D. (1988). A
transformation for ordering multispectral data in terms of image quality
with implications for noise removal. *IEEE Transactions on Geoscience
and Remote Sensing*, 26(1), 65-74. `doi:10.1109/36.3001`

## Examples

``` r
cube <- hs_example_cube()
mnf <- hs_mnf(cube, n_components = 3)
dim(mnf$scores)
#> [1] 30 30  3
```
