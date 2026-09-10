# Apply a Fitted Spectral Transform to Another Cube

Applies saved PCA/MNF centering, scaling and loadings without refitting.

## Usage

``` r
hs_transform(model, cube)
```

## Arguments

- model:

  Result from
  [`hs_pca()`](https://cttir.github.io/hyperspectR/dev/reference/hs_pca.md)
  or
  [`hs_mnf()`](https://cttir.github.io/hyperspectR/dev/reference/hs_mnf.md).

- cube:

  New
  [hsi_cube](https://cttir.github.io/hyperspectR/dev/reference/hsi_cube.md)
  with the same wavelength grid.

## Value

Score array with spatial dimensions of the new cube; invalid pixels are
NA.
