# Export a Single-Band Image as PNG

Exports a single band or index map from an HSI cube as a PNG image.

## Usage

``` r
hs_export_png(
  data,
  path,
  palette = "viridis",
  range = NULL,
  width = NULL,
  height = NULL
)
```

## Arguments

- data:

  Numeric matrix to export (rows x cols).

- path:

  Character. Output file path (should end in .png).

- palette:

  Character. Color palette: `"viridis"`, `"magma"`, `"inferno"`,
  `"plasma"`, `"grey"`. Default `"viridis"`.

- range:

  Numeric vector of length 2. Data range for color mapping. Default
  `NULL` (auto from data range).

- width:

  Integer. Image width in pixels. Default `NULL` (matches data cols).

- height:

  Integer. Image height in pixels. Default `NULL` (matches data rows).

## Value

Invisible path to the written file.

## Examples

``` r
cube <- hs_example_cube()
mat <- cube$data[, , 30]
path <- file.path(tempdir(), "band30.png")
hs_export_png(mat, path)
```
