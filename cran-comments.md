## Resubmission

This is a resubmission addressing the points raised by Konstanze Lauseker.

* **Single-quoted software names in DESCRIPTION.** The Title and Description
  now wrap 'R', 'Linux', 'macOS', 'Dockerfile', and 'GitHub Actions' in single
  quotes where they refer to software names.

* **Examples no longer use `\dontrun{}`.** Offline examples are now executed
  directly; examples that build a small project write only to `tempdir()`.
  The three functions that require the live Posit Package Manager service
  (`ppm_platforms()`, `check_ppm()`, `ppm_sysreqs()`) use `\donttest{}`.

* **No writing to the home filespace or working directory by default.**
  `write_report()`, `write_install_script()`, and `write_dockerfile_snippet()`
  no longer have a default `path`; the caller must supply one. `use_ppm()` also
  requires an explicit `path` when `dry_run = FALSE`. All examples, tests, and
  vignettes write only to `tempdir()` or are not evaluated.

* **No package installation in functions, examples, or vignettes.** The
  illustrative package installation command in a vignette has been replaced
  with a placeholder project script.

* **`installed.packages()` removed.** `check_library()` now uses
  `.packages(all.available = TRUE, lib.loc = library)` to list installed
  packages, per the `installed.packages()` help page recommendation.

## Test environments

* Local macOS, R 4.6.0
* GitHub Actions: ubuntu-latest (R-devel, R-release, R-oldrel-1),
  macos-latest (R-release), windows-latest (R-release)

## R CMD check results

0 errors | 0 warnings | 1 NOTE.

The only NOTE is the expected:

* New submission

## Dependencies

`sysreqr` has no Imports and no Depends beyond base R. Suggests lists only
testthat, knitr, rmarkdown, and withr, used for tests and vignettes; none are
loaded at runtime. Two optional integrations (Posit Package Manager over HTTPS
and pak::pkg_sysreqs()) are detected at runtime and are never required. Tests
are offline and mock-based.
