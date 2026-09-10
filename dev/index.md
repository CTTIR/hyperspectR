# hyperspectR

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.21889940.svg)](https://doi.org/10.5281/zenodo.21889940)

**hyperspectR** provides a complete R pipeline for biomedical
hyperspectral imaging analysis – from camera data to reproducible
research maps.

## Installation

``` r

# install.packages("remotes")
remotes::install_github("cttir/hyperspectR")
```

## Quick Start

``` r

library(hyperspectR)

# Load example cube (synthetic 30x30 tissue scene, 61 bands, 430-910 nm)
cube <- hs_example_cube()
print(cube)

# Plot RGB composite
autoplot(cube, type = "rgb")

# Compute tissue oxygenation
sto2 <- hs_sto2(cube)
hs_plot_index(sto2, title = "Fitted Hb fraction (%)", palette = "sto2")

# Clinical 5-panel display (TIVITA-style)
hs_plot_clinical(cube)

# Launch interactive explorer
hs_run_app(cube)
```

## Features

- **I/O**: Read ENVI, multi-channel TIFF, and Cubert .cu3s files
- **Calibration**: Dark correction, white reference normalization, bad
  pixel repair
- **Preprocessing**: Savitzky-Golay smoothing, SNV, MSC, spectral
  derivatives
- **Research indices**: fitted hemoglobin fraction, dimensionless band
  ratios and normalized differences
- **Analysis**: PCA, MNF, SAM classification, SVM/RF pixel
  classification, Beer-Lambert unmixing
- **Visualization**: ggplot2-based spectral plots, research panel
  displays, interactive Shiny app
- **Clinical focus**: Intraoperative oxygenation mapping, compartment
  syndrome assessment

## Citation

To cite hyperspectR in publications, please use:

``` bibtex
@Manual{,
  title = {hyperspectR: Hyperspectral Imaging Analysis for Biomedical Applications},
  author = {R. Heller and V. Forstmeier},
  year = {2026},
  note = {R package version 0.1.0},
  url = {https://github.com/cttir/hyperspectR},
}
```

## Use of LLM tools

Portions of this package were prepared with assistance from large
language model tooling for narrowly defined, non-authorial tasks:
copyediting, prose smoothing, Markdown/LaTeX formatting, scaffolding of
boilerplate files (CI configs, build scripts), code refactoring. The
tools used were [Chat
AI](https://kisski.gwdg.de/leistungen/2-02-llm-service/), the LLM
service of KISSKI (GWDG), and a self-hosted **Mistral Small (24B,
Apache-2.0)** run locally via [Ollama](https://ollama.com/) and the
`ollamar` R package — local inference only, with no data sent to third
parties for the self-hosted model.

## License

MIT

## Corrected research semantics

The development version changes numerical behavior from 0.1.0.
[`hs_sto2()`](https://cttir.github.io/hyperspectR/dev/reference/hs_sto2.md)
now fits tabulated hemoglobin reference spectra; `method = "ratio"`
raises a migration error.
[`hs_band_ratio()`](https://cttir.github.io/hyperspectR/dev/reference/hs_band_ratio.md)
and the legacy NPI/THI/TWI functions return dimensionless, unscaled
ratios. They are not vendor clinical indices or calibrated physiological
measurements. The simulator is a software demonstration, not validation
data.

[`hs_beer_lambert()`](https://cttir.github.io/hyperspectR/dev/reference/hs_beer_lambert.md)
requires a declared reflectance/absorbance domain. It returns
`coefficients` in mol/L \* cm; `concentrations` is available only with a
supplied `pathlength_cm`. Sensor response and tissue scattering require
separate evaluation.

See the repository’s [migration
details](https://github.com/cttir/hyperspectR/blob/main/MIGRATION.md),
[implementation
record](https://github.com/cttir/hyperspectR/blob/main/planning/implementation-status.md),
and [analysis
protocol](https://github.com/cttir/hyperspectR/blob/main/planning/analysis-validation.md).

## Reproducible processing

``` r

recipe <- hs_recipe(list(list(method = "smooth", args = list(window = 5))))
processed <- hs_process(hs_example_cube(), recipe)
# Use the saved recipe; MSC references, if present, are fitted only once.
new_data <- hs_process(hs_example_cube(), processed$recipe, learn = FALSE)
```

[`hs_batch()`](https://cttir.github.io/hyperspectR/dev/reference/hs_batch.md)
saves input checksums, recipes, results, implementation fingerprints and
environment versions, isolates failed recordings, and resumes matching
work.
[`hs_grouped_evaluate()`](https://cttir.github.io/hyperspectR/dev/reference/hs_grouped_evaluate.md)
keeps subjects together across validation splits;
[`hs_group_summary()`](https://cttir.github.io/hyperspectR/dev/reference/hs_group_summary.md)
reports uncertainty using independent groups rather than pixels.

Device readers are covered by software fixtures and SDK mocks. Real
camera, phantom and independently labeled study validation remain
separate evidence gates.
