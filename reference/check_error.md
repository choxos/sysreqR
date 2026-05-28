# Check the most recent install error for likely system requirements

Convenience wrapper around
[`diagnose_log()`](https://choxos.github.io/sysreqR/reference/diagnose_log.md).
When `text` is `NULL` (the default), the most recent R error message is
read from [`base::geterrmessage()`](https://rdrr.io/r/base/stop.html).

## Usage

``` r
check_error(
  text = NULL,
  platform = NULL,
  backend = c("auto", "bundled", "ppm", "pak"),
  repo = "cran",
  check_installed = TRUE
)
```

## Arguments

- text:

  Error text. When `NULL`, the most recent R error message is used.

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
[`diagnose_failed_packages()`](https://choxos.github.io/sysreqR/reference/diagnose_failed_packages.md),
[`diagnose_log()`](https://choxos.github.io/sysreqR/reference/diagnose_log.md)

## Examples

``` r
check_error(
  text = "ERROR: configuration failed for package 'xml2'",
  platform = "ubuntu-22.04",
  backend = "bundled"
)
#> System requirement preflight
#> 
#> Platform: Ubuntu 22.04
#> Package manager: apt
#> Backend: diagnose-log
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
