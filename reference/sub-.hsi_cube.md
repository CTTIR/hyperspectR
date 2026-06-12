# Subset an hsi_cube Object

Extract spatial and/or spectral subsets from a cube. Subsetting
preserves the `hsi_cube` class.

## Usage

``` r
# S3 method for class 'hsi_cube'
x[i, j, k, ...]
```

## Arguments

- x:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- i:

  Row indices (spatial).

- j:

  Column indices (spatial).

- k:

  Band indices (spectral).

- ...:

  Additional arguments (ignored).

## Value

A subsetted
[hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
object.

## Examples

``` r
cube <- hs_example_cube()
sub <- cube[1:10, 1:10, 1:5]
dim(sub)
#> [1] 10 10  5
```
