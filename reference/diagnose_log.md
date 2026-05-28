# Diagnose an R package installation log

Scans an installation log for common compiler and linker errors and for
R-level "configuration failed" and "non-zero exit status" patterns, then
resolves those failed packages back to their system requirements.

## Usage

``` r
diagnose_log(
  path = NULL,
  text = NULL,
  platform = NULL,
  backend = c("auto", "bundled", "ppm", "pak"),
  repo = "cran",
  check_installed = TRUE
)

diagnose_install_log(
  path = NULL,
  text = NULL,
  platform = NULL,
  backend = c("auto", "bundled", "ppm", "pak"),
  repo = "cran",
  check_installed = TRUE
)
```

## Arguments

- path:

  Path to an installation log.

- text:

  Log text. Used when `path` is `NULL`.

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

A `sysreqr_plan` with likely system package fixes.

## Details

The function combines two paths:

1.  Direct log-pattern matching against a curated list of header and
    linker error messages.

2.  Failed package extraction plus a back-end lookup of those package
    names.

Confidence levels are `"high"` for direct pattern matches and pak/PPM
lookups, and `"medium"` for bundled fallback data and inferred package
requirements.

## See also

Other diagnose:
[`check_error()`](https://choxos.github.io/sysreqR/reference/check_error.md),
[`diagnose_failed_packages()`](https://choxos.github.io/sysreqR/reference/diagnose_failed_packages.md)

## Examples

``` r
log <- paste(
  "fatal error: libxml/parser.h: No such file or directory",
  "ERROR: configuration failed for package 'xml2'",
  sep = "\n"
)
plan <- diagnose_log(text = log, platform = "ubuntu-22.04")
plan
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
