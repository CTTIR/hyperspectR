# Continuum Removal

Removes the spectral continuum (convex hull) from each spectrum. Useful
for enhancing absorption features and normalizing baseline variations.

## Usage

``` r
hs_continuum_removal(cube, method = c("division", "subtraction"))
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- method:

  Character. `"division"` (default) divides by the continuum,
  `"subtraction"` subtracts the continuum.

## Value

An [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
object with continuum-removed spectra.

## Examples

``` r
cube <- hs_example_cube()
cr <- hs_continuum_removal(cube, method = "division")
```
