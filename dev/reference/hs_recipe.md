# Define a Reproducible Processing Recipe

Recipes contain ordered operations and their explicit parameters. A
fitted MSC reference is stored in the returned recipe, allowing reuse on
held-out data.

## Usage

``` r
hs_recipe(steps = list(), seed = 1L)
```

## Arguments

- steps:

  List of steps, each with `method` and an optional `args` list.
  Methods: `smooth`, `snv`, `msc`, `derivative`, `absorbance`,
  `resample`, `continuum_removal`, `calibrate`, `dark_correct`,
  `white_normalize`, `fix_bad_pixels`.

- seed:

  Integer random seed recorded with the recipe.

## Value

An `hsi_recipe` object.
