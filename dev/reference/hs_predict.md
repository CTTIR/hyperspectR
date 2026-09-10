# Predict Classes in a New Cube Using a Fitted Classifier

Predict Classes in a New Cube Using a Fitted Classifier

## Usage

``` r
hs_predict(model, cube)
```

## Arguments

- model:

  Classification result from
  [`hs_classify_svm()`](https://cttir.github.io/hyperspectR/dev/reference/hs_classify_svm.md)
  or
  [`hs_classify_rf()`](https://cttir.github.io/hyperspectR/dev/reference/hs_classify_rf.md).

- cube:

  New
  [hsi_cube](https://cttir.github.io/hyperspectR/dev/reference/hsi_cube.md)
  on the same wavelength grid and preprocessing domain.

## Value

Character matrix of predicted classes; invalid pixels are NA.
