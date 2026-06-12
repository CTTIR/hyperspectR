# Get Chromophore Extinction Coefficient Spectra

Returns published molar extinction coefficient spectra for common tissue
chromophores. Data from Prahl (Oregon Medical Laser Center) and Jacques
(2013).

## Usage

``` r
hs_chromophore_data(
  chromophore = c("HbO2", "Hb"),
  wavelength_range = c(400, 1000)
)
```

## Arguments

- chromophore:

  Character vector. One or more of: `"HbO2"` (oxyhemoglobin), `"Hb"`
  (deoxyhemoglobin), `"water"`, `"melanin"`, `"metHb"` (methemoglobin).
  Default `c("HbO2", "Hb")`.

- wavelength_range:

  Numeric vector of length 2. Wavelength range in nm. Default
  `c(400, 1000)`.

## Value

A [tibble::tibble](https://tibble.tidyverse.org/reference/tibble.html)
with columns `wavelength` (nm) and one column per requested chromophore
(extinction coefficient in cm^-1 / (mol/L)).

## Examples

``` r
hb_data <- hs_chromophore_data()
head(hb_data)
#> # A tibble: 6 × 3
#>   wavelength    HbO2      Hb
#>        <dbl>   <dbl>   <dbl>
#> 1        400 147007.  28787.
#> 2        402 178450.  38491.
#> 3        404 210722.  50509.
#> 4        406 242043.  65011.
#> 5        408 270427.  82049.
#> 6        410 293884. 101514.
```
