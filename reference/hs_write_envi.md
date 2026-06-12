# Write an HSI Cube to ENVI Format

Writes an
[hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
object as an ENVI header (.hdr) and binary (.dat) file pair.

## Usage

``` r
hs_write_envi(cube, path, interleave = "bsq", data_type = 4L, verbose = TRUE)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- path:

  Character. Output path without extension. Files `.hdr` and `.dat` will
  be created.

- interleave:

  Character. Data interleave format: `"bsq"` (default), `"bil"`, or
  `"bip"`.

- data_type:

  Integer. ENVI data type code. Default `4` (float32).

- verbose:

  Logical. Print progress. Default `TRUE`.

## Value

Invisible character vector of written file paths.

## Examples

``` r
cube <- hs_example_cube()
dir <- tempdir()
paths <- hs_write_envi(cube, file.path(dir, "test_cube"), verbose = FALSE)
file.exists(paths)
#> [1] TRUE TRUE
```
