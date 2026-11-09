# Summarize Repeated ROI Measurements with Group-Level Uncertainty

First averages observations within each independent group, then computes
an equally weighted mean across groups. Bootstrap samples resample whole
groups. Pixel or repeated-recording counts do not inflate the
independent sample size.

## Usage

``` r
hs_group_summary(
  data,
  value = "value",
  group = "subject_id",
  bootstrap = 1000L,
  seed = 1L
)
```

## Arguments

- data:

  Data frame containing a numeric outcome and a group identifier.

- value:

  Column name containing the outcome.

- group:

  Column name identifying independent subjects or sampling units.

- bootstrap:

  Number of bootstrap samples. Default 1000.

- seed:

  Random seed. Default 1.

## Value

List containing group means, independent group count, overall estimate,
percentile interval and number of excluded nonfinite observations.

## Examples

``` r
roi <- data.frame(
  subject_id = rep(c("s1", "s2", "s3"), times = c(5, 3, 4)),
  value = c(0.61, 0.63, 0.60, 0.62, 0.64, 0.55, 0.57, 0.56,
            0.70, 0.71, 0.69, 0.72)
)
res <- hs_group_summary(roi, bootstrap = 200)
res$estimate
#> [1] 0.6283333
res$interval
#> [1] 0.560 0.705
```
