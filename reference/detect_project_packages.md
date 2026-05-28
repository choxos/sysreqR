# Detect R packages used by a project

Inspects a project directory for the R packages it uses. The detection
priority is:

## Usage

``` r
detect_project_packages(path = ".", include_suggests = FALSE)
```

## Arguments

- path:

  Project path.

- include_suggests:

  Whether to include `Suggests` from `DESCRIPTION`.

## Value

A character vector of package names.

## Details

1.  `renv.lock` (the `Packages` map),

2.  `DESCRIPTION` (`Depends`, `Imports`, `LinkingTo`, and optionally
    `Suggests`),

3.  `.R`, `.Rmd`, `.qmd`, and `NAMESPACE` files (looking for
    [`library()`](https://rdrr.io/r/base/library.html),
    [`require()`](https://rdrr.io/r/base/library.html), and `pkg::fun`
    references).

## See also

Other preflight:
[`check_library()`](https://choxos.github.io/sysreqR/reference/check_library.md),
[`check_packages()`](https://choxos.github.io/sysreqR/reference/check_packages.md),
[`check_project()`](https://choxos.github.io/sysreqR/reference/check_project.md)

## Examples

``` r
if (FALSE) { # \dontrun{
detect_project_packages(".")
detect_project_packages(".", include_suggests = TRUE)
} # }
```
