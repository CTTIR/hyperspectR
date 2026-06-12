# Convert Reflectance to Absorbance

Computes `A(lambda) = -log10(R(lambda))`. Values of R at or below zero
are clamped to `floor` before log transformation.

## Usage

``` r
hs_absorbance(cube, floor = 1e-06)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object with reflectance values.

- floor:

  Numeric. Minimum reflectance value to prevent log(0). Default `1e-6`.

## Value

An [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
object with absorbance values.

## Examples

``` r
cube <- hs_example_cube()
abs_cube <- hs_absorbance(cube)
```
