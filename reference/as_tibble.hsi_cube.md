# Convert hsi_cube to Tibble

Convert hsi_cube to Tibble

## Usage

``` r
as_tibble.hsi_cube(x, ..., long = TRUE, .name_repair = "unique")
```

## Arguments

- x:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- ...:

  Additional arguments (ignored).

- long:

  Logical. If `TRUE` (default), returns long format. See
  [`as.data.frame.hsi_cube()`](https://cttir.github.io/hyperspectR/reference/as.data.frame.hsi_cube.md)
  for details.

- .name_repair:

  Name repair strategy (passed to
  [`tibble::as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)).

## Value

A [tibble::tibble](https://tibble.tidyverse.org/reference/tibble.html).

## Examples

``` r
cube <- hs_example_cube()
tb <- as_tibble.hsi_cube(cube[1:3, 1:3, 1:3])
head(tb)
#> # A tibble: 6 × 4
#>       x     y wavelength  value
#>   <int> <int>      <dbl>  <dbl>
#> 1     1     1        430 0.0637
#> 2     1     1        438 0.0983
#> 3     1     1        446 0.164 
#> 4     1     2        430 0.0444
#> 5     1     2        438 0.0864
#> 6     1     2        446 0.172 
```
