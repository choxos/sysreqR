startup_platform_example <- function() {
  fallback <- "ubuntu-24.04"
  platform <- tryCatch(detect_platform(), error = function(e) NULL)
  if (is.null(platform) || !identical(platform$os, "linux") ||
        !isTRUE(platform$supported)) {
    return(fallback)
  }
  distro <- platform$distro
  version <- as.character(platform$version)
  if (!is.character(distro) || is.na(distro) || !nzchar(distro) ||
        is.na(version) || !nzchar(version)) {
    return(fallback)
  }
  key <- paste0(distro, "-", version)
  # Only suggest keys that resolve_platform() accepts, so the startup hint
  # never points users at an invalid platform string (for example when an
  # os-release ID contains a dash).
  resolved <- tryCatch(resolve_platform(key), error = function(e) NULL)
  if (is.null(resolved)) {
    return(fallback)
  }
  key
}

.onAttach <- function(libname, pkgname) {
  if (!interactive()) {
    return()
  }
  ver <- utils::packageVersion(pkgname)
  example <- tryCatch(startup_platform_example(), error = function(e) "ubuntu-24.04")
  msg <- c(
    sprintf("sysreqr %s", ver),
    "",
    sprintf("New here? Try setup_advice(platform = \"%s\"),", example),
    "or help(package = \"sysreqr\") for the function reference.",
    "",
    "Guides and articles: https://choxos.github.io/sysreqR/articles/",
    "Source and issues:   https://github.com/choxos/sysreqR",
    "",
    "Suppress this message with suppressPackageStartupMessages()."
  )
  packageStartupMessage(paste(msg, collapse = "\n"))
}
