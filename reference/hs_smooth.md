# Savitzky-Golay Spectral Smoothing

Applies a Savitzky-Golay filter along the spectral dimension. Optionally
computes spectral derivatives. Uses `prospectr` or `signal` if
available, otherwise falls back to a built-in convolution
implementation.

## Usage

``` r
hs_smooth(cube, window = 5L, poly = 2L, deriv = 0L)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- window:

  Integer (odd). Filter window size in bands. Default `5`.

- poly:

  Integer. Polynomial order. Must be less than `window`. Default `2`.

- deriv:

  Integer. Derivative order (0 = smoothing only, 1 = first derivative, 2
  = second derivative). Default `0`.

## Value

An [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
object with smoothed/differentiated spectra.

## Examples

``` r
cube <- hs_example_cube()
smoothed <- hs_smooth(cube, window = 5, poly = 2)
dim(smoothed)
#> [1] 30 30 61
```
