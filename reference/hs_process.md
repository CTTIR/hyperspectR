# Execute a Processing Recipe

Execute a Processing Recipe

## Usage

``` r
hs_process(cube, recipe = hs_recipe(), learn = TRUE)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- recipe:

  A recipe from
  [`hs_recipe()`](https://cttir.github.io/hyperspectR/reference/hs_recipe.md).

- learn:

  Logical. Allow fitting an unspecified MSC reference on this cube. Set
  FALSE for validation or prediction data.

## Value

List containing the processed `cube` and reusable fitted `recipe`.

## Examples

``` r
recipe <- hs_recipe(list(list(method = "snv"), list(method = "msc")))
fitted <- hs_process(hs_example_cube(), recipe)
# Reuse the MSC reference learned above on held-out data
new_cube <- hs_simulate_cube(rows = 10, cols = 10, seed = 7)
held_out <- hs_process(new_cube, fitted$recipe, learn = FALSE)
dim(held_out$cube)
#> [1] 10 10 61
```
