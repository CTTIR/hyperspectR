# Write Example ENVI Files to a Temporary Directory

Writes a minimal ENVI header + binary pair for testing I/O functions.

## Usage

``` r
hs_example_files(dir = tempdir())
```

## Arguments

- dir:

  Character. Directory to write to. Default
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html).

## Value

Character. Path to the written `.hdr` file (invisibly).

## Examples

``` r
hdr_path <- hs_example_files()
file.exists(hdr_path)
#> [1] TRUE
```
