# Compute Near-Infrared Perfusion Index (NPI)

Estimates deeper tissue perfusion (4-6 mm depth) from NIR wavelengths.
Note: Cubert Ultris X MR upper limit is 910 nm; the original TIVITA NPI
extends to 925 nm. Results are approximate with Cubert data.

## Usage

``` r
hs_npi(cube, band1 = c(655, 735), band2 = c(825, 910))
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object with reflectance data.

- band1:

  Numeric vector of length 2. Default `c(655, 735)`.

- band2:

  Numeric vector of length 2. Default `c(825, 910)`.

## Value

A numeric matrix with values 0-100.

## Examples

``` r
cube <- hs_example_cube()
npi <- hs_npi(cube)
```
