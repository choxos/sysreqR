# Build a Posit Package Manager repository URL

Constructs a Linux binary repository URL for the given platform, CRAN
repository alias, and snapshot.

## Usage

``` r
ppm_repo(
  platform = NULL,
  repo = "cran",
  snapshot = "latest",
  base_url = ppm_default_base_url()
)
```

## Arguments

- platform:

  Platform specification accepted by
  [`resolve_platform()`](https://choxos.github.io/sysreqR/reference/resolve_platform.md).

- repo:

  Repository name.

- snapshot:

  Snapshot name or date.

- base_url:

  Posit Package Manager base URL.

## Value

A repository URL.

## See also

Other ppm:
[`check_ppm()`](https://choxos.github.io/sysreqR/reference/check_ppm.md),
[`ppm_platforms()`](https://choxos.github.io/sysreqR/reference/ppm_platforms.md),
[`ppm_sysreqs()`](https://choxos.github.io/sysreqR/reference/ppm_sysreqs.md),
[`use_ppm()`](https://choxos.github.io/sysreqR/reference/use_ppm.md)

## Examples

``` r
ppm_repo(platform = "ubuntu-22.04")
#> [1] "https://packagemanager.posit.co/cran/__linux__/jammy/latest"
ppm_repo(platform = "ubuntu-26.04", snapshot = "2026-04-01")
#> [1] "https://packagemanager.posit.co/cran/__linux__/resolute/2026-04-01"
```
