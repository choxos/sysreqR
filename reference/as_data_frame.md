# Coerce a plan to a plain data frame

Strips the `sysreqr_plan` class and attributes, returning a plain
`data.frame`. Equivalent to
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) on a
plan, but provided as a verb form for users who prefer that style.

## Usage

``` r
as_data_frame(x)
```

## Arguments

- x:

  A `sysreqr_plan`.

## Value

A data frame without the `sysreqr_plan` class.

## See also

Other plan:
[`is_sysreqr_plan()`](https://choxos.github.io/sysreqR/reference/is_sysreqr_plan.md),
[`print.sysreqr_plan()`](https://choxos.github.io/sysreqR/reference/print.sysreqr_plan.md)

## Examples

``` r
plan <- check_packages("xml2", platform = "ubuntu-22.04")
df <- as_data_frame(plan)
inherits(df, "sysreqr_plan")
#> [1] FALSE
inherits(df, "data.frame")
#> [1] TRUE
```
