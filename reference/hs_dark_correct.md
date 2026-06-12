# Apply Dark Current Correction

Subtracts a dark reference from the cube data.

## Usage

``` r
hs_dark_correct(cube, dark)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- dark:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object or 3D array representing the dark reference.

## Value

An [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
object with dark-corrected values.

## Examples

``` r
cube <- hs_simulate_cube(rows = 10, cols = 10, noise_sd = 0)
dark <- hsi_cube(array(0.01, dim(cube$data)), cube$wavelengths)
corrected <- hs_dark_correct(cube, dark)
```
