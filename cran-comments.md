## R CMD check environments

* Local macOS, R 4.6.0
* GitHub Actions: ubuntu-latest (devel, release, oldrel-1), macos-latest,
  windows-latest
* win-builder (planned)
* `rhub::check_for_cran()` (planned)

## R CMD check results

0 errors | 0 warnings | 1 note

Checked with `R CMD check --as-cran`.

The note is expected for an initial CRAN submission:

* New submission

## Release summary

This is the initial release of `sysreqr`.

`sysreqr` helps R users on GNU/Linux find and install system requirements for
R packages. It provides preflight checks, installation commands, Dockerfile
snippets, GitHub Actions snippets, failed-install log diagnosis, beginner
setup advice, and administrator request templates.

## Dependencies

`sysreqr` has zero required dependencies (no `Imports`, no `Depends` beyond
base R).

The `Suggests` field lists `testthat`, `knitr`, `rmarkdown`, and `withr`.
These are used only for tests and vignette building. None of them is loaded
or required when a user calls package functions.

Two optional run-time integrations exist: Posit Package Manager (over HTTPS)
and `pak::pkg_sysreqs()`. Both are detected at run time and are never
required.

## Vignettes

The package ships five HTML vignettes (knitr / rmarkdown):

* `preflight-setup.Rmd`
* `diagnosing-failures.Rmd`
* `linux-fundamentals.Rmd` (a GNU/Linux primer for newcomers)
* `docker-and-ci.Rmd`
* `faq.Rmd`

All vignettes build cleanly with `tools::buildVignette()`.

## Examples

Every exported function has a runnable example. Examples that require network
access (PPM queries) are wrapped in `\dontrun{}`. Examples that write files
to disk use `tempfile()` or `tempdir()` and clean up after themselves.
