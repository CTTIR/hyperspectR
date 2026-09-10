# Package index

## Data I/O

Read and write hyperspectral data cubes

- [`hsi_cube()`](https://cttir.github.io/hyperspectR/dev/reference/hsi_cube.md)
  : Create an HSI Cube Object
- [`print(`*`<hsi_cube>`*`)`](https://cttir.github.io/hyperspectR/dev/reference/print.hsi_cube.md)
  : Print an hsi_cube Object
- [`summary(`*`<hsi_cube>`*`)`](https://cttir.github.io/hyperspectR/dev/reference/summary.hsi_cube.md)
  : Summarize an hsi_cube Object
- [`dim(`*`<hsi_cube>`*`)`](https://cttir.github.io/hyperspectR/dev/reference/dim.hsi_cube.md)
  : Get Dimensions of an hsi_cube
- [`` `[`( ``*`<hsi_cube>`*`)`](https://cttir.github.io/hyperspectR/dev/reference/sub-.hsi_cube.md)
  : Subset an hsi_cube Object
- [`as.data.frame(`*`<hsi_cube>`*`)`](https://cttir.github.io/hyperspectR/dev/reference/as.data.frame.hsi_cube.md)
  : Convert hsi_cube to Data Frame
- [`as_tibble(`*`<hsi_cube>`*`)`](https://cttir.github.io/hyperspectR/dev/reference/as_tibble.hsi_cube.md)
  : Convert hsi_cube to Tibble
- [`hs_read_cube()`](https://cttir.github.io/hyperspectR/dev/reference/hs_read_cube.md)
  : Read a Hyperspectral Data Cube from Any Supported Format
- [`hs_read_envi()`](https://cttir.github.io/hyperspectR/dev/reference/hs_read_envi.md)
  : Read an ENVI Hyperspectral Image File
- [`hs_read_tiff()`](https://cttir.github.io/hyperspectR/dev/reference/hs_read_tiff.md)
  : Read a Multi-Channel TIFF File
- [`hs_read_cubert()`](https://cttir.github.io/hyperspectR/dev/reference/hs_read_cubert.md)
  : Read a Cubert .cu3s Session File
- [`hs_read_tivita()`](https://cttir.github.io/hyperspectR/dev/reference/hs_read_tivita.md)
  : Read a TIVITA Suite Recording
- [`hs_write_envi()`](https://cttir.github.io/hyperspectR/dev/reference/hs_write_envi.md)
  : Write an HSI Cube to ENVI Format
- [`hs_write_tiff()`](https://cttir.github.io/hyperspectR/dev/reference/hs_write_tiff.md)
  : Write an HSI Cube to Multi-Band TIFF
- [`hs_export_png()`](https://cttir.github.io/hyperspectR/dev/reference/hs_export_png.md)
  : Export a Single-Band Image as PNG

## Calibration

Radiometric calibration and correction

- [`hs_calibrate()`](https://cttir.github.io/hyperspectR/dev/reference/hs_calibrate.md)
  : Calibrate Raw HSI Data to Reflectance
- [`hs_dark_correct()`](https://cttir.github.io/hyperspectR/dev/reference/hs_dark_correct.md)
  : Apply Dark Current Correction
- [`hs_white_normalize()`](https://cttir.github.io/hyperspectR/dev/reference/hs_white_normalize.md)
  : Apply White Reference Normalization
- [`hs_fix_bad_pixels()`](https://cttir.github.io/hyperspectR/dev/reference/hs_fix_bad_pixels.md)
  : Detect and Correct Bad Pixels

## Preprocessing

Spectral smoothing, normalization, and transformation

- [`hs_smooth()`](https://cttir.github.io/hyperspectR/dev/reference/hs_smooth.md)
  : Savitzky-Golay Spectral Smoothing
- [`hs_snv()`](https://cttir.github.io/hyperspectR/dev/reference/hs_snv.md)
  : Standard Normal Variate Correction
- [`hs_msc()`](https://cttir.github.io/hyperspectR/dev/reference/hs_msc.md)
  : Multiplicative Scatter Correction
- [`hs_derivative()`](https://cttir.github.io/hyperspectR/dev/reference/hs_derivative.md)
  : Spectral Derivative
- [`hs_absorbance()`](https://cttir.github.io/hyperspectR/dev/reference/hs_absorbance.md)
  : Convert Reflectance to Absorbance
- [`hs_continuum_removal()`](https://cttir.github.io/hyperspectR/dev/reference/hs_continuum_removal.md)
  : Continuum Removal
- [`hs_resample()`](https://cttir.github.io/hyperspectR/dev/reference/hs_resample.md)
  : Resample Spectra to New Wavelength Grid

## Biomedical Indices

Research hemoglobin fractions and dimensionless spectral ratios

- [`hs_sto2()`](https://cttir.github.io/hyperspectR/dev/reference/hs_sto2.md)
  : Estimate the Oxygenated Hemoglobin Fraction for Research
- [`hs_npi()`](https://cttir.github.io/hyperspectR/dev/reference/hs_npi.md)
  : Compute Near-Infrared Perfusion Index (NPI)
- [`hs_thi()`](https://cttir.github.io/hyperspectR/dev/reference/hs_thi.md)
  : Compute Tissue Hemoglobin Index (THI)
- [`hs_twi()`](https://cttir.github.io/hyperspectR/dev/reference/hs_twi.md)
  : Compute Tissue Water Index (TWI)
- [`hs_band_ratio()`](https://cttir.github.io/hyperspectR/dev/reference/hs_band_ratio.md)
  : Compute an Unscaled Spectral Band Ratio
- [`hs_ndi()`](https://cttir.github.io/hyperspectR/dev/reference/hs_ndi.md)
  : Compute Normalized Difference Index (General Purpose)
- [`hs_clinical_indices()`](https://cttir.github.io/hyperspectR/dev/reference/hs_clinical_indices.md)
  : Compute All Available Clinical Indices

## Analysis

Dimensionality reduction, classification, and unmixing

- [`hs_pca()`](https://cttir.github.io/hyperspectR/dev/reference/hs_pca.md)
  : PCA on Hyperspectral Cube
- [`hs_mnf()`](https://cttir.github.io/hyperspectR/dev/reference/hs_mnf.md)
  : Minimum Noise Fraction Transform
- [`hs_umap()`](https://cttir.github.io/hyperspectR/dev/reference/hs_umap.md)
  : UMAP Embedding of Spectral Data
- [`hs_sam()`](https://cttir.github.io/hyperspectR/dev/reference/hs_sam.md)
  : Spectral Angle Mapper Classification
- [`hs_classify_svm()`](https://cttir.github.io/hyperspectR/dev/reference/hs_classify_svm.md)
  : SVM Pixel Classification
- [`hs_classify_rf()`](https://cttir.github.io/hyperspectR/dev/reference/hs_classify_rf.md)
  : Random Forest Pixel Classification
- [`hs_unmix_nnls()`](https://cttir.github.io/hyperspectR/dev/reference/hs_unmix_nnls.md)
  : Linear Spectral Unmixing via NNLS
- [`hs_beer_lambert()`](https://cttir.github.io/hyperspectR/dev/reference/hs_beer_lambert.md)
  : Beer-Lambert Chromophore Fitting
- [`hs_endmembers()`](https://cttir.github.io/hyperspectR/dev/reference/hs_endmembers.md)
  : Extract Endmember Spectra from a Cube
- [`hs_transform()`](https://cttir.github.io/hyperspectR/dev/reference/hs_transform.md)
  : Apply a Fitted Spectral Transform to Another Cube
- [`hs_predict()`](https://cttir.github.io/hyperspectR/dev/reference/hs_predict.md)
  : Predict Classes in a New Cube Using a Fitted Classifier
- [`hs_grouped_evaluate()`](https://cttir.github.io/hyperspectR/dev/reference/hs_grouped_evaluate.md)
  : Evaluate Classification with Entire Groups Held Out

## ROI Analysis

Region-of-interest tools

- [`hs_roi_rect()`](https://cttir.github.io/hyperspectR/dev/reference/hs_roi_rect.md)
  : Define Rectangular ROI
- [`hs_roi_polygon()`](https://cttir.github.io/hyperspectR/dev/reference/hs_roi_polygon.md)
  : Define Polygon ROI
- [`hs_roi_stats()`](https://cttir.github.io/hyperspectR/dev/reference/hs_roi_stats.md)
  : Compute ROI Statistics
- [`hs_group_summary()`](https://cttir.github.io/hyperspectR/dev/reference/hs_group_summary.md)
  : Summarize Repeated ROI Measurements with Group-Level Uncertainty

## Visualization

Plotting and research display

- [`autoplot(`*`<hsi_cube>`*`)`](https://cttir.github.io/hyperspectR/dev/reference/autoplot.hsi_cube.md)
  : Plot an hsi_cube Object
- [`hs_plot_spectra()`](https://cttir.github.io/hyperspectR/dev/reference/hs_plot_spectra.md)
  : Plot Spectral Profiles
- [`hs_plot_image()`](https://cttir.github.io/hyperspectR/dev/reference/hs_plot_image.md)
  : Plot Single-Band Spatial Image
- [`hs_plot_rgb()`](https://cttir.github.io/hyperspectR/dev/reference/hs_plot_rgb.md)
  : Synthesize RGB Image from Spectral Cube
- [`hs_plot_clinical()`](https://cttir.github.io/hyperspectR/dev/reference/hs_plot_clinical.md)
  : Research HSI Panel Display
- [`hs_plot_index()`](https://cttir.github.io/hyperspectR/dev/reference/hs_plot_index.md)
  : Plot Index Map with Clinical Color Scale
- [`scale_color_wavelength()`](https://cttir.github.io/hyperspectR/dev/reference/scale_color_wavelength.md)
  [`scale_colour_wavelength()`](https://cttir.github.io/hyperspectR/dev/reference/scale_color_wavelength.md)
  : Wavelength-to-Color Scale for Spectral Plots
- [`theme_hsi()`](https://cttir.github.io/hyperspectR/dev/reference/theme_hsi.md)
  : Minimalist HSI Theme

## Reference Data

Chromophore spectra and simulation

- [`hs_chromophore_data()`](https://cttir.github.io/hyperspectR/dev/reference/hs_chromophore_data.md)
  : Get Chromophore Extinction Coefficient Spectra
- [`hs_simulate_cube()`](https://cttir.github.io/hyperspectR/dev/reference/hs_simulate_cube.md)
  : Generate a Synthetic HSI Cube for Testing and Examples
- [`hs_example_cube()`](https://cttir.github.io/hyperspectR/dev/reference/hs_example_cube.md)
  : Get Example HSI Cube
- [`hs_example_files()`](https://cttir.github.io/hyperspectR/dev/reference/hs_example_files.md)
  : Write Example ENVI Files to a Temporary Directory

## Reproducible Workflows

- [`hs_recipe()`](https://cttir.github.io/hyperspectR/dev/reference/hs_recipe.md)
  : Define a Reproducible Processing Recipe
- [`hs_process()`](https://cttir.github.io/hyperspectR/dev/reference/hs_process.md)
  : Execute a Processing Recipe
- [`hs_batch()`](https://cttir.github.io/hyperspectR/dev/reference/hs_batch.md)
  : Run and Resume a Manifest of Hyperspectral Recordings

## Shiny Application

Interactive HSI explorer

- [`hs_run_app()`](https://cttir.github.io/hyperspectR/dev/reference/hs_run_app.md)
  : Launch Interactive Hyperspectral Image Explorer
