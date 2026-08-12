## R CMD check results

0 errors | 0 warnings | 1 note

* Note: "Suggests or Enhances not in mainstream repositories: cuvis.r, tivis.r".

  Both are optional format readers for hyperspectral camera data, used
  conditionally and guarded with `rlang::check_installed()`. They are published
  at <https://cttir.r-universe.dev>, which is declared in
  `Additional_repositories:`, so they resolve during checking.

  `cuvis.r` additionally wraps the proprietary Cubert CUVIS SDK, which cannot
  be redistributed. Every function that needs it is guarded, and the
  corresponding tests skip when it is unavailable, so the package checks
  cleanly without it.

## Test environments

* local: Ubuntu 26.04, R 4.6.1
* GitHub Actions: ubuntu-latest (release, devel, oldrel-1),
  macos-latest (release), windows-latest (release)

## Notes for the reviewer

The package builds and checks with no suggested packages installed
(`_R_CHECK_DEPENDS_ONLY_=true`); all optional functionality degrades with an
informative message rather than failing.

## This is a new submission.

## Downstream dependencies

There are currently no downstream dependencies for this package.
