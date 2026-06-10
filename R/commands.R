#' Generate an installation command
#'
#' Translates a plan (or a package vector that can be resolved to a plan) into
#' shell commands appropriate for the platform's package manager.
#'
#' @param x A `sysreqr_plan` or package vector.
#' @param platform Platform specification accepted by [resolve_platform()].
#' @param sudo Whether to prefix commands with `sudo`.
#' @param update Whether to include the package manager update command when
#'   appropriate.
#' @param missing_only Whether to include only packages not known to be
#'   installed.
#' @param ... Passed to [check_packages()] when `x` is not a plan.
#'
#' @return A character vector of shell commands.
#' @family commands
#' @export
#' @examples
#' plan <- check_packages(c("xml2", "curl"), platform = "ubuntu-22.04")
#' install_command(plan)
#' install_command(plan, sudo = FALSE, update = FALSE)
install_command <- function(x, platform = NULL, sudo = TRUE, update = TRUE,
                            missing_only = TRUE, ...) {
  plan <- ensure_plan(x, platform = platform, ...)
  platform <- attr(plan, "platform_info") %||% resolve_platform(platform)
  pkgs <- plan_system_packages(plan, missing_only = missing_only)
  pre <- attr(plan, "pre_install") %||% character()
  post <- attr(plan, "post_install") %||% character()

  install <- install_command_for_packages(pkgs, platform)
  commands <- c(pre, install, post)
  if (isTRUE(update) && length(install)) {
    commands <- c(update_command(platform), commands)
  }

  commands <- compact_chr(commands)
  if (isTRUE(sudo)) {
    commands <- add_sudo(commands)
  }
  unname(commands)
}

ensure_plan <- function(x, platform = NULL, ...) {
  if (is_sysreqr_plan(x)) {
    x
  } else {
    check_packages(x, platform = platform, ...)
  }
}

update_command <- function(platform) {
  pm <- platform$package_manager
  if (identical(pm, "apt")) {
    "apt-get update"
  } else {
    character()
  }
}

install_command_for_packages <- function(pkgs, platform) {
  pkgs <- compact_chr(pkgs)
  pkgs <- sanitize_system_package_names(pkgs)
  if (!length(pkgs)) {
    return(character())
  }

  pm <- platform$package_manager
  if (identical(pm, "apt")) {
    paste("apt-get install -y", paste(pkgs, collapse = " "))
  } else if (identical(pm, "dnf")) {
    paste("dnf install -y", paste(pkgs, collapse = " "))
  } else if (identical(pm, "yum")) {
    paste("yum install -y", paste(pkgs, collapse = " "))
  } else if (identical(pm, "zypper")) {
    paste("zypper --non-interactive install", paste(pkgs, collapse = " "))
  } else if (identical(pm, "apk")) {
    paste("apk add --no-cache", paste(pkgs, collapse = " "))
  } else if (identical(pm, "brew")) {
    paste("brew install", paste(pkgs, collapse = " "))
  } else {
    character()
  }
}

# System package names come from external metadata (Package Manager, pak).
# Only names made of the characters used by real apt/dnf/zypper/apk/brew
# packages are allowed into generated shell lines; anything else is dropped
# with a warning rather than pasted into a command.
sanitize_system_package_names <- function(pkgs) {
  ok <- grepl("^[A-Za-z0-9][A-Za-z0-9._+:@-]*$", pkgs)
  if (any(!ok)) {
    warning(
      "Dropping system package names with unexpected characters: ",
      paste(pkgs[!ok], collapse = ", "),
      call. = FALSE
    )
  }
  pkgs[ok]
}

add_sudo <- function(commands) {
  vapply(commands, add_sudo_one, character(1), USE.NAMES = FALSE)
}

add_sudo_one <- function(cmd) {
  if (grepl("^sudo\\b", cmd)) {
    return(cmd)
  }
  # Compound shell constructs (pipes, redirects, command separators, command
  # substitution) cannot be safely prefixed: `sudo curl | sh` would run curl
  # as root and sh as the current user. Leave such commands as-is and trust
  # the upstream metadata to apply sudo where it intends to.
  if (grepl("[|;&<>`]|\\$\\(", cmd)) {
    return(cmd)
  }
  # Known privileged operations: prefix with sudo.
  if (grepl(paste0(
    "^(apt|apt-get|dnf|yum|zypper|apk|dpkg|rpm|snap|",
    "add-apt-repository|update-alternatives|systemctl)\\b"
  ), cmd)) {
    return(paste("sudo", cmd))
  }
  # Default: leave unchanged. Includes user-level tools (brew, R CMD, curl,
  # wget) and anything else not on the allow-list.
  cmd
}

#' Generate Dockerfile lines
#'
#' Produces a Dockerfile `RUN` snippet that installs the system packages a
#' plan needs. On `apt` platforms the output uses the standard
#' `apt-get update && apt-get install -y --no-install-recommends ... && rm -rf
#' /var/lib/apt/lists/*` pattern.
#'
#' @param x A `sysreqr_plan` or package vector.
#' @param platform Platform specification accepted by [resolve_platform()].
#' @param missing_only Whether to include only packages not known to be
#'   installed.
#' @param ... Passed to [check_packages()] when `x` is not a plan.
#'
#' @return A single Dockerfile snippet.
#' @family commands
#' @export
#' @examples
#' plan <- check_packages("xml2", platform = "ubuntu-22.04")
#' cat(dockerfile(plan))
dockerfile <- function(x, platform = NULL, missing_only = TRUE, ...) {
  plan <- ensure_plan(x, platform = platform, ...)
  platform <- attr(plan, "platform_info") %||% resolve_platform(platform)
  pkgs <- plan_system_packages(plan, missing_only = missing_only)
  pkgs <- sanitize_system_package_names(pkgs)

  if (!length(pkgs)) {
    return("# No external system requirements detected")
  }

  if (!identical(platform$package_manager, "apt")) {
    return(paste(c("RUN", install_command(plan, sudo = FALSE, update = FALSE)), collapse = " "))
  }

  paste(
    c(
      "RUN apt-get update && apt-get install -y --no-install-recommends \\",
      paste0("    ", pkgs, " \\"),
      "    && rm -rf /var/lib/apt/lists/*"
    ),
    collapse = "\n"
  )
}

#' Generate a GitHub Actions snippet
#'
#' Produces a GitHub Actions YAML step that installs the system packages a
#' plan needs. `gha()` is a short alias.
#'
#' @param x A `sysreqr_plan` or package vector.
#' @param platform Platform specification accepted by [resolve_platform()].
#' @param missing_only Whether to include only packages not known to be
#'   installed.
#' @param ... Passed to [check_packages()] when `x` is not a plan.
#'
#' @return A YAML snippet.
#' @family commands
#' @export
#' @examples
#' plan <- check_packages("xml2", platform = "ubuntu-22.04")
#' cat(github_actions(plan))
#' identical(gha(plan), github_actions(plan))
github_actions <- function(x, platform = NULL, missing_only = TRUE, ...) {
  plan <- ensure_plan(x, platform = platform, ...)
  commands <- install_command(plan, sudo = TRUE, update = TRUE, missing_only = missing_only)

  if (!length(commands)) {
    return(paste(
      "- name: Install Linux system dependencies",
      "  run: echo \"No external system requirements detected\"",
      sep = "\n"
    ))
  }

  paste(
    c(
      "- name: Install Linux system dependencies",
      "  run: |",
      paste0("    ", commands)
    ),
    collapse = "\n"
  )
}

#' @rdname github_actions
#' @export
gha <- github_actions

#' Generate a GitLab CI snippet
#'
#' Produces a GitLab CI YAML job that installs the system packages a plan
#' needs. GitLab CI jobs usually run as root inside a container image, so
#' the commands are emitted without `sudo`.
#'
#' @param x A `sysreqr_plan` or package vector.
#' @param platform Platform specification accepted by [resolve_platform()].
#' @param job Name of the generated CI job.
#' @param missing_only Whether to include only packages not known to be
#'   installed.
#' @param ... Passed to [check_packages()] when `x` is not a plan.
#'
#' @return A YAML snippet.
#' @family commands
#' @export
#' @examples
#' plan <- check_packages("xml2", platform = "ubuntu-22.04", backend = "bundled")
#' cat(gitlab_ci(plan))
gitlab_ci <- function(x, platform = NULL, job = "install_system_requirements",
                      missing_only = TRUE, ...) {
  plan <- ensure_plan(x, platform = platform, ...)
  commands <- install_command(plan, sudo = FALSE, update = TRUE, missing_only = missing_only)

  if (!length(commands)) {
    commands <- "echo \"No external system requirements detected\""
  }

  paste(
    c(
      paste0(job, ":"),
      "  script:",
      paste0("    - ", commands)
    ),
    collapse = "\n"
  )
}

#' Create an administrator request
#'
#' Produces a plain-text message that a user without root access can send to
#' their system administrator. The message lists missing system packages,
#' which R packages need them, and a suggested install command.
#'
#' @param x A `sysreqr_plan` or package vector.
#' @param platform Platform specification accepted by [resolve_platform()].
#' @param ... Passed to [check_packages()] when `x` is not a plan.
#'
#' @return A plain-text administrator request.
#' @family commands
#' @export
#' @examples
#' plan <- check_packages("xml2", platform = "ubuntu-22.04")
#' cat(admin_request(plan))
admin_request <- function(x, platform = NULL, ...) {
  plan <- ensure_plan(x, platform = platform, ...)
  pkgs <- plan_system_packages(plan, missing_only = TRUE)
  rpkgs <- compact_chr(plan$r_package)
  commands <- install_command(plan, sudo = TRUE, update = TRUE, missing_only = TRUE)

  if (!length(pkgs)) {
    return(paste(
      c(
        "Hello,",
        "",
        "No missing system packages were detected for this sysreqr plan.",
        "No administrator action is needed.",
        "",
        "Thank you."
      ),
      collapse = "\n"
    ))
  }

  paste(
    c(
      "Hello,",
      "",
      "Could you please install the following system packages on this server?",
      "",
      pkgs,
      "",
      "They are required to install or use these R packages:",
      paste(rpkgs, collapse = ", "),
      "",
      "Suggested command:",
      commands,
      "",
      "Thank you."
    ),
    collapse = "\n"
  )
}
