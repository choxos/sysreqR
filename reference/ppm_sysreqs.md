# Query Package Manager system requirements

Queries the Posit Package Manager `/sysreqs` endpoint for the given
packages and platform, and normalizes the response into a
`sysreqr_plan`. If the API call fails, the function falls back to the
bundled database (or to an empty plan when the bundled data has no names
for the platform's package manager) and records the failure in the
`"fallback_error"` attribute of the returned plan.

## Usage

``` r
ppm_sysreqs(
  packages = NULL,
  all = FALSE,
  platform = NULL,
  repo = "cran",
  base_url = ppm_default_base_url(),
  check_installed = TRUE
)
```

## Arguments

- packages:

  Package names. Required when `all = FALSE`.

- all:

  Whether to return system requirements for the whole repository.

- platform:

  Platform specification accepted by
  [`resolve_platform()`](https://choxos.github.io/sysreqR/reference/resolve_platform.md).

- repo:

  Repository name.

- base_url:

  Posit Package Manager base URL.

- check_installed:

  Whether to check installed system packages on the current host when
  possible.

## Value

A `sysreqr_plan`.

## See also

Other ppm:
[`check_ppm()`](https://choxos.github.io/sysreqR/reference/check_ppm.md),
[`ppm_platforms()`](https://choxos.github.io/sysreqR/reference/ppm_platforms.md),
[`ppm_repo()`](https://choxos.github.io/sysreqR/reference/ppm_repo.md),
[`use_ppm()`](https://choxos.github.io/sysreqR/reference/use_ppm.md)

## Examples

``` r
# \donttest{
ppm_sysreqs(c("xml2", "curl"), platform = "ubuntu-22.04")
#> System requirement preflight
#> 
#> Platform: Ubuntu 22.04
#> Package manager: apt
#> Backend: ppm
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
# }
```
