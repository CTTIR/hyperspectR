# Detect and Correct Bad Pixels

Identifies dead/hot pixels by statistical deviation from spatial
neighborhood median/MAD and replaces with neighborhood interpolation.
Detection uses the immutable image; replacement excludes every detected
defect. Defects occupying most of a neighborhood may not be
distinguishable.

## Usage

``` r
hs_fix_bad_pixels(cube, threshold = 3, method = "median")
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/dev/reference/hsi_cube.md)
  object.

- threshold:

  Numeric. Robust standard deviation (scaled MAD) threshold. Default
  `3`.

- method:

  Character. Replacement method: `"mean"` or `"median"` of spatial
  neighbors. Default `"median"`.

## Value

An
[hsi_cube](https://cttir.github.io/hyperspectR/dev/reference/hsi_cube.md)
object with corrected pixels.

## Examples

``` r
cube <- hs_example_cube()
# Introduce a hot pixel
cube$data[15, 15, ] <- 999
fixed <- hs_fix_bad_pixels(cube, threshold = 3)
```
