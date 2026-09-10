# Implementation and verification record

Recorded 2026-09-10. Baseline: audited 0.1.0, commit
`d4fb6ab81176c0704797f31b4c7f1a9a7cb35d73`. Working version: **0.2.0.9000**.
This record describes the verification snapshot taken before committing and
pushing the implementation. Consult Git history and workflow runs for the current
publication state; the working version is a development version, not a release.

All **25 confirmed software findings** have corrections or explicit retirement
of unsupported behavior, with permanent regression assertions in the
[closure register](finding-closure.md). The complete roadmap also contains
release and empirical acceptance gates that remain outstanding.

## Delivered work and remaining gates

| Work | Implemented and locally verified | Remaining acceptance work |
|---|---|---|
| W00–W02 | Finding inventory; independent fixtures; shared cube/mask/domain/coordinate contracts; dimensionless ratios; retired ratio StO2 migration; unknown wavelengths; aligned band metadata | Independent code and optical-methods review |
| W03–W04 | Independent BSQ/BIL/BIP fixtures in both byte orders; header/extent/type checks; correct TIFF orientation; paired-output rollback; plot/cursor coordinates | Actual camera exports and hardware sessions; two-file replacement is not crash atomic |
| W05–W06 | Explicit SG backends, support and derivative units; reusable MSC; reference compatibility; saturation/denominator/clipping QC; immutable bad-pixel repair | Measured detector noise, saturation limits and calibration repeatability |
| W07–W08 | Pinned Hb table and notice; domain/pathlength semantics; response approximation; equality NNLS/KKT checks; rank/scale tests; reusable PCA/MNF/classifiers; reproducible UMAP | Instrument response and empirical identifiability review; synthetic chromophores remain excluded from default quantitative fitting |
| W09 | Startup modes, upload pairs, TIFF wavelengths, archive and spectra downloads, stale-result invalidation, cursor validation, background execution and cancellation | Full camera-size usability and memory evaluation; broader browser/platform matrix |
| W10 | Blocking semantic workflow defined; R 4.1 minimal and optional backend jobs; browser/sensitivity/performance artifacts; coverage floor raised from 0 to 90 | Remote CI has not run; Windows/macOS jobs and branch protection not verified; no exhaustive automated mutation campaign |
| W11 | Help, five vignettes, README and migration guide corrected; package and website built; test/check evidence archived | One SDK-generated temporary-log check note; independent review and maintainer release workflow |
| W12 | Manifest execution, learned recipes, input/environment/implementation fingerprints, per-recording failures, resumable RDS outputs; two fresh sessions verified | Environment restoration must be provisioned separately; fingerprints detect changes but do not install historical dependencies |
| W13 | Independent ideal recovery grid; 80 synthetic perturbation cases and 240 fits; prespecified holdout fractions, errors and failure counts | Measured sensor response/noise; scattering/baseline/regularization candidates; empirical interval coverage and independent final holdout |
| W14 | Training-only preprocessing; whole-group folds; reusable prediction; class metrics and prediction coverage; group bootstrap; ROI QC denominators | Study-specific grouping, nested tuning if needed, repeated-measures agreement model and statistical review |
| W15 | Chunk equivalence; optional residuals; cancellable workers; 16–64 pixel-side runtime and whole-process memory baseline | Actual acquisition dimensions, target hardware and memory budget; workers still copy input cubes |
| W16 | Acquisition manifest and protocol/reviewer handoff documented | Device/phantom/study data, independent references, assigned reviewers and prespecified empirical endpoints |

See [data contracts](data-contracts.md), [migration](../MIGRATION.md),
[analysis results](analysis-results.md) and [external validation](external-validation.md).
Roadmap effort ranges remain estimates; actual engineering effort was not tracked.

## Final local verification

| Check | Result | Evidence |
|---|---|---|
| Full suite, R 4.6.1 / Linux | 286 test blocks; 675 passing assertions; zero failures, errors, warnings or skips | [Test results](../validation/results/tests.csv) |
| Minimum R 4.1.0 / Linux container | 569 passing assertions; 37 optional cases skipped; zero failures, errors or warnings | [Minimum-version results](../validation/results/tests-r41-minimal.csv) |
| Tests-only coverage | 92.24548% of instrumented package R code; configured floor 90% | [Coverage](../validation/results/coverage.csv) |
| Strict package check | `--as-cran --no-manual`: zero errors, zero warnings, one note for SDK-created `VmbCPP.log`; examples, tests and rebuilt vignettes pass | [Check log](../validation/results/R-CMD-check.log) |
| Actual Chromium explorer | Default/supplied startup, background processing/reset, PCA, NDI, paired/incomplete uploads, TIFF wavelengths and archive download pass | [Browser result](../validation/results/browser.txt) |
| Website | Reference pages and five articles built locally | [Build log](../validation/results/pkgdown.log) |
| Fresh-process batch | First session `complete`; second session `resumed` | [Batch evidence](../validation/results/batch-sessions.txt) |
| Synthetic and performance | 240 fit configurations, zero failed pixel fits; chunk outputs agree | [Analysis report](analysis-results.md) |

Coverage measures `R/` functions. Explorer modules are tested through server and
real-browser workflows and are **not included in that percentage**. Device mocks
establish wrapper behavior only; these checks establish no real clinical,
phantom or camera-acquisition accuracy.

The [source checksums](../validation/results/source-checksums.csv) identify the
tested implementation and fixtures independently of the uncommitted Git state.
The [verification record](../validation/results/verification.txt) lists commands
and environmental limits. Remote CI, other operating systems and publication
are not represented as completed work.
