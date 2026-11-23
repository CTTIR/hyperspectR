# Summarize an hsi_cube Object

Returns a named list of cube statistics including per-band means and
standard deviations.

## Usage

``` r
# S3 method for class 'hsi_cube'
summary(object, ...)
```

## Arguments

- object:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- ...:

  Additional arguments (ignored).

## Value

A list of class `summary.hsi_cube` with elements `dimensions`,
`wavelength_range`, `n_bands`, `data_range`, `band_means`, `band_sds`,
`band_counts` (finite values per band), `n_valid_pixels` (pixels whose
whole spectrum is finite and unmasked), `n_total_pixels` and `metadata`.
Band statistics are named by rounded wavelength, or by the full
wavelength when rounding would give two bands the same name. Printing
the object shows a compact overview instead of the full list.

## Examples

``` r
cube <- hs_example_cube()
s <- summary(cube)
s
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
s$dimensions
#> [1] 30 30 61
```
