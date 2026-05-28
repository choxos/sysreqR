diagnose_patterns <- data.frame(
  pattern = c(
    "libxml/parser\\.h",
    "curl/curl\\.h",
    "openssl/ssl\\.h",
    "\\bgdal\\.h\\b",
    "\\bproj\\.h\\b",
    "udunits2\\.h",
    "harfbuzz/hb\\.h",
    "fribidi\\.h",
    "cannot find -lxml2",
    "cannot find -lcurl",
    "cannot find -lssl",
    "pkg-config.*not found|pkg-config was not found"
  ),
  system_package = c(
    "libxml2-dev",
    "libcurl4-openssl-dev",
    "libssl-dev",
    "libgdal-dev",
    "libproj-dev",
    "libudunits2-dev",
    "libharfbuzz-dev",
    "libfribidi-dev",
    "libxml2-dev",
    "libcurl4-openssl-dev",
    "libssl-dev",
    "pkg-config"
  ),
  confidence = c(
    rep("high", 11),
    "medium"
  ),
  stringsAsFactors = FALSE
)

#' Diagnose an R package installation log
#'
#' Scans an installation log for common compiler and linker errors and for
#' R-level "configuration failed" and "non-zero exit status" patterns, then
#' resolves those failed packages back to their system requirements.
#'
#' The function combines two paths:
#'
#' 1. Direct log-pattern matching against a curated list of header and
#'    linker error messages.
#' 2. Failed package extraction plus a back-end lookup of those package
#'    names.
#'
#' Confidence levels are `"high"` for direct pattern matches and pak/PPM
#' lookups, and `"medium"` for bundled fallback data and inferred package
#' requirements.
#'
#' @param path Path to an installation log.
#' @param text Log text. Used when `path` is `NULL`.
#' @param platform Platform specification accepted by [resolve_platform()].
#' @param backend One of `"auto"`, `"bundled"`, `"ppm"`, or `"pak"` for failed
#'   package lookup.
#' @param repo Repository name used by the PPM backend.
#' @param check_installed Whether to check installed system packages on the
#'   current host when possible.
#'
#' @return A `sysreqr_plan` with likely system package fixes.
#' @family diagnose
#' @export
#' @examples
#' log <- paste(
#'   "fatal error: libxml/parser.h: No such file or directory",
#'   "ERROR: configuration failed for package 'xml2'",
#'   sep = "\n"
#' )
#' plan <- diagnose_log(text = log, platform = "ubuntu-22.04")
#' plan
diagnose_log <- function(path = NULL, text = NULL, platform = NULL,
                         backend = c("auto", "bundled", "ppm", "pak"),
                         repo = "cran", check_installed = TRUE) {
  backend <- match.arg(backend)
  if (!is.null(path)) {
    text <- paste(readLines(path, warn = FALSE), collapse = "\n")
  }
  if (is.null(text) || !nzchar(text)) {
    stop("Provide `path` or non-empty `text`.", call. = FALSE)
  }

  platform <- resolve_platform(platform)
  failed_packages <- extract_failed_packages(text)
  direct_plan <- diagnose_direct_patterns(
    text = text,
    platform = platform,
    check_installed = check_installed
  )

  failed_plan <- diagnose_failed_packages(
    failed_packages,
    platform = platform,
    backend = backend,
    repo = repo,
    check_installed = check_installed
  )

  plan <- merge_sysreqr_plans(
    list(direct_plan, failed_plan),
    platform_info = platform,
    backend = "diagnose-log"
  )
  attr(plan, "failed_packages") <- failed_packages
  plan
}

#' Check the most recent install error for likely system requirements
#'
#' Convenience wrapper around [diagnose_log()]. When `text` is `NULL` (the
#' default), the most recent R error message is read from
#' `base::geterrmessage()`.
#'
#' @param text Error text. When `NULL`, the most recent R error message is
#'   used.
#' @inheritParams diagnose_log
#'
#' @return A `sysreqr_plan`.
#' @family diagnose
#' @export
#' @examples
#' check_error(
#'   text = "ERROR: configuration failed for package 'xml2'",
#'   platform = "ubuntu-22.04",
#'   backend = "bundled"
#' )
check_error <- function(text = NULL, platform = NULL,
                        backend = c("auto", "bundled", "ppm", "pak"),
                        repo = "cran", check_installed = TRUE) {
  if (is.null(text)) {
    text <- base::geterrmessage()
  }
  diagnose_log(
    text = text,
    platform = platform,
    backend = backend,
    repo = repo,
    check_installed = check_installed
  )
}

#' Diagnose failed R packages
#'
#' Resolves the system requirements for a set of R packages that the user
#' already knows failed to install. Useful when an install was attempted
#' outside R, or when the log was lost.
#'
#' @param packages R package names inferred from failed installation output.
#' @inheritParams diagnose_log
#'
#' @return A `sysreqr_plan`.
#' @family diagnose
#' @export
#' @examples
#' diagnose_failed_packages(
#'   c("xml2", "curl"),
#'   platform = "ubuntu-22.04",
#'   backend = "bundled"
#' )
diagnose_failed_packages <- function(packages, platform = NULL,
                                     backend = c("auto", "bundled", "ppm", "pak"),
                                     repo = "cran", check_installed = TRUE) {
  backend <- match.arg(backend)
  packages <- compact_chr(as.character(packages))
  platform <- resolve_platform(platform)
  if (!length(packages)) {
    plan <- new_sysreqr_plan(platform_info = platform, backend = "failed-package-lookup")
    attr(plan, "failed_packages") <- packages
    return(plan)
  }

  plan <- check_packages(
    packages,
    platform = platform,
    backend = backend,
    repo = repo,
    check_installed = check_installed
  )
  if (nrow(plan)) {
    plan$source <- "failed-package-lookup"
    plan$confidence <- "medium"
    plan$notes <- paste0(
      "Requirement inferred from failed R package `",
      plan$r_package,
      "` in install output. This may help if missing system libraries caused the failure."
    )
  }
  attr(plan, "backend") <- "failed-package-lookup"
  attr(plan, "failed_packages") <- packages
  plan
}

#' @rdname diagnose_log
#' @export
diagnose_install_log <- diagnose_log

diagnose_direct_patterns <- function(text, platform, check_installed = TRUE) {
  rows <- list()
  for (i in seq_len(nrow(diagnose_patterns))) {
    pat <- diagnose_patterns$pattern[[i]]
    if (!grepl(pat, text, ignore.case = TRUE, perl = TRUE)) {
      next
    }
    spkg <- diagnose_patterns$system_package[[i]]
    evidence <- extract_evidence(text, pat)
    rows[[length(rows) + 1]] <- data.frame(
      r_package = NA_character_,
      sysreq = NA_character_,
      system_package = spkg,
      install_script = install_script_for_package(spkg, platform),
      pre_install = NA_character_,
      post_install = NA_character_,
      platform = paste0(platform$distro, "-", platform$version),
      package_manager = platform$package_manager,
      installed = NA,
      source = "manual-log-pattern",
      confidence = diagnose_patterns$confidence[[i]],
      notes = paste0("Evidence: ", evidence),
      stringsAsFactors = FALSE
    )
  }

  data <- if (length(rows)) unique(do.call(rbind, rows)) else data.frame()
  plan <- new_sysreqr_plan(
    data,
    platform_info = platform,
    backend = "manual-log-pattern"
  )
  if (isTRUE(check_installed)) {
    plan <- add_installed_state(plan, platform)
  }
  plan
}

extract_evidence <- function(text, pattern) {
  lines <- strsplit(text, "\n", fixed = TRUE)[[1]]
  idx <- grep(pattern, lines, ignore.case = TRUE, perl = TRUE)
  if (!length(idx)) {
    return(pattern)
  }
  trimws(lines[[idx[[1]]]])
}

extract_failed_packages <- function(text) {
  text <- normalize_install_text(text)
  lines <- strsplit(text, "\n", fixed = TRUE)[[1]]

  packages <- c(
    extract_first_group(
      lines,
      "(?:ERROR:\\s*)?configuration failed for package ['\"]([^'\"]+)['\"]"
    ),
    extract_first_group(
      lines,
      "installation of package ['\"]([^'\"]+)['\"] had non-zero exit status"
    ),
    extract_dependency_failures(lines)
  )

  compact_chr(packages[is_simple_package_name(packages)])
}

normalize_install_text <- function(text) {
  text <- paste(text, collapse = "\n")
  text <- gsub("\u2018|\u2019|\u201A|\u201B", "'", text, perl = TRUE)
  text <- gsub("\u201C|\u201D|\u201E|\u201F", "\"", text, perl = TRUE)
  text
}

extract_first_group <- function(lines, pattern) {
  out <- character()
  for (line in lines) {
    match <- regexec(pattern, line, ignore.case = TRUE, perl = TRUE)
    values <- regmatches(line, match)[[1]]
    if (length(values) > 1L) {
      out <- c(out, values[[2L]])
    }
  }
  out
}

extract_dependency_failures <- function(lines) {
  out <- character()
  pattern <- paste0(
    "(?:ERROR:\\s*)?dependenc(?:y|ies)\\s+(.+?)\\s+",
    "(?:is|are) not available for package ['\"]([^'\"]+)['\"]"
  )

  for (line in lines) {
    match <- regexec(pattern, line, ignore.case = TRUE, perl = TRUE)
    values <- regmatches(line, match)[[1]]
    if (length(values) <= 1L) {
      next
    }

    deps <- gsub("['\"]", "", values[[2L]])
    deps <- gsub("\\band\\b", ",", deps, ignore.case = TRUE, perl = TRUE)
    out <- c(out, trimws(strsplit(deps, ",", fixed = TRUE)[[1]]))
  }

  out
}

merge_sysreqr_plans <- function(plans, platform_info, backend) {
  plans <- Filter(is_sysreqr_plan, plans)
  data <- lapply(plans, as_data_frame)
  data <- data[vapply(data, nrow, integer(1)) > 0L]
  data <- if (length(data)) {
    unique_plan_rows(do.call(rbind, data))
  } else {
    data.frame()
  }

  unresolved <- unique(compact_chr(
    unlist(lapply(plans, attr, "unresolved"), use.names = FALSE)
  ))

  plan <- new_sysreqr_plan(
    data,
    platform_info = platform_info,
    pre_install = unlist(lapply(plans, attr, "pre_install"), use.names = FALSE),
    post_install = unlist(lapply(plans, attr, "post_install"), use.names = FALSE),
    backend = backend
  )
  if (length(unresolved)) {
    attr(plan, "unresolved") <- unresolved
  }
  plan
}

unique_plan_rows <- function(data) {
  key <- paste(data$r_package, data$system_package, data$source, sep = "\r")
  data[!duplicated(key), , drop = FALSE]
}
