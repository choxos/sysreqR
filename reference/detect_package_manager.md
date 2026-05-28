# Detect the platform package manager

Returns the name of the operating system package manager for a platform:
`"apt"`, `"dnf"`, `"yum"`, `"zypper"`, `"apk"`, or `"brew"`.

## Usage

``` r
detect_package_manager(platform = NULL)
```

## Arguments

- platform:

  A platform specification accepted by
  [`resolve_platform()`](https://choxos.github.io/sysreqR/reference/resolve_platform.md).

## Value

A package manager name such as `"apt"` or `"dnf"`.

## See also

Other platform:
[`detect_platform()`](https://choxos.github.io/sysreqR/reference/detect_platform.md),
[`resolve_platform()`](https://choxos.github.io/sysreqR/reference/resolve_platform.md)

## Examples

``` r
detect_package_manager("ubuntu-22.04")
#> [1] "apt"
detect_package_manager("fedora-40")
#> [1] "dnf"
detect_package_manager("opensuse156")
#> [1] "zypper"
```
