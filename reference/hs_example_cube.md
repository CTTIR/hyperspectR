# Get Example HSI Cube

Generates a small pre-configured synthetic cube for quick examples and
documentation. The cube simulates a 30x30 pixel tissue scene with four
regions of varying oxygenation (healthy, ischemic, hyperemic,
background).

## Usage

``` r
hs_example_cube()
```

## Value

An [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
object (30 x 30 x 61 bands, 430-910 nm).

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
dim(cube)
#> [1] 30 30 61
```
