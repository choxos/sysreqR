# Write a sysreqr plan as JSON

Serializes the plan data frame to JSON.

## Usage

``` r
write_json(plan, path)
```

## Arguments

- plan:

  A `sysreqr_plan`.

- path:

  Output path.

## Value

`path`, invisibly.

## See also

Other output:
[`as_install_plan()`](https://choxos.github.io/sysreqR/reference/as_install_plan.md),
[`write_dockerfile_snippet()`](https://choxos.github.io/sysreqR/reference/write_dockerfile_snippet.md),
[`write_install_script()`](https://choxos.github.io/sysreqR/reference/write_install_script.md),
[`write_report()`](https://choxos.github.io/sysreqR/reference/write_report.md)

## Examples

``` r
plan <- check_packages("xml2", platform = "ubuntu-22.04")
write_json(plan, file.path(tempdir(), "sysreqs.json"))
```
