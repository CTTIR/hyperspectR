# hyperspectR 0.3.0

## CRAN preparation

* Documentation uses British English (`Language: en-GB`); code identifiers,
  argument names and plot labels are unchanged.
* Added runnable examples to `hs_band_ratio()`, `hs_batch()`,
  `hs_group_summary()`, `hs_grouped_evaluate()`, `hs_predict()`,
  `hs_process()`, `hs_recipe()` and `hs_transform()`, and replaced
  commented-out examples of the TIFF, TIVITA and Cubert readers and writers
  with code that runs whenever the optional backend is installed.
* Expanded acronyms in the Description, declared `Language: en-US`, and
  documented the copyright of the bundled haemoglobin reference spectra in
  `inst/COPYRIGHTS`.
* Updated the maintainer e-mail address to raban.heller@uni-ulm.de.
* Includes all changes of the 0.2.0.9000 and 0.2.0.9001 development
  candidates listed below.

## New features

* `summary()` of a cube and the results of `hs_pca()`, `hs_mnf()`,
  `hs_umap()`, `hs_unmix_nnls()`, `hs_beer_lambert()`, `hs_sam()`,
  `hs_classify_svm()`, `hs_classify_rf()`, `hs_roi_rect()`,
  `hs_roi_polygon()` and `hs_recipe()` now print a compact overview instead
  of every score map, residual cube and fitted model. The objects themselves
  are unchanged lists.

## Bug fixes

* `hs_plot_clinical()` arranged four panels in one row by default, so panel
  titles overlapped on a default 7 inch device. The automatic layout
  (`ncol = NULL`) is now a near-square grid; pass `ncol = 4` for the former
  single row. `ncol` is validated.
* `as.data.frame()` (wide format), `summary()`, `hs_endmembers()` and
  `hs_write_tiff()` gave two bands the same name on wavelength grids finer
  than 1 nm (for example `band_500` twice). Such grids now use the full
  wavelength; names on whole-nm grids are unchanged.
* `hs_plot_spectra()` rejects a `pixels` value other than `"mean"`,
  `"random"` or a data frame with an informative error, and validates
  `show_sd`. `hs_plot_image()` validates `band` before using it, and
  `hs_plot_index()` rejects character and empty matrices and a `range` that
  is not two numbers or is infinite with an informative error. Logical
  matrices, reversed ranges and `NA` limits (taken from the data) keep
  working as before.
* The `hs_twi()` warning for missing bands now names the requested band
  ranges instead of a fixed 980 nm requirement that did not match the
  defaults.

## Performance

* Reading a single band no longer copies the whole cube. `hs_roi_stats()`
  reshapes the cube once instead of twice per band, and `hs_roi_polygon()`,
  `hs_sam()` and `hs_simulate_cube()` no longer loop over pixels. Results are
  identical to the previous implementations.

## Visualization

* `hs_plot_spectra()` labels the value axis with a readable processing mode
  ("Reflectance" instead of "reflectance") and draws selected pixels in the
  colour-blind-safe Okabe-Ito palette, with the legend in the order the pixels
  were supplied.
* Figures in the reference examples of the website keep their colours in dark
  mode, and all vignette figures carry alternative text.
* The explorer app renders its plots at 96 dpi, so titles, axis labels and
  legends are no longer smaller than the surrounding controls.

## Documentation

* `hs_smooth()`, `hs_snv()`, `hs_msc()`, `hs_mnf()`, `hs_umap()`, `hs_sam()`,
  `hs_unmix_nnls()` and `hs_continuum_removal()` cite their primary sources.
* The README lists the TIVITA reader and a GitHub installation command, the
  getting-started vignette cites the current version, and package URLs use
  the `CTTIR` organization spelling.

# hyperspectR 0.2.0.9001 (development candidate, not released)

* Retry UMAP's identified older-R PCA dependency failure with base SVD while
  preserving embedding settings and propagating unrelated errors. Compare
  canonical filesystem paths in the cross-platform TIVITA resume regression.
* Preserve cube quality metadata through band selection and spatial subsets;
  reject ambiguous fields and malformed coordinate vectors. Resampling retains
  source-grid quality flags separately from current-grid data.
* Validate ENVI metadata and missing values, preserve int32 input, reject lossy
  float32 overflow, and stage TIFF exports before replacing existing files.
  TIFF output explicitly uses float64. Cubert measurement indices must be whole.
* Preserve calibration invalidity, avoid integer subtraction overflow, stabilize
  spectral angles, and validate derivative orders before conversion.
* Check ordered preprocessing when reusing fitted models; validate batch output
  schemas and checksums before resuming. See MIGRATION.md for saved-model and
  batch-output changes.
* Align explorer image/spectra downloads with the displayed selection, support
  unknown wavelengths as band indices, and restore launcher state on exit.
* Preserve scientific coverage warnings, anchor wavelength colours to physical
  wavelengths, and correct image scaling for small and large finite ranges.
* Require viridisLite >= 0.4.0 for the documented palettes, repair standalone
  first-use instructions, and align citation metadata with the development state.

# hyperspectR 0.2.0.9000

* Standardize the named v5 package logo across README, documentation pages
  and available application headers, with matching light and dark artwork.


* Corrected cube dimensions, masks, wavelength/FWHM alignment, spatial plotting,
  TIFF/ENVI pixel order, truncated ENVI input and unsupported integer exports.
* SG smoothing now returns full-window centre bands consistently across explicit
  backends; derivatives use wavelength units. Calibration validates reference
  compatibility and bad-pixel repair uses immutable valid neighbours.
* Replaced generated haemoglobin fitting references with a pinned tabulated source.
  Beer-Lambert fitting requires an explicit domain and separates coefficients
  from concentrations requiring optical pathlength. Default StO2 is a research
  model fraction. The former ratio method errors; relative indices are unscaled.
* Added equality-constrained nonnegative unmixing with convergence diagnostics,
  optional residual storage and chunk equivalence. PCA/MNF respect masks and
  rank limits and expose reusable transforms.
* Repaired explorer initialization, stale results, paired uploads, TIFF metadata
  entry and complete archive downloads; added cancellable background computations.
* Added processing recipes, resumable manifest analysis, reusable classifier
  prediction, group-separated evaluation and group-level uncertainty summaries.
* Expanded exact-value regressions, browser and minimal-dependency validation,
  reference sensitivity reports, and performance measurements. Clinical claims
  remain outside the evidence supplied by synthetic tests. See MIGRATION.md for
  breaking changes.

# hyperspectR 0.1.0

## Initial release

### Data I/O
* `hs_read_envi()`: Read ENVI .hdr + binary hyperspectral cubes (BSQ/BIL/BIP).
* `hs_read_tiff()`: Read multi-channel TIFF files.
* `hs_read_cubert()`: Read Cubert .cu3s session files via Python bridge (optional).
* `hs_read_cube()`: Auto-detect format and dispatch to correct reader.
* `hs_write_envi()`, `hs_write_tiff()`, `hs_export_png()`: Export functions.

### Calibration
* `hs_calibrate()`: Full calibration workflow (dark + white reference).
* `hs_fix_bad_pixels()`: Statistical bad pixel detection and interpolation.

### Preprocessing
* `hs_smooth()`: Savitzky-Golay smoothing and derivatives.
* `hs_snv()`: Standard Normal Variate correction.
* `hs_msc()`: Multiplicative Scatter Correction.
* `hs_absorbance()`: Reflectance to absorbance conversion.
* `hs_continuum_removal()`, `hs_resample()`.

### Biomedical Indices
* `hs_sto2()`: Tissue oxygen saturation (500-815 nm).
* `hs_npi()`: Near-infrared perfusion index (655-910 nm).
* `hs_thi()`: Tissue haemoglobin index (530-825 nm).
* `hs_twi()`: Tissue water index (adapted for Cubert range).
* `hs_ndi()`: Generic normalized difference index.
* `hs_clinical_indices()`: Compute all available indices.

### Analysis
* `hs_pca()`, `hs_mnf()`: Dimensionality reduction.
* `hs_umap()`: UMAP spectral embedding (optional, requires uwot).
* `hs_sam()`: Spectral Angle Mapper classification.
* `hs_classify_svm()`, `hs_classify_rf()`: Machine learning classification.
* `hs_unmix_nnls()`: Linear spectral unmixing via NNLS.
* `hs_beer_lambert()`: Chromophore concentration fitting.

### Visualization
* `autoplot.hsi_cube()`: Plot RGB, single band, or spectra.
* `hs_plot_clinical()`: TIVITA-style clinical panel display.
* `hs_plot_index()`: Pseudocolor index map with clinical palette.
* `hs_plot_spectra()`: Spectral profile plots with mean +/- SD.
* `scale_color_wavelength()`, `theme_hsi()`.

### Shiny Application
* `hs_run_app()`: Interactive 6-tab HSI explorer.

### Data
* `hs_example_cube()`: Synthetic 30x30 tissue cube (430-910 nm, 61 bands).
* `hs_simulate_cube()`: Configurable synthetic cube generator.
* `hs_chromophore_data()`: Published HbO2/Hb extinction coefficients.
