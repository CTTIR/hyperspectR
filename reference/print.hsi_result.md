# Print hyperspectR Result Objects

Compact console overviews for the objects returned by the analysis
functions. Without these methods R prints every score map, residual cube
and fitted model in full. Each method shows the class, the dimensions
and the key settings, and returns its argument invisibly. The objects
stay plain lists: use [`names()`](https://rdrr.io/r/base/names.html),
[`str()`](https://rdrr.io/r/utils/str.html) or `$` to reach every
element.

## Usage

``` r
# S3 method for class 'summary.hsi_cube'
print(x, ...)

# S3 method for class 'hsi_pca'
print(x, ...)

# S3 method for class 'hsi_mnf'
print(x, ...)

# S3 method for class 'hsi_umap'
print(x, ...)

# S3 method for class 'hsi_unmix'
print(x, ...)

# S3 method for class 'hsi_chromophore_fit'
print(x, ...)

# S3 method for class 'hsi_classification'
print(x, ...)

# S3 method for class 'hsi_roi'
print(x, ...)

# S3 method for class 'hsi_recipe'
print(x, ...)
```

## Arguments

- x:

  An object returned by
  [`summary.hsi_cube()`](https://cttir.github.io/hyperspectR/reference/summary.hsi_cube.md),
  [`hs_pca()`](https://cttir.github.io/hyperspectR/reference/hs_pca.md),
  [`hs_mnf()`](https://cttir.github.io/hyperspectR/reference/hs_mnf.md),
  [`hs_umap()`](https://cttir.github.io/hyperspectR/reference/hs_umap.md),
  [`hs_unmix_nnls()`](https://cttir.github.io/hyperspectR/reference/hs_unmix_nnls.md),
  [`hs_beer_lambert()`](https://cttir.github.io/hyperspectR/reference/hs_beer_lambert.md),
  [`hs_sam()`](https://cttir.github.io/hyperspectR/reference/hs_sam.md),
  [`hs_classify_svm()`](https://cttir.github.io/hyperspectR/reference/hs_classify_svm.md),
  [`hs_classify_rf()`](https://cttir.github.io/hyperspectR/reference/hs_classify_rf.md),
  [`hs_roi_rect()`](https://cttir.github.io/hyperspectR/reference/hs_roi_rect.md),
  [`hs_roi_polygon()`](https://cttir.github.io/hyperspectR/reference/hs_roi_polygon.md)
  or
  [`hs_recipe()`](https://cttir.github.io/hyperspectR/reference/hs_recipe.md).

- ...:

  Additional arguments (ignored).

## Value

Invisible `x`.

## Examples

``` r
cube <- hs_example_cube()
summary(cube)
#> 
#> ── summary.hsi_cube ────────────────────────────────────────────────────────────
#> Dimensions: 30 rows x 30 cols x 61 bands
#> Wavelengths: 430-910 nm
#> Valid pixels: 900/900 (100%)
#> Data range: [0.01982, 0.73060]
#> Band means: [0.04962, 0.70050]
#> Band SDs: [0.009737, 0.065890]
#> Metadata: camera, spectral_model, interpretation, processing_mode,
#> acquisition_time, region_map, sto2_ground_truth, seed
hs_pca(cube, n_components = 3)
#> 
#> ── hsi_pca ─────────────────────────────────────────────────────────────────────
#> Scores: 30 rows x 30 cols x 3 components
#> Loadings: 61 bands x 3 components
#> Variance explained (%): 72.400, 0.862, 0.695
#> Valid pixels: 900/900 (100%)
#> Centered: TRUE; scaled: FALSE
hs_roi_rect(cube, x_range = c(5, 15), y_range = c(5, 15))
#> 
#> ── hsi_roi ─────────────────────────────────────────────────────────────────────
#> Type: rectangle
#> Mask: 30 rows x 30 cols, 121/900 (13.4%) pixels selected
#> Columns 5-15, rows 5-15
hs_recipe(list(list(method = "snv"), list(method = "msc")))
#> 
#> ── hsi_recipe ──────────────────────────────────────────────────────────────────
#> Steps: 2; seed: 1
#> 1. snv
#> 2. msc
```
