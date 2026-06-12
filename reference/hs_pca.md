# PCA on Hyperspectral Cube

Performs Principal Component Analysis on the spectral dimension of an
HSI cube. Reduces the spectral bands to a smaller number of orthogonal
components ordered by explained variance.

## Usage

``` r
hs_pca(cube, n_components = 5L, center = TRUE, scale = FALSE)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- n_components:

  Integer. Number of components to retain. Default `5`.

- center:

  Logical. Center bands before PCA. Default `TRUE`.

- scale:

  Logical. Scale bands to unit variance. Default `FALSE`.

## Value

A list with class `"hsi_pca"`:

- scores:

  3D array (rows x cols x n_components) of component score maps.

- loadings:

  Matrix (bands x n_components) of spectral loadings.

- variance_explained:

  Numeric vector of proportion of variance per component.

- center:

  Centering vector used (or `FALSE`).

- scale:

  Scaling vector used (or `FALSE`).

- wavelengths:

  Wavelength vector from input cube.

## Examples

``` r
cube <- hs_example_cube()
pca <- hs_pca(cube, n_components = 3)
pca$variance_explained
#> [1] 0.723528996 0.008620008 0.006954791
```
