# Resolve a platform specification

Accepts a `NULL`, a `sysreqr_platform` object, or a short string and
returns a fully normalized platform object. Strings can be the
`<distro>-<version>` shorthand (`"ubuntu-22.04"`, `"debian-12"`) or a
codename alias (`"jammy"`, `"noble"`, `"resolute"`, `"bookworm"`,
`"trixie"`).

## Usage

``` r
resolve_platform(platform = NULL)
```

## Arguments

- platform:

  `NULL`, a platform list returned by
  [`detect_platform()`](https://choxos.github.io/sysreqR/reference/detect_platform.md),
  or a character string such as `"ubuntu-22.04"`, `"debian-12"`,
  `"jammy"`, or `"bookworm"`.

## Value

A platform list with class `"sysreqr_platform"`.

## See also

Other platform:
[`detect_package_manager()`](https://choxos.github.io/sysreqR/reference/detect_package_manager.md),
[`detect_platform()`](https://choxos.github.io/sysreqR/reference/detect_platform.md)

## Examples

``` r
resolve_platform("ubuntu-22.04")
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
resolve_platform("resolute")
#> $os
#> [1] "linux"
#> 
#> $distro
#> [1] "ubuntu"
#> 
#> $version
#> [1] "26.04"
#> 
#> $codename
#> [1] "resolute"
#> 
#> $package_manager
#> [1] "apt"
#> 
#> $ppm_binary_url
#> [1] "resolute"
#> 
#> $supported
#> [1] TRUE
#> 
#> $label
#> [1] "Ubuntu 26.04"
#> 
#> attr(,"class")
#> [1] "sysreqr_platform"
resolve_platform("bookworm")
#> $os
#> [1] "linux"
#> 
#> $distro
#> [1] "debian"
#> 
#> $version
#> [1] "12"
#> 
#> $codename
#> [1] "bookworm"
#> 
#> $package_manager
#> [1] "apt"
#> 
#> $ppm_binary_url
#> [1] "bookworm"
#> 
#> $supported
#> [1] TRUE
#> 
#> $label
#> [1] "Debian 12"
#> 
#> attr(,"class")
#> [1] "sysreqr_platform"
```
