# Read a Cubert .cu3s Session File

Reads Cubert session files using the `cuvis.r` package, an R wrapper for
the Cubert CUVIS C SDK (see <https://github.com/r-heller/cuvis.r>).

## Usage

``` r
hs_read_cubert(
  path,
  index = 1L,
  mode = c("reflectance", "spectral_radiance", "dark_subtract", "raw"),
  settings_dir = NULL,
  verbose = TRUE
)
```

## Arguments

- path:

  Path to `.cu3s` Cubert session file.

- index:

  Integer. Measurement index within session (1-based). Default `1`.

- mode:

  Character. Processing mode: `"reflectance"` (default),
  `"spectral_radiance"`, `"dark_subtract"`, `"raw"`.

- settings_dir:

  Character or `NULL`. Path to the CUVIS settings directory (e.g.,
  `"C:/ProgramData/cuvis"`). If `NULL` (default), uses the
  `CUVIS_SETTINGS` environment variable or a temporary directory.

- verbose:

  Logical. Print progress messages. Default `TRUE`.

## Value

An [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
object. Reflectance data is in 0-1 range.

## Details

The processing context automatically loads dark/white references
embedded in the session file, so separate reference files are typically
not needed.

Cubert reflectance values are stored as uint16 scaled by 10000 (i.e.
10000 = 100% reflectance). This function automatically converts to
fractional reflectance (0-1) when `mode = "reflectance"`.

## Examples

``` r
# \donttest{
# Requires cuvis.r package and Cubert CUVIS SDK
# cube <- hs_read_cubert("path/to/session.cu3s")
# }
```
