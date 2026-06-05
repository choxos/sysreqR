# Get beginner setup advice for R package installation on Linux

Produces a practical checklist for users who are new to R on GNU/Linux.
It recommends binary package repositories where available, explains when
R Project operating system repositories are relevant, lists source build
tools, and can add package-specific system requirements. It never runs
`sudo`, edits the system R configuration, or changes operating system
repositories; the user remains in control.

## Usage

``` r
setup_advice(
  packages = NULL,
  platform = NULL,
  backend = c("auto", "bundled", "ppm", "pak"),
  repo = "cran",
  check_installed = TRUE,
  include_r_project_repo = TRUE,
  script = NULL
)
```

## Arguments

- packages:

  Optional R package names to check.

- platform:

  Platform specification accepted by
  [`resolve_platform()`](https://choxos.github.io/sysreqR/reference/resolve_platform.md).

- backend:

  One of `"auto"`, `"bundled"`, `"ppm"`, or `"pak"`.

- repo:

  Repository name used for Posit Package Manager and sysreq lookup.

- check_installed:

  Whether to check installed system packages on the current host when
  possible.

- include_r_project_repo:

  Whether to include optional R Project operating system repository
  commands for supported Linux distributions.

- script:

  Optional path. When supplied, an executable shell script is written
  with the safe setup commands.

## Value

A `sysreqr_setup_advice` object.

## See also

Other setup:
[`explain()`](https://choxos.github.io/sysreqR/reference/explain.md),
[`print.sysreqr_setup_advice()`](https://choxos.github.io/sysreqR/reference/print.sysreqr_setup_advice.md)

## Examples

``` r
advice <- setup_advice(
  "xml2",
  platform = "ubuntu-22.04",
  backend = "bundled"
)
print(advice)
#> R package installation setup advice
#> 
#> Platform: Ubuntu 22.04
#> Package manager: apt
#> 
#> 1. Prefer binary R packages when available
#> Posit Package Manager repository:
#>   https://packagemanager.posit.co/cran/__linux__/jammy/latest
#> Preview .Rprofile lines:
#>   options(
#>     repos = c(
#>       CRAN = "https://packagemanager.posit.co/cran/__linux__/jammy/latest"
#>     )
#>   )
#> 
#> Using binary packages can avoid many source compilation failures. This changes only R's repository option when you choose to apply it.
#> 
#> 2. Install source build tools when source packages are needed
#>   sudo apt-get update
#>   sudo apt-get install -y --no-install-recommends r-base-dev build-essential gfortran make pkg-config
#> 
#> On Debian and Ubuntu, r-base-dev is needed for compiling many R packages from source.
#> 
#> 3. Optional R Project operating system repository
#>   sudo apt update -qq
#>   sudo apt install --no-install-recommends software-properties-common dirmngr
#>   wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
#>   sudo add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu jammy-cran40/"
#>   sudo apt install --no-install-recommends r-base
#> 
#> Use the R Project Ubuntu repository when your system R is too old. For many package install failures, try Posit Package Manager or system requirements first. On Ubuntu 24.04 and newer, the trusted.gpg.d step may print a deprecation warning; it still works.
#> 
#> 4. Package-specific system requirements
#> R packages checked: xml2
#>   sudo apt-get update
#>   sudo apt-get install -y libxml2-dev
#> 

# \donttest{
# Write a reviewable shell script:
setup_advice(
  c("xml2", "curl"),
  platform = "ubuntu-22.04",
  backend = "bundled",
  script = tempfile(fileext = ".sh")
)
#> R package installation setup advice
#> 
#> Platform: Ubuntu 22.04
#> Package manager: apt
#> 
#> 1. Prefer binary R packages when available
#> Posit Package Manager repository:
#>   https://packagemanager.posit.co/cran/__linux__/jammy/latest
#> Preview .Rprofile lines:
#>   options(
#>     repos = c(
#>       CRAN = "https://packagemanager.posit.co/cran/__linux__/jammy/latest"
#>     )
#>   )
#> 
#> Using binary packages can avoid many source compilation failures. This changes only R's repository option when you choose to apply it.
#> 
#> 2. Install source build tools when source packages are needed
#>   sudo apt-get update
#>   sudo apt-get install -y --no-install-recommends r-base-dev build-essential gfortran make pkg-config
#> 
#> On Debian and Ubuntu, r-base-dev is needed for compiling many R packages from source.
#> 
#> 3. Optional R Project operating system repository
#>   sudo apt update -qq
#>   sudo apt install --no-install-recommends software-properties-common dirmngr
#>   wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
#>   sudo add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu jammy-cran40/"
#>   sudo apt install --no-install-recommends r-base
#> 
#> Use the R Project Ubuntu repository when your system R is too old. For many package install failures, try Posit Package Manager or system requirements first. On Ubuntu 24.04 and newer, the trusted.gpg.d step may print a deprecation warning; it still works.
#> 
#> 4. Package-specific system requirements
#> R packages checked: xml2, curl
#>   sudo apt-get update
#>   sudo apt-get install -y libcurl4-openssl-dev libssl-dev libxml2-dev
#> 
#> 
#> Script written to: /tmp/RtmpipParS/file1a6341c868c7.sh
# }
```
