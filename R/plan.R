#' Test whether an object is a sysreqr plan
#'
#' @param x An object.
#'
#' @return `TRUE` if `x` inherits from `"sysreqr_plan"`.
#' @family plan
#' @export
#' @examples
#' plan <- check_packages("xml2", platform = "ubuntu-22.04")
#' is_sysreqr_plan(plan)
#' is_sysreqr_plan(data.frame(x = 1))
is_sysreqr_plan <- function(x) {
  inherits(x, "sysreqr_plan")
}

new_sysreqr_plan <- function(data = NULL, platform_info = NULL,
                             pre_install = character(),
                             post_install = character(),
                             backend = NA_character_) {
  cols <- plan_columns()

  if (is.null(data)) {
    data <- data.frame()
  }

  data <- as.data.frame(data, stringsAsFactors = FALSE)
  for (col in cols) {
    if (!col %in% names(data)) {
      data[[col]] <- default_plan_column(col, nrow(data))
    }
  }
  data <- data[, cols]

  data$installed <- as.logical(data$installed)
  data$confidence <- ifelse(
    is.na(data$confidence) | !nzchar(data$confidence),
    "high",
    data$confidence
  )
  row.names(data) <- NULL

  class(data) <- c("sysreqr_plan", "data.frame")
  attr(data, "platform_info") <- platform_info
  attr(data, "pre_install") <- compact_chr(pre_install)
  attr(data, "post_install") <- compact_chr(post_install)
  attr(data, "backend") <- backend
  attr(data, "created_at") <- Sys.time()
  data
}

plan_columns <- function() {
  c(
    "r_package", "sysreq", "system_package", "install_script",
    "pre_install", "post_install", "platform", "package_manager",
    "installed", "source", "confidence", "notes"
  )
}

default_plan_column <- function(col, n) {
  if (identical(col, "installed")) {
    rep(NA, n)
  } else {
    rep(NA_character_, n)
  }
}

#' Coerce a plan to a plain data frame
#'
#' Strips the `sysreqr_plan` class and attributes, returning a plain
#' `data.frame`. Equivalent to `as.data.frame()` on a plan, but provided as a
#' verb form for users who prefer that style.
#'
#' @param x A `sysreqr_plan`.
#'
#' @return A data frame without the `sysreqr_plan` class.
#' @family plan
#' @export
#' @examples
#' plan <- check_packages("xml2", platform = "ubuntu-22.04")
#' df <- as_data_frame(plan)
#' inherits(df, "sysreqr_plan")
#' inherits(df, "data.frame")
as_data_frame <- function(x) {
  if (!is_sysreqr_plan(x)) {
    return(as.data.frame(x, stringsAsFactors = FALSE))
  }

  class(x) <- setdiff(class(x), "sysreqr_plan")
  as.data.frame(x, stringsAsFactors = FALSE)
}

#' @export
as.data.frame.sysreqr_plan <- function(x, row.names = NULL, optional = FALSE, ...) {
  class(x) <- setdiff(class(x), "sysreqr_plan")
  as.data.frame(x, row.names = row.names, optional = optional, ...)
}

#' @export
`[.sysreqr_plan` <- function(x, i, j, drop = FALSE) {
  attrs <- attributes(x)
  class(x) <- setdiff(class(x), "sysreqr_plan")
  out <- NextMethod("[")
  if (inherits(out, "data.frame") && !drop && all(plan_columns() %in% names(out))) {
    class(out) <- unique(c("sysreqr_plan", class(out)))
    attr(out, "platform_info") <- attrs$platform_info
    attr(out, "pre_install") <- attrs$pre_install
    attr(out, "post_install") <- attrs$post_install
    attr(out, "backend") <- attrs$backend
    attr(out, "created_at") <- attrs$created_at
    attr(out, "unresolved") <- attrs$unresolved
  }
  out
}

#' Print a sysreqr plan
#'
#' @param x A `sysreqr_plan`.
#' @param ... Unused.
#'
#' @return `x`, invisibly.
#' @family plan
#' @export
print.sysreqr_plan <- function(x, ...) {
  platform <- attr(x, "platform_info")
  backend <- attr(x, "backend") %||% "unknown"

  cat("System requirement preflight\n\n")
  cat("Platform: ", platform_label(platform), "\n", sep = "")
  cat("Package manager: ", platform$package_manager %||% "unknown", "\n", sep = "")
  cat("Backend: ", backend, "\n\n", sep = "")

  unresolved <- attr(x, "unresolved")

  if (!nrow(x)) {
    cat("No external system requirements were detected.\n")
    if (length(unresolved)) {
      cat(unresolved_note(unresolved, backend))
    }
    return(invisible(x))
  }

  packages <- compact_chr(x$r_package)
  if (length(packages)) {
    cat("R packages checked:\n")
    cat("  ", paste(packages, collapse = ", "), "\n\n", sep = "")
  }

  rows <- unique(as_data_frame(x)[, c("system_package", "installed")])
  rows <- rows[!is.na(rows$system_package) & nzchar(rows$system_package), , drop = FALSE]

  if (!nrow(rows)) {
    cat("No installable system packages were detected.\n")
  } else {
    missing <- is.na(rows$installed) | !rows$installed
    title <- if (any(missing)) "System packages to install:" else "System packages:"
    cat(title, "\n")
    for (pkg in rows$system_package) {
      needed_by <- compact_chr(x$r_package[x$system_package == pkg])
      status <- x$installed[match(pkg, x$system_package)]
      mark <- if (isTRUE(status)) "installed" else if (isFALSE(status)) "missing" else "unknown"
      cat("  ", pkg, "  needed by: ", paste(needed_by, collapse = ", "),
          "  status: ", mark, "\n", sep = "")
    }
  }

  cmd <- install_command(x, missing_only = TRUE)
  if (length(cmd)) {
    cat("\nRun:\n")
    cat(paste0("  ", cmd), sep = "\n")
    cat("\n")
  }

  if (length(unresolved)) {
    cat(unresolved_note(unresolved, backend))
  }

  invisible(x)
}

unresolved_note <- function(unresolved, backend) {
  pkgs <- paste(unresolved, collapse = ", ")
  if (identical(backend, "diagnose-log")) {
    paste0(
      "\nNote: no system requirement data was found for the failed package(s): ",
      pkgs, ".\n",
      "Try backend = \"ppm\" or backend = \"pak\" for live metadata, or ",
      "inspect the install log manually.\n"
    )
  } else {
    paste0(
      "\nNote: no bundled data was found for: ", pkgs, ".\n",
      "Try backend = \"ppm\" or backend = \"pak\" for live metadata.\n"
    )
  }
}

plan_system_packages <- function(plan, missing_only = TRUE) {
  if (!is_sysreqr_plan(plan)) {
    stop("Expected a `sysreqr_plan`.", call. = FALSE)
  }

  pkgs <- plan$system_package
  keep <- !is.na(pkgs) & nzchar(pkgs)
  if (missing_only) {
    keep <- keep & (is.na(plan$installed) | !plan$installed)
  }
  compact_chr(pkgs[keep])
}

add_installed_state <- function(plan, platform) {
  pkgs <- compact_chr(plan$system_package)
  if (!length(pkgs)) {
    return(plan)
  }

  installed <- check_system_packages(pkgs, platform)
  if (!length(installed)) {
    return(plan)
  }

  map <- stats::setNames(installed, pkgs)
  plan$installed <- unname(map[plan$system_package])
  plan
}

check_system_packages <- function(packages, platform = NULL) {
  packages <- compact_chr(packages)
  if (!length(packages)) {
    return(logical())
  }

  mock <- getOption("sysreqr.installed_system_packages", NULL)
  if (!is.null(mock)) {
    if (is.logical(mock) && !is.null(names(mock))) {
      return(unname(mock[packages]))
    }
    return(packages %in% as.character(mock))
  }

  platform <- resolve_platform(platform)
  if (!platform_matches_current(platform)) {
    return(stats::setNames(rep(NA, length(packages)), packages))
  }

  installed <- list_installed_system_packages(platform)
  if (!length(installed)) {
    return(stats::setNames(rep(NA, length(packages)), packages))
  }

  stats::setNames(packages %in% installed, packages)
}

list_installed_system_packages <- function(platform = NULL) {
  platform <- resolve_platform(platform)
  pm <- platform$package_manager

  # Format arguments contain shell metacharacters ($, newline). system2()
  # on Unix joins args without per-argument shell quoting, so the shell
  # would otherwise expand ${Package} to empty and a literal newline in
  # the arg would break the 2>/dev/null redirect. shQuote keeps the
  # tokens intact when passed through the shell.
  out <- tryCatch({
    if (identical(pm, "apt") && nzchar(Sys.which("dpkg-query"))) {
      system2(
        "dpkg-query",
        c("-W", shQuote("-f=${Package}\n")),
        stdout = TRUE, stderr = FALSE
      )
    } else if (pm %in% c("dnf", "yum", "zypper") && nzchar(Sys.which("rpm"))) {
      system2(
        "rpm",
        c("-qa", "--qf", shQuote("%{NAME}\n")),
        stdout = TRUE, stderr = FALSE
      )
    } else if (identical(pm, "brew") && nzchar(Sys.which("brew"))) {
      system2("brew", "list", stdout = TRUE, stderr = FALSE)
    } else {
      character()
    }
  }, error = function(e) character())

  compact_chr(out)
}
