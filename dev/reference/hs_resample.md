# Resample Spectra to New Wavelength Grid

Interpolates the spectral data to a new set of wavelength positions.

## Usage

``` r
hs_resample(cube, target_wavelengths, method = "linear")
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/dev/reference/hsi_cube.md)
  object.

- target_wavelengths:

  Numeric vector. Target wavelength positions in nm.

- method:

  Character. Interpolation method: `"linear"` (default), `"spline"`.

## Value

An
[hsi_cube](https://cttir.github.io/hyperspectR/dev/reference/hsi_cube.md)
object with resampled spectra.

## Details

Band-specific quality flags are not interpolated. Existing calibration
and absorbance flags move to `metadata$source_spectral_qc`, where each
record retains its original `wavelengths` and named `flags`. Their
former current-grid fields are removed. Repeated resampling without new
flags does not duplicate these records; spatial subsetting retains
aligned source flags without changing their original spectral axis.

## Examples

``` r
cube <- hs_example_cube()
resampled <- hs_resample(cube, target_wavelengths = seq(450, 900, by = 10))
length(resampled$wavelengths)
#> [1] 46
```
