#' Detect R packages used by a project
#'
#' Inspects a project directory for the R packages it uses. The detection
#' priority is:
#'
#' 1. `renv.lock` (the `Packages` map),
#' 2. `DESCRIPTION` (`Depends`, `Imports`, `LinkingTo`, and optionally
#'    `Suggests`),
#' 3. `.R`, `.Rmd`, `.qmd`, and `NAMESPACE` files (looking for `library()`,
#'    `require()`, and `pkg::fun` references).
#'
#' @param path Project path.
#' @param include_suggests Whether to include `Suggests` from `DESCRIPTION`.
#'
#' @return A character vector of package names.
#' @family preflight
#' @export
#' @examples
#' \dontrun{
#' detect_project_packages(".")
#' detect_project_packages(".", include_suggests = TRUE)
#' }
detect_project_packages <- function(path = ".", include_suggests = FALSE) {
  path <- normalizePath(path, mustWork = TRUE)

  packages <- character()
  lockfile <- file.path(path, "renv.lock")
  desc <- file.path(path, "DESCRIPTION")

  if (file.exists(lockfile)) {
    packages <- c(packages, packages_from_renv_lock(lockfile))
  }

  if (file.exists(desc)) {
    packages <- c(packages, packages_from_description(desc, include_suggests))
  }

  if (!length(packages)) {
    packages <- packages_from_source_files(path)
  }

  sort(setdiff(compact_chr(packages), "R"))
}

#' Check system requirements for a project
#'
#' Convenience wrapper around [detect_project_packages()] and
#' [check_packages()].
#'
#' @param path Project path.
#' @param include_suggests Whether to include `Suggests` from `DESCRIPTION`.
#' @param platform Platform specification accepted by [resolve_platform()].
#' @param backend One of `"auto"`, `"ppm"`, or `"pak"`.
#' @param ... Passed to [check_packages()].
#'
#' @return A `sysreqr_plan`.
#' @family preflight
#' @export
#' @examples
#' \dontrun{
#' check_project(".")
#' check_project(".", platform = "ubuntu-22.04", backend = "ppm")
#' }
check_project <- function(path = ".", include_suggests = FALSE,
                          platform = NULL,
                          backend = c("auto", "bundled", "ppm", "pak"),
                          ...) {
  backend <- match.arg(backend)
  packages <- detect_project_packages(path, include_suggests = include_suggests)
  if (!length(packages)) {
    stop("No R packages were detected in the project.", call. = FALSE)
  }

  plan <- check_packages(
    packages,
    platform = platform,
    backend = backend,
    ...
  )
  attr(plan, "project_path") <- normalizePath(path, mustWork = TRUE)
  attr(plan, "detected_packages") <- packages
  plan
}

packages_from_renv_lock <- function(path) {
  lock <- json_read_file(path)
  packages <- names(lock$Packages %||% list())
  setdiff(packages, "R")
}

packages_from_description <- function(path, include_suggests = FALSE) {
  dcf <- read.dcf(path, all = TRUE)
  fields <- c("Depends", "Imports", "LinkingTo")
  if (isTRUE(include_suggests)) {
    fields <- c(fields, "Suggests")
  }

  values <- unlist(dcf[intersect(fields, names(dcf))], use.names = FALSE)
  parse_package_fields(values)
}

parse_package_fields <- function(x) {
  if (!length(x)) {
    return(character())
  }

  parts <- unlist(strsplit(x, ",", fixed = TRUE), use.names = FALSE)
  parts <- trimws(parts)
  parts <- sub("\\s*\\(.*\\)$", "", parts)
  compact_chr(parts)
}

packages_from_source_files <- function(path) {
  files <- list.files(
    path,
    pattern = "[.](R|r|Rmd|rmd|qmd)$|^NAMESPACE$",
    recursive = TRUE,
    full.names = TRUE
  )
  files <- files[!grepl("(^|/)refs/", files)]
  if (!length(files)) {
    return(character())
  }

  text <- unlist(lapply(files, readLines, warn = FALSE), use.names = FALSE)
  matches <- gregexpr(
    "(library|require)\\s*\\(\\s*['\"]?([A-Za-z][A-Za-z0-9.]*)|([A-Za-z][A-Za-z0-9.]*)\\s*::",
    text,
    perl = TRUE
  )

  found <- character()
  for (i in seq_along(matches)) {
    m <- regmatches(text[[i]], matches[[i]])[[1]]
    if (!length(m)) {
      next
    }
    found <- c(
      found,
      sub(".*\\(\\s*['\"]?([A-Za-z][A-Za-z0-9.]*).*", "\\1", m),
      sub("^([A-Za-z][A-Za-z0-9.]*)\\s*::.*", "\\1", m)
    )
  }

  found <- found[is_simple_package_name(found)]
  compact_chr(found)
}
