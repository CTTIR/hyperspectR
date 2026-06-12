# Spectral Derivative

Computes the spectral derivative using Savitzky-Golay differentiation.
Shorthand for
[`hs_smooth()`](https://cttir.github.io/hyperspectR/reference/hs_smooth.md)
with `deriv > 0`.

## Usage

``` r
hs_derivative(cube, order = 1L, window = 5L)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- order:

  Integer. Derivative order. Default `1`.

- window:

  Integer (odd). SG window size. Default `5`.

## Value

An [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
object with derivative spectra.

## Examples

``` r
cube <- hs_example_cube()
d1 <- hs_derivative(cube, order = 1)
```
