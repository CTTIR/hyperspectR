## Submission

This is a new submission.

## Test environments

* local: macOS (aarch64), R 4.6.1 — `R CMD check --as-cran --no-manual`
  (the PDF manual was built locally with TinyTeX (TeX Live 2026) via
  `R CMD Rd2pdf` without errors; the check run itself used `--no-manual`)
* GitHub Actions (r-lib/actions v2, `--as-cran`):
  * macOS-latest (release)
  * windows-latest (release)
  * ubuntu-latest (devel, release, oldrel-1)

## R CMD check results

0 errors | 0 warnings | 1 note

* checking CRAN incoming feasibility ... NOTE
  Maintainer: 'R. Heller <raban.heller@uni-ulm.de>'

  New submission

  Suggests or Enhances not in mainstream repositories:
    cuvis.r, tivis.r
  Availability using Additional_repositories specification:
    cuvis.r   yes   https://cttir.r-universe.dev
    tivis.r   yes   https://cttir.r-universe.dev

  This is the first submission of this package. `cuvis.r` and `tivis.r` are
  optional readers for two camera file formats. They are published at
  <https://cttir.r-universe.dev>, which is declared in
  `Additional_repositories`, and are used only conditionally
  (`rlang::check_installed()` in the reader functions, `requireNamespace()`
  in examples and `skip_if_not_installed()` in tests). `cuvis.r` additionally
  wraps the proprietary Cubert CUVIS SDK; every code path that needs it is
  guarded, so the package checks cleanly without it.

## Notes for the reviewer

* The package builds and checks with no suggested packages installed
  (`_R_CHECK_FORCE_SUGGESTS_=false`); optional functionality degrades with an
  informative message rather than failing.
* `inst/extdata/prahl-hemoglobin-v1.csv` is a third-party hemoglobin
  extinction table redistributed under the BSD 3-Clause license of
  MNE-Python; its copyright is recorded in the `Copyright` field and in
  `inst/COPYRIGHTS`.

## Downstream dependencies

There are currently no downstream dependencies on CRAN.
