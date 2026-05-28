#' Check system requirements for R packages
#'
#' Resolves the system packages an R package needs on a given Linux platform
#' and returns them in a structured plan. The `"auto"` backend prefers the
#' offline bundled database on `apt` platforms, then Posit Package Manager,
#' then `pak`.
#'
#' @param packages Package names or package references.
#' @param platform Platform specification accepted by [resolve_platform()].
#' @param backend One of `"auto"`, `"bundled"`, `"ppm"`, or `"pak"`.
#' @param repo Repository name used in notes and by the PPM backend.
#' @param dependencies Dependency policy passed to `pak::pkg_sysreqs()` when the
#'   pak backend is used.
#' @param upgrade Upgrade policy passed to `pak::pkg_sysreqs()` when the pak
#'   backend is used.
#' @param check_installed Whether to check installed system packages on the
#'   current host when possible.
#'
#' @return A `sysreqr_plan`.
#' @family preflight
#' @seealso [check_project()], [check_library()], [diagnose_log()].
#' @export
#' @examples
#' plan <- check_packages(c("xml2", "curl"), platform = "ubuntu-22.04")
#' plan
#'
#' install_command(plan)
#'
#' \dontrun{
#' # Network-dependent: queries Posit Package Manager.
#' check_packages("xml2", platform = "ubuntu-22.04", backend = "ppm")
#' }
check_packages <- function(packages, platform = NULL,
                           backend = c("auto", "bundled", "ppm", "pak"),
                           repo = "cran", dependencies = NA,
                           upgrade = TRUE, check_installed = TRUE) {
  backend <- match.arg(backend)
  packages <- compact_chr(as.character(packages))
  if (!length(packages)) {
    stop("`packages` must contain at least one package name or reference.", call. = FALSE)
  }

  platform <- resolve_platform(platform)
  selected <- select_backend(packages, backend, platform)

  if (identical(selected, "bundled")) {
    plan <- bundled_sysreqs(packages, platform, repo = repo)
    if (isTRUE(check_installed)) {
      plan <- add_installed_state(plan, platform)
    }
    return(plan)
  }

  if (identical(selected, "ppm")) {
    return(tryCatch(
      ppm_sysreqs(
        packages = packages,
        all = FALSE,
        platform = platform,
        repo = repo,
        check_installed = check_installed
      ),
      error = function(e) {
        if (!identical(backend, "auto")) {
          stop(e)
        }
        check_packages_pak(
          packages = packages,
          platform = platform,
          dependencies = dependencies,
          upgrade = upgrade,
          check_installed = check_installed,
          fallback_error = e
        )
      }
    ))
  }

  check_packages_pak(
    packages = packages,
    platform = platform,
    dependencies = dependencies,
    upgrade = upgrade,
    check_installed = check_installed
  )
}

select_backend <- function(packages, backend, platform = NULL) {
  if (!identical(backend, "auto")) {
    return(backend)
  }

  apt_platform <- !is.null(platform) && identical(platform$package_manager, "apt")

  if (apt_platform && all(is_simple_package_name(packages)) && bundled_has_packages(packages)) {
    "bundled"
  } else if (all(is_simple_package_name(packages))) {
    "ppm"
  } else {
    "pak"
  }
}

check_packages_pak <- function(packages, platform, dependencies = NA,
                               upgrade = TRUE, check_installed = TRUE,
                               fallback_error = NULL) {
  sysreqs_platform <- paste0(platform$distro, "-", platform$version)
  res <- pak_pkg_sysreqs(
    pkg = packages,
    upgrade = upgrade,
    dependencies = dependencies,
    sysreqs_platform = sysreqs_platform
  )

  plan <- normalize_pak_sysreqs(res, platform)
  if (isTRUE(check_installed)) {
    plan <- add_installed_state(plan, platform)
  }

  if (!is.null(fallback_error)) {
    attr(plan, "fallback_error") <- conditionMessage(fallback_error)
  }

  plan
}

pak_pkg_sysreqs <- function(...) {
  mock <- getOption("sysreqr.pak_pkg_sysreqs", NULL)
  if (is.function(mock)) {
    return(mock(...))
  }
  if (!is_package_installed("pak")) {
    stop(
      paste(
        "The `pak` package is required for the pak backend.",
        "Install it with install.packages(\"pak\")."
      ),
      call. = FALSE
    )
  }
  getExportedValue("pak", "pkg_sysreqs")(...)
}

normalize_pak_sysreqs <- function(res, platform) {
  pkgs <- res$packages %||% data.frame()
  rows <- list()
  pre_all <- as_chr(res$pre_install)
  post_all <- as_chr(res$post_install)

  if (nrow(pkgs)) {
    for (i in seq_len(nrow(pkgs))) {
      sysreq <- pkgs$sysreq[[i]]
      r_packages <- as_chr(pkgs$packages[[i]])
      system_packages <- as_chr(pkgs$system_packages[[i]])
      pre <- as_chr(pkgs$pre_install[[i]])
      post <- as_chr(pkgs$post_install[[i]])
      pre_all <- c(pre_all, pre)
      post_all <- c(post_all, post)

      if (!length(r_packages)) {
        r_packages <- NA_character_
      }
      if (!length(system_packages)) {
        system_packages <- NA_character_
      }

      for (rpkg in r_packages) {
        for (spkg in system_packages) {
          rows[[length(rows) + 1]] <- data.frame(
            r_package = rpkg,
            sysreq = sysreq,
            system_package = spkg,
            install_script = install_script_for_package(spkg, platform),
            pre_install = paste(pre, collapse = "\n"),
            post_install = paste(post, collapse = "\n"),
            platform = paste0(platform$distro, "-", platform$version),
            package_manager = platform$package_manager,
            installed = NA,
            source = "pak",
            confidence = "high",
            notes = "Requirement reported by pak.",
            stringsAsFactors = FALSE
          )
        }
      }
    }
  }

  data <- if (length(rows)) do.call(rbind, rows) else data.frame()
  new_sysreqr_plan(
    data,
    platform_info = platform,
    pre_install = pre_all,
    post_install = post_all,
    backend = "pak"
  )
}

install_script_for_package <- function(system_package, platform) {
  if (is.na(system_package) || !nzchar(system_package)) {
    return(NA_character_)
  }

  pm <- platform$package_manager
  if (identical(pm, "apt")) {
    paste("apt-get install -y", system_package)
  } else if (identical(pm, "dnf")) {
    paste("dnf install -y", system_package)
  } else if (identical(pm, "yum")) {
    paste("yum install -y", system_package)
  } else if (identical(pm, "zypper")) {
    paste("zypper --non-interactive install", system_package)
  } else if (identical(pm, "apk")) {
    paste("apk add --no-cache", system_package)
  } else if (identical(pm, "brew")) {
    paste("brew install", system_package)
  } else {
    NA_character_
  }
}

#' Check system requirements for installed R packages
#'
#' Reads the package names from one or more R library paths and resolves
#' their system requirements. Useful for auditing an existing R installation.
#'
#' @param packages Optional installed R package names.
#' @param library Library path or paths.
#' @param platform Platform specification accepted by [resolve_platform()].
#' @param backend One of `"bundled"`, `"auto"`, `"ppm"`, or `"pak"`.
#'
#' @return A `sysreqr_plan`.
#' @family preflight
#' @export
#' @examples
#' \dontrun{
#' # Audits the default library:
#' check_library()
#' }
#'
#' # With an explicit package list (offline, bundled backend):
#' check_library(
#'   packages = c("xml2", "curl"),
#'   platform = "ubuntu-22.04",
#'   backend = "bundled"
#' )
check_library <- function(packages = NULL, library = .libPaths()[1],
                          platform = NULL,
                          backend = c("bundled", "auto", "ppm", "pak")) {
  backend <- match.arg(backend)
  if (is.null(packages)) {
    installed <- utils::installed.packages(lib.loc = library, noCache = TRUE)
    packages <- rownames(installed)
  }

  packages <- compact_chr(as.character(packages))
  if (!length(packages)) {
    stop("No installed packages were found to check.", call. = FALSE)
  }

  plan <- check_packages(
    packages = packages,
    platform = platform,
    backend = backend,
    check_installed = TRUE
  )
  attr(plan, "library") <- library
  plan
}
