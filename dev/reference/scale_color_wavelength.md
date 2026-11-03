# Wavelength-to-Color Scale for Spectral Plots

Maps wavelength values to approximate visible light colors for spectral
line coloring. The default scale is fixed at 380-780 nm, so a wavelength
retains its colour when the plotted range changes. Values outside the
display limits use the scale's missing-value colour. Numeric increasing
`limits` supplied in `...` may restrict or extend the displayed range
while preserving the wavelength mapping.

## Usage

``` r
scale_color_wavelength(...)

scale_colour_wavelength(...)
```

## Arguments

- ...:

  Additional arguments passed to
  [`ggplot2::scale_color_gradientn()`](https://ggplot2.tidyverse.org/reference/scale_gradient.html).

## Value

A [ggplot2::Scale](https://ggplot2.tidyverse.org/reference/Scale.html)
object.

## Examples

``` r
cube <- hs_example_cube()
library(ggplot2)
df <- data.frame(
  wavelength = cube$wavelengths,
  value = cube$data[15, 15, ]
)
ggplot(df, aes(wavelength, value, color = wavelength)) +
  geom_line() +
  scale_color_wavelength()

```
