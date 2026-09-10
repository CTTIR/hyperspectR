# External validation handoff

Status: awaiting data and independent review. No instrument-specific or clinical
accuracy claim is established by the software regression or synthetic reports.

## Required acquisition manifest

For every recording, record a stable recording ID, subject/phantom ID, session,
site, device and serial number, software/SDK version, acquisition time,
integration time, gain, illumination geometry, distance, wavelength grid,
response curves or FWHM, calibration files and their acquisition settings,
raw-file checksums, reference measurement, reference uncertainty, timing offset,
ROI definition, exclusion reason and intended split. Data remain outside the
package. De-identification and access arrangements belong to the dataset owner.

## Protocol to freeze before evaluating holdout recordings

1. Define the intended research endpoint and independent reference method.
2. Have the optical-methods reviewer approve units, pathlength/scattering
   assumptions, spectral response and calibration compatibility criteria.
3. Have the statistician define the independent sampling unit, minimum independent
   sample count, repeatability/agreement analysis and empirical acceptance bounds
   based on the intended use and reference uncertainty.
4. Freeze input checksums, recipes, wavelength support, model parameters, QC
   exclusions and the group/site holdout split. Record all changes after freezing.
5. Run the manifest through `hs_batch()`; report failed recordings and QC yield
   alongside results. Never silently drop failures from the denominator.
6. Evaluate held-out bias, RMSE, repeatability, agreement and interval coverage at
   the specified inference unit. Report device/site subgroups and failure causes.
7. Archive the frozen recipe, source version, environment, reference metadata,
   outputs and reviewer conclusions. Retain limits or reject the intended claim
   when the prespecified gates are not met.

## Device integration evidence still required

- Cubert: at least one real session per supported SDK/processing mode, comparison
  to an independent SDK export, correct orientation/wavelengths/scaling, and
  repeated-open lifecycle behavior. Existing mocks do not supply this evidence.
- TIVITA: real authorized recordings with acquisition metadata and independently
  exported pixel spectra. Vendor clinical indices are not implemented by the
  package's relative ratio functions.
- Phantom: repeated known reference conditions spanning the intended range,
  dark/white repeats, saturation and low-signal cases, and measured response
  information where available.

Owners for acquisition, optical review and statistical review remain unassigned.
No empirical thresholds or sample size have been invented to close this gate.
