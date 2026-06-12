# Create an HSI Cube Object

Constructs a hyperspectral imaging data cube as an S3 object. The cube
stores a 3D array of spectral data (rows x columns x bands) along with
wavelength metadata, spatial mask, and additional metadata.

## Usage

``` r
hsi_cube(data, wavelengths, fwhm = NULL, metadata = list(), mask = NULL)
```

## Arguments

- data:

  Numeric 3D array with dimensions (rows, cols, bands).

- wavelengths:

  Numeric vector of band center wavelengths in nanometers. Length must
  match `dim(data)[3]`.

- fwhm:

  Numeric vector of full-width-at-half-maximum values per band in nm.
  Default `NULL` (unknown). If scalar, recycled to all bands.

- metadata:

  Named list of metadata (camera model, integration time, processing
  mode, acquisition timestamp, etc.). Default empty list.

- mask:

  Logical matrix matching spatial dimensions. `TRUE` = valid pixel.
  Default `NULL` (all pixels valid).

## Value

An `hsi_cube` S3 object (a named list with class `"hsi_cube"`).

## Examples

``` r
# Create a small synthetic cube
data <- array(runif(10 * 10 * 5), dim = c(10, 10, 5))
wavelengths <- c(500, 550, 600, 650, 700)
cube <- hsi_cube(data, wavelengths)
print(cube)
#> 
#> ── hsi_cube ────────────────────────────────────────────────────────────────────
#> Dimensions: 10 rows x 10 cols x 5 bands
#> Wavelengths: 500-700 nm (5 bands)
#> Data range: [0.005, 0.9999]
```
