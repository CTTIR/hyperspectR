# Compute Near-Infrared Perfusion Index (NPI)

Legacy name for a dimensionless NIR band ratio. It is not a validated
perfusion measurement or an implementation of a vendor index.

## Usage

``` r
hs_npi(cube, band1 = c(655, 735), band2 = c(825, 910))
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/dev/reference/hsi_cube.md)
  object with reflectance data.

- band1:

  Numeric vector of length 2. Default `c(655, 735)`.

- band2:

  Numeric vector of length 2. Default `c(825, 910)`.

## Value

A numeric matrix of unscaled dimensionless band ratios.

## Examples

``` r
cube <- hs_example_cube()
npi <- hs_npi(cube)
```
