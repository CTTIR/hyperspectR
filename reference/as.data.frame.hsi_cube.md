# Convert hsi_cube to Data Frame

Convert hsi_cube to Data Frame

## Usage

``` r
# S3 method for class 'hsi_cube'
as.data.frame(x, ..., long = FALSE)
```

## Arguments

- x:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- ...:

  Additional arguments (ignored).

- long:

  Logical. If `TRUE`, returns long format with columns `x`, `y`,
  `wavelength`, `value`. If `FALSE`, returns wide format with columns
  `x`, `y`, and one column per band. Default `FALSE`.

## Value

A `data.frame`.

## Examples

``` r
cube <- hs_example_cube()
df <- as.data.frame(cube[1:3, 1:3, 1:3], long = TRUE)
head(df)
#>   x y wavelength      value
#> 1 1 1        430 0.06370958
#> 2 1 1        438 0.09825999
#> 3 1 1        446 0.16391515
#> 4 1 2        430 0.04435302
#> 5 1 2        438 0.08635461
#> 6 1 2        446 0.17159862
```
