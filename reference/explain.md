# Explain system requirements

Prints a short, friendly explanation for each system package an R
package needs and the command to install it. Useful for teaching and for
emails to less-experienced collaborators.

## Usage

``` r
explain(x, platform = NULL, ...)
```

## Arguments

- x:

  A package name, package vector, or `sysreqr_plan`.

- platform:

  Platform specification accepted by
  [`resolve_platform()`](https://choxos.github.io/sysreqR/reference/resolve_platform.md).

- ...:

  Passed to
  [`check_packages()`](https://choxos.github.io/sysreqR/reference/check_packages.md)
  when `x` is not a plan.

## Value

A character vector of explanation lines, invisibly.

## See also

Other setup:
[`print.sysreqr_setup_advice()`](https://choxos.github.io/sysreqR/reference/print.sysreqr_setup_advice.md),
[`setup_advice()`](https://choxos.github.io/sysreqR/reference/setup_advice.md)

## Examples

``` r
plan <- check_packages("xml2", platform = "ubuntu-22.04")
explain(plan)
#> System requirement explanation
#> 
#> xml2 needs libxml2-dev.
#> Install it with: apt-get install -y libxml2-dev
#> 
```
