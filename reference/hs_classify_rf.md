# Random Forest Pixel Classification

Trains a random forest on labeled pixels and classifies all pixels.
Requires the `ranger` package.

## Usage

``` r
hs_classify_rf(
  cube,
  training_labels,
  training_mask = NULL,
  num.trees = 500L,
  mtry = NULL,
  ...
)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- training_labels:

  Character or factor matrix with class labels. `NA` for unlabeled
  pixels.

- training_mask:

  Logical matrix. Default `NULL`.

- num.trees:

  Integer. Number of trees. Default `500`.

- mtry:

  Integer. Variables per split. Default `NULL` (auto).

- ...:

  Additional arguments passed to
  [`ranger::ranger()`](http://imbs-hl.github.io/ranger/reference/ranger.md).

## Value

A list with class `"hsi_classification"` containing `class_map`.

## Examples

``` r
# \donttest{
# Requires ranger package
cube <- hs_example_cube()
labels <- matrix(NA_character_, 30, 30)
labels[1:10, 1:10] <- "class_a"
labels[20:30, 20:30] <- "class_b"
if (requireNamespace("ranger", quietly = TRUE)) {
  result <- hs_classify_rf(cube, labels)
}
# }
```
