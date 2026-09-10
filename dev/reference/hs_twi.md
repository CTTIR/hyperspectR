# Compute Tissue Water Index (TWI)

Legacy name for a dimensionless NIR reflectance ratio. The default
830-910 nm bands do not include the 970 nm water peak and do not measure
water content.

## Usage

``` r
hs_twi(cube, numerator = c(880, 910), denominator = c(830, 870))
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/dev/reference/hsi_cube.md)
  object.

- numerator:

  Numeric vector of length 2. Default `c(880, 910)` (adapted for Cubert
  range).

- denominator:

  Numeric vector of length 2. Default `c(830, 870)`.

## Value

A numeric matrix of unscaled dimensionless ratios, or an NA matrix with
a warning if required wavelengths are unavailable.

## Examples

``` r
cube <- hs_example_cube()
twi <- hs_twi(cube)
```
