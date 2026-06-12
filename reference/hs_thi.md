# Compute Tissue Hemoglobin Index (THI)

Estimates relative hemoglobin concentration at superficial depth.

## Usage

``` r
hs_thi(cube, band1 = c(530, 590), band2 = c(785, 825))
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- band1:

  Numeric vector of length 2. Default `c(530, 590)` (Hb Q-bands).

- band2:

  Numeric vector of length 2. Default `c(785, 825)` (reference).

## Value

A numeric matrix with values 0-100.

## Examples

``` r
cube <- hs_example_cube()
thi <- hs_thi(cube)
```
