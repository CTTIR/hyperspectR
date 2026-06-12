# Extract Endmember Spectra from a Cube

Extracts endmember spectra from specified pixel locations.

## Usage

``` r
hs_endmembers(cube, pixels, labels = NULL)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- pixels:

  Data.frame or matrix with columns `x` (col) and `y` (row).

- labels:

  Character vector of class labels for each pixel. Default `NULL`
  (auto-generated).

## Value

A named matrix with endmember spectra (rows = endmembers, cols = bands).

## Examples

``` r
cube <- hs_example_cube()
pixels <- data.frame(x = c(5, 25), y = c(5, 25))
em <- hs_endmembers(cube, pixels, labels = c("region_1", "region_2"))
dim(em)
#> [1]  2 61
```
