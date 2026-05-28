# Generate a GitHub Actions snippet

Produces a GitHub Actions YAML step that installs the system packages a
plan needs. `gha()` is a short alias.

## Usage

``` r
github_actions(x, platform = NULL, missing_only = TRUE, ...)

gha(x, platform = NULL, missing_only = TRUE, ...)
```

## Arguments

- x:

  A `sysreqr_plan` or package vector.

- platform:

  Platform specification accepted by
  [`resolve_platform()`](https://choxos.github.io/sysreqR/reference/resolve_platform.md).

- missing_only:

  Whether to include only packages not known to be installed.

- ...:

  Passed to
  [`check_packages()`](https://choxos.github.io/sysreqR/reference/check_packages.md)
  when `x` is not a plan.

## Value

A YAML snippet.

## See also

Other commands:
[`admin_request()`](https://choxos.github.io/sysreqR/reference/admin_request.md),
[`dockerfile()`](https://choxos.github.io/sysreqR/reference/dockerfile.md),
[`install_command()`](https://choxos.github.io/sysreqR/reference/install_command.md)

## Examples

``` r
plan <- check_packages("xml2", platform = "ubuntu-22.04")
cat(github_actions(plan))
#> - name: Install Linux system dependencies
#>   run: |
#>     sudo apt-get update
#>     sudo apt-get install -y libxml2-dev
identical(gha(plan), github_actions(plan))
#> [1] TRUE
```
