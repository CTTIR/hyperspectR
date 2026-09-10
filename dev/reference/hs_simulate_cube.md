# Generate a Synthetic HSI Cube for Testing and Examples

Creates a realistic synthetic tissue hyperspectral cube with known
ground truth. Simulates a tissue scene with regions of varying
oxygenation, hemoglobin concentration, and a background (non-tissue)
region.

## Usage

``` r
hs_simulate_cube(
  rows = 50L,
  cols = 50L,
  wavelengths = seq(430, 910, by = 8),
  n_regions = 4L,
  sto2_range = c(0.3, 0.95),
  noise_sd = 0.01,
  seed = 42L
)
```

## Arguments

- rows:

  Integer. Spatial rows. Default `50`.

- cols:

  Integer. Spatial columns. Default `50`.

- wavelengths:

  Numeric vector. Wavelength grid in nm. Default:
  `seq(430, 910, by = 8)` matching Cubert Ultris X MR.

- n_regions:

  Integer. Number of distinct tissue regions. Default `4`.

- sto2_range:

  Numeric vector of length 2. Synthetic mixture fractions (0 to 1), not
  validated tissue oxygenation measurements. Default `c(0.3, 0.95)`.

- noise_sd:

  Numeric. Gaussian noise standard deviation. Default `0.01`.

- seed:

  Integer. Random seed for reproducibility. Default `42`.

## Value

An
[hsi_cube](https://cttir.github.io/hyperspectR/dev/reference/hsi_cube.md)
object with known synthetic `region_map`. Legacy `sto2_ground_truth`
metadata records simulator parameters only; the generated spectra are
not an independent reference for quantitative tissue validation.

## Examples

``` r
cube <- hs_simulate_cube(rows = 20, cols = 20)
dim(cube)
#> [1] 20 20 61
```
