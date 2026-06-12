# Resample Spectra to New Wavelength Grid

Interpolates the spectral data to a new set of wavelength positions.

## Usage

``` r
hs_resample(cube, target_wavelengths, method = "linear")
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- target_wavelengths:

  Numeric vector. Target wavelength positions in nm.

- method:

  Character. Interpolation method: `"linear"` (default), `"spline"`.

## Value

An [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
object with resampled spectra.

## Examples

``` r
cube <- hs_example_cube()
resampled <- hs_resample(cube, target_wavelengths = seq(450, 900, by = 10))
length(resampled$wavelengths)
#> [1] 46
```
