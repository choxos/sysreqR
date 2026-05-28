# Generate Dockerfile lines

Produces a Dockerfile `RUN` snippet that installs the system packages a
plan needs. On `apt` platforms the output uses the standard
`apt-get update && apt-get install -y --no-install-recommends ... && rm -rf /var/lib/apt/lists/*`
pattern.

## Usage

``` r
dockerfile(x, platform = NULL, missing_only = TRUE, ...)
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

A single Dockerfile snippet.

## See also

Other commands:
[`admin_request()`](https://choxos.github.io/sysreqR/reference/admin_request.md),
[`github_actions()`](https://choxos.github.io/sysreqR/reference/github_actions.md),
[`install_command()`](https://choxos.github.io/sysreqR/reference/install_command.md)

## Examples

``` r
plan <- check_packages("xml2", platform = "ubuntu-22.04")
cat(dockerfile(plan))
#> RUN apt-get update && apt-get install -y --no-install-recommends \
#>     libxml2-dev \
#>     && rm -rf /var/lib/apt/lists/*
```
