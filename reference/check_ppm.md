# Check Posit Package Manager support

Reports whether a platform is currently served by Posit Package Manager
and whether it has system requirement metadata and binary packages.

## Usage

``` r
check_ppm(platform = NULL, base_url = ppm_default_base_url())
```

## Arguments

- platform:

  Platform specification accepted by
  [`resolve_platform()`](https://choxos.github.io/sysreqR/reference/resolve_platform.md).

- base_url:

  Posit Package Manager base URL.

## Value

A list with the matched platform and Package Manager status.

## See also

Other ppm:
[`ppm_platforms()`](https://choxos.github.io/sysreqR/reference/ppm_platforms.md),
[`ppm_repo()`](https://choxos.github.io/sysreqR/reference/ppm_repo.md),
[`ppm_sysreqs()`](https://choxos.github.io/sysreqR/reference/ppm_sysreqs.md),
[`use_ppm()`](https://choxos.github.io/sysreqR/reference/use_ppm.md)

## Examples

``` r
if (FALSE) { # \dontrun{
check_ppm("ubuntu-22.04")
check_ppm("fedora-40")
} # }
```
