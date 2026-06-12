# Read an ENVI Hyperspectral Image File

Reads ENVI format hyperspectral data consisting of a `.hdr` header file
and a binary data file. Supports BSQ, BIL, and BIP interleave formats.

## Usage

``` r
hs_read_envi(
  path,
  backend = "auto",
  bands = NULL,
  extent = NULL,
  verbose = TRUE
)
```

## Arguments

- path:

  Path to the ENVI header file (.hdr) or binary file.

- backend:

  Character. `"auto"` (default) uses terra if available, otherwise falls
  back to built-in reader. `"builtin"` forces pure-R reader. `"terra"`
  forces terra (errors if not installed).

- bands:

  Integer vector of band indices to read. Default `NULL` = all.

- extent:

  Numeric vector `c(row_start, row_end, col_start, col_end)` for spatial
  subset. Default `NULL` = full image.

- verbose:

  Logical. Print progress messages. Default `TRUE`.

## Value

An [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
object.

## Examples

``` r
hdr_path <- hs_example_files()
cube <- hs_read_envi(hdr_path, verbose = FALSE)
dim(cube)
#> [1] 10 10 11
```
