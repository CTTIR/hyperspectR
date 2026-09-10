# Reproducible validation

Install the development package before running these scripts. Set
`HYPERSPECTR_VALIDATION_OUTPUT` to select an output directory (default
`validation/results`). Preserve the package source revision and environment
record with each result bundle.

```sh
R CMD INSTALL .
NOT_CRAN=true Rscript validation/minimal-dependencies.R
NOT_CRAN=true Rscript validation/browser.R
Rscript validation/model-sensitivity.R
/usr/bin/time -v Rscript validation/performance.R
# Use a new output directory for a new source/environment version.
HYPERSPECTR_VALIDATION_OUTPUT=/tmp/hyperspectr-batch-evidence Rscript validation/batch-reproduce.R
HYPERSPECTR_VALIDATION_OUTPUT=/tmp/hyperspectr-batch-evidence Rscript validation/batch-reproduce.R
```

The browser test requires shinytest2 and a Chromium executable. Configure
`CHROMOTE_CHROME` if the browser is not on PATH. Use the browser's supported local
launch configuration for the execution environment; the test does not change
system browser or sandbox settings.

- `minimal-dependencies.R` runs with an isolated library containing only hard
  dependencies and testthat. Optional integration tests skip explicitly.
- `browser.R` starts the installed explorer in another process and drives an
  actual browser. It tests source-to-display interactions and downloads.
- `model-sensitivity.R` constructs reflectance independently from the reference
  table, without using the package simulator. It evaluates prespecified fractions,
  additive reflectance offsets, multiplicative gain errors, noise, response width,
  fitting ranges and response approximations. Prespecified holdout fractions are
  reported separately. Model parameters are not tuned on these results.
- `performance.R` verifies chunk equivalence and measures elapsed time and object
  sizes. `/usr/bin/time -v` measures whole-process peak RSS, including runtime
  overhead. The small benchmark dimensions are explicit and do not establish
  performance for megapixel camera acquisitions.
- `batch-reproduce.R` is invoked in two fresh R sessions. It expects completion
  followed by resume for the same input, recipe, implementation and environment.
  Use an empty output directory when any of these change; a changed fingerprint
  correctly requires recomputation.

The recorded minimum-version run used `rocker/r-ver:4.1.0`, an installed package
and a library of R 4.1-compatible hard dependencies plus testthat. The script
then isolates that library and explicitly checks that Shiny and the optional
numerical backends are absent. The source was copied from a read-only mount into
a temporary writable directory for testthat. This is distinct from running a
current R interpreter with optional packages hidden.

See [the verification record](results/verification.txt), [source checksums](results/source-checksums.csv)
and [analysis results](../planning/analysis-results.md) for the recorded run.

Algebraic recovery and model sensitivity are different evidence types. The
included reference table validates coefficient use; synthetic model recovery
validates implementation. Neither demonstrates empirical tissue accuracy.
See `planning/analysis-validation.md` for the study protocol and
`planning/external-validation.md` for outstanding acquisition/review requirements.
