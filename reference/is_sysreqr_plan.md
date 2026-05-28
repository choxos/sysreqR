# Test whether an object is a sysreqr plan

Test whether an object is a sysreqr plan

## Usage

``` r
is_sysreqr_plan(x)
```

## Arguments

- x:

  An object.

## Value

`TRUE` if `x` inherits from `"sysreqr_plan"`.

## See also

Other plan:
[`as_data_frame()`](https://choxos.github.io/sysreqR/reference/as_data_frame.md),
[`print.sysreqr_plan()`](https://choxos.github.io/sysreqR/reference/print.sysreqr_plan.md)

## Examples

``` r
plan <- check_packages("xml2", platform = "ubuntu-22.04")
is_sysreqr_plan(plan)
#> [1] TRUE
is_sysreqr_plan(data.frame(x = 1))
#> [1] FALSE
```
