# Summarize an hsi_cube Object

Returns a named list of cube statistics including per-band means and
standard deviations.

## Usage

``` r
# S3 method for class 'hsi_cube'
summary(object, ...)
```

## Arguments

- object:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- ...:

  Additional arguments (ignored).

## Value

A named list with elements `dimensions`, `wavelength_range`, `n_bands`,
`data_range`, `band_means`, `band_sds`, `n_valid_pixels`, and
`metadata`.

## Examples

``` r
cube <- hs_example_cube()
s <- summary(cube)
s$dimensions
#> [1] 30 30 61
```
