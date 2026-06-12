# SVM Pixel Classification

Trains a Support Vector Machine on labeled pixels and classifies all
pixels. Requires the `e1071` package.

## Usage

``` r
hs_classify_svm(
  cube,
  training_labels,
  training_mask = NULL,
  kernel = "radial",
  cost = 10,
  gamma = NULL,
  ...
)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- training_labels:

  Character or factor matrix (same spatial dims as cube) with class
  labels. `NA` for unlabeled pixels.

- training_mask:

  Logical matrix. Alternative to NA in labels. Default `NULL`.

- kernel:

  Character. SVM kernel: `"radial"` (default), `"linear"`,
  `"polynomial"`.

- cost:

  Numeric. Cost parameter. Default `10`.

- gamma:

  Numeric. Gamma parameter. Default `NULL` (auto).

- ...:

  Additional arguments passed to
  [`e1071::svm()`](https://rdrr.io/pkg/e1071/man/svm.html).

## Value

A list with class `"hsi_classification"` containing `class_map`.

## Examples

``` r
# \donttest{
# Requires e1071 package
cube <- hs_example_cube()
labels <- matrix(NA_character_, 30, 30)
labels[1:10, 1:10] <- "class_a"
labels[20:30, 20:30] <- "class_b"
if (requireNamespace("e1071", quietly = TRUE)) {
  result <- hs_classify_svm(cube, labels)
}
# }
```
