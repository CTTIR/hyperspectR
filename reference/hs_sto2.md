# Compute Tissue Oxygen Saturation (StO2)

Estimates superficial tissue oxygenation from visible-range hemoglobin
absorption. Uses the ratio of reflectance in the 500-650 nm
(oxy/deoxy-Hb Q-bands) and 700-815 nm (NIR oxy-Hb shoulder) regions.

## Usage

``` r
hs_sto2(cube, band1 = c(500, 650), band2 = c(700, 815), method = "ratio")
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object with reflectance data.

- band1:

  Numeric vector of length 2. Wavelength range for first band (default
  `c(500, 650)`, visible Hb absorption).

- band2:

  Numeric vector of length 2. Wavelength range for second band (default
  `c(700, 815)`, NIR region).

- method:

  Character. `"ratio"` for band-ratio index (default), `"beer_lambert"`
  for full chromophore fitting.

## Value

A numeric matrix (rows x cols) with values 0-100 representing estimated
tissue oxygen saturation percentage. Returns `NA` for masked pixels.

## Examples

``` r
cube <- hs_example_cube()
sto2 <- hs_sto2(cube)
range(sto2, na.rm = TRUE)
#> [1]   0 100
```
