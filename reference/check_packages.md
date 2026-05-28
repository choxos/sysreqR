# Check system requirements for R packages

Resolves the system packages an R package needs on a given Linux
platform and returns them in a structured plan. The `"auto"` backend
prefers the offline bundled database on `apt` platforms, then Posit
Package Manager, then `pak`.

## Usage

``` r
check_packages(
  packages,
  platform = NULL,
  backend = c("auto", "bundled", "ppm", "pak"),
  repo = "cran",
  dependencies = NA,
  upgrade = TRUE,
  check_installed = TRUE
)
```

## Arguments

- packages:

  Package names or package references.

- platform:

  Platform specification accepted by
  [`resolve_platform()`](https://choxos.github.io/sysreqR/reference/resolve_platform.md).

- backend:

  One of `"auto"`, `"bundled"`, `"ppm"`, or `"pak"`.

- repo:

  Repository name used in notes and by the PPM backend.

- dependencies:

  Dependency policy passed to
  [`pak::pkg_sysreqs()`](https://pak.r-lib.org/reference/pkg_sysreqs.html)
  when the pak backend is used.

- upgrade:

  Upgrade policy passed to
  [`pak::pkg_sysreqs()`](https://pak.r-lib.org/reference/pkg_sysreqs.html)
  when the pak backend is used.

- check_installed:

  Whether to check installed system packages on the current host when
  possible.

## Value

A `sysreqr_plan`.

## See also

[`check_project()`](https://choxos.github.io/sysreqR/reference/check_project.md),
[`check_library()`](https://choxos.github.io/sysreqR/reference/check_library.md),
[`diagnose_log()`](https://choxos.github.io/sysreqR/reference/diagnose_log.md).

Other preflight:
[`check_library()`](https://choxos.github.io/sysreqR/reference/check_library.md),
[`check_project()`](https://choxos.github.io/sysreqR/reference/check_project.md),
[`detect_project_packages()`](https://choxos.github.io/sysreqR/reference/detect_project_packages.md)

## Examples

``` r
plan <- check_packages(c("xml2", "curl"), platform = "ubuntu-22.04")
plan
#> System requirement preflight
#> 
#> Platform: Ubuntu 22.04
#> Package manager: apt
#> Backend: bundled
#> 
#> R packages checked:
#>   curl, xml2
#> 
#> System packages to install: 
#>   libcurl4-openssl-dev  needed by: curl  status: unknown
#>   libssl-dev  needed by: curl  status: unknown
#>   libxml2-dev  needed by: xml2  status: unknown
#> 
#> Run:
#>   sudo apt-get update
#>   sudo apt-get install -y libcurl4-openssl-dev libssl-dev libxml2-dev
#> 

install_command(plan)
#> [1] "sudo apt-get update"                                                
#> [2] "sudo apt-get install -y libcurl4-openssl-dev libssl-dev libxml2-dev"

if (FALSE) { # \dontrun{
# Network-dependent: queries Posit Package Manager.
check_packages("xml2", platform = "ubuntu-22.04", backend = "ppm")
} # }
```
