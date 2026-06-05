# Write a Markdown report

Produces a human-readable Markdown report describing the platform,
selected backend, R packages checked, system packages needed, and a
suggested install command.

## Usage

``` r
write_report(plan, path)
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
[`write_json()`](https://choxos.github.io/sysreqR/reference/write_json.md)

## Examples

``` r
plan <- check_packages("xml2", platform = "ubuntu-22.04")
write_report(plan, file.path(tempdir(), "SYSREQS.md"))
```
