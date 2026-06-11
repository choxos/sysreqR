#' Get beginner setup advice for R package installation on Linux
#'
#' Produces a practical checklist for users who are new to R on GNU/Linux. It
#' recommends binary package repositories where available, explains when R
#' Project operating system repositories are relevant, lists source build
#' tools, and can add package-specific system requirements. It never runs
#' `sudo`, edits the system R configuration, or changes operating system
#' repositories; the user remains in control.
#'
#' @param packages Optional R package names to check.
#' @param platform Platform specification accepted by [resolve_platform()].
#' @param backend One of `"auto"`, `"bundled"`, `"ppm"`, or `"pak"`.
#' @param repo Repository name used for Posit Package Manager and sysreq lookup.
#' @param check_installed Whether to check installed system packages on the
#'   current host when possible.
#' @param include_r_project_repo Whether to include optional R Project operating
#'   system repository commands for supported Linux distributions.
#' @param script Optional path. When supplied, an executable shell script is
#'   written with the safe setup commands.
#'
#' @return A `sysreqr_setup_advice` object.
#' @family setup
#' @export
#' @examples
#' advice <- setup_advice(
#'   "xml2",
#'   platform = "ubuntu-22.04",
#'   backend = "bundled"
#' )
#' print(advice)
#'
#' \donttest{
#' # Write a reviewable shell script:
#' setup_advice(
#'   c("xml2", "curl"),
#'   platform = "ubuntu-22.04",
#'   backend = "bundled",
#'   script = tempfile(fileext = ".sh")
#' )
#' }
setup_advice <- function(packages = NULL, platform = NULL,
                         backend = c("auto", "bundled", "ppm", "pak"),
                         repo = "cran", check_installed = TRUE,
                         include_r_project_repo = TRUE, script = NULL) {
  backend <- match.arg(backend)
  platform <- resolve_platform(platform)
  package_arg <- packages
  packages <- if (is.null(packages)) {
    character()
  } else {
    compact_chr(as.character(packages))
  }

  if (!is.null(package_arg) && !length(packages)) {
    stop("`packages` must be NULL or contain at least one package name.", call. = FALSE)
  }

  if (!is.null(script)) {
    script <- as.character(script)
    if (length(script) != 1 || !nzchar(script)) {
      stop("`script` must be NULL or a single file path.", call. = FALSE)
    }
  }

  ppm <- setup_ppm_advice(platform, repo = repo)
  build <- setup_build_advice(platform)
  r_project <- if (isTRUE(include_r_project_repo)) {
    setup_r_project_advice(platform)
  } else {
    list(commands = character(), notes = "R Project repository advice was not requested.")
  }

  plan <- NULL
  package_commands <- character()
  if (length(packages)) {
    plan <- check_packages(
      packages = packages,
      platform = platform,
      backend = backend,
      repo = repo,
      check_installed = check_installed
    )
    package_commands <- install_command(plan, sudo = TRUE, update = TRUE)
  }

  advice <- structure(
    list(
      platform = platform,
      packages = packages,
      plan = plan,
      ppm_repo = ppm$url,
      ppm_lines = ppm$lines,
      ppm_notes = ppm$notes,
      build_commands = build$commands,
      build_notes = build$notes,
      r_project_commands = r_project$commands,
      r_project_notes = r_project$notes,
      package_commands = package_commands,
      script = script
    ),
    class = "sysreqr_setup_advice"
  )

  if (!is.null(script)) {
    write_setup_advice_script(advice, script)
  }

  advice
}

#' Print setup advice
#'
#' @param x A `sysreqr_setup_advice` object.
#' @param ... Unused.
#'
#' @return `x`, invisibly.
#' @family setup
#' @export
print.sysreqr_setup_advice <- function(x, ...) {
  cat("R package installation setup advice\n\n")
  cat("Platform: ", platform_label(x$platform), "\n", sep = "")
  cat("Package manager: ", x$platform$package_manager %||% "unknown", "\n\n", sep = "")

  cat("1. Prefer binary R packages when available\n")
  if (!is.na(x$ppm_repo) && nzchar(x$ppm_repo)) {
    cat("Posit Package Manager repository:\n")
    cat("  ", x$ppm_repo, "\n", sep = "")
    cat("Preview .Rprofile lines:\n")
    cat(paste0("  ", x$ppm_lines), sep = "\n")
    cat("\n")
  } else {
    cat("No Posit Package Manager binary repository URL is known for this platform.\n")
  }
  if (nzchar(x$ppm_notes)) {
    cat(x$ppm_notes, "\n", sep = "")
  }

  cat("\n2. Install source build tools when source packages are needed\n")
  if (length(x$build_commands)) {
    cat(paste0("  ", x$build_commands), sep = "\n")
    cat("\n")
  } else {
    cat("No build-tool command is known for this platform.\n")
  }
  if (nzchar(x$build_notes)) {
    cat(x$build_notes, "\n", sep = "")
  }

  if (length(x$r_project_commands) || nzchar(x$r_project_notes)) {
    cat("\n3. Optional R Project operating system repository\n")
    if (length(x$r_project_commands)) {
      cat(paste0("  ", x$r_project_commands), sep = "\n")
      cat("\n")
    }
    if (nzchar(x$r_project_notes)) {
      cat(x$r_project_notes, "\n", sep = "")
    }
  }

  cat("\n4. Package-specific system requirements\n")
  if (length(x$packages)) {
    cat("R packages checked: ", paste(x$packages, collapse = ", "), "\n", sep = "")
    if (length(x$package_commands)) {
      cat(paste0("  ", x$package_commands), sep = "\n")
      cat("\n")
    } else {
      cat("No external system packages were detected for these packages.\n")
    }
  } else {
    cat(
      "No R package names were supplied.",
      "Run setup_advice(c(\"xml2\", \"curl\")) for package-specific checks.\n"
    )
  }

  if (!is.null(x$script)) {
    cat("\nScript written to: ", x$script, "\n", sep = "")
  }

  invisible(x)
}

setup_ppm_advice <- function(platform, repo = "cran") {
  if (!identical(platform$os, "linux")) {
    return(list(
      url = NA_character_,
      lines = character(),
      notes = "Package Manager binary repository advice is currently focused on Linux."
    ))
  }

  url <- tryCatch(ppm_repo(platform = platform, repo = repo), error = function(e) NA_character_)
  if (is.na(url) || !nzchar(url)) {
    return(list(
      url = NA_character_,
      lines = character(),
      notes = "Package Manager does not expose a known binary URL for this platform in sysreqR."
    ))
  }

  list(
    url = url,
    lines = use_ppm(platform = platform, repo = repo, dry_run = TRUE),
    notes = paste(
      "Using binary packages can avoid many source compilation failures.",
      "This changes only R's repository option when you choose to apply it."
    )
  )
}

setup_build_advice <- function(platform) {
  pm <- platform$package_manager
  if (identical(pm, "apt")) {
    return(list(
      commands = c(
        "sudo apt-get update",
        paste(
          "sudo apt-get install -y --no-install-recommends",
          "r-base-dev build-essential gfortran make pkg-config"
        )
      ),
      notes = paste(
        "On Debian and Ubuntu, r-base-dev is needed for compiling",
        "many R packages from source."
      )
    ))
  }

  if (identical(pm, "dnf")) {
    return(list(
      commands = "sudo dnf install -y R gcc gcc-c++ gcc-gfortran make pkgconf-pkg-config",
      notes = paste(
        "On Fedora-style systems, the R package provides the standard",
        "R installation and development files."
      )
    ))
  }

  if (identical(pm, "yum")) {
    return(list(
      commands = "sudo yum install -y R gcc gcc-c++ gcc-gfortran make pkgconfig",
      notes = paste(
        "On older RPM systems, install R and compiler tools before building",
        "R packages from source."
      )
    ))
  }

  if (identical(pm, "zypper")) {
    return(list(
      commands = paste(
        "sudo zypper --non-interactive install R-base gcc gcc-c++",
        "gcc-fortran make pkg-config"
      ),
      notes = paste(
        "On OpenSUSE and SLE, install R-base and compiler tools before",
        "building R packages from source."
      )
    ))
  }

  if (identical(pm, "apk")) {
    return(list(
      commands = "sudo apk add --no-cache R R-dev build-base gfortran make pkgconf",
      notes = "On Alpine, source builds often need R-dev and build-base."
    ))
  }

  if (identical(pm, "brew")) {
    return(list(
      commands = "brew install pkg-config",
      notes = "On macOS, CRAN binaries usually avoid most system library build problems."
    ))
  }

  list(
    commands = character(),
    notes = paste(
      "Install R development files, a C and C++ compiler, a Fortran compiler,",
      "make, and pkg-config for source builds."
    )
  )
}

setup_r_project_advice <- function(platform) {
  distro <- tolower(platform$distro %||% "")
  if (identical(distro, "ubuntu")) {
    codename <- platform$codename
    if (is.na(codename) || !nzchar(codename)) {
      codename <- "$(lsb_release -cs)"
    }
    repo <- paste0("deb https://cloud.r-project.org/bin/linux/ubuntu ", codename, "-cran40/")
    return(list(
      commands = c(
        "sudo apt update -qq",
        "sudo apt install --no-install-recommends software-properties-common dirmngr",
        paste(
          "wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc",
          "| sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc"
        ),
        paste0("sudo add-apt-repository \"", repo, "\""),
        "sudo apt install --no-install-recommends r-base"
      ),
      notes = paste(
        "Use the R Project Ubuntu repository when your system R is too old.",
        "For many package install failures, try Posit Package Manager or",
        "system requirements first.",
        "On Ubuntu 24.04 and newer, the trusted.gpg.d step may print a deprecation",
        "warning; it still works.",
        "The optional r2u project (https://eddelbuettel.github.io/r2u/) serves",
        "all of CRAN as Ubuntu binaries with system dependencies resolved by apt",
        "and integrates with install.packages() through the bspm package."
      )
    ))
  }

  if (identical(distro, "debian")) {
    suite <- debian_cran_suite(platform)
    commands <- "sudo apt install -y r-base r-base-dev"
    notes <- "Install r-base-dev when you want to compile R packages from source."
    if (!is.na(suite) && nzchar(suite)) {
      sources <- paste0(
        "Types: deb\\n",
        "URIs: https://cloud.r-project.org/bin/linux/debian/\\n",
        "Suites: ", suite, "/\\n",
        "Components:\\n",
        "Signed-By: /etc/apt/keyrings/cran_debian_key.asc\\n"
      )
      commands <- c(
        "sudo install -d -m 0755 /etc/apt/keyrings",
        paste0(
          "gpg --keyserver keyserver.ubuntu.com --recv-key ",
          "'95C0FAF38DB3CCAD0C080A7BDC78B2DDEABC47B7'"
        ),
        paste(
          "gpg --armor --export '95C0FAF38DB3CCAD0C080A7BDC78B2DDEABC47B7'",
          "| sudo tee /etc/apt/keyrings/cran_debian_key.asc"
        ),
        paste0("printf '", sources, "' | sudo tee /etc/apt/sources.list.d/cran.sources"),
        "sudo apt update",
        "sudo apt install -y r-base r-base-dev"
      )
      notes <- paste(
        "Use the R Project Debian repository when you need newer R than Debian provides.",
        "This uses the deb822 sources format with a Signed-By keyring, matching CRAN's",
        "current Debian instructions. Compiled packages may need reinstalling after an",
        "R version change."
      )
    }
    return(list(commands = commands, notes = notes))
  }

  if (identical(distro, "fedora")) {
    return(list(
      commands = c(
        "sudo dnf install -y R",
        "sudo dnf copr enable iucar/cran",
        "sudo dnf install -y R-CoprManager"
      ),
      notes = paste(
        "Fedora provides R through the system package manager.",
        "The optional iucar/cran Copr repository (the cran2copr project,",
        "https://github.com/cran4linux/cran2copr) adds binary RPMs for nearly all",
        "of CRAN with system dependencies resolved by dnf; R-CoprManager",
        "integrates it with R's package installation workflow."
      )
    ))
  }

  list(
    commands = character(),
    notes = "No R Project repository commands are bundled for this platform."
  )
}

debian_cran_suite <- function(platform) {
  codename <- tolower(platform$codename %||% "")
  version <- as.character(platform$version %||% "")
  if (codename %in% c("bookworm", "trixie")) {
    return(paste0(codename, "-cran46"))
  }
  if (identical(version, "12")) {
    return("bookworm-cran46")
  }
  if (identical(version, "13")) {
    return("trixie-cran46")
  }
  NA_character_
}

write_setup_advice_script <- function(advice, path) {
  commands <- setup_advice_active_commands(advice)
  if (!length(commands)) {
    commands <- "printf \"%s\\n\" \"No setup commands were generated\""
  }

  lines <- c(
    "#!/usr/bin/env sh",
    "set -eu",
    "",
    "# Generated by sysreqr::setup_advice().",
    "# Review commands before running them on a shared machine.",
    "",
    "# Source build tools and package system requirements.",
    commands
  )

  if (length(advice$r_project_commands)) {
    lines <- c(
      lines,
      "",
      "# Optional R Project repository commands.",
      "# These are commented because they change operating system repositories.",
      paste0("# ", advice$r_project_commands)
    )
  }

  writeLines(lines, path)
  Sys.chmod(path, mode = "0755")
  invisible(path)
}

setup_advice_active_commands <- function(advice) {
  compact_chr(c(advice$build_commands, advice$package_commands))
}
