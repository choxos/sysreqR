# Helpers and fixtures shared across testthat files.
# This file is loaded automatically by testthat before each test file.

mock_ppm_get <- function(endpoint, query, base_url) {
  if (identical(endpoint, "status")) {
    return(list(
      version = "2026.04.2",
      distros = list(
        list(
          name = "jammy",
          os = "linux",
          binaryURL = "jammy",
          display = "Ubuntu 22.04",
          distribution = "ubuntu",
          release = "22.04",
          sysReqs = TRUE,
          binaries = TRUE,
          hidden = FALSE,
          arch = list("x86_64")
        ),
        list(
          name = "noble",
          os = "linux",
          binaryURL = "noble",
          display = "Ubuntu 24.04",
          distribution = "ubuntu",
          release = "24.04",
          sysReqs = TRUE,
          binaries = TRUE,
          hidden = FALSE,
          arch = list("x86_64")
        )
      )
    ))
  }

  if (identical(endpoint, "repos/cran/sysreqs")) {
    pkgs <- query$pkgname
    if (is.null(pkgs)) pkgs <- c("xml2", "curl")
    reqs <- list()
    if ("xml2" %in% pkgs || isTRUE(query$all)) {
      reqs <- c(reqs, list(list(
        name = "xml2",
        requirements = list(
          packages = list("libxml2-dev"),
          install_scripts = list("apt-get install -y libxml2-dev")
        )
      )))
    }
    if ("curl" %in% pkgs || isTRUE(query$all)) {
      reqs <- c(reqs, list(list(
        name = "curl",
        requirements = list(
          packages = list("libcurl4-openssl-dev", "libssl-dev"),
          install_scripts = list(
            "apt-get install -y libcurl4-openssl-dev",
            "apt-get install -y libssl-dev"
          )
        )
      )))
    }
    return(list(requirements = reqs))
  }

  stop("unexpected endpoint: ", endpoint, call. = FALSE)
}

# Accessors for internal helpers tested directly.
json_read_file <- getFromNamespace("json_read_file", "sysreqr")
json_read_text <- getFromNamespace("json_read_text", "sysreqr")
json_write <- getFromNamespace("json_write", "sysreqr")
parse_os_release <- getFromNamespace("parse_os_release", "sysreqr")
extract_failed_packages <- getFromNamespace("extract_failed_packages", "sysreqr")
extract_dependency_failures <- getFromNamespace("extract_dependency_failures", "sysreqr")
select_backend <- getFromNamespace("select_backend", "sysreqr")
