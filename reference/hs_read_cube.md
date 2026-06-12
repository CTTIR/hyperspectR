# Read a Hyperspectral Data Cube from Any Supported Format

Auto-detects format from file extension and dispatches to the
appropriate reader. Supported formats: ENVI (.hdr), TIFF (.tif/.tiff),
Cubert (.cu3s).

## Usage

``` r
hs_read_cube(path, ...)
```

## Arguments

- path:

  Path to the hyperspectral data file.

- ...:

  Additional arguments passed to the format-specific reader.

## Value

An [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
object.

## Examples

``` r
hdr_path <- hs_example_files()
cube <- hs_read_cube(hdr_path, verbose = FALSE)
dim(cube)
#> [1] 10 10 11
```
