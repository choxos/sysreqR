# Check system requirements for installed R packages

Reads the package names from one or more R library paths and resolves
their system requirements. Useful for auditing an existing R
installation.

## Usage

``` r
check_library(
  packages = NULL,
  library = .libPaths()[1],
  platform = NULL,
  backend = c("bundled", "auto", "ppm", "pak")
)
```

## Arguments

- packages:

  Optional installed R package names.

- library:

  Library path or paths.

- platform:

  Platform specification accepted by
  [`resolve_platform()`](https://choxos.github.io/sysreqR/reference/resolve_platform.md).

- backend:

  One of `"bundled"`, `"auto"`, `"ppm"`, or `"pak"`.

## Value

A `sysreqr_plan`.

## See also

Other preflight:
[`check_packages()`](https://choxos.github.io/sysreqR/reference/check_packages.md),
[`check_project()`](https://choxos.github.io/sysreqR/reference/check_project.md),
[`detect_project_packages()`](https://choxos.github.io/sysreqR/reference/detect_project_packages.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Audits the default library:
check_library()
} # }

# With an explicit package list (offline, bundled backend):
check_library(
  packages = c("xml2", "curl"),
  platform = "ubuntu-22.04",
  backend = "bundled"
)
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
```
