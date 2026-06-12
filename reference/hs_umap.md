# UMAP Embedding of Spectral Data

Computes a UMAP (Uniform Manifold Approximation and Projection)
embedding of the spectral data. Requires the `uwot` package.

## Usage

``` r
hs_umap(
  cube,
  n_components = 2L,
  n_neighbors = 15L,
  min_dist = 0.1,
  pca_pre = 20L
)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- n_components:

  Integer. UMAP dimensions. Default `2`.

- n_neighbors:

  Integer. Default `15`.

- min_dist:

  Numeric. Default `0.1`.

- pca_pre:

  Integer or NULL. PCA pre-reduction dimensionality. Default `20`.

## Value

A list with class `"hsi_umap"` containing embedding matrix and spatial
coordinates.

## Examples

``` r
# \donttest{
# Requires uwot package
cube <- hs_example_cube()
if (requireNamespace("uwot", quietly = TRUE)) {
  umap_result <- hs_umap(cube, n_components = 2)
}
# }
```
