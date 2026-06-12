# Minimalist HSI Theme

A clean ggplot2 theme designed for hyperspectral image display. Uses
minimal styling with a white background.

## Usage

``` r
theme_hsi(base_size = 11)
```

## Arguments

- base_size:

  Numeric. Base font size. Default `11`.

## Value

A [ggplot2::theme](https://ggplot2.tidyverse.org/reference/theme.html)
object.

## Examples

``` r
library(ggplot2)
ggplot(data.frame(x = 1:10, y = 1:10), aes(x, y)) +
  geom_point() +
  theme_hsi()

```
