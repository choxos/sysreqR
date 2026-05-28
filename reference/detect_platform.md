# Detect the current platform

Detects the host operating system and, on Linux, parses
`/etc/os-release`. On macOS, queries `sw_vers`. Returns a structured
platform object used by the rest of the package. When `os_release` is
supplied and exists, the file is parsed even on macOS or Windows; this
makes fixture-driven testing practical.

## Usage

``` r
detect_platform(os_release = "/etc/os-release")
```

## Arguments

- os_release:

  Path to an `os-release` file. Defaults to the system file
  `/etc/os-release`. Mainly useful for tests and reproducible builds.

## Value

An object of class `sysreqr_platform` (a list).

## See also

Other platform:
[`detect_package_manager()`](https://choxos.github.io/sysreqR/reference/detect_package_manager.md),
[`resolve_platform()`](https://choxos.github.io/sysreqR/reference/resolve_platform.md)

## Examples

``` r
platform <- detect_platform()
platform$distro
#> [1] "ubuntu"

# Reproducible reads from a fixture file:
fixture <- system.file(
  "extdata", "os-release-fedora-40",
  package = "sysreqr",
  mustWork = FALSE
)
if (nzchar(fixture)) detect_platform(os_release = fixture)
```
