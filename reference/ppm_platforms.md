# List Posit Package Manager platforms

Queries the Posit Package Manager `/__api__/status` endpoint and returns
a data frame of supported distributions.

## Usage

``` r
ppm_platforms(base_url = ppm_default_base_url())
```

## Arguments

- base_url:

  Posit Package Manager base URL.

## Value

A data frame of platform records reported by Package Manager.

## See also

Other ppm:
[`check_ppm()`](https://choxos.github.io/sysreqR/reference/check_ppm.md),
[`ppm_repo()`](https://choxos.github.io/sysreqR/reference/ppm_repo.md),
[`ppm_sysreqs()`](https://choxos.github.io/sysreqR/reference/ppm_sysreqs.md),
[`use_ppm()`](https://choxos.github.io/sysreqR/reference/use_ppm.md)

## Examples

``` r
if (FALSE) { # \dontrun{
ppm_platforms()
} # }
```
