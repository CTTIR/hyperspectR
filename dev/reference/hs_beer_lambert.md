# Beer-Lambert Chromophore Fitting

Fits decadic absorbance to reference extinction coefficients with NNLS.
Without a known optical pathlength, coefficients are
concentration-pathlength products. The hemoglobin fraction is a research
model estimate; diffuse tissue scattering and camera response can bias
it.

## Usage

``` r
hs_beer_lambert(
  cube,
  chromophores = c("HbO2", "Hb"),
  wavelength_range = c(500, 600),
  input = c("auto", "reflectance", "absorbance"),
  pathlength_cm = NULL,
  response = c("point", "gaussian"),
  keep_residuals = FALSE
)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/dev/reference/hsi_cube.md)
  object with an explicit reflectance or absorbance domain.

- chromophores:

  Character vector. Default `c("HbO2", "Hb")`.

- wavelength_range:

  Numeric vector of length 2. Fitting range. Default `c(500, 600)` (Hb
  Q-band region for best contrast).

- input:

  `"auto"` reads the declared processing mode, or explicitly specify
  `"reflectance"` or `"absorbance"`. Values never determine the domain.

- pathlength_cm:

  Positive scalar optical pathlength, or NULL (unknown).

- response:

  `"point"` (default) samples band centers; `"gaussian"` integrates
  reference coefficients using cube FWHM as Gaussian widths.

- keep_residuals:

  Logical. Retain spectral residuals. Default FALSE.

## Value

A list with class `"hsi_chromophore_fit"`:

- coefficients:

  Named matrices of concentration-pathlength products (mol/L \* cm).

- concentrations:

  Named matrices in mol/L when pathlength is supplied; otherwise NULL.

- sto2:

  Matrix of oxygen saturation = HbO2 / (HbO2 + Hb) \* 100.

- total_hb:

  Sum of HbO2 and Hb concentration-pathlength products.

- rmse:

  Matrix of fit residuals.

## Examples

``` r
cube <- hs_example_cube()
fit <- hs_beer_lambert(cube)
range(fit$sto2, na.rm = TRUE)
#> [1]  7.232219 83.120956
```
