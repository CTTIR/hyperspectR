# Write an HSI Cube to Multi-Band TIFF

Writes an
[hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
object as a multi-band GeoTIFF file. Requires the `terra` package.

## Usage

``` r
hs_write_tiff(cube, path, verbose = TRUE)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- path:

  Character. Output path (should end in .tif).

- verbose:

  Logical. Print progress. Default `TRUE`.

## Value

Invisible path to the written file.

## Examples

``` r
# \donttest{
# Requires terra package
# cube <- hs_example_cube()
# hs_write_tiff(cube, file.path(tempdir(), "test.tif"))
# }
```
