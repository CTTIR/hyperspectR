# Evaluate Classification with Entire Groups Held Out

Splits by subject (or another independent sampling unit), fits
preprocessing only on training spectra, and predicts held-out groups.
Hyperparameters must be chosen before evaluation; this function does not
tune on validation data. Group accuracy is conditional on valid
predictions; prediction coverage and unevaluated group counts are
reported separately. Per-class recall treats withheld predictions as
missed labels. Accuracy intervals resample whole groups, not pixels.
These intervals summarize out-of-fold predictions and do not include
uncertainty from refitting models.

## Usage

``` r
hs_grouped_evaluate(
  spectra,
  wavelengths,
  labels,
  groups,
  folds = NULL,
  n_folds = 5L,
  method = c("svm", "rf"),
  recipe = hs_recipe(),
  model_args = list(),
  seed = 1L,
  bootstrap = 1000L
)
```

## Arguments

- spectra:

  Numeric matrix, observations in rows and wavelengths in columns.

- wavelengths:

  Numeric band centers in nm.

- labels:

  Character class labels for each observation.

- groups:

  Independent group identifiers, usually subject identifiers.

- folds:

  Optional named integer vector mapping every group to a fold.

- n_folds:

  Number of folds when no mapping is supplied. Default 5.

- method:

  Classifier, `"svm"` or `"rf"`.

- recipe:

  Processing recipe. Learned references are fitted inside each fold.

- model_args:

  Named list of fixed classifier parameters.

- seed:

  Random seed for fold assignment and model fitting.

- bootstrap:

  Number of group bootstrap samples for the accuracy interval.

## Value

List of out-of-fold predictions, group metrics, confusion matrix,
group-mean accuracy and interval, fold assignments and fitted recipes.

## Examples

``` r
# \donttest{
if (requireNamespace("e1071", quietly = TRUE)) {
  spectra <- rbind(c(1, 2, 1), c(2, 1, 2), c(1.1, 2, 1), c(2.1, 1, 2),
                   c(1, 2.1, 1), c(2, 1.1, 2), c(1, 2, 1.1), c(2, 1, 2.1))
  result <- hs_grouped_evaluate(
    spectra, wavelengths = c(500, 600, 700),
    labels = rep(c("a", "b"), 4), groups = rep(letters[1:4], each = 2),
    n_folds = 2, model_args = list(kernel = "linear"), bootstrap = 50
  )
  result$accuracy
  result$group_metrics
}
#>   group n n_predicted accuracy
#> 1     a 2           2        1
#> 2     b 2           2        1
#> 3     c 2           2        1
#> 4     d 2           2        1
# }
```
