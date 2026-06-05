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
# \donttest{
check_ppm("ubuntu-22.04")
#> $supported
#> [1] TRUE
#> 
#> $binaries
#> [1] TRUE
#> 
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
#> $ppm
#> $ppm$name
#> [1] "jammy"
#> 
#> $ppm$os
#> [1] "linux"
#> 
#> $ppm$binaryDisplay
#> [1] "Ubuntu 22.04 (Jammy)"
#> 
#> $ppm$binaryURL
#> [1] "jammy"
#> 
#> $ppm$display
#> [1] "Ubuntu 22.04 (Jammy)"
#> 
#> $ppm$distribution
#> [1] "ubuntu"
#> 
#> $ppm$release
#> [1] "22.04"
#> 
#> $ppm$build_distribution
#> [1] ""
#> 
#> $ppm$sysReqs
#> [1] TRUE
#> 
#> $ppm$binaries
#> [1] TRUE
#> 
#> $ppm$hidden
#> [1] FALSE
#> 
#> $ppm$official_rspm
#> [1] TRUE
#> 
#> $ppm$arch
#> $ppm$arch[[1]]
#> [1] "x86_64"
#> 
#> 
#> 
#> $version
#> [1] "2026.05.0"
#> 
check_ppm("fedora-40")
#> $supported
#> [1] FALSE
#> 
#> $binaries
#> [1] FALSE
#> 
#> $platform
#> $os
#> [1] "linux"
#> 
#> $distro
#> [1] "fedora"
#> 
#> $version
#> [1] "40"
#> 
#> $codename
#> [1] NA
#> 
#> $package_manager
#> [1] "dnf"
#> 
#> $ppm_binary_url
#> [1] NA
#> 
#> $supported
#> [1] TRUE
#> 
#> $label
#> [1] "fedora 40"
#> 
#> attr(,"class")
#> [1] "sysreqr_platform"
#> 
#> $ppm
#> NULL
#> 
#> $version
#> [1] "2026.05.0"
#> 
# }
```
