# Execute a Processing Recipe

Execute a Processing Recipe

## Usage

``` r
hs_process(cube, recipe = hs_recipe(), learn = TRUE)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/dev/reference/hsi_cube.md)
  object.

- recipe:

  A recipe from
  [`hs_recipe()`](https://cttir.github.io/hyperspectR/dev/reference/hs_recipe.md).

- learn:

  Logical. Allow fitting an unspecified MSC reference on this cube. Set
  FALSE for validation or prediction data.

## Value

List containing the processed `cube` and reusable fitted `recipe`.
