# Contributing to sysreqR

Thank you for considering a contribution to sysreqR. The package is
designed to help R users diagnose and resolve system requirement
problems without changing their operating system state unexpectedly.

## Ways to Contribute

Useful contributions include:

- bug reports with the R package name, platform, and error output;
- corrections to system requirement mappings;
- improvements to GNU/Linux setup guidance;
- documentation improvements for new R or GNU/Linux users;
- tests for edge cases in package detection, command generation, and log
  diagnosis.

## Before Opening an Issue

Please include:

- your operating system and version;
- your R version;
- the sysreqR version;
- the R package or project you checked;
- the command you ran;
- the output or error message.

Do not include private logs, tokens, internal hostnames, or credentials.

## Development Setup

Clone the repository and install the suggested development packages:

``` r

install.packages(c("testthat", "knitr", "rmarkdown", "withr", "lintr", "roxygen2"))
```

The package has no required runtime dependencies beyond base R.

## Local Checks

Before opening a pull request, run:

``` sh
Rscript -e 'testthat::test_local(".", reporter = testthat::SummaryReporter$new())'
Rscript -e 'lintr::lint_package()'
R CMD build .
R CMD check --as-cran sysreqr_*.tar.gz
```

Tests should be offline and mock-based. Do not add tests that install
system packages, edit user configuration files, write to the home
directory, or require network access unless the behavior is explicitly
mocked.

## Documentation

If you change exported functions or examples, regenerate documentation
with:

``` r

roxygen2::roxygenise()
```

Examples that write files should use
[`tempdir()`](https://rdrr.io/r/base/tempfile.html) or
[`tempfile()`](https://rdrr.io/r/base/tempfile.html). Examples that
would edit a user’s environment should be dry runs or clearly
non-executed.

## Pull Requests

Pull requests should:

- describe the user-facing problem and the fix;
- include tests for behavior changes when practical;
- keep dependency additions out unless they are essential;
- avoid unrelated formatting or refactoring;
- update README, NEWS, or vignettes when user-facing behavior changes.
