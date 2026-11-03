# Maintenance audit and roadmap — 2 November 2026

Status: local development-candidate criteria satisfied on 3 November 2026. Baseline
`09170d23b7c4191e550e2f8eb78868e8d2c3a087`, version 0.2.0.9000.
The original clean checkout and all 275 tracked files are preserved; work occurs
on an isolated maintenance branch. Existing scientific claims, reference tables,
authorship and historical verification records remain traceable.

## Purpose and acceptance criteria

Provide reproducible hyperspectral research from file import through calibration,
preprocessing, analysis, inspection and export. Spatial coordinates, masks,
wavelengths, physical units and learned transforms must remain consistent across
these boundaries. Results are research outputs; synthetic regression and model
recovery do not establish camera-specific or clinical accuracy.

1. **Essential integrity repairs.** Reproduce malformed cube/reader/model/cache
   behavior independently of existing tests. Correct confirmed defects at their
   source and retain valid ordinary workflows. Require asymmetric spatial,
   mask, metadata, failure-isolation and saved-result regression checks.
2. **Dependable explorer.** Make the selected view, downloaded figure and spectra
   describe the same valid observations. Support explicitly unknown wavelengths
   as band indices, retain selection/palette semantics, and release temporary
   state after completion, errors or cancellation. Exercise actual uploads,
   processing, invalidation and downloads in a browser.
3. **First use and documentation.** Verify required-only installation and an
   explicit optional-app path. Align current package version, research semantics,
   citation and distribution claims. Preserve both existing human authors and
   source-data notices. Rebuild and inspect the site, articles and manual.
4. **Release evidence.** Full and minimal archive checks, meaningful numerical
   and integration regressions, existing 90% coverage floor, workflow checks,
   independent review, actual first use and source-package inspection. Record
   hosted baseline evidence separately from this candidate's local results.

The milestones are ordered by data integrity and user impact. Each requires a
baseline-failing example, a focused correction, regression validation and review
of affected integrations before closure. Additional algorithms, clinical
thresholds, new devices and a broad architecture rewrite remain outside scope.
Real acquisitions and independently measured reference outcomes remain external
gates described in `external-validation.md`.

## Established baseline

- Initial direct suite: 660 passing assertions, no failures/errors/warnings and
  four explicit skips because optional nnls was absent. An evidence CSV writer
  initially failed on a list column after tests completed; the saved result was
  recovered without rerunning or changing package assertions.
- Initial full check: one error for missing optional prospectr/nnls, no warnings,
  one incoming note. Both optional packages were then installed into an isolated
  evidence library before the complete baseline. This was an environment issue.
- Complete frozen baseline after installing prospectr 0.2.11 and nnls 1.6:
  **675 passing assertions, zero failures/errors/warnings/skips**; full package
  check **0 errors, 0 warnings, 1 incoming note**. The unchanged baseline still
  fails the independent new integrity probes.
- The public baseline has successful R checks, semantic regressions, coverage,
  lint and website workflows. No GitHub release was observed. Candidate hosted
  CI has not run.
- The DOI resolver and public Zenodo record for `10.5281/zenodo.21889940` return
  HTTP 404. The current CRAN package page also returns 404. These observations
  do not establish the absence of a private draft/reservation or past archives.
- The pinned MNE v1.10.2 reference artifact matches its recorded SHA256, and the
  shipped MNE notice is byte-identical to that release's official notice. The
  original Prahl table documents decadic molar-extinction units. Reference data
  have not been altered.
- GitHub reports Dependabot alerts disabled (HTTP 403); no clean advisory status
  is inferred and repository administration settings are unchanged.

## Confirmed findings repaired

| Evidence/location | User impact | Priority and action |
| --- | --- | --- |
| Explorer PNG download reads the raw middle band rather than current masked display (`mod_export.R`). | Masked observations reappear and exports can disagree with the selected band, RGB mode and palette. | Essential: share validated view state with export and compare actual downloaded content. |
| Random-spectrum CSV uses summary statistics (`mod_spectra.R`). | Download does not reproduce the visible sample. | Essential: freeze one valid pixel sample shared by plot and CSV; retain spatial coordinates. |
| Unknown-wavelength cube uses wavelength-based viewer calls and reports synthetic indices in nm (`mod_viewer.R`). | Supported cubes fail to display and labels misstate calibration. | Everyday use: explicit band-index mode and accurate units. |
| Wavelength color scale trains on the local data range (`plot-utils.R`). | The same physical wavelength receives different colors across plots. | Everyday use: fixed physical scale limits with verified colors. |
| App launcher leaves supplied cube in process-wide Shiny options (`R/app.R`). | Large or sensitive data remain referenced after the app exits. | Everyday use: restore prior option on every exit path. |
| README and citation metadata describe 0.1.0 and unsupported clinical uses. | New users may install or interpret the development package incorrectly. | Release preparation: current version, reproducible commands and evidence-bounded research wording. |

Independent reader and scientific probes subsequently confirmed additional
integrity repairs for the first milestone:

- Calibration with default clamping turns infinite input into valid 0/1 output;
  integer reference subtraction can overflow before division. Preserve invalidity
  before clamping and perform supported integer-input arithmetic in double form.
- Saved models accept different continuum methods and different processing
  orders. Require an ordered preprocessing contract and a clear migration path
  for saved models that lack sufficient compatibility information.
- Altered saved batch results retain the input fingerprint and are resumed.
  Validate a versioned result schema/checksum as well as the input identity;
  failed recomputation must preserve previous files. This is accidental-integrity
  protection, not an authenticity or hostile-file guarantee.
- SAM loses scale invariance at extreme finite magnitudes; fractional derivative
  orders are silently truncated. Use bounded normalization and strict validation.
- Band reordering can misalign quality arrays; malformed field names and factor
  coordinates can be accepted; named dimensions reject valid masks. Enforce the
  declared cube contract and preserve alignment and caller data.
- Polygon winding changes boundary inclusion. ENVI metadata truncates fractional
  codes/offsets, int32 minimum decodes as missing, and float32 export can silently
  turn finite data into infinities. Preserve exact supported values or reject
  unsupported conversion before modifying destination files.
- PNG auto-scaling fails for tiny finite ranges, and clinical-style panels hide
  coverage warnings. Correct display normalization and retain scientific warnings.

Details, baseline-failing probes, independent expectations and exact commands
are retained in the sibling local evidence directory. Other suspected defects
are not counted as confirmed until reproduced.

## Completed verification

Environment: R 4.6.1 on Apple silicon macOS 27.0.1. These observations do not
replace Linux/Windows or older-R qualification.

- Direct final suite: **977 passing assertions**, no failures, errors, warnings
  or skips. Independent reader/science/app reviews found no remaining material
  defect within the synthetic software scope.
- Final source archive, full and required-dependencies-only `R CMD check
  --as-cran`: **0 errors, 0 warnings, 1 incoming note each**. Full tests: 972
  passes and five explicit CRAN skips; minimal tests: 774 passes and 51 optional
  dependency/CRAN skips. The incoming note concerns a new development-version
  submission and optional packages hosted outside mainstream repositories.
- Tests-only coverage: **93.09%**, above the unchanged 90% floor. Actionlint
  passes. The existing report-only house lint reports 100 findings versus 81
  at baseline; added findings are test calls to the supported `verbose` API
  and deliberately failing mock functions. No production lint regression or
  suppressed check was introduced. A compatibility migration of that API is
  deferred rather than renamed solely to satisfy a style rule.
- Fresh empty user/site libraries: installed remotes, required dependencies and
  the package from source; the README RGB, fitted-fraction, panel and reusable
  recipe examples run successfully. The app remains an explicit optional path.
  A separate fresh session renders the panel successfully with the declared
  minimum viridisLite 0.4.0.
- Actual browser: 24 functional checks plus seven bounded closeout checks pass,
  including uploads, selected-view PNG pixels, ENVI readback/provenance,
  random/clicked spectra CSVs, worker cancellation and source replacement.
  Eleven observed plot-alt variants accurately describe their current modes.
- Website: 82 HTML pages, 3,578 local references and seven browser journeys
  checked; 85 desktop/mobile page views have no local broken images, overflow,
  script errors or failed requests. The inherited search and color switch are
  restored. Scientific images bypass pkgdown's dark-mode inversion: all 900 RGB
  cell centers match the original rendered image in both modes. Transparent
  margins correctly follow the surrounding page background.
- All five articles and the 50-page reference manual build. Representative
  manual pages covering installation, ENVI, the explorer and TIFF were visually
  inspected. CFF validates against the official 1.2.0 schema; both human authors
  and pinned reference-data bytes/notices are preserved. Zenodo metadata is
  prepared, not submitted or externally accepted.

The first candidate package check exposed a linked-worktree `.git` file in the
archive. Explicit exclusions now remove it and incidental `Rplots.pdf`; the
final full/minimal checks confirm the repair. Failed baseline probes and harness
attempts remain in local evidence. Pixel checks compare scientific cell content,
not incidental browser layout or transparent page margins.

## First use and remaining gates

Use R >= 4.1.0 and a working R source-development toolchain for compiled
dependencies. From this source checkout, run the two installation commands in
the README, followed by its Quick Start. For the explorer, install `shiny`
(>= 1.6.0), `bslib` and `callr`, then run
`hyperspectR::hs_run_app(hyperspectR::hs_example_cube())` interactively.

The integrity, explorer and local release-evidence milestones are complete.
Saved pre-contract models require refitting/retraining; migration details are in
`MIGRATION.md`. Cache checksums protect accidental integrity, not authenticity.
CUVIS SDK/settings and real acquisition calibration remain external inputs;
neither a synthetic regression nor a successful import certifies a camera.
Large recordings still require sufficient memory for cubes and background
copies. Native device, independently labeled study and clinical qualification,
and a formal CRAN/Zenodo release remain outside this development candidate.
The shared pkgdown first-focus search race remains a dependency follow-up.

Source merge/push to `main` is now authorized as a separate fleet task. Local
validation does not establish the subsequent hosted CI or deployed site result;
publication receipts are recorded separately. No release or submission was made.

## Hosted compatibility follow-up, 2026-11-03

Hosted R-CMD-check run `41608256212` for published commit `4430874` exposed two
platform cases absent from the local macOS qualification. On Windows, a TIVITA
resume test compared equivalent image paths with different separators. The test
now resolves both paths through the filesystem before comparing them; it still
checks reference membership, resumption after image-byte changes and invalidation
after image removal. Normalizing both also respects macOS temporary-directory
symlinks.

On Ubuntu oldrel-3, three UMAP tests reached an irlba PCA failure with the exact
message `LENGTH or similar applied to NULL object` from `oknum(scale)`. UMAP now
retries only that identified error with uwot's base-SVD PCA method and emits a
classed informational message. Ordinary calls retain the original argument set;
older uwot versions without that PCA option keep their original failure rather
than receiving an unsupported argument. The input matrix, neighborhood and embedding
settings, default metric and thread settings remain unchanged. Other dependency
errors retain their original condition. See the upstream
[uwot parameter documentation](https://jlmelville.github.io/uwot/reference/umap.html).

The regression exercises actual uwot with the identified irlba failure injected,
both with and without PCA pre-reduction. It checks finite results, repeated-seed
identity, caller random-state restoration, retained settings and unrelated-error
propagation. A restricted historical uwot signature also exercises ordinary
success and unchanged-error behavior. All 125 affected assertions and all 1,037 full-suite assertions pass
locally without warnings or skips. Local source packaging also succeeds; the
package-check and exact-commit hosted results are recorded in the follow-up
receipt. Local execution does not establish Windows or oldrel hosted acceptance.

The existing report-only house-lint policy remains unchanged: 104 findings
versus the prior 100. The four additions are deliberate upstream-condition
signaling in three regression fixtures and rethrowing the original error condition;
no checks or supported interfaces were disabled to reduce that count.
