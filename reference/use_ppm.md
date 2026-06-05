# Configure Package Manager repository options

Emits or installs the R code lines that point `options(repos)` at a
Posit Package Manager binary repository. With `dry_run = TRUE` (the
default), the lines are returned without touching any file, so the user
can review them before applying. When `dry_run = FALSE`, `path` must be
supplied explicitly.

## Usage

``` r
use_ppm(
  scope = c("user", "project"),
  platform = NULL,
  repo = "cran",
  dry_run = TRUE,
  path = NULL
)
```

## Arguments

- scope:

  `"user"` edits the user `.Rprofile`, `"project"` edits the current
  project `.Rprofile`.

- platform:

  Platform specification accepted by
  [`resolve_platform()`](https://choxos.github.io/sysreqR/reference/resolve_platform.md).

- repo:

  Repository name.

- dry_run:

  If `TRUE`, return the lines that would be written without editing
  files.

- path:

  Explicit `.Rprofile` path used when `dry_run = FALSE`.

## Value

The configuration lines, invisibly when written.

## See also

Other ppm:
[`check_ppm()`](https://choxos.github.io/sysreqR/reference/check_ppm.md),
[`ppm_platforms()`](https://choxos.github.io/sysreqR/reference/ppm_platforms.md),
[`ppm_repo()`](https://choxos.github.io/sysreqR/reference/ppm_repo.md),
[`ppm_sysreqs()`](https://choxos.github.io/sysreqR/reference/ppm_sysreqs.md)

## Examples

``` r
use_ppm("user", platform = "ubuntu-22.04", dry_run = TRUE)
#> [1] "options("                                                                  
#> [2] "  repos = c("                                                              
#> [3] "    CRAN = \"https://packagemanager.posit.co/cran/__linux__/jammy/latest\""
#> [4] "  )"                                                                       
#> [5] ")"                                                                         

# Write to a throwaway .Rprofile under tempdir():
use_ppm(
  "user",
  platform = "ubuntu-22.04",
  dry_run = FALSE,
  path = file.path(tempdir(), ".Rprofile")
)
```
