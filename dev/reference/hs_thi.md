# Compute Tissue Hemoglobin Index (THI)

Legacy name for a dimensionless reference/Hb-band reflectance ratio. It
is not a hemoglobin concentration measurement.

## Usage

``` r
hs_thi(cube, band1 = c(530, 590), band2 = c(785, 825))
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/dev/reference/hsi_cube.md)
  object.

- band1:

  Numeric vector of length 2. Default `c(530, 590)` (Hb Q-bands).

- band2:

  Numeric vector of length 2. Default `c(785, 825)` (reference).

## Value

A numeric matrix of unscaled dimensionless band ratios.

## Examples

``` r
cube <- hs_example_cube()
thi <- hs_thi(cube)
```
