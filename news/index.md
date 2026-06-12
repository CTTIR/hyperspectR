# Changelog

## hyperspectR 0.1.0

### Initial release

#### Data I/O

- [`hs_read_envi()`](https://cttir.github.io/hyperspectR/reference/hs_read_envi.md):
  Read ENVI .hdr + binary hyperspectral cubes (BSQ/BIL/BIP).
- [`hs_read_tiff()`](https://cttir.github.io/hyperspectR/reference/hs_read_tiff.md):
  Read multi-channel TIFF files.
- [`hs_read_cubert()`](https://cttir.github.io/hyperspectR/reference/hs_read_cubert.md):
  Read Cubert .cu3s session files via Python bridge (optional).
- [`hs_read_cube()`](https://cttir.github.io/hyperspectR/reference/hs_read_cube.md):
  Auto-detect format and dispatch to correct reader.
- [`hs_write_envi()`](https://cttir.github.io/hyperspectR/reference/hs_write_envi.md),
  [`hs_write_tiff()`](https://cttir.github.io/hyperspectR/reference/hs_write_tiff.md),
  [`hs_export_png()`](https://cttir.github.io/hyperspectR/reference/hs_export_png.md):
  Export functions.

#### Calibration

- [`hs_calibrate()`](https://cttir.github.io/hyperspectR/reference/hs_calibrate.md):
  Full calibration workflow (dark + white reference).
- [`hs_fix_bad_pixels()`](https://cttir.github.io/hyperspectR/reference/hs_fix_bad_pixels.md):
  Statistical bad pixel detection and interpolation.

#### Preprocessing

- [`hs_smooth()`](https://cttir.github.io/hyperspectR/reference/hs_smooth.md):
  Savitzky-Golay smoothing and derivatives.
- [`hs_snv()`](https://cttir.github.io/hyperspectR/reference/hs_snv.md):
  Standard Normal Variate correction.
- [`hs_msc()`](https://cttir.github.io/hyperspectR/reference/hs_msc.md):
  Multiplicative Scatter Correction.
- [`hs_absorbance()`](https://cttir.github.io/hyperspectR/reference/hs_absorbance.md):
  Reflectance to absorbance conversion.
- [`hs_continuum_removal()`](https://cttir.github.io/hyperspectR/reference/hs_continuum_removal.md),
  [`hs_resample()`](https://cttir.github.io/hyperspectR/reference/hs_resample.md).

#### Biomedical Indices

- [`hs_sto2()`](https://cttir.github.io/hyperspectR/reference/hs_sto2.md):
  Tissue oxygen saturation (500-815 nm).
- [`hs_npi()`](https://cttir.github.io/hyperspectR/reference/hs_npi.md):
  Near-infrared perfusion index (655-910 nm).
- [`hs_thi()`](https://cttir.github.io/hyperspectR/reference/hs_thi.md):
  Tissue hemoglobin index (530-825 nm).
- [`hs_twi()`](https://cttir.github.io/hyperspectR/reference/hs_twi.md):
  Tissue water index (adapted for Cubert range).
- [`hs_ndi()`](https://cttir.github.io/hyperspectR/reference/hs_ndi.md):
  Generic normalized difference index.
- [`hs_clinical_indices()`](https://cttir.github.io/hyperspectR/reference/hs_clinical_indices.md):
  Compute all available indices.

#### Analysis

- [`hs_pca()`](https://cttir.github.io/hyperspectR/reference/hs_pca.md),
  [`hs_mnf()`](https://cttir.github.io/hyperspectR/reference/hs_mnf.md):
  Dimensionality reduction.
- [`hs_umap()`](https://cttir.github.io/hyperspectR/reference/hs_umap.md):
  UMAP spectral embedding (optional, requires uwot).
- [`hs_sam()`](https://cttir.github.io/hyperspectR/reference/hs_sam.md):
  Spectral Angle Mapper classification.
- [`hs_classify_svm()`](https://cttir.github.io/hyperspectR/reference/hs_classify_svm.md),
  [`hs_classify_rf()`](https://cttir.github.io/hyperspectR/reference/hs_classify_rf.md):
  Machine learning classification.
- [`hs_unmix_nnls()`](https://cttir.github.io/hyperspectR/reference/hs_unmix_nnls.md):
  Linear spectral unmixing via NNLS.
- [`hs_beer_lambert()`](https://cttir.github.io/hyperspectR/reference/hs_beer_lambert.md):
  Chromophore concentration fitting.

#### Visualization

- [`autoplot.hsi_cube()`](https://cttir.github.io/hyperspectR/reference/autoplot.hsi_cube.md):
  Plot RGB, single band, or spectra.
- [`hs_plot_clinical()`](https://cttir.github.io/hyperspectR/reference/hs_plot_clinical.md):
  TIVITA-style clinical panel display.
- [`hs_plot_index()`](https://cttir.github.io/hyperspectR/reference/hs_plot_index.md):
  Pseudocolor index map with clinical palette.
- [`hs_plot_spectra()`](https://cttir.github.io/hyperspectR/reference/hs_plot_spectra.md):
  Spectral profile plots with mean +/- SD.
- [`scale_color_wavelength()`](https://cttir.github.io/hyperspectR/reference/scale_color_wavelength.md),
  [`theme_hsi()`](https://cttir.github.io/hyperspectR/reference/theme_hsi.md).

#### Shiny Application

- [`hs_run_app()`](https://cttir.github.io/hyperspectR/reference/hs_run_app.md):
  Interactive 6-tab HSI explorer.

#### Data

- [`hs_example_cube()`](https://cttir.github.io/hyperspectR/reference/hs_example_cube.md):
  Synthetic 30x30 tissue cube (430-910 nm, 61 bands).
- [`hs_simulate_cube()`](https://cttir.github.io/hyperspectR/reference/hs_simulate_cube.md):
  Configurable synthetic cube generator.
- [`hs_chromophore_data()`](https://cttir.github.io/hyperspectR/reference/hs_chromophore_data.md):
  Published HbO2/Hb extinction coefficients.
