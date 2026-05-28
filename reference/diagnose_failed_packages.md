# Diagnose failed R packages

Resolves the system requirements for a set of R packages that the user
already knows failed to install. Useful when an install was attempted
outside R, or when the log was lost.

## Usage

``` r
diagnose_failed_packages(
  packages,
  platform = NULL,
  backend = c("auto", "bundled", "ppm", "pak"),
  repo = "cran",
  check_installed = TRUE
)
```

## Arguments

- packages:

  R package names inferred from failed installation output.

- platform:

  Platform specification accepted by
  [`resolve_platform()`](https://choxos.github.io/sysreqR/reference/resolve_platform.md).

- backend:

  One of `"auto"`, `"bundled"`, `"ppm"`, or `"pak"` for failed package
  lookup.

- repo:

  Repository name used by the PPM backend.

- check_installed:

  Whether to check installed system packages on the current host when
  possible.

## Value

A `sysreqr_plan`.

## See also

Other diagnose:
[`check_error()`](https://choxos.github.io/sysreqR/reference/check_error.md),
[`diagnose_log()`](https://choxos.github.io/sysreqR/reference/diagnose_log.md)

## Examples

``` r
diagnose_failed_packages(
  c("xml2", "curl"),
  platform = "ubuntu-22.04",
  backend = "bundled"
)
#> System requirement preflight
#> 
#> Platform: Ubuntu 22.04
#> Package manager: apt
#> Backend: failed-package-lookup
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
```
