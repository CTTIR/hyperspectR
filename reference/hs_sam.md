# Spectral Angle Mapper Classification

Classifies each pixel by computing the spectral angle to a set of
reference endmember spectra and assigning the class with the smallest
angle.

## Usage

``` r
hs_sam(cube, endmembers, threshold = 0.1)
```

## Arguments

- cube:

  An
  [hsi_cube](https://cttir.github.io/hyperspectR/reference/hsi_cube.md)
  object.

- endmembers:

  Named matrix or data.frame. Rows = endmembers, cols = bands. Row names
  become class labels.

- threshold:

  Numeric. Maximum angle (radians) for assignment. Pixels exceeding this
  are classified as `"unclassified"`. Default `0.1`.

## Value

A list with class `"hsi_classification"`:

- class_map:

  Character matrix (rows x cols) of class labels.

- angle_map:

  3D array of angles to each endmember.

- endmembers:

  The endmember matrix used.

## Examples

``` r
cube <- hs_example_cube()
# Define endmembers from specific pixels
em <- rbind(
  healthy = cube$data[5, 5, ],
  ischemic = cube$data[25, 5, ]
)
result <- hs_sam(cube, em, threshold = 0.5)
table(result$class_map)
#> 
#>  healthy ischemic 
#>      407      493 
```
