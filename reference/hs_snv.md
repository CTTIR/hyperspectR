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

## References

Barnes, R. J., Dhanoa, M. S. and Lister, S. J. (1989). Standard normal
variate transformation and de-trending of near-infrared diffuse
reflectance spectra. *Applied Spectroscopy*, 43(5), 772-777.
`doi:10.1366/0003702894202201`

## Examples

``` r
cube <- hs_example_cube()
snv_cube <- hs_snv(cube)
```
