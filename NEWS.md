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
* `hs_thi()`: Tissue hemoglobin index (530-825 nm).
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
