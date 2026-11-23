# Multiplicative Scatter Correction

Corrects spectra for multiplicative and additive scatter effects by
regressing each spectrum against a reference spectrum (default: mean
spectrum).

## Usage

``` r
hs_msc(cube, reference = NULL)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- reference:

  Numeric vector. Reference spectrum. Default `NULL` = mean spectrum of
  the cube.

## Value

An [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
object with MSC-corrected spectra.

## References

Geladi, P., MacDougall, D. and Martens, H. (1985). Linearization and
scatter-correction for near-infrared reflectance spectra of meat.
*Applied Spectroscopy*, 39(3), 491-500. `doi:10.1366/0003702854248656`

## Examples

``` r
cube <- hs_example_cube()
msc_cube <- hs_msc(cube)
```
