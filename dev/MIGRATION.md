# Migrating from 0.1.0

The development version 0.2.0.9000 corrects spatial and numerical
behavior. Re-run analyses from source recordings; retain old outputs
with their original version. Do not relabel historical maps as corrected
measurements.

| Area | Previous behavior | Current behavior |
|----|----|----|
| StO2 | Default image-percentile band-ratio stretch labeled 0–100% | Default reference-based Hb fraction fit; explicit ratio method and retired band arguments error |
| Relative indices | NPI/THI/TWI stretched separately in each scene | Unscaled dimensionless ratios; use [`hs_band_ratio()`](https://cttir.github.io/hyperspectR/dev/reference/hs_band_ratio.md) for explicit bands |
| References | Generated Gaussian shapes presented as published spectra | Pinned HbO2/Hb table; other shapes require `source="synthetic"` |
| Domains | Numeric range guessed reflectance vs absorbance | Metadata or explicit `input` declares the domain |
| Concentrations | Coefficients labeled concentration without pathlength | `coefficients` in mol/L \* cm; `concentrations` only with `pathlength_cm` |
| SG | Optional packages could change support, orientation and values | Built-in default, explicit optional backends, full-window centers, derivatives per nm |
| Spatial output | Several plots/readers mixed row/column order | Data are `[row, column, band]`; plotted x=column, y=row |
| Masks | Inconsistently applied or applied after estimation | Applied before statistics/fitting; invalid output locations remain NA |
| ENVI | Short payloads recycled; wide integers lossy | Truncation errors; unsupported types 13/14/15 rejected before creating files |
| Equality unmixing | Soft penalty encouraged abundance sums near one | Nonnegative equality-constrained least squares with convergence diagnostics |
| PCA/MNF | Small/invalid inputs could fail unpredictably | Rank/sample checks; saved transforms apply to another cube |

## Explicit fitting

``` r

cube <- hs_example_cube()
fit <- hs_beer_lambert(cube, input = "reflectance")
fit$coefficients      # concentration-pathlength products
fit$concentrations   # NULL until an optical pathlength is supplied
fit$status           # "ok", "invalid", "nonconverged", or "no_hemoglobin_signal"

abs_cube <- hs_absorbance(cube)
fit_abs <- hs_beer_lambert(abs_cube)  # no second log transform
relative <- hs_band_ratio(cube, c(700, 815), c(500, 650))
```

Reflectance converted by `-log10()` is apparent absorbance. Correct
inversion of a linear reference mixture does not validate diffuse tissue
measurements. The default point response samples reference band centers;
`response="gaussian"` is an explicit approximation using FWHM. Neither
supplies measured instrument response curves.

## Smoothing support

A 9-band cube smoothed with a 5-band window returns the center bands
3–7, including their wavelengths and FWHM. Derivatives are divided by
wavelength spacing to the derivative order. Irregular grids require
explicit resampling within measured coverage.

## Reproducibility and prediction

Save the complete
[`hs_process()`](https://cttir.github.io/hyperspectR/dev/reference/hs_process.md)
result’s recipe. Apply it to validation data with `learn=FALSE`; an
unspecified MSC reference cannot be learned from held-out spectra.
[`hs_transform()`](https://cttir.github.io/hyperspectR/dev/reference/hs_transform.md)
applies saved PCA/MNF parameters, and
[`hs_predict()`](https://cttir.github.io/hyperspectR/dev/reference/hs_predict.md)
applies a saved classifier on the matching grid and domain.

[`hs_grouped_evaluate()`](https://cttir.github.io/hyperspectR/dev/reference/hs_grouped_evaluate.md)
accepts independent group identifiers and fixed model parameters. Its
primary accuracy is an equally weighted group mean, with a group
bootstrap interval conditional on the fitted out-of-fold predictions.
Pixel confusion counts are descriptive. Hyperparameter tuning and
independent final holdout evaluation require separate data splits.

Evaluation reports prediction coverage, class precision/recall/F1, macro
F1 and balanced accuracy. Accuracy is conditional on valid predictions;
recall includes withheld predictions as missed labels.
[`hs_roi_stats()`](https://cttir.github.io/hyperspectR/dev/reference/hs_roi_stats.md)
retains its existing summary columns and adds ROI pixel counts, valid
fractions and repaired-pixel counts for each band. Report these
denominators with the estimates.

## File and explorer changes

ENVI uploads require a matching header/binary pair. TIFF uploads require
wavelength entry. ENVI downloads are ZIP archives containing the pair
and a provenance RDS. Changing the cube or analysis parameters clears
stale results. ENVI trailing bytes are permitted after the declared
payload; short payloads are rejected. Integer exports reject
missing/noninteger/out-of-range values; use floating point when
preserving masked data.

Processing, indices and analysis run in cancellable background
processes. The explorer requires `callr` in addition to Shiny and bslib.
`hs_run_app(max_upload_mb = 256)` sets the upload limit in MiB; choose a
larger limit explicitly when the available memory supports it.
Background workers keep the interface responsive but do not eliminate
the memory cost of transferring a cube.

ENVI replacement stages both files and restores previous files if
publication fails. This provides rollback for handled failures; a
two-file replacement is not atomic across a process crash or power loss.
