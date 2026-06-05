# Write a Dockerfile snippet

Writes the output of
[`dockerfile()`](https://choxos.github.io/sysreqR/reference/dockerfile.md)
to a file so it can be appended to an existing Dockerfile or included
verbatim.

## Usage

``` r
write_dockerfile_snippet(plan, path)
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
[`write_install_script()`](https://choxos.github.io/sysreqR/reference/write_install_script.md),
[`write_json()`](https://choxos.github.io/sysreqR/reference/write_json.md),
[`write_report()`](https://choxos.github.io/sysreqR/reference/write_report.md)

## Examples

``` r
plan <- check_packages("xml2", platform = "ubuntu-22.04")
write_dockerfile_snippet(plan, file.path(tempdir(), "Dockerfile.sysreqs"))
```
