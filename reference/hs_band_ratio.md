# Compute an Unscaled Spectral Band Ratio

A scene-independent, dimensionless ratio of mean spectral values. It is
not calibrated oxygen saturation, perfusion, concentration or water
content.

## Usage

``` r
hs_band_ratio(cube, numerator, denominator)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- numerator, denominator:

  Numeric scalar wavelength or two-element range in nm.

## Value

A spatial numeric matrix. Zero denominators and invalid pixels are NA.

## Examples

``` r
cube <- hs_example_cube()
ratio <- hs_band_ratio(cube, numerator = c(650, 700), denominator = c(800, 850))
range(ratio, na.rm = TRUE)
#> [1] 0.8343857 0.8918165
```
