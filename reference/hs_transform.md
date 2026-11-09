# Apply a Fitted Spectral Transform to Another Cube

Applies saved PCA/MNF centering, scaling and loadings without refitting.

## Usage

``` r
hs_transform(model, cube)
```

## Arguments

- model:

  Result from
  [`hs_pca()`](https://cttir.github.io/hyperspectR/reference/hs_pca.md)
  or
  [`hs_mnf()`](https://cttir.github.io/hyperspectR/reference/hs_mnf.md).

- cube:

  New
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  with the same wavelength grid.

## Value

Score array with spatial dimensions of the new cube; invalid pixels are
NA.

## Examples

``` r
pca <- hs_pca(hs_example_cube(), n_components = 3)
new_cube <- hs_simulate_cube(rows = 10, cols = 10, seed = 7)
scores <- hs_transform(pca, new_cube)
dim(scores)
#> [1] 10 10  3
```
