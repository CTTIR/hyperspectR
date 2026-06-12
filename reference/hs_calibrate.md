# Calibrate Raw HSI Data to Reflectance

Applies dark current subtraction and white reference normalization:
`R(x,y,lambda) = (raw - dark) / (white - dark)`. Values are clamped to
`[0, 1]` unless `clamp = FALSE`.

## Usage

``` r
hs_calibrate(cube, dark, white, clamp = TRUE)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object with raw data.

- dark:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object or 3D array representing the dark reference (lens cap
  measurement).

- white:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object or 3D array representing the white reference (Spectralon panel
  measurement).

- clamp:

  Logical. Clamp output to `[0, 1]`. Default `TRUE`.

## Value

An [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
object with reflectance values.

## Examples

``` r
cube <- hs_simulate_cube(rows = 10, cols = 10, noise_sd = 0)
dark <- hsi_cube(array(0.01, dim(cube$data)), cube$wavelengths)
white <- hsi_cube(array(0.95, dim(cube$data)), cube$wavelengths)
cal <- hs_calibrate(cube, dark, white)
range(cal$data)
#> [1] 0.04255319 0.73404255
```
