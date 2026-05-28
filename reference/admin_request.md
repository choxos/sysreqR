# Create an administrator request

Produces a plain-text message that a user without root access can send
to their system administrator. The message lists missing system
packages, which R packages need them, and a suggested install command.

## Usage

``` r
admin_request(x, platform = NULL, ...)
```

## Arguments

- x:

  A `sysreqr_plan` or package vector.

- platform:

  Platform specification accepted by
  [`resolve_platform()`](https://choxos.github.io/sysreqR/reference/resolve_platform.md).

- ...:

  Passed to
  [`check_packages()`](https://choxos.github.io/sysreqR/reference/check_packages.md)
  when `x` is not a plan.

## Value

A plain-text administrator request.

## See also

Other commands:
[`dockerfile()`](https://choxos.github.io/sysreqR/reference/dockerfile.md),
[`github_actions()`](https://choxos.github.io/sysreqR/reference/github_actions.md),
[`install_command()`](https://choxos.github.io/sysreqR/reference/install_command.md)

## Examples

``` r
plan <- check_packages("xml2", platform = "ubuntu-22.04")
cat(admin_request(plan))
#> Hello,
#> 
#> Could you please install the following system packages on this server?
#> 
#> libxml2-dev
#> 
#> They are required to install or use these R packages:
#> xml2
#> 
#> Suggested command:
#> sudo apt-get update
#> sudo apt-get install -y libxml2-dev
#> 
#> Thank you.
```
