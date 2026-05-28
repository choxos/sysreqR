#' sysreqr: Preflight Checks for R Package System Requirements
#'
#' `sysreqr` helps users on Linux (and, where applicable, macOS) discover the
#' system packages they need before installing R packages from source. It
#' queries maintained system requirement sources, reports missing system
#' packages, and generates installation commands, Dockerfile snippets, GitHub
#' Actions steps, administrator request templates, and diagnostic reports from
#' failed installation logs.
#'
#' The package has zero required dependencies. It uses only base R at run
#' time. `testthat`, `knitr`, `rmarkdown`, and `withr` are listed in
#' `Suggests` only for development needs (tests and vignettes); they are
#' never loaded when end users call package functions.
#'
#' @section Main entry points:
#' * Preflight checks: [check_packages()], [check_library()], [check_project()],
#'   [detect_project_packages()].
#' * Platform detection: [detect_platform()], [detect_package_manager()],
#'   [resolve_platform()].
#' * Output generators: [install_command()], [dockerfile()], [github_actions()],
#'   [admin_request()].
#' * Diagnostics: [diagnose_log()], [check_error()], [diagnose_failed_packages()].
#' * Posit Package Manager: [ppm_platforms()], [check_ppm()], [ppm_repo()],
#'   [ppm_sysreqs()], [use_ppm()].
#' * Setup advice: [setup_advice()], [explain()].
#' * File writers: [write_json()], [write_report()], [write_install_script()],
#'   [write_dockerfile_snippet()], [as_install_plan()].
#'
#' @section Package options:
#' The following options influence behavior. Set them with `options()` or in
#' `.Rprofile`.
#' \describe{
#'   \item{`sysreqr.ppm_base_url`}{Posit Package Manager base URL. Defaults to
#'     `"https://packagemanager.posit.co"`.}
#'   \item{`sysreqr.ppm_get`}{Optional function used in place of the PPM HTTP
#'     client. Mainly for tests.}
#'   \item{`sysreqr.pak_pkg_sysreqs`}{Optional function used in place of
#'     `pak::pkg_sysreqs()`. Mainly for tests.}
#'   \item{`sysreqr.installed_system_packages`}{Optional character vector or
#'     named logical vector used to override installed-package detection.
#'     Mainly for tests.}
#'   \item{`sysreqr.timeout`}{Numeric timeout (seconds) for Posit Package
#'     Manager HTTP calls. Defaults to the larger of `getOption("timeout")`
#'     and `60`.}
#' }
#'
#' @section Learning more:
#' See `vignette("preflight-setup", package = "sysreqr")` for a beginner
#' workflow, `vignette("diagnosing-failures", package = "sysreqr")` for log
#' diagnosis, `vignette("linux-fundamentals", package = "sysreqr")` for a
#' GNU/Linux primer, `vignette("docker-and-ci", package = "sysreqr")` for
#' container and CI workflows, and `vignette("faq", package = "sysreqr")` for
#' common questions.
#'
#' @keywords internal
"_PACKAGE"
