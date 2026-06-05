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
    [`require()`](https://rdrr.io/r/base/library.html),
    [`requireNamespace()`](https://rdrr.io/r/base/ns-load.html), and
    `pkg::fun` references; line comments are ignored).

## See also

Other preflight:
[`check_library()`](https://choxos.github.io/sysreqR/reference/check_library.md),
[`check_packages()`](https://choxos.github.io/sysreqR/reference/check_packages.md),
[`check_project()`](https://choxos.github.io/sysreqR/reference/check_project.md)

## Examples

``` r
project <- file.path(tempdir(), "demo-project")
dir.create(project, showWarnings = FALSE)
writeLines(
  c("Package: demo", "Imports: xml2, curl"),
  file.path(project, "DESCRIPTION")
)
detect_project_packages(project)
#> [1] "curl" "xml2"
```
