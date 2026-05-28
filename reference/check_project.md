# Check system requirements for a project

Convenience wrapper around
[`detect_project_packages()`](https://choxos.github.io/sysreqR/reference/detect_project_packages.md)
and
[`check_packages()`](https://choxos.github.io/sysreqR/reference/check_packages.md).

## Usage

``` r
check_project(
  path = ".",
  include_suggests = FALSE,
  platform = NULL,
  backend = c("auto", "bundled", "ppm", "pak"),
  ...
)
```

## Arguments

- path:

  Project path.

- include_suggests:

  Whether to include `Suggests` from `DESCRIPTION`.

- platform:

  Platform specification accepted by
  [`resolve_platform()`](https://choxos.github.io/sysreqR/reference/resolve_platform.md).

- backend:

  One of `"auto"`, `"ppm"`, or `"pak"`.

- ...:

  Passed to
  [`check_packages()`](https://choxos.github.io/sysreqR/reference/check_packages.md).

## Value

A `sysreqr_plan`.

## See also

Other preflight:
[`check_library()`](https://choxos.github.io/sysreqR/reference/check_library.md),
[`check_packages()`](https://choxos.github.io/sysreqR/reference/check_packages.md),
[`detect_project_packages()`](https://choxos.github.io/sysreqR/reference/detect_project_packages.md)

## Examples

``` r
if (FALSE) { # \dontrun{
check_project(".")
check_project(".", platform = "ubuntu-22.04", backend = "ppm")
} # }
```
