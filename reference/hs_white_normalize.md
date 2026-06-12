# Apply White Reference Normalization

Normalizes the cube by a white reference, optionally with dark
correction.

## Usage

``` r
hs_white_normalize(cube, white, dark = NULL)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- white:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object or 3D array representing the white reference.

- dark:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object or 3D array representing the dark reference. Default `NULL` (no
  dark subtraction).

## Value

An [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
object with normalized values.

## Examples

``` r
cube <- hs_simulate_cube(rows = 10, cols = 10, noise_sd = 0)
white <- hsi_cube(array(0.95, dim(cube$data)), cube$wavelengths)
norm <- hs_white_normalize(cube, white)
```
