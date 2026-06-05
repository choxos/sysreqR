ppm_default_base_url <- function() {
  getOption("sysreqr.ppm_base_url", "https://packagemanager.posit.co")
}

ppm_api_get <- function(endpoint, query = list(), base_url = ppm_default_base_url()) {
  mock <- getOption("sysreqr.ppm_get", NULL)
  if (is.function(mock)) {
    return(mock(endpoint = endpoint, query = query, base_url = base_url))
  }

  qs <- build_query(query)
  url <- paste0(trim_slashes(base_url), "/__api__/", endpoint)
  if (nzchar(qs)) {
    url <- paste0(url, "?", qs)
  }

  tmp <- tempfile("sysreqr-ppm-", fileext = ".json")
  on.exit(unlink(tmp), add = TRUE)

  prev_timeout <- getOption("timeout", 60L)
  timeout <- getOption("sysreqr.timeout", max(prev_timeout, 60L))
  on.exit(options(timeout = prev_timeout), add = TRUE)
  options(timeout = timeout)

  ok <- tryCatch({
    utils::download.file(url, tmp, quiet = TRUE, mode = "wb")
    TRUE
  }, warning = function(w) {
    FALSE
  }, error = function(e) {
    FALSE
  })

  if (!isTRUE(ok)) {
    stop("PPM API request failed.", call. = FALSE)
  }

  json_read_file(tmp)
}

#' List Posit Package Manager platforms
#'
#' Queries the Posit Package Manager `/__api__/status` endpoint and returns a
#' data frame of supported distributions.
#'
#' @param base_url Posit Package Manager base URL.
#'
#' @return A data frame of platform records reported by Package Manager.
#' @family ppm
#' @export
#' @examples
#' \donttest{
#' ppm_platforms()
#' }
ppm_platforms <- function(base_url = ppm_default_base_url()) {
  status <- ppm_api_get("status", base_url = base_url)
  list_to_data_frame(status$distros %||% list())
}

#' Check Posit Package Manager support
#'
#' Reports whether a platform is currently served by Posit Package Manager
#' and whether it has system requirement metadata and binary packages.
#'
#' @param platform Platform specification accepted by [resolve_platform()].
#' @param base_url Posit Package Manager base URL.
#'
#' @return A list with the matched platform and Package Manager status.
#' @family ppm
#' @export
#' @examples
#' \donttest{
#' check_ppm("ubuntu-22.04")
#' check_ppm("fedora-40")
#' }
check_ppm <- function(platform = NULL, base_url = ppm_default_base_url()) {
  platform <- resolve_platform(platform)
  status <- ppm_api_get("status", base_url = base_url)
  distros <- status$distros %||% list()

  matched <- Filter(function(x) {
    identical(x$os, platform$os) &&
      identical(x$distribution, platform$distro) &&
      identical(as.character(x$release), as.character(platform$version))
  }, distros)

  list(
    supported = length(matched) > 0 && isTRUE(matched[[1]]$sysReqs),
    binaries = length(matched) > 0 && isTRUE(matched[[1]]$binaries),
    platform = platform,
    ppm = if (length(matched)) matched[[1]] else NULL,
    version = status$version %||% NA_character_
  )
}

#' Build a Posit Package Manager repository URL
#'
#' Constructs a Linux binary repository URL for the given platform, CRAN
#' repository alias, and snapshot.
#'
#' @param platform Platform specification accepted by [resolve_platform()].
#' @param repo Repository name.
#' @param snapshot Snapshot name or date.
#' @param base_url Posit Package Manager base URL.
#'
#' @return A repository URL.
#' @family ppm
#' @export
#' @examples
#' ppm_repo(platform = "ubuntu-22.04")
#' ppm_repo(platform = "ubuntu-26.04", snapshot = "2026-04-01")
ppm_repo <- function(platform = NULL, repo = "cran", snapshot = "latest",
                     base_url = ppm_default_base_url()) {
  platform <- resolve_platform(platform)
  binary <- platform$ppm_binary_url
  if (is.na(binary) || !nzchar(binary)) {
    stop("No Package Manager binary URL segment is known for this platform.", call. = FALSE)
  }

  paste0(
    trim_slashes(base_url), "/",
    url_encode(repo), "/__linux__/",
    url_encode(binary), "/",
    url_encode(snapshot)
  )
}

#' Query Package Manager system requirements
#'
#' Queries the Posit Package Manager `/sysreqs` endpoint for the given
#' packages and platform, and normalizes the response into a
#' `sysreqr_plan`. If the API call fails, the function falls back to the
#' bundled database and records the failure in the
#' `"fallback_error"` attribute of the returned plan.
#'
#' @param packages Package names. Required when `all = FALSE`.
#' @param all Whether to return system requirements for the whole repository.
#' @param platform Platform specification accepted by [resolve_platform()].
#' @param repo Repository name.
#' @param base_url Posit Package Manager base URL.
#' @param check_installed Whether to check installed system packages on the
#'   current host when possible.
#'
#' @return A `sysreqr_plan`.
#' @family ppm
#' @export
#' @examples
#' \donttest{
#' ppm_sysreqs(c("xml2", "curl"), platform = "ubuntu-22.04")
#' }
ppm_sysreqs <- function(packages = NULL, all = FALSE, platform = NULL,
                        repo = "cran", base_url = ppm_default_base_url(),
                        check_installed = TRUE) {
  platform <- resolve_platform(platform)
  dist <- ppm_distribution_release(platform)

  if (!isTRUE(all) && !length(packages)) {
    stop("`packages` is required when `all = FALSE`.", call. = FALSE)
  }

  query <- list(
    all = isTRUE(all),
    distribution = dist$distribution,
    release = dist$release
  )
  if (!isTRUE(all)) {
    query$pkgname <- packages
  }

  endpoint <- paste0("repos/", url_encode(repo), "/sysreqs")
  res <- tryCatch(
    ppm_api_get(endpoint, query = query, base_url = base_url),
    error = function(e) e
  )
  if (inherits(res, "error")) {
    if (isTRUE(all)) {
      stop(res)
    }
    plan <- bundled_sysreqs(packages, platform, repo = repo, error = NULL)
    if (isTRUE(check_installed)) {
      plan <- add_installed_state(plan, platform)
    }
    attr(plan, "fallback_error") <- conditionMessage(res)
    return(plan)
  }

  plan <- normalize_ppm_sysreqs(res, platform, repo = repo)

  if (isTRUE(check_installed)) {
    plan <- add_installed_state(plan, platform)
  }

  plan
}

ppm_distribution_release <- function(platform) {
  distro <- platform$distro
  version <- as.character(platform$version)

  if (distro %in% c("rhel")) {
    distro <- "redhat"
  }

  if (distro %in% c("rocky", "almalinux")) {
    distro <- "rockylinux"
  }

  if (distro %in% c("sles")) {
    distro <- "sle"
  }

  if (!distro %in% c("centos", "debian", "opensuse", "redhat", "rockylinux", "sle", "ubuntu")) {
    stop("This platform is not supported by the Package Manager sysreqs API.", call. = FALSE)
  }

  list(distribution = distro, release = version)
}

normalize_ppm_sysreqs <- function(res, platform, repo = "cran") {
  items <- res$requirements %||% list()
  rows <- list()
  pre_all <- character()
  post_all <- character()

  for (item in items) {
    req <- item$requirements %||% list()
    r_package <- item$name %||% NA_character_
    system_packages <- as_chr(req$packages)
    install_scripts <- as_chr(req$install_scripts)
    pre <- extract_commands(req$pre_install)
    post <- extract_commands(req$post_install)
    pre_all <- c(pre_all, pre)
    post_all <- c(post_all, post)

    if (!length(system_packages) && length(pre)) {
      rows[[length(rows) + 1]] <- data.frame(
        r_package = r_package,
        sysreq = NA_character_,
        system_package = NA_character_,
        install_script = NA_character_,
        pre_install = paste(pre, collapse = "\n"),
        post_install = paste(post, collapse = "\n"),
        platform = paste0(platform$distro, "-", platform$version),
        package_manager = platform$package_manager,
        installed = NA,
        source = "ppm",
        confidence = "high",
        notes = paste0("Requirement reported by Package Manager repository `", repo, "`."),
        stringsAsFactors = FALSE
      )
      next
    }

    for (idx in seq_along(system_packages)) {
      install_script <- if (idx <= length(install_scripts)) {
        install_scripts[[idx]]
      } else {
        install_script_for_package(system_packages[[idx]], platform)
      }
      rows[[length(rows) + 1]] <- data.frame(
        r_package = r_package,
        sysreq = NA_character_,
        system_package = system_packages[[idx]],
        install_script = install_script %||% NA_character_,
        pre_install = paste(pre, collapse = "\n"),
        post_install = paste(post, collapse = "\n"),
        platform = paste0(platform$distro, "-", platform$version),
        package_manager = platform$package_manager,
        installed = NA,
        source = "ppm",
        confidence = "high",
        notes = paste0("Requirement reported by Package Manager repository `", repo, "`."),
        stringsAsFactors = FALSE
      )
    }
  }

  data <- if (length(rows)) do.call(rbind, rows) else data.frame()
  new_sysreqr_plan(
    data,
    platform_info = platform,
    pre_install = pre_all,
    post_install = post_all,
    backend = "ppm"
  )
}

#' Configure Package Manager repository options
#'
#' Emits or installs the R code lines that point `options(repos)` at a Posit
#' Package Manager binary repository. With `dry_run = TRUE` (the default),
#' the lines are returned without touching any file, so the user can review
#' them before applying. When `dry_run = FALSE`, `path` must be supplied
#' explicitly.
#'
#' @param scope `"user"` edits the user `.Rprofile`, `"project"` edits the
#'   current project `.Rprofile`.
#' @param platform Platform specification accepted by [resolve_platform()].
#' @param repo Repository name.
#' @param dry_run If `TRUE`, return the lines that would be written without
#'   editing files.
#' @param path Explicit `.Rprofile` path used when `dry_run = FALSE`.
#'
#' @return The configuration lines, invisibly when written.
#' @family ppm
#' @export
#' @examples
#' use_ppm("user", platform = "ubuntu-22.04", dry_run = TRUE)
#'
#' # Write to a throwaway .Rprofile under tempdir():
#' use_ppm(
#'   "user",
#'   platform = "ubuntu-22.04",
#'   dry_run = FALSE,
#'   path = file.path(tempdir(), ".Rprofile")
#' )
use_ppm <- function(scope = c("user", "project"), platform = NULL, repo = "cran",
                    dry_run = TRUE, path = NULL) {
  scope <- match.arg(scope)
  url <- ppm_repo(platform = platform, repo = repo)
  lines <- c(
    "options(",
    "  repos = c(",
    paste0('    CRAN = "', url, '"'),
    "  )",
    ")"
  )

  if (isTRUE(dry_run)) {
    return(lines)
  }

  if (is.null(path)) {
    stop("`path` must be supplied when `dry_run = FALSE`.", call. = FALSE)
  }

  old <- read_lines_if_exists(path)
  writeLines(c(old, "", "# Added by sysreqr", lines), path)
  invisible(lines)
}
