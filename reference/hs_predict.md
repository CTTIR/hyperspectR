# Predict Classes in a New Cube Using a Fitted Classifier

Predict Classes in a New Cube Using a Fitted Classifier

## Usage

``` r
hs_predict(model, cube)
```

## Arguments

- model:

  Classification result from
  [`hs_classify_svm()`](https://cttir.github.io/hyperspectR/reference/hs_classify_svm.md)
  or
  [`hs_classify_rf()`](https://cttir.github.io/hyperspectR/reference/hs_classify_rf.md).

- cube:

  New
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  on the same wavelength grid and preprocessing domain.

## Value

Character matrix of predicted classes; invalid pixels are NA.

## Examples

``` r
# \donttest{
if (requireNamespace("e1071", quietly = TRUE)) {
  cube <- hs_example_cube()
  labels <- matrix(NA_character_, 30, 30)
  labels[1:10, 1:10] <- "class_a"
  labels[20:30, 20:30] <- "class_b"
  fit <- hs_classify_svm(cube, labels)
  new_cube <- hs_simulate_cube(rows = 10, cols = 10, seed = 7)
  table(hs_predict(fit, new_cube))
}
#> 
#> class_a class_b 
#>      49      51 
# }
```
