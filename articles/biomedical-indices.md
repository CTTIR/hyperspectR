# Research Spectral Indices Explained

![hyperspectR logo](figures/logo.svg)![hyperspectR
logo](figures/logo-dark.svg)

[![R-CMD-check](https://github.com/CTTIR/hyperspectR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/CTTIR/hyperspectR/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/CTTIR/hyperspectR/actions/workflows/pkgdown.yaml/badge.svg)](https://cttir.github.io/hyperspectR/)
[![Codecov test
coverage](https://codecov.io/gh/CTTIR/hyperspectR/branch/main/graph/badge.svg)](https://app.codecov.io/gh/CTTIR/hyperspectR?branch=main)
[![License:
MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

``` r

library(hyperspectR)
#> hyperspectR v0.3.0 - Hyperspectral Imaging Analysis for Biomedical Applications
```

## Haemoglobin Absorption

Tissue oxygenation assessment via HSI relies on the distinct absorption
spectra of oxyhaemoglobin (HbO2) and deoxyhaemoglobin (Hb).

``` r

hb_data <- hs_chromophore_data(c("HbO2", "Hb"), wavelength_range = c(430, 910))
library(ggplot2)
ggplot(hb_data, aes(x = wavelength)) +
  geom_line(aes(y = HbO2, color = "HbO2"), linewidth = 0.8) +
  geom_line(aes(y = Hb, color = "Hb"), linewidth = 0.8) +
  scale_color_manual(values = c(HbO2 = "#E41A1C", Hb = "#377EB8")) +
  labs(x = "Wavelength (nm)", y = "Molar extinction coefficient (cm^-1 / (mol/L))",
       title = "Hemoglobin Absorption Spectra", color = "Hemoglobin") +
  theme_hsi()
```

![Line plot of the tabulated molar extinction coefficients of
oxyhaemoglobin and deoxyhaemoglobin from 430 to 910 nm; both are highest
at the blue end, show peaks between 540 and 580 nm and are low in the
near
infrared.](biomedical-indices_files/figure-html/unnamed-chunk-2-1.png)

## Tissue Oxygen Saturation (StO2)

[`hs_sto2()`](https://cttir.github.io/hyperspectR/reference/hs_sto2.md)
reports the fitted HbO2 fraction using tabulated decadic extinction
coefficients. It assumes the stated Beer-Lambert model; it is not an
empirically validated measure of tissue oxygen saturation for a camera
or clinical task.

``` r

cube <- hs_example_cube()
sto2 <- hs_sto2(cube)
hs_plot_index(sto2, title = "Fitted Hb fraction (%)", palette = "sto2")
```

![Map of the fitted oxygenated haemoglobin fraction in percent; the four
quadrants of the synthetic scene take four distinct levels on a
blue-to-red
scale.](biomedical-indices_files/figure-html/unnamed-chunk-3-1.png)

## Near-Infrared Perfusion Index (NPI)

The legacy NPI name returns an unscaled NIR band ratio. It has no
calibrated perfusion or depth interpretation.

``` r

npi <- hs_npi(cube)
hs_plot_index(npi, title = "NIR ratio", palette = "perfusion")
```

![Map of the dimensionless near-infrared band ratio of the example cube
on a viridis
scale.](biomedical-indices_files/figure-html/unnamed-chunk-4-1.png)

## Tissue Haemoglobin Index (THI)

The legacy THI name returns a dimensionless reference/Hb-band ratio. It
is not a concentration.

``` r

thi <- hs_thi(cube)
hs_plot_index(thi, title = "Hb-band ratio", palette = "hemoglobin")
```

![Map of the dimensionless haemoglobin-band ratio of the example cube on
a magma scale; the four quadrants take four distinct
levels.](biomedical-indices_files/figure-html/unnamed-chunk-5-1.png)

## Custom Normalized Difference Index

Create any two-band ratio index:

``` r

ndi <- hs_ndi(cube, band1 = 540, band2 = 660)
hs_plot_index(ndi, title = "NDI (540/660)", range = c(-1, 1))
```

![Map of the normalized difference index of the bands at 540 and 660 nm,
drawn on a fixed scale from minus one to
one.](biomedical-indices_files/figure-html/unnamed-chunk-6-1.png)

## Research Panel

The research panel combines RGB with model fractions and relative
indices. It does not reproduce vendor indices:

``` r

hs_plot_clinical(cube)
```

![Research panel in a two-by-two grid: RGB composite, fitted haemoglobin
fraction map, near-infrared band ratio map and haemoglobin-band ratio
map of the synthetic scene, each with rows and columns as axes and its
own colour
bar.](biomedical-indices_files/figure-html/unnamed-chunk-7-1.png)
