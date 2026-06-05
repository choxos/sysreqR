# Preflight setup before installing R packages

## Why preflight?

A new GNU/Linux user often meets system requirements only after
something has already failed. The better workflow is to check the setup
first, use binary R packages where possible, and install source build
tools only when source packages are needed.

`sysreqr` is a zero-runtime-dependency helper for that workflow. It does
not run `sudo`, edit operating system repositories, or install system
packages. It prints commands and writes files that the user, or their
administrator, can review.

## Understand the platform

`sysreqr` tries to detect the current platform automatically, but
examples and reproducible scripts should usually pass a platform string.

``` r

detect_package_manager("ubuntu-24.04")
#> [1] "apt"
resolve_platform("noble")
#> $os
#> [1] "linux"
#> 
#> $distro
#> [1] "ubuntu"
#> 
#> $version
#> [1] "24.04"
#> 
#> $codename
#> [1] "noble"
#> 
#> $package_manager
#> [1] "apt"
#> 
#> $ppm_binary_url
#> [1] "noble"
#> 
#> $supported
#> [1] TRUE
#> 
#> $label
#> [1] "Ubuntu 24.04"
#> 
#> attr(,"class")
#> [1] "sysreqr_platform"
```

Common platform strings:

| Distribution | `<distro>-<version>`       | Codename alias |
|--------------|----------------------------|----------------|
| Ubuntu       | `ubuntu-22.04`             | `jammy`        |
| Ubuntu       | `ubuntu-24.04`             | `noble`        |
| Ubuntu       | `ubuntu-26.04`             | `resolute`     |
| Debian       | `debian-12`                | `bookworm`     |
| Debian       | `debian-13`                | `trixie`       |
| RHEL family  | `rockylinux-9`, `redhat-9` |                |
| Fedora       | `fedora-40`                |                |
| openSUSE/SLE | `opensuse156`, `sle-15.6`  |                |

## Start with setup advice

[`setup_advice()`](https://choxos.github.io/sysreqR/reference/setup_advice.md)
produces a practical checklist for a Linux platform.

``` r

setup_advice(platform = "ubuntu-24.04")
```

The advice has four layers:

1.  **Posit Package Manager**, when a binary repository URL is known.
2.  **Source build tools** such as `r-base-dev`, compilers, `make`, and
    `pkg-config`.
3.  **Optional R Project operating system repository commands** for
    supported Ubuntu, Debian, and Fedora systems.
4.  **Package-specific system requirements** when package names are
    supplied.

The R Project operating system repository layer is optional because it
changes the operating system repository configuration. It is most
relevant when the system R version is too old. It is not the first fix
for every missing library.

To include package-specific requirements:

``` r

setup_advice(
  packages = c("xml2", "curl"),
  platform = "ubuntu-24.04"
)
```

To write a reviewable shell script:

``` r

setup_advice(
  packages = c("xml2", "curl"),
  platform = "ubuntu-24.04",
  script = file.path(tempdir(), "setup-sysreqr.sh")
)
```

The script contains source build tools and package system requirements
as active commands. Optional operating system repository commands are
included as comments because they should be reviewed first.

## Use Posit Package Manager

Binary R packages are the simplest way to avoid source compilation
problems.

Build a Posit Package Manager repository URL:

``` r

ppm_repo(platform = "ubuntu-24.04")
#> [1] "https://packagemanager.posit.co/cran/__linux__/noble/latest"
```

Preview the `.Rprofile` lines that would point R at that repository:

``` r

use_ppm(platform = "ubuntu-24.04", dry_run = TRUE)
#> [1] "options("                                                                  
#> [2] "  repos = c("                                                              
#> [3] "    CRAN = \"https://packagemanager.posit.co/cran/__linux__/noble/latest\""
#> [4] "  )"                                                                       
#> [5] ")"
```

[`use_ppm()`](https://choxos.github.io/sysreqR/reference/use_ppm.md)
does not edit files unless `dry_run = FALSE` and an explicit `path` is
supplied.

When network access is available, these helpers query Posit Package
Manager support and system requirement data live:

``` r

check_ppm("ubuntu-22.04")
ppm_platforms()
ppm_sysreqs(c("xml2", "curl"), platform = "ubuntu-22.04")
```

## Check packages before installing

[`check_packages()`](https://choxos.github.io/sysreqR/reference/check_packages.md)
returns a `sysreqr_plan`. The plan is a data frame with the R package,
system requirement, installable system package, install script,
platform, package manager, installed status when available, source,
confidence, and notes.

``` r

plan <- check_packages(
  c("xml2", "curl"),
  platform = "ubuntu-22.04"
)
plan
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
```

Turn the plan into common outputs:

``` r

install_command(plan)
#> [1] "sudo apt-get update"                                                
#> [2] "sudo apt-get install -y libcurl4-openssl-dev libssl-dev libxml2-dev"
```

``` r

write_install_script(plan, file.path(tempdir(), "install-sysreqs.sh"))
dockerfile(plan)
github_actions(plan)
```

Write files for review or automation:

``` r

write_report(plan, file.path(tempdir(), "SYSREQS.md"))
write_json(plan, file.path(tempdir(), "sysreqs.json"))
```

Create a message for an administrator:

``` r

admin_request(plan)
```

Inspect or explain a plan:

``` r

as_data_frame(plan)
as_install_plan(plan)
is_sysreqr_plan(plan)
explain(plan)
```

## Pick a backend

[`check_packages()`](https://choxos.github.io/sysreqR/reference/check_packages.md)
accepts four backend modes.

- `backend = "auto"` uses bundled data for simple, known CRAN packages
  on `apt` platforms, then Package Manager, then `pak` when possible.
- `backend = "bundled"` uses only the static database shipped with the
  installed `sysreqr` release. Currently optimized for `apt`.
- `backend = "ppm"` uses the Posit Package Manager API when network
  access is available.
- `backend = "pak"` uses
  [`pak::pkg_sysreqs()`](https://pak.r-lib.org/reference/pkg_sysreqs.html)
  when `pak` is installed.

`sysreqr` has zero runtime dependencies. Optional live backends (`ppm`,
`pak`) are used only when requested and available.

## See also

- [`vignette("diagnosing-failures")`](https://choxos.github.io/sysreqR/articles/diagnosing-failures.md)
  for post-failure log diagnosis.
- [`vignette("linux-fundamentals")`](https://choxos.github.io/sysreqR/articles/linux-fundamentals.md)
  for a GNU/Linux primer.
- [`vignette("docker-and-ci")`](https://choxos.github.io/sysreqR/articles/docker-and-ci.md)
  for container and CI workflows.
- [`vignette("faq")`](https://choxos.github.io/sysreqR/articles/faq.md)
  for frequently asked questions.
