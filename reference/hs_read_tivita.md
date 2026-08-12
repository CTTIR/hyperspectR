# Read a TIVITA Suite Recording

Reads a Diaspective Vision TIVITA `*_SpecCube.dat` recording through the
tivis.r package and returns it as an
[hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md).

## Usage

``` r
hs_read_tivita(path, bands = NULL, verbose = TRUE)
```

## Arguments

- path:

  Path to a `*_SpecCube.dat` file.

- bands:

  Optional integer vector of band indices to read. `NULL` (default)
  reads all bands.

- verbose:

  Logical. Print progress messages. Default `TRUE`.

## Value

An [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
object. Values are calibrated reflectance, normally within `[0, 1]` but
not clamped, since specular regions legitimately exceed it.

## Details

Unlike the Cubert reader, this needs no vendor SDK: the TIVITA container
is a plain binary format and tivis.r is pure R.

Acquisition metadata from the Suite's `*_meta.log` is attached to the
cube when present, along with the paths of the parameter images the
Suite exported beside the recording (RGB rendering, oxygenation, NIR
perfusion, THI, TWI). Those are the Suite's own results and are useful
as a reference when checking independently computed indices such as
[`hs_sto2()`](https://cttir.github.io/hyperspectR/reference/hs_sto2.md).

## See also

[`hs_read_cube()`](https://cttir.github.io/hyperspectR/reference/hs_read_cube.md)
for extension-based dispatch,
[`hs_read_cubert()`](https://cttir.github.io/hyperspectR/reference/hs_read_cubert.md)
for Cubert session files.

## Examples

``` r
# \donttest{
# Requires the tivis.r package
# cube <- hs_read_tivita("2019_11_25_13_29_24_SpecCube.dat")
# }
```
