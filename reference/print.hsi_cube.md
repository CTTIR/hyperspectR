# Print an hsi_cube Object

Displays a compact summary of the hyperspectral cube.

## Usage

``` r
# S3 method for class 'hsi_cube'
print(x, ...)
```

## Arguments

- x:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- ...:

  Additional arguments (ignored).

## Value

Invisible `x`.

## Examples

``` r
cube <- hs_example_cube()
print(cube)
#> 
#> ── hsi_cube ────────────────────────────────────────────────────────────────────
#> Dimensions: 30 rows x 30 cols x 61 bands
#> Wavelengths: 430-910 nm (61 bands)
#> FWHM: 25 nm (mean)
#> Mask: 900/900 valid pixels (100%)
#> Data range: [0.0198, 0.7306]
#> Metadata: camera, processing_mode, acquisition_time, region_map,
#> sto2_ground_truth, seed
```
