# Standard Normal Variate Correction

Normalizes each spectrum to zero mean and unit variance. Useful for
reducing multiplicative scatter effects and baseline variation.

## Usage

``` r
hs_snv(cube)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

## Value

An [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
object with SNV-corrected spectra.

## Examples

``` r
cube <- hs_example_cube()
snv_cube <- hs_snv(cube)
```
