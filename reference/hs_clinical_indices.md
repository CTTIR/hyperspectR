# Compute All Available Clinical Indices

Convenience function that computes StO2, NPI, THI, and TWI (if
wavelength range permits) and returns them as a named list of matrices.

## Usage

``` r
hs_clinical_indices(cube)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object with reflectance data.

## Value

A named list of numeric matrices: `sto2`, `npi`, `thi`, `twi` (TWI may
be NA matrix if wavelengths are insufficient).

## Examples

``` r
cube <- hs_example_cube()
indices <- hs_clinical_indices(cube)
names(indices)
#> [1] "sto2" "npi"  "thi"  "twi" 
```
