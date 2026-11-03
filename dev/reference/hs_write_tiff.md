# Write an HSI Cube to Multi-Band TIFF

Writes an
[hsi_cube](https://cttir.github.io/hyperspectR/dev/reference/hsi_cube.md)
object as a multi-band GeoTIFF file. Requires the `terra` package.
Values are stored as float64 to preserve the R double range and
precision; this can use more disk space than float32 TIFF. A completed
temporary TIFF replaces the target only after encoding succeeds;
ordinary write failures leave an existing target intact.

## Usage

``` r
hs_write_tiff(cube, path, verbose = TRUE)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/dev/reference/hsi_cube.md)
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
