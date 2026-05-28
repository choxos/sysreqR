# Return backend install plan data

Converts a plan into a structured list suitable for downstream tooling
(other R code, deployment scripts, or CI). The fields are `platform`,
`backend`, `pre_install`, `install`, `post_install`, and `packages`.

## Usage

``` r
as_install_plan(x)
```

## Arguments

- x:

  A `sysreqr_plan`.

## Value

A list with commands and plan data.

## See also

Other output:
[`write_dockerfile_snippet()`](https://choxos.github.io/sysreqR/reference/write_dockerfile_snippet.md),
[`write_install_script()`](https://choxos.github.io/sysreqR/reference/write_install_script.md),
[`write_json()`](https://choxos.github.io/sysreqR/reference/write_json.md),
[`write_report()`](https://choxos.github.io/sysreqR/reference/write_report.md)

## Examples

``` r
plan <- check_packages("xml2", platform = "ubuntu-22.04")
as_install_plan(plan)
#> $platform
#> $os
#> [1] "linux"
#> 
#> $distro
#> [1] "ubuntu"
#> 
#> $version
#> [1] "22.04"
#> 
#> $codename
#> [1] "jammy"
#> 
#> $package_manager
#> [1] "apt"
#> 
#> $ppm_binary_url
#> [1] "jammy"
#> 
#> $supported
#> [1] TRUE
#> 
#> $label
#> [1] "Ubuntu 22.04"
#> 
#> attr(,"class")
#> [1] "sysreqr_platform"
#> 
#> $backend
#> [1] "bundled"
#> 
#> $pre_install
#> character(0)
#> 
#> $install
#> [1] "apt-get update"                 "apt-get install -y libxml2-dev"
#> 
#> $post_install
#> character(0)
#> 
#> $packages
#>   r_package sysreq system_package                 install_script pre_install
#> 1      xml2   <NA>    libxml2-dev apt-get install -y libxml2-dev        <NA>
#>   post_install     platform package_manager installed  source confidence
#> 1         <NA> ubuntu-22.04             apt        NA bundled     medium
#>                                                                   notes
#> 1 Requirement from bundled sysreqR fallback data for repository `cran`.
#> 
```
