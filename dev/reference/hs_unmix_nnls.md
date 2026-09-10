# Linear Spectral Unmixing via NNLS

Solves the linear mixing model per pixel using non-negative least
squares.

## Usage

``` r
hs_unmix_nnls(
  cube,
  endmembers,
  sum_to_one = FALSE,
  backend = c("builtin", "nnls"),
  keep_residuals = TRUE,
  chunk_size = 10000L
)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/dev/reference/hsi_cube.md)
  object (reflectance or absorbance).

- endmembers:

  Numeric matrix. Columns = endmember spectra. Rows = bands. Column
  names become abundance map labels.

- sum_to_one:

  Logical. Apply sum-to-one constraint. Default `FALSE`.

- backend:

  Explicit solver: `"builtin"` (default) or `"nnls"`.

- keep_residuals:

  Logical. Retain the full residual cube.

- chunk_size:

  Positive integer. Number of pixels per processing block.

## Value

A list with class `"hsi_unmix"`:

- abundances:

  3D array (rows x cols x n_endmembers) of abundance maps.

- residuals:

  3D array of reconstruction residuals.

- rmse:

  Numeric matrix of per-pixel RMSE.

- endmember_names:

  Character vector.

## Examples

``` r
cube <- hs_example_cube()
# Create simple endmembers
em <- cbind(
  tissue = cube$data[5, 5, ],
  background = cube$data[25, 25, ]
)
result <- hs_unmix_nnls(cube, em)
dim(result$abundances)
#> [1] 30 30  2
```
