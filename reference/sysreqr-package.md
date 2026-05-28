# sysreqr: Preflight Checks for R Package System Requirements

`sysreqr` helps users on Linux (and, where applicable, macOS) discover
the system packages they need before installing R packages from source.
It queries maintained system requirement sources, reports missing system
packages, and generates installation commands, Dockerfile snippets,
GitHub Actions steps, administrator request templates, and diagnostic
reports from failed installation logs.

## Details

The package has zero required dependencies. It uses only base R at run
time. `testthat`, `knitr`, `rmarkdown`, and `withr` are listed in
`Suggests` only for development needs (tests and vignettes); they are
never loaded when end users call package functions.

## Main entry points

- Preflight checks:
  [`check_packages()`](https://choxos.github.io/sysreqR/reference/check_packages.md),
  [`check_library()`](https://choxos.github.io/sysreqR/reference/check_library.md),
  [`check_project()`](https://choxos.github.io/sysreqR/reference/check_project.md),
  [`detect_project_packages()`](https://choxos.github.io/sysreqR/reference/detect_project_packages.md).

- Platform detection:
  [`detect_platform()`](https://choxos.github.io/sysreqR/reference/detect_platform.md),
  [`detect_package_manager()`](https://choxos.github.io/sysreqR/reference/detect_package_manager.md),
  [`resolve_platform()`](https://choxos.github.io/sysreqR/reference/resolve_platform.md).

- Output generators:
  [`install_command()`](https://choxos.github.io/sysreqR/reference/install_command.md),
  [`dockerfile()`](https://choxos.github.io/sysreqR/reference/dockerfile.md),
  [`github_actions()`](https://choxos.github.io/sysreqR/reference/github_actions.md),
  [`admin_request()`](https://choxos.github.io/sysreqR/reference/admin_request.md).

- Diagnostics:
  [`diagnose_log()`](https://choxos.github.io/sysreqR/reference/diagnose_log.md),
  [`check_error()`](https://choxos.github.io/sysreqR/reference/check_error.md),
  [`diagnose_failed_packages()`](https://choxos.github.io/sysreqR/reference/diagnose_failed_packages.md).

- Posit Package Manager:
  [`ppm_platforms()`](https://choxos.github.io/sysreqR/reference/ppm_platforms.md),
  [`check_ppm()`](https://choxos.github.io/sysreqR/reference/check_ppm.md),
  [`ppm_repo()`](https://choxos.github.io/sysreqR/reference/ppm_repo.md),
  [`ppm_sysreqs()`](https://choxos.github.io/sysreqR/reference/ppm_sysreqs.md),
  [`use_ppm()`](https://choxos.github.io/sysreqR/reference/use_ppm.md).

- Setup advice:
  [`setup_advice()`](https://choxos.github.io/sysreqR/reference/setup_advice.md),
  [`explain()`](https://choxos.github.io/sysreqR/reference/explain.md).

- File writers:
  [`write_json()`](https://choxos.github.io/sysreqR/reference/write_json.md),
  [`write_report()`](https://choxos.github.io/sysreqR/reference/write_report.md),
  [`write_install_script()`](https://choxos.github.io/sysreqR/reference/write_install_script.md),
  [`write_dockerfile_snippet()`](https://choxos.github.io/sysreqR/reference/write_dockerfile_snippet.md),
  [`as_install_plan()`](https://choxos.github.io/sysreqR/reference/as_install_plan.md).

## Package options

The following options influence behavior. Set them with
[`options()`](https://rdrr.io/r/base/options.html) or in `.Rprofile`.

- `sysreqr.ppm_base_url`:

  Posit Package Manager base URL. Defaults to
  `"https://packagemanager.posit.co"`.

- `sysreqr.ppm_get`:

  Optional function used in place of the PPM HTTP client. Mainly for
  tests.

- `sysreqr.pak_pkg_sysreqs`:

  Optional function used in place of
  [`pak::pkg_sysreqs()`](https://pak.r-lib.org/reference/pkg_sysreqs.html).
  Mainly for tests.

- `sysreqr.installed_system_packages`:

  Optional character vector or named logical vector used to override
  installed-package detection. Mainly for tests.

- `sysreqr.timeout`:

  Numeric timeout (seconds) for Posit Package Manager HTTP calls.
  Defaults to the larger of `getOption("timeout")` and `60`.

## Learning more

See
[`vignette("preflight-setup", package = "sysreqr")`](https://choxos.github.io/sysreqR/articles/preflight-setup.md)
for a beginner workflow,
[`vignette("diagnosing-failures", package = "sysreqr")`](https://choxos.github.io/sysreqR/articles/diagnosing-failures.md)
for log diagnosis,
[`vignette("linux-fundamentals", package = "sysreqr")`](https://choxos.github.io/sysreqR/articles/linux-fundamentals.md)
for a GNU/Linux primer,
[`vignette("docker-and-ci", package = "sysreqr")`](https://choxos.github.io/sysreqR/articles/docker-and-ci.md)
for container and CI workflows, and
[`vignette("faq", package = "sysreqr")`](https://choxos.github.io/sysreqR/articles/faq.md)
for common questions.

## See also

Useful links:

- <https://github.com/choxos/sysreqR>

- Report bugs at <https://github.com/choxos/sysreqR/issues>

## Author

**Maintainer**: Ahmad Sofi-Mahmudi <a.sofimahmudi@gmail.com>
([ORCID](https://orcid.org/0000-0001-6829-0823))

Authors:

- Ahmad Sofi-Mahmudi <a.sofimahmudi@gmail.com>
  ([ORCID](https://orcid.org/0000-0001-6829-0823))
