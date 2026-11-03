# Run and Resume a Manifest of Hyperspectral Recordings

Each recording is isolated: failures are recorded without discarding
successful results. Resume requires matching input checksums, recipe,
analysis parameters, package implementation, R version and dependency
versions, plus an intact versioned output record. Legacy or damaged
records are recomputed. The output checksum detects accidental changes;
it does not authenticate an untrusted file. Failed recomputation leaves
the previous result file unchanged. Input and output paths are local; no
network or hardware acquisition is performed. TIVITA input identity
includes the consumed metadata log and the names/paths of reference
images returned by the reader. Reference image bytes are not read by the
analysis and are not checksummed. For Cubert sessions, file bytes and
explicit reader arguments are tracked, but external vendor SDK settings
and assets are not enumerated. Use `resume = FALSE` when that external
configuration may have changed.

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

  Logical. Reuse intact results only if their fingerprint matches.

## Value

Data frame of recording identifiers, statuses, result files and errors.
