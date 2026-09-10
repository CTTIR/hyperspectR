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
