# Generate a GitLab CI snippet

Produces a GitLab CI YAML job that installs the system packages a plan
needs. GitLab CI jobs usually run as root inside a container image, so
the commands are emitted without `sudo`.

## Usage

``` r
gitlab_ci(
  x,
  platform = NULL,
  job = "install_system_requirements",
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

- job:

  Name of the generated CI job.

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
[`github_actions()`](https://choxos.github.io/sysreqR/reference/github_actions.md),
[`install_command()`](https://choxos.github.io/sysreqR/reference/install_command.md)

## Examples

``` r
plan <- check_packages("xml2", platform = "ubuntu-22.04", backend = "bundled")
cat(gitlab_ci(plan))
#> install_system_requirements:
#>   script:
#>     - apt-get update
#>     - apt-get install -y libxml2-dev
```
