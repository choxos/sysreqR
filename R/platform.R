#' Detect the current platform
#'
#' Detects the host operating system and, on Linux, parses `/etc/os-release`.
#' On macOS, queries `sw_vers`. Returns a structured platform object used by
#' the rest of the package. When `os_release` is supplied and exists, the file
#' is parsed even on macOS or Windows; this makes fixture-driven testing
#' practical.
#'
#' @param os_release Path to an `os-release` file. Defaults to the system file
#'   `/etc/os-release`. Mainly useful for tests and reproducible builds.
#'
#' @return An object of class `sysreqr_platform` (a list).
#' @family platform
#' @export
#' @examples
#' platform <- detect_platform()
#' platform$distro
#'
#' # Reproducible reads from a fixture file:
#' fixture <- system.file(
#'   "extdata", "os-release-fedora-40",
#'   package = "sysreqr",
#'   mustWork = FALSE
#' )
#' if (nzchar(fixture)) detect_platform(os_release = fixture)
detect_platform <- function(os_release = "/etc/os-release") {
  sysname <- tolower(Sys.info()[["sysname"]] %||% "")

  user_supplied <- !identical(os_release, "/etc/os-release")
  if (user_supplied && file.exists(os_release)) {
    return(detect_platform_from_file(os_release))
  }

  if (identical(sysname, "darwin")) {
    macos_version <- tryCatch(
      suppressWarnings(system2(
        "sw_vers",
        "-productVersion",
        stdout = TRUE,
        stderr = FALSE
      )),
      error = function(e) character()
    )
    version_value <- if (length(macos_version)) {
      as.character(macos_version[[1L]])
    } else {
      NA_character_
    }
    return(new_platform(
      os = "macos",
      distro = "macos",
      version = version_value,
      codename = NA_character_,
      package_manager = "brew",
      ppm_binary_url = "macos",
      supported = FALSE,
      label = "macOS"
    ))
  }

  if (startsWith(sysname, "mingw") || identical(sysname, "windows")) {
    return(new_platform(
      os = "windows",
      distro = "windows",
      version = NA_character_,
      codename = NA_character_,
      package_manager = NA_character_,
      ppm_binary_url = "windows",
      supported = FALSE,
      label = "Windows"
    ))
  }

  if (!file.exists(os_release)) {
    return(new_platform(
      os = sysname %||% "unknown",
      distro = NA_character_,
      version = NA_character_,
      codename = NA_character_,
      package_manager = NA_character_,
      ppm_binary_url = NA_character_,
      supported = FALSE,
      label = sysname %||% "unknown"
    ))
  }

  detect_platform_from_file(os_release)
}

detect_platform_from_file <- function(os_release) {
  props <- parse_os_release(readLines(os_release, warn = FALSE))
  get_prop <- function(key) {
    if (key %in% names(props)) props[[key]] else NA_character_
  }
  distro <- tolower(get_prop("ID"))
  version <- get_prop("VERSION_ID")
  codename <- get_prop("UBUNTU_CODENAME")
  if (is.na(codename) || !nzchar(codename)) {
    codename <- get_prop("VERSION_CODENAME")
  }
  if (is.na(codename) || !nzchar(codename)) {
    codename <- NA_character_
  }

  if (!is.na(distro) && "UBUNTU_CODENAME" %in% names(props)) {
    distro <- "ubuntu"
  }

  pm <- package_manager_for_distro(distro, version)
  ppm <- ppm_binary_from_platform(distro, version, codename)
  supported <- distro %in% c(
    "ubuntu", "debian", "centos", "redhat", "rhel", "rocky",
    "rockylinux", "almalinux", "fedora", "opensuse", "opensuse-leap",
    "sles", "sle", "alpine"
  )

  new_platform(
    os = "linux",
    distro = distro,
    version = version,
    codename = codename,
    package_manager = pm,
    ppm_binary_url = ppm,
    supported = supported,
    label = paste(compact_chr(c(get_prop("PRETTY_NAME"), distro)), collapse = " ")
  )
}

#' Detect the platform package manager
#'
#' Returns the name of the operating system package manager for a platform:
#' `"apt"`, `"dnf"`, `"yum"`, `"zypper"`, `"apk"`, or `"brew"`.
#'
#' @param platform A platform specification accepted by [resolve_platform()].
#'
#' @return A package manager name such as `"apt"` or `"dnf"`.
#' @family platform
#' @export
#' @examples
#' detect_package_manager("ubuntu-22.04")
#' detect_package_manager("fedora-40")
#' detect_package_manager("opensuse156")
detect_package_manager <- function(platform = NULL) {
  resolve_platform(platform)$package_manager
}

parse_os_release <- function(lines) {
  lines <- lines[grepl("=", lines, fixed = TRUE)]
  lines <- lines[!grepl("^\\s*#", lines)]
  keys <- sub("=.*$", "", lines)
  vals <- sub("^[^=]*=", "", lines)
  vals <- sub('^"(.*)"$', "\\1", vals)
  vals <- sub("^'(.*)'$", "\\1", vals)
  stats::setNames(vals, keys)
}

new_platform <- function(os, distro, version, codename, package_manager,
                         ppm_binary_url, supported, label) {
  structure(
    list(
      os = os,
      distro = distro,
      version = version,
      codename = codename,
      package_manager = package_manager,
      ppm_binary_url = ppm_binary_url,
      supported = supported,
      label = label
    ),
    class = "sysreqr_platform"
  )
}

#' Resolve a platform specification
#'
#' Accepts a `NULL`, a `sysreqr_platform` object, or a short string and
#' returns a fully normalized platform object. Strings can be the
#' `<distro>-<version>` shorthand (`"ubuntu-22.04"`, `"debian-12"`) or a
#' codename alias (`"jammy"`, `"noble"`, `"resolute"`, `"bookworm"`,
#' `"trixie"`).
#'
#' @param platform `NULL`, a platform list returned by [detect_platform()], or a
#'   character string such as `"ubuntu-22.04"`, `"debian-12"`, `"jammy"`, or
#'   `"bookworm"`.
#'
#' @return A platform list with class `"sysreqr_platform"`.
#' @family platform
#' @export
#' @examples
#' resolve_platform("ubuntu-22.04")
#' resolve_platform("resolute")
#' resolve_platform("bookworm")
resolve_platform <- function(platform = NULL) {
  if (is.null(platform)) {
    return(detect_platform())
  }

  if (inherits(platform, "sysreqr_platform") || is.list(platform)) {
    return(platform)
  }

  platform <- as.character(platform)
  if (length(platform) != 1 || !nzchar(platform)) {
    stop("`platform` must be NULL, a platform object, or a single string.", call. = FALSE)
  }

  known <- known_platforms()
  idx <- match(platform, known$key)
  if (!is.na(idx)) {
    row <- known[idx, , drop = FALSE]
    return(new_platform(
      os = "linux",
      distro = row$distro,
      version = row$version,
      codename = row$codename,
      package_manager = package_manager_for_distro(row$distro, row$version),
      ppm_binary_url = row$ppm_binary_url,
      supported = TRUE,
      label = row$label
    ))
  }

  parts <- strsplit(platform, "-", fixed = TRUE)[[1]]
  if (length(parts) >= 2) {
    distro <- parts[[1]]
    version <- paste(parts[-1], collapse = "-")
    return(new_platform(
      os = "linux",
      distro = distro,
      version = version,
      codename = NA_character_,
      package_manager = package_manager_for_distro(distro, version),
      ppm_binary_url = ppm_binary_from_platform(distro, version, NA_character_),
      supported = !is.na(package_manager_for_distro(distro, version)),
      label = paste(distro, version)
    ))
  }

  stop(
    "Unknown platform. Use a value like `ubuntu-22.04`, `debian-12`, `jammy`, or `bookworm`.",
    call. = FALSE
  )
}

known_platforms <- function() {
  data.frame(
    key = c(
      "ubuntu-22.04", "ubuntu-24.04", "ubuntu-26.04",
      "jammy", "noble", "resolute",
      "debian-12", "debian-13", "bookworm", "trixie",
      "redhat-7", "redhat-8", "redhat-9", "redhat-10",
      "rockylinux-9", "rockylinux-10", "rhel9", "rhel10",
      "almalinux-9", "almalinux-10",
      "centos7", "opensuse156", "sle-15.6", "sles156"
    ),
    distro = c(
      "ubuntu", "ubuntu", "ubuntu",
      "ubuntu", "ubuntu", "ubuntu",
      "debian", "debian", "debian", "debian",
      "redhat", "redhat", "redhat", "redhat",
      "rockylinux", "rockylinux", "rockylinux", "rockylinux",
      "almalinux", "almalinux",
      "centos", "opensuse", "sle", "sle"
    ),
    version = c(
      "22.04", "24.04", "26.04",
      "22.04", "24.04", "26.04",
      "12", "13", "12", "13",
      "7", "8", "9", "10",
      "9", "10", "9", "10",
      "9", "10",
      "7", "15.6", "15.6", "15.6"
    ),
    codename = c(
      "jammy", "noble", "resolute",
      "jammy", "noble", "resolute",
      "bookworm", "trixie", "bookworm", "trixie",
      rep(NA_character_, 14)
    ),
    ppm_binary_url = c(
      "jammy", "noble", "resolute",
      "jammy", "noble", "resolute",
      "bookworm", "trixie", "bookworm", "trixie",
      "centos7", "centos8", "rhel9", "rhel10",
      "rhel9", "rhel10", "rhel9", "rhel10",
      "rhel9", "rhel10",
      "centos7", "opensuse156", "opensuse156", "opensuse156"
    ),
    label = c(
      "Ubuntu 22.04", "Ubuntu 24.04", "Ubuntu 26.04",
      "Ubuntu 22.04", "Ubuntu 24.04", "Ubuntu 26.04",
      "Debian 12", "Debian 13", "Debian 12", "Debian 13",
      "Red Hat Enterprise Linux 7", "Red Hat Enterprise Linux 8",
      "Red Hat Enterprise Linux 9", "Red Hat Enterprise Linux 10",
      "Rocky Linux 9", "Rocky Linux 10", "Rocky Linux 9", "Rocky Linux 10",
      "AlmaLinux 9", "AlmaLinux 10",
      "CentOS 7", "OpenSUSE 15.6", "SLE 15.6", "SLE 15.6"
    ),
    stringsAsFactors = FALSE
  )
}

ppm_binary_from_platform <- function(distro, version, codename) {
  distro <- tolower(distro %||% "")
  version <- as.character(version %||% "")
  codename <- codename %||% NA_character_

  if (distro %in% c("ubuntu", "debian") && !is.na(codename) && nzchar(codename)) {
    return(codename)
  }

  known <- known_platforms()
  key <- paste0(distro, "-", version)
  idx <- match(key, known$key)
  if (!is.na(idx)) {
    return(known$ppm_binary_url[[idx]])
  }

  NA_character_
}

platform_matches_current <- function(platform) {
  current <- detect_platform()
  identical(current$os, platform$os) &&
    identical(current$distro, platform$distro) &&
    identical(as.character(current$version), as.character(platform$version))
}
