# Audit baseline for roadmap tracking

Audit date: **2026-09-10**. Package: **hyperspectR 0.1.0**. Source commit: `d4fb6ab81176c0704797f31b4c7f1a9a7cb35d73`.

The full source, bundled explorer, tests, package documentation and workflow configuration were reviewed. Local tests passed. `R CMD check --no-manual` completed with Status: OK and reported 498 passing expectations, no failures/warnings, and seven snapshot tests skipped under CRAN conditions. Targeted numerical and integration checks nevertheless reproduced the findings below.

This durable inventory records the audit outcome; it does not assert that the planned corrections have been implemented. All entries start **Open**. Close them through the [roadmap work packages](../ROADMAP.md), with links to permanent reproductions, tests and changes added during implementation.

P1: central silent result corruption or a broken primary workflow. P2: narrower correctness or integration defect. Some prerequisites contain P2 fixes because later work depends on their contracts.

| Finding | Priority | Source | Reproduced behavior | Primary work package |
|---|---|---|---|---|
| F01 | P1 | [indices.R](../R/indices.R) | An unchanged pixel's StO2 changes from 32.64% to 2.56% when an unrelated masked pixel changes; uniform cubes return 50% | W01 |
| F02 | P1 | [preprocess.R](../R/preprocess.R) | prospectr smoothing converts `1:9` to `3,4,5,6,7,3,4,5,6` under the original wavelength labels | W05 |
| F03 | P1 | [plot.R](../R/plot.R), [plot-clinical.R](../R/plot-clinical.R) | On an asymmetric image, plotted `(x=2,y=1)` has value 2 instead of the source value 3 | W04 |
| F04 | P1 | [io-read.R](../R/io-read.R), [io-write.R](../R/io-write.R) | terra readers and TIFF writer confuse row-major raster cells with column-major cube storage | W03 |
| F05 | P1 | [chromophores.R](../R/chromophores.R) | A noiseless 70% mixture generated from independent reference data is fitted as 53.18% | W07 |
| F06 | P1 | [unmix.R](../R/unmix.R) | Equivalent reflectance and preconverted absorbance return about 70% and 26% because of numeric-range domain inference | W07 |
| F07 | P1 | [unmix.R](../R/unmix.R), [roi.R](../R/roi.R), [reduce.R](../R/reduce.R) | Invalid pixels affect fitting/statistics; NA in a masked spectrum aborts whole-cube unmixing | W02, W08 |
| F08 | P1 | [io-read.R](../R/io-read.R) | Two binary values are recycled into a header-declared 12-value cube | W03 |
| F09 | P1 | [mod_analysis.R](../inst/shiny/hyperspectR/modules/mod_analysis.R) | R `%in%` inside `sprintf()` raises `too few arguments` while constructing the UI; it is also not valid JavaScript | W09 |
| F10 | P1 | [mod_viewer.R](../inst/shiny/hyperspectR/modules/mod_viewer.R) | A single uploaded ENVI header is treated as its own binary companion and reports a successful load | W09 |
| F11 | P1 | [app.R](../inst/shiny/hyperspectR/app.R) | The supplied initial cube is reapplied after processing because initialization observes cube changes | W09 |
| F12 | P1 | [mod_indices.R](../inst/shiny/hyperspectR/modules/mod_indices.R), [mod_analysis.R](../inst/shiny/hyperspectR/modules/mod_analysis.R) | An old StO2 map can acquire a THI label, or persist after a different cube is loaded | W09 |
| F13 | P2 | [preprocess.R](../R/preprocess.R) | Built-in first derivatives have the opposite sign from signal/prospectr | W05 |
| F14 | P2 | [unmix.R](../R/unmix.R) | `sum_to_one=TRUE` returns abundance sums of 1.333333 on an identity-endmember example | W08 |
| F15 | P2 | [calibrate.R](../R/calibrate.R) | Calibration silently pairs cube and reference bands on different wavelength grids | W06 |
| F16 | P2 | [hsi_cube-class.R](../R/hsi_cube-class.R) | Sorting wavelengths does not reorder FWHM | W02 |
| F17 | P2 | [io-read.R](../R/io-read.R) | Wavelengths in micrometers become nanometers while FWHM remains unconverted | W03 |
| F18 | P2 | [calibrate.R](../R/calibrate.R) | Mean bad-pixel replacement includes the defective center: 115.44 instead of neighbor mean 5 | W06 |
| F19 | P2 | [calibrate.R](../R/calibrate.R) | Zero-variance neighborhoods prevent detection of an isolated hot pixel | W06 |
| F20 | P2 | [plot.R](../R/plot.R) | Random-spectrum reshaping assigns wavelengths in the wrong order | W04 |
| F21 | P2 | [utils.R](../R/utils.R), [plot.R](../R/plot.R), [indices.R](../R/indices.R) | One-row/column cube slices become vectors, breaking plots and documented result shapes | W02, W04 |
| F22 | P2 | [reduce.R](../R/reduce.R) | Default PCA requests five score columns from a three-pixel cube and indexes out of bounds | W08 |
| F23 | P2 | [io-read.R](../R/io-read.R), [io-write.R](../R/io-write.R) | uint32/int64/uint64 pathways lose values through R integer conversion or unsupported unsigned reads | W03 |
| F24 | P2 | [mod_viewer.R](../inst/shiny/hyperspectR/modules/mod_viewer.R) | TIFF uploads cannot supply the required wavelengths and fail | W09 |
| F25 | P2 | [mod_export.R](../inst/shiny/hyperspectR/modules/mod_export.R) | ENVI download serves the header while leaving its binary companion on the server | W09 |

## Reproduction evidence to preserve in W00

Create source-independent fixtures for a 2×3 spatial image, linear/polynomial spectra, truncated ENVI payloads, an independently encoded uint32 payload, an identity-endmember constrained fit, masked outliers and masked NA spectra, reversed wavelength/FWHM metadata, uniform/noisy hot-pixel neighborhoods, and real Shiny upload temporary-file layouts.

For F05, the audit used the [Prahl hemoglobin table](https://omlc.org/spectra/hemoglobin/summary.html) to generate monochromatic noiseless reflectance at 500–600 nm in 2 nm steps, with total concentration-path-length product `1e-5` and HbO2/Hb fractions 0.7/0.3. The current fitter returned about 53.18%. This fixture establishes a model/reference inconsistency; it does not establish tissue-level clinical accuracy. Pin the source and preprocessing before using it as a regression fixture.

For F11, reproduce actual session-option inheritance explicitly. A default mock session does not automatically inherit the initial cube, which can conceal this bug. For F25, test the downloaded archive itself with an independent reader; the existence of a server-side binary is insufficient.

## Evidence boundaries

The audit ran on Linux with R 4.6.1 and installed optional dependencies. It did not establish native Windows/macOS behavior, real Cubert acquisition behavior, full-size memory limits, or clinical performance. Cubert success-path tests mocked SDK calls; TIVITA fixture tests passed. The full app failed to construct, so the other explorer findings were verified in isolated modules/server tests.

The package checks are useful but currently insufficient: many affected tests assert only class, dimensions or file existence. Temporary audit logs are not a long-term test dependency. This inventory and the planned permanent fixtures are the repository's baseline.
