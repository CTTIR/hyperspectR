# Analytical validation and research improvement plan

Status: **Engineering implementation and initial synthetic evaluation completed; empirical studies and independent review pending.** Current evidence is tracked in [implementation-status.md](implementation-status.md). Linked work packages: W01, W05–W08 and W12–W16 in the [development roadmap](../ROADMAP.md). Baseline findings are recorded in the [audit inventory](audit-baseline.md).

## 1. Questions the improved analysis must answer

1. Does the software preserve the measured spectrum and its spatial location through import, calibration, processing, analysis and export?
2. Do implemented models solve the mathematical problem they claim to solve, with consistent units, constraints and domains?
3. How sensitive are estimated quantities to calibration, noise, spectral sampling, detector response, scattering and model assumptions?
4. Do results generalize to independent recordings, subjects and instruments within a specified use case?
5. Can another analyst reproduce a result and determine why an individual spectrum was accepted, rejected or repaired?

A passing answer to one question does not answer the next. In particular, fitting a synthetic spectrum correctly establishes numerical consistency, not accuracy in tissue. This plan keeps these evidence levels separate.

## 2. Define quantities before choosing algorithms

| Output | Intended interpretation | Evidence required | Required metadata |
|---|---|---|---|
| Calibrated reflectance | Dimensionless signal relative to a characterized reference | Known-reference calibration, acquisition compatibility, detector QC | Dark/white identifiers, exposure, scaling, reference reflectance, clipping policy |
| Apparent absorbance | `-log10(R)` for supported positive reflectance | Explicit conversion and domain equivalence | Log base, reflectance floor, excluded pixels, source domain |
| Relative spectral index | Defined ratio/contrast with stated wavelength support | Exact formula and scene-invariance tests | Bands, formula, units/scale, validity mask |
| Model-based oxygenation estimate | HbO2 fraction under a specified forward model | Numerical recovery, sensitivity tests and stated assumptions | Model, reference data, wavelength support, fit validity and evidence status |
| Absolute chromophore concentration | Physical concentration under a calibrated measurement model | Compatible coefficient units and identifiable/calibrated path length plus empirical evaluation | Concentration convention, path length, model calibration and reference uncertainty |
| Class prediction | Membership learned from labeled data | Held-out evaluation at the relevant independent unit | Training/split identifiers, learned transformations, model parameters and validation scope |
| PCA/MNF/UMAP output | Exploratory representation or documented noise/variance decomposition | Mathematical and reproducibility checks | Fitted transform, scaling, retained rank, noise estimator and seed where relevant |

For the idealized transmission model, absorbance depends on extinction coefficient, concentration and path length; concentrations cannot be inferred by silently setting an unknown path length to one. Hemoglobin coefficient conventions also distinguish molar concentration from heme equivalents. Preserve the convention and conversions from the [Prahl source](https://omlc.org/spectra/hemoglobin/).

For diffuse-reflectance tissue measurements, treat a linear apparent-absorbance fit as a model to evaluate. Real reflectance depends on light transport and scattering as well as absorption; a relevant primary example fits reflectance using a transport model to estimate optical properties. [Bish et al., diffuse reflectance spectral imaging](https://pmc.ncbi.nlm.nih.gov/articles/PMC3920886/). Any simpler model needs its own demonstrated scope.

Do not import a cutoff from another device or clinical endpoint merely because an output has a similar name or a 0–100 scale. Proprietary vendor maps may support comparison, but are not automatically independent ground truth. Record what each reference actually measures and whether it samples the same region, time and tissue compartment.

## 3. Establish a versioned evidence collection

| Level | Data | Purpose | Release dependency |
|---|---|---|---|
| A: software fixtures | Hand-constructed small arrays, byte payloads, polynomials, masks, exact solver cases | Detect indexing, decoding, interpolation and algebra errors | Mandatory for M1/M2 |
| B: independent spectral calculations | Pinned published spectra and an independently constructed forward calculation | Validate reference ingestion, coefficient scaling and inverse solutions | Mandatory for quantitative research pathways in M2 |
| C: instrument-aware simulation | High-resolution spectra, sensor response, measurement noise and known perturbations | Quantify bias and robustness under controlled assumptions | M3 |
| D: physical references/phantoms | Independently characterized optical/oxygenation references and repeated acquisitions | Evaluate calibration, repeatability and model mismatch | Relevant M4 claims |
| E: independent study data | Recordings grouped by subject/session/site/device, with an appropriate comparison measurement | Estimate real-use agreement and generalization | Relevant M4 claims |

For each dataset or fixture, store a manifest containing identifier, source/version, access/redistribution status, checksum, dimensions, wavelengths, response/FWHM metadata, units/domain, instrument/software configuration, reference identifiers, grouping variables, exclusions and intended role. A source being accessible on the web does not establish redistribution rights; resolve that before embedding external tables or recordings in a package release.

Separate development, tuning and final evaluation datasets. Keep evaluation reference values unavailable to fitting code except through the evaluator. Preserve a fixed holdout once the acquisition protocol and sample definition are set. Repeated measurements and derived crops inherit their original subject/session grouping.

Small reproducible fixtures belong in the test collection. Full recordings belong in a documented external dataset location with checksums and a reproducible subset-generation script; package checks must work without downloading them.

## 4. Standard analysis recipe and provenance

The proposed batch workflow is:

```text
Input manifest and integrity checks
  → format decoding and canonical spatial/spectral coordinates
  → acquisition/domain compatibility checks
  → dark/white calibration when needed
  → detector and spectral QC with reason masks
  → explicit preprocessing recipe
  → analysis on valid supported spectra
  → fit diagnostics and uncertainty
  → ROI/recording summaries
  → results, QC report and complete run manifest
```

Retain the original decoded data and a recipe describing transformations. Display stretching is a terminal display operation and must not become analysis input. Image-wide reference estimation, such as MSC, must record which valid pixels formed the reference; reapplying a saved reference and re-estimating it are distinct operations.

Proposed run records should include:

- Input identifiers/checksums, package version and source revision, R/dependency versions, seed and backend selection.
- Calibration references and settings; source/output domains; wavelength units, FWHM/response source and selected support.
- Ordered processing operations and parameters, fitted transformation objects, excluded bands and pixel reason masks.
- Model formula, solver settings, reference-table version, learned parameters, constraint settings and convergence diagnostics.
- Result quantity and units, original image dimensions, cube/processing revision, creation time and validation scope.
- Counts of valid/rejected/repaired pixels by reason; warnings and failures, including recordings that did not complete.

Schema/API design should preserve useful existing matrix access while exposing this metadata consistently. Do not require analysts to recover the method from a filename. Batch failures must be recorded per acquisition, with completed acquisitions preserved and resumable execution validated against input/recipe identifiers.

## 5. Measurement and preprocessing quality control

| Stage | Required checks | Expected response |
|---|---|---|
| Import | Payload size, finite supported metadata, dimensions, orientation, endian/type, wavelength/FWHM units | Reject malformed input before analysis; retain unknown metadata explicitly |
| Calibration | Compatible exposures/modes, matched spectral/spatial grids, reference uncertainty, near-zero denominator, saturation | Reject incompatible calibration; mask invalid pixels/bands with reasons |
| Spectral support | Required band coverage, gaps, FWHM and response overlap | Report actual support; do not extrapolate a missing physiological band silently |
| Detector repair | Hot/dead pixels, boundaries, adjacent defects, valid-neighbor count | Repair only under the selected documented rule; preserve repair mask |
| Processing | Domain compatibility, wavelength spacing, edge support, missingness | Reject unsupported recipes or require explicit resampling; never silently fill arbitrary missing data with zero |
| Fitting | Finite inputs, usable rank, conditioning, convergence, residual structure, active constraints | Return result plus status, or NA with an interpretable reason |
| Summary | Valid-pixel counts, ROI geometry, acquisition/subject grouping | Report denominators and exclusions; do not count masked pixels as observations |

Thresholds for saturation, poor conditioning, fit residuals and acceptable missingness must be estimated on development data and locked before evaluation. Record retained-data yield as well as accuracy: a method that rejects difficult spectra should not appear successful by hiding those exclusions.

## 6. Numerical acceptance tests

The following are **engineering targets for specified fixtures**, not clinical accuracy requirements. Implemented assertions and measured results are recorded in the [finding register](finding-closure.md) and [analysis report](analysis-results.md); that evidence defines the tested scope rather than implying every possible fixture has been evaluated. Use well-conditioned fixtures in double precision unless stated otherwise. If a tolerance needs changing, document the numerical reason and change the fixture contract deliberately.

| Test family | Proposed acceptance condition |
|---|---|
| Spatial identity | Exact equality of pixel coordinates and integer-valued fixtures through conversion, subsetting and supported lossless I/O |
| Floating-point I/O | Float64 fixture round trips preserve stored values; float32 decoding matches independently rounded expected values within `1e-6 * max(1, abs(expected))` |
| Metadata | Exact band order and unit conversion within numeric parsing tolerance; every width/response follows its associated band |
| SG polynomial reproduction | Interior values satisfy `abs(error) <= 1e-10 + 1e-8 * abs(expected)` on scaled fixtures; declared edge behavior and wavelength support match the contract |
| Domain equivalence | Fitting a reflectance fixture and its explicitly converted absorbance agrees within the same scaled double tolerance |
| Unconstrained/nonnegative fit | Reconstruction and independent objective agree within `1e-8 * max(1, reference objective)`; scaled optimality residual within `1e-7` |
| Sum-to-one fit | Nonnegativity within `1e-10`, abundance sums within `1e-8` of one, and independent constrained objective/optimality checks pass |
| Ideal oxygenation recovery | At least 0, 10, 30, 50, 70, 90 and 100% fixtures over several nonzero total coefficients recover within `1e-4` percentage points under the exactly matched ideal model |
| Zero-signal and rank deficiency | Explicit invalid/indeterminate status; no arbitrary saturation or asserted identifiable concentrations |
| Mask invariance | Replacing invalid pixels with outliers/NA leaves valid-only statistics and outputs unchanged; invalid outputs retain shape and reason codes |
| Backend/chunk equivalence | Common-support outputs meet the applicable fixture tolerance for each backend/chunk size; documented stochastic methods use fixed seeds and appropriately defined reproducibility checks |

Compare coefficients only when they are identifiable. For a rank-deficient system, compare reconstructed spectra, objective value and constraint optimality; different coefficient vectors can represent the same solution. For PCA, compare subspaces/reconstruction when sign or repeated-eigenvalue rotation makes direct loading equality inappropriate. For MNF, separately validate noise estimation and the resulting transform.

Do not use the same numerical implementation to create both expected and actual values. Appropriate independent checks include closed-form polynomial values, hand-encoded bytes, exhaustive active-set solutions for very small constrained examples, trusted external solvers, and pinned reference tables. An optional backend is a useful cross-check but is not the sole definition of correctness.

## 7. Model experiments and ablations

### 7.1 Forward-model hierarchy

Start with exact monochromatic linear absorbance cases to isolate solver/reference errors. Next construct high-resolution reflectance and pass it through an instrument response before fitting. For a normalized band response `S_b`, the simulated band measures the weighted reflectance average `integral(S_b * R) / integral(S_b)`; logging this average generally differs from averaging log reflectance. Test this explicitly rather than assuming an averaged extinction spectrum is an exact inverse model for broad bands.

Use measured response curves where available. If only center wavelength and FWHM exist, label an assumed Gaussian response as an approximation and vary it in sensitivity experiments. Reject unsupported coverage in production recipes; studying an approximation does not authorize silent extrapolation.

Then evaluate the simplest viable nuisance model for scattering/baseline/path length on independent data. Treat additional nuisance bases and regularization as candidate models, because they can compete with chromophore coefficients and change identifiability. Do not add a flexible baseline merely to reduce residuals.

### 7.2 Prespecified comparisons

| Experiment | Alternatives / perturbations | Primary readout |
|---|---|---|
| Spectral references | Corrected pinned references; current Gaussian implementation retained only as a historical benchmark | Bias in coefficient/oxygenation recovery and residual shape |
| Preprocessing | None; SG settings within physical wavelength widths; explicitly resampled grid | Bias, noise variance, spectral feature distortion and retained support |
| Fitting bands | Default visible region versus supported wider/narrower ranges | Identifiability, sensitivity and error by saturation/total absorber |
| Sensor response | Monochromatic ideal; measured response; approximated response; shifted centers/widths | Bias from finite bandwidth and metadata errors |
| Calibration | Reference perturbations, exposure mismatch, low denominators, specular/high-reflectance regions | Error, rejection yield and failure flags |
| Noise and missingness | Noise estimated from repeated data; correlated/heteroscedastic variants; dropped bands and invalid pixels | Bias, uncertainty calibration and graceful failure |
| Model complexity | Hb-only baseline; justified nuisance terms; additional chromophores with compatible units | Held-out error, conditioning and coefficient stability |
| Solver constraints | NNLS; true fully constrained abundances where the mixture interpretation warrants it | Objective, constraint satisfaction and coefficient bias |
| Instrument/site shift | Within-device held-out recordings; separately held-out devices/sites | Generalization gap and supported scope |

Choose perturbation ranges from observed acquisitions or clearly stated stress scenarios. Predeclare seeds and the experiment grid. Use paired cases when comparing pipelines, so differences are not caused by a different simulated scene/noise draw. Log all candidate recipes and avoid selecting a winner on the final holdout.

### 7.3 Model selection and reporting

Select model settings on development data using predefined criteria for error, stability and valid-data yield. Prefer the simplest candidate meeting those criteria. Freeze preprocessing, band support, reference versions, solver tolerances and rejection rules before final evaluation.

Report bias, MAE/RMSE, residual-versus-wavelength plots, error over the reference range, fit failure fraction, active constraints, sensitivity to calibration and representative maps with QC masks. A small residual by itself does not establish correct concentrations or physiological interpretation. Document failure cases and any range where a model is not identifiable.

## 8. Uncertainty and ROI inference

Keep these sources of uncertainty distinct: detector/repeatability variation, dark/white reference uncertainty, wavelength/response uncertainty, model mismatch, and between-subject/acquisition variation. A solver covariance or bootstrap over wavelengths cannot represent all of them automatically.

Use repeated acquisitions to characterize measurement noise. Evaluate parameter sensitivity through justified perturbations of references and sensor metadata. Where a bootstrap is used, choose the resampling unit to match the question and any correlation structure; do not treat adjacent pixels or spectral bands as independent replicates without evidence. Validate interval coverage in controlled simulations before attaching confidence claims to real estimates.

ROI outputs should include pixel count, valid fraction, repaired fraction, summary estimates, spread, acquisition identity and uncertainty method. Freeze ROI definition rules before viewing outcomes, and evaluate sensitivity to reasonable boundary changes. Keep displayed spatial variability separate from uncertainty of a population or recording-level mean.

For comparison measurements with repeated observations per individual, use an agreement analysis that accounts for that structure. Report systematic bias, limits of agreement and their uncertainty at the intended unit; correlation alone is insufficient to establish interchangeability. [Bland and Altman, agreement with multiple observations per individual](https://www-users.york.ac.uk/~mb55/meas/bland2007.pdf).

If no valid independent reference exists for a quantity, report repeatability, sensitivity or association, and label them accordingly. Do not convert a vendor-map agreement result into an accuracy claim against tissue ground truth.

## 9. Classification evaluation

Retain SAM as a simple reference and evaluate the existing SVM/random-forest methods before adding new model families. Introduce reusable fitted models and transformations so training and prediction are separate operations.

Split by subject at minimum for new-subject generalization; keep all crops, pixels and repeat recordings from a subject on the same side. Add site/device/session holdouts when these are the intended deployment shifts. When subjects cross sites/devices, define a split policy that avoids subject overlap as well as testing the intended shift. Random pixel splits within one image answer a much narrower interpolation question.

Fit scaling, reference spectra, PCA, feature selection, imbalance handling and hyperparameters only in training folds. Reuse learned transformations on validation/test data. This avoids information from evaluation data influencing preprocessing; the principle is described in the [official leakage guidance](https://scikit-learn.org/stable/common_pitfalls.html) and [grouped cross-validation documentation](https://scikit-learn.org/stable/modules/cross_validation.html).

Use nested grouped validation for tuning when sample size permits; otherwise specify a separate grouped development/validation split and acknowledge its uncertainty. Record the number of independent subjects and positive cases in each fold, not only pixel counts. Derive sample requirements from endpoint precision and class frequency rather than selecting an arbitrary number of images.

Report confusion matrices, per-class recall/precision, macro F1, balanced accuracy, and probability calibration where probabilistic predictions are used. Use appropriate AUROC/PR measures when warranted by the task. Include subject/recording-level results and clustered intervals. Define any rejection or decision threshold on development data, lock it, and report the fraction of predictions withheld.

## 10. Reproducible execution and performance

W12 should first provide a minimal manifest-driven runner over existing validated functions. Add workflow orchestration only if resumability, dependency tracking or operational complexity warrants it. Save each recording's results and diagnostics without requiring the interactive explorer.

W15 benchmarks should include small CI fixtures, a medium development cube and actual supported full-size acquisitions. Record dimensions, data precision, algorithm parameters, thread count, CPU/RAM, elapsed time and peak memory. Set latency/memory targets only after measuring these cases on named reference hardware.

Prioritize shared matrix conversion, avoiding redundant array copies, blockwise pixel calculations and optional residual storage. Do not change precision merely to reduce memory without quantifying its numerical effects. Fit global quantities such as PCA/MSC references consistently: independently fitting each chunk is a different analysis, not equivalent chunking. Use halos where spatial operations need neighbors, and verify boundary behavior.

If long-running app work becomes asynchronous, associate tasks with immutable cube/recipe revisions; cancellation or completion of an old task must not replace current results. Cache only when keys include input and processing identity. Test repeat runs, memory bounds, cancellation, changed input and partial failures.

## 11. Evaluation gates and protocol template

| Gate | Required evidence | If unsuccessful |
|---|---|---|
| G1: implementation correctness | All mandatory spatial/spectral/domain/mask/solver fixtures pass | Repair the implementation; empirical evaluation cannot compensate |
| G2: ideal-model recovery | Independent reference calculations meet predefined numerical tolerances | Resolve reference, units, solver or identifiability errors |
| G3: realistic sensitivity | Prespecified perturbation experiments quantify error and rejection yield | Restrict support or revise the candidate model, then repeat development evaluation |
| G4: independent empirical agreement | Frozen protocol and holdout meet previously selected application-specific limits | Report the failure and restrict claims; do not retune and call the same holdout independent |
| G5: reproducibility | Fresh-session recreation of inputs, recipes, outputs and summary statistics | Complete provenance/environment support before publishing results |

G1/G2 tolerances are engineering decisions. **G4 bias, agreement and failure-rate limits are intentionally unset:** the intended use, appropriate reference, reference uncertainty and acceptable decision error must be specified first. No universal oxygenation error threshold is assumed by this roadmap.

Before W16 begins final evaluation, fill in and freeze:

| Protocol field | Required decision |
|---|---|
| Intended use | Quantity or prediction, population/material, acquisition conditions and supported device(s) |
| Independent unit | Subject/phantom/recording and repeat-measure structure |
| Reference | What is measured, how uncertainty is characterized, spatial/temporal matching and independence from the fitted method |
| Sampling | Inclusion/exclusion rules, calibration/QC criteria and planned range of reference values |
| Sample size | Precision/power calculation appropriate to the endpoint and independent units; assumptions recorded |
| Data partition | Fixed development/validation/holdout identifiers and safeguards against group overlap |
| Frozen recipe | Exact preprocessing, reference tables, response model, bands, solver/classifier and rejection rules |
| Primary endpoint | Prespecified accuracy/agreement or classification measure and acceptable limit with uncertainty |
| Secondary endpoints | Repeatability, calibration, subgroup/device differences, valid-data yield and runtime |
| Missing/failed data | Treatment of rejected fits, missing references, exclusions and incomplete recordings |
| Analysis plan | Comparisons, intervals, repeated-measures handling and sensitivity analyses |
| Review | Named method/statistical reviewers, deviations, evidence location and final supported scope |

Deliver an evaluation bundle containing this protocol, dataset manifests, pinned references, analysis recipes, environment information, executable evaluation code, machine-readable metrics, QC/error plots, failure cases and the final interpretation. Record negative results as well as successful examples.

## 12. Explorer testing as an analysis safeguard

Pair numerical library tests with module/server tests and browser-driven scenarios. Browser testing is needed to exercise actual UI construction and interaction; server-only tests do not execute client-side conditions. The [shinytest2 documentation](https://rstudio.github.io/shinytest2/articles/shinytest2.html) provides the proposed browser-test approach.

The mandatory path is: supply or upload a cube → inspect a known pixel → calibrate/process → compute → change method → replace cube → reset → export → independently reopen the result. Assert values, source identity, method labels, masks and dimensions, not only screenshots. Include invalid uploads and missing required wavelengths. Repeat with a supplied initial cube and the example-cube startup.

For comparison with scripted analysis, save the explorer's recipe and run it outside the app. The results must agree within the applicable numerical tolerance. This provides an end-to-end check that the interface has not changed the scientific meaning of the computation.
