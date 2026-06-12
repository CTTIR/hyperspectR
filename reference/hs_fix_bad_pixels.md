# Detect and Correct Bad Pixels

Identifies dead/hot pixels by statistical deviation from spatial
neighborhood and replaces with neighborhood interpolation.

## Usage

``` r
hs_fix_bad_pixels(cube, threshold = 3, method = "median")
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- threshold:

  Numeric. Standard deviation threshold for detection. Default `3`.

- method:

  Character. Replacement method: `"mean"` or `"median"` of spatial
  neighbors. Default `"median"`.

## Value

An [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
object with corrected pixels.

## Examples

``` r
cube <- hs_example_cube()
# Introduce a hot pixel
cube$data[15, 15, ] <- 999
fixed <- hs_fix_bad_pixels(cube, threshold = 3)
```
