# Compute Tissue Water Index (TWI)

Estimates tissue water content from the 960 nm water absorption band.
The Cubert Ultris X MR (430-910 nm) does NOT fully cover this range.

## Usage

``` r
hs_twi(cube, numerator = c(880, 910), denominator = c(830, 870))
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- numerator:

  Numeric vector of length 2. Default `c(880, 910)` (adapted for Cubert
  range).

- denominator:

  Numeric vector of length 2. Default `c(830, 870)`.

## Value

A numeric matrix with values 0-100, or an NA matrix with a warning if
required wavelengths are unavailable.

## Examples

``` r
cube <- hs_example_cube()
twi <- hs_twi(cube)
```
