# Write an install script

Writes a POSIX-shell install script. The script begins with
`#!/usr/bin/env sh` and `set -eu` and is marked executable.

## Usage

``` r
write_install_script(plan, path = "install-sysreqs.sh")
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
[`write_json()`](https://choxos.github.io/sysreqR/reference/write_json.md),
[`write_report()`](https://choxos.github.io/sysreqR/reference/write_report.md)

## Examples

``` r
plan <- check_packages("xml2", platform = "ubuntu-22.04")
write_install_script(plan, file.path(tempdir(), "install-sysreqs.sh"))
```
