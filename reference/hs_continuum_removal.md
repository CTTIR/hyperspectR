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

## References

Clark, R. N. and Roush, T. L. (1984). Reflectance spectroscopy:
quantitative analysis techniques for remote sensing applications.
*Journal of Geophysical Research: Solid Earth*, 89(B7), 6329-6340.
`doi:10.1029/JB089iB07p06329`

## Examples

``` r
cube <- hs_example_cube()
cr <- hs_continuum_removal(cube, method = "division")
```
