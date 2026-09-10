# Run and Resume a Manifest of Hyperspectral Recordings

Each recording is isolated: failures are recorded without discarding
successful results. Resume requires matching input checksums, recipe,
analysis parameters, package implementation, R version and dependency
versions. Input and output paths are local; no network or hardware
acquisition is performed.

## Usage

``` r
hs_batch(
  manifest,
  recipe = hs_recipe(),
  out_dir,
  analysis = c("summary", "beer_lambert", "pca"),
  analysis_args = list(),
  resume = TRUE
)
```

## Arguments

- manifest:

  Data frame with distinct `id` and `path` columns. Optional
  `reader_args` list-column provides per-recording reader arguments.

- recipe:

  A recipe from
  [`hs_recipe()`](https://cttir.github.io/hyperspectR/dev/reference/hs_recipe.md).

- out_dir:

  Directory for per-recording RDS files and `run-summary.csv`.

- analysis:

  One of `"summary"`, `"beer_lambert"`, or `"pca"`.

- analysis_args:

  Named list of arguments for the analysis function.

- resume:

  Logical. Reuse results only if their fingerprint matches.

## Value

Data frame of recording identifiers, statuses, result files and errors.
