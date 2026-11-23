# Plot Index Map with Clinical Colour Scale

Displays a single tissue index as a pseudocolour spatial map with colour
scales selected for research visualization.

## Usage

``` r
hs_plot_index(
  index_matrix,
  title = "",
  palette = "sto2",
  range = NULL,
  mask = NULL
)
```

## Arguments

- index_matrix:

  Numeric matrix (rows x cols) from an index function. A logical matrix
  is drawn as 0/1.

- title:

  Character. Map title (e.g., "StO2 (%)"). Default `""`.

- palette:

  Character. `"sto2"` (blue-red diverging), `"perfusion"` (viridis),
  `"hemoglobin"` (magma), `"water"` (mako). Default `"sto2"`.

- range:

  Numeric vector of length 2. Display range. Default `NULL` (data
  range). An `NA` entry takes that limit from the data.

- mask:

  Logical matrix. Pixels to mask (FALSE = masked). Default `NULL`.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
cube <- hs_example_cube()
sto2 <- hs_sto2(cube)
hs_plot_index(sto2, title = "Fitted Hb fraction (%)", palette = "sto2")

```
