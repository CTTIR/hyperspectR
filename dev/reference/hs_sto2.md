# Estimate the Oxygenated Hemoglobin Fraction for Research

Returns the fitted HbO2 fraction from
[`hs_beer_lambert()`](https://cttir.github.io/hyperspectR/dev/reference/hs_beer_lambert.md).
This is a research model estimate and requires empirical validation for
tissue use.

## Usage

``` r
hs_sto2(
  cube,
  band1 = c(500, 650),
  band2 = c(700, 815),
  method = "beer_lambert"
)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/dev/reference/hsi_cube.md)
  object with reflectance data.

- band1, band2:

  Retired ratio-method arguments. Supplying either raises a migration
  error; use
  [`hs_band_ratio()`](https://cttir.github.io/hyperspectR/dev/reference/hs_band_ratio.md)
  or the fitting range in
  [`hs_beer_lambert()`](https://cttir.github.io/hyperspectR/dev/reference/hs_beer_lambert.md).

- method:

  `"beer_lambert"` (default). The former `"ratio"` method is rejected;
  use
  [`hs_band_ratio()`](https://cttir.github.io/hyperspectR/dev/reference/hs_band_ratio.md)
  for a relative band ratio.

## Value

A numeric matrix (rows x cols) with values 0-100 representing estimated
tissue oxygen saturation percentage. Returns `NA` for masked pixels.

## Examples

``` r
cube <- hs_example_cube()
sto2 <- hs_sto2(cube)
range(sto2, na.rm = TRUE)
#> [1]  7.232219 83.120956
```
