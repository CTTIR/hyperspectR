# Get Dimensions of an hsi_cube

Get Dimensions of an hsi_cube

## Usage

``` r
# S3 method for class 'hsi_cube'
dim(x)
```

## Arguments

- x:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

## Value

Integer vector `c(rows, cols, bands)`.

## Examples

``` r
cube <- hs_example_cube()
dim(cube)
#> [1] 30 30 61
```
