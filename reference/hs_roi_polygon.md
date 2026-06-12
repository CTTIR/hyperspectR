# Define Polygon ROI

Creates a polygon region of interest using point-in-polygon testing.

## Usage

``` r
hs_roi_polygon(cube, vertices)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- vertices:

  Matrix with columns `x` and `y` (polygon vertices in pixel
  coordinates).

## Value

A list with class `"hsi_roi"` containing the mask.

## Examples

``` r
cube <- hs_example_cube()
verts <- matrix(c(5, 5, 15, 15, 5, 20, 5, 20), ncol = 2,
                dimnames = list(NULL, c("x", "y")))
roi <- hs_roi_polygon(cube, verts)
```
