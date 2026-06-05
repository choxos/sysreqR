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
project <- file.path(tempdir(), "demo-project")
dir.create(project, showWarnings = FALSE)
writeLines(
  c("Package: demo", "Imports: xml2"),
  file.path(project, "DESCRIPTION")
)
check_project(project, platform = "ubuntu-22.04", backend = "bundled")
#> System requirement preflight
#> 
#> Platform: Ubuntu 22.04
#> Package manager: apt
#> Backend: bundled
#> 
#> R packages checked:
#>   xml2
#> 
#> System packages to install: 
#>   libxml2-dev  needed by: xml2  status: unknown
#> 
#> Run:
#>   sudo apt-get update
#>   sudo apt-get install -y libxml2-dev
#> 
```
