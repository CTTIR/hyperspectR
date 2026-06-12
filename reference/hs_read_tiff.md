# Read a Multi-Channel TIFF File

Reads a multi-band TIFF file as a hyperspectral cube. Requires the
`terra` package for TIFF reading.

## Usage

``` r
hs_read_tiff(path, wavelengths, fwhm = NULL, verbose = TRUE)
```

## Arguments

- path:

  Path to multi-channel TIFF file.

- wavelengths:

  Numeric vector of wavelengths (required for TIFF files as they lack
  spectral metadata).

- fwhm:

  Numeric vector of FWHM values. Default `NULL`.

- verbose:

  Logical. Print progress messages. Default `TRUE`.

## Value

An [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
object.

## Examples

``` r
# \donttest{
# Requires terra package
# cube <- hs_read_tiff("path/to/image.tif", wavelengths = seq(430, 910, by = 8))
# }
```
