# Generate an installation command

Translates a plan (or a package vector that can be resolved to a plan)
into shell commands appropriate for the platform's package manager.

## Usage

``` r
install_command(
  x,
  platform = NULL,
  sudo = TRUE,
  update = TRUE,
  missing_only = TRUE,
  ...
)
```

## Arguments

- x:

  A `sysreqr_plan` or package vector.

- platform:

  Platform specification accepted by
  [`resolve_platform()`](https://choxos.github.io/sysreqR/reference/resolve_platform.md).

- sudo:

  Whether to prefix commands with `sudo`.

- update:

  Whether to include the package manager update command when
  appropriate.

- missing_only:

  Whether to include only packages not known to be installed.

- ...:

  Passed to
  [`check_packages()`](https://choxos.github.io/sysreqR/reference/check_packages.md)
  when `x` is not a plan.

## Value

A character vector of shell commands.

## See also

Other commands:
[`admin_request()`](https://choxos.github.io/sysreqR/reference/admin_request.md),
[`dockerfile()`](https://choxos.github.io/sysreqR/reference/dockerfile.md),
[`github_actions()`](https://choxos.github.io/sysreqR/reference/github_actions.md),
[`gitlab_ci()`](https://choxos.github.io/sysreqR/reference/gitlab_ci.md)

## Examples

``` r
plan <- check_packages(c("xml2", "curl"), platform = "ubuntu-22.04")
install_command(plan)
#> [1] "sudo apt-get update"                                                
#> [2] "sudo apt-get install -y libcurl4-openssl-dev libssl-dev libxml2-dev"
install_command(plan, sudo = FALSE, update = FALSE)
#> [1] "apt-get install -y libcurl4-openssl-dev libssl-dev libxml2-dev"
```
