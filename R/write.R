#' Write a sysreqr plan as JSON
#'
#' Serializes the plan data frame to JSON.
#'
#' @param plan A `sysreqr_plan`.
#' @param path Output path.
#'
#' @return `path`, invisibly.
#' @family output
#' @export
#' @examples
#' plan <- check_packages("xml2", platform = "ubuntu-22.04")
#' write_json(plan, file.path(tempdir(), "sysreqs.json"))
write_json <- function(plan, path) {
  plan <- ensure_plan(plan)
  json_write(as_data_frame(plan), path)
  invisible(path)
}

#' Write a Markdown report
#'
#' Produces a human-readable Markdown report describing the platform,
#' selected backend, R packages checked, system packages needed, and a
#' suggested install command.
#'
#' @param plan A `sysreqr_plan`.
#' @param path Output path.
#'
#' @return `path`, invisibly.
#' @family output
#' @export
#' @examples
#' plan <- check_packages("xml2", platform = "ubuntu-22.04")
#' write_report(plan, file.path(tempdir(), "SYSREQS.md"))
write_report <- function(plan, path = "SYSREQS.md") {
  plan <- ensure_plan(plan)
  pkgs <- plan_system_packages(plan, missing_only = TRUE)
  rpkgs <- compact_chr(plan$r_package)
  commands <- install_command(plan, sudo = TRUE, update = TRUE)

  lines <- c(
    "# System Requirements Report",
    "",
    paste0("Platform: ", platform_label(attr(plan, "platform_info"))),
    paste0("Backend: ", attr(plan, "backend") %||% "unknown"),
    "",
    "## R Packages",
    "",
    if (length(rpkgs)) paste0("- ", rpkgs) else "- None detected",
    "",
    "## System Packages",
    "",
    if (length(pkgs)) paste0("- ", pkgs) else "- No external system packages detected",
    "",
    "## Install Command",
    "",
    "```sh",
    commands,
    "```"
  )

  writeLines(lines, path)
  invisible(path)
}

#' Write an install script
#'
#' Writes a POSIX-shell install script. The script begins with
#' `#!/usr/bin/env sh` and `set -eu` and is marked executable.
#'
#' @param plan A `sysreqr_plan`.
#' @param path Output path.
#'
#' @return `path`, invisibly.
#' @family output
#' @export
#' @examples
#' plan <- check_packages("xml2", platform = "ubuntu-22.04")
#' write_install_script(plan, file.path(tempdir(), "install-sysreqs.sh"))
write_install_script <- function(plan, path = "install-sysreqs.sh") {
  plan <- ensure_plan(plan)
  commands <- install_command(plan, sudo = TRUE)
  if (!length(commands)) {
    commands <- "printf \"%s\\n\" \"No external system requirements detected\""
  }
  lines <- c(
    "#!/usr/bin/env sh",
    "set -eu",
    "",
    commands
  )
  writeLines(lines, path)
  Sys.chmod(path, mode = "0755")
  invisible(path)
}

#' Write a Dockerfile snippet
#'
#' Writes the output of [dockerfile()] to a file so it can be appended to an
#' existing Dockerfile or included verbatim.
#'
#' @param plan A `sysreqr_plan`.
#' @param path Output path.
#'
#' @return `path`, invisibly.
#' @family output
#' @export
#' @examples
#' plan <- check_packages("xml2", platform = "ubuntu-22.04")
#' write_dockerfile_snippet(plan, file.path(tempdir(), "Dockerfile.sysreqs"))
write_dockerfile_snippet <- function(plan, path = "Dockerfile.sysreqs") {
  plan <- ensure_plan(plan)
  writeLines(dockerfile(plan), path)
  invisible(path)
}

#' Return backend install plan data
#'
#' Converts a plan into a structured list suitable for downstream tooling
#' (other R code, deployment scripts, or CI). The fields are `platform`,
#' `backend`, `pre_install`, `install`, `post_install`, and `packages`.
#'
#' @param x A `sysreqr_plan`.
#'
#' @return A list with commands and plan data.
#' @family output
#' @export
#' @examples
#' plan <- check_packages("xml2", platform = "ubuntu-22.04")
#' as_install_plan(plan)
as_install_plan <- function(x) {
  plan <- ensure_plan(x)
  list(
    platform = attr(plan, "platform_info"),
    backend = attr(plan, "backend"),
    pre_install = attr(plan, "pre_install"),
    install = install_command(plan, sudo = FALSE),
    post_install = attr(plan, "post_install"),
    packages = as_data_frame(plan)
  )
}
