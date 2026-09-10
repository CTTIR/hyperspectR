# Implemented data contracts

The cube stores `data[row, column, band]`; pixel matrices advance rows within each column. Plotted coordinates are `x = column`, `y = row`. A spatial band is always a matrix, including one-row, one-column and one-pixel images.

Wavelengths are finite, unique positive nanometers and are sorted with data and FWHM. FWHM is a positive finite width in nanometers. Unknown wavelength calibration is marked in metadata and cannot be used for wavelength-dependent analysis. Empty dimensions and masks containing NA are invalid.

A cube mask denotes spatial validity. Methods additionally reject spectra with nonfinite required bands. Invalid pixels are omitted from estimation and restored as NA at the same coordinates. Per-band summaries count only finite, spatially valid samples. Learned references and transforms are saved for application without refitting.

Spectral domains are recorded explicitly. Numeric magnitude does not determine reflectance versus absorbance. Display stretching does not change computed indices. Relative band ratios are dimensionless; model-based oxygenation carries its model and validation status. Unknown path length permits concentration-path-length products, not absolute concentration.

Savitzky–Golay processing returns only full-window centers, with matching wavelength/FWHM metadata. Derivatives are per nanometer (or per squared nanometer). Uniform sampling is required. The built-in implementation is the deterministic default; optional implementations must produce the same common-support result.

Calibration requires identical spatial and spectral grids. Nonpositive/near-zero denominators are invalid; clamping is optional and recorded. Repairs exclude the original center, invalid neighbors and other detected defects, and read from an immutable original neighborhood.

I/O validates expected payload lengths before reshaping and rejects unsupported numeric types before writing. ENVI/TIFF interoperability is tested independently of package round trips. Exports carry masks through missing values and retain analysis provenance separately where a format cannot represent it.

Acceptance is tracked by the permanent tests and the audit inventory. These contracts do not establish clinical validation.
