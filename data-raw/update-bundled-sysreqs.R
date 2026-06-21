# Release utility for refreshing the bundled system requirement data.
# Run from the package root as part of release preparation, e.g.
#   Rscript data-raw/update-bundled-sysreqs.R
#   Rscript data-raw/update-bundled-sysreqs.R cran https://packagemanager.posit.co
#
# The bundled table is a small, hand-curated fallback for common CRAN
# packages. Since 0.2.0 it stores one row per (r_package, package_manager,
# system_package):
#
#   * apt names come from Posit Package Manager for Ubuntu 22.04, with
#     overrides that keep them portable across Debian (bookworm/trixie) and
#     Ubuntu (jammy/noble) -- for example "default-libmysqlclient-dev"
#     rather than the Ubuntu-only "libmysqlclient-dev".
#   * dnf names come from Package Manager for Red Hat 9 (also used for
#     Fedora and the RHEL rebuilds; yum platforms reuse them at run time).
#   * zypper names come from Package Manager for openSUSE 15.6.
#   * apk names come from the hand-curated table below, because Package
#     Manager does not cover Alpine.
#
# Build tools (make and friends) are excluded: setup_advice() handles the
# toolchain separately. When Package Manager has no entry for a curated
# package on some distribution, no row is emitted for that package manager;
# bundled_sysreqs() reports the gap in the plan notes. The maintainer must
# review the diff this script produces before committing. The committed
# R/bundled-sysreqs.R is the source of truth.
#
# This script only refreshes the curated package set below; it never expands
# the table to the full Package Manager database.

source(file.path("R", "utils.R"))
source(file.path("R", "json.R"))

# Curated R packages tracked by the bundled fallback. Keep this list in
# sync with the table shipped in the package source.
bundled_packages <- c(
  "curl", "xml2", "openssl", "ragg", "systemfonts", "textshaping",
  "sf", "terra", "units", "git2r", "gert", "magick", "pdftools",
  "tesseract", "RPostgres", "RMariaDB", "RMySQL", "RODBC", "V8",
  "sodium", "stringi", "webp", "png", "jpeg", "tiff", "gsl", "RcppGSL",
  "gmp", "Rmpfr", "fftwtools", "hdf5r", "ncdf4",
  "igraph", "rJava", "jqr", "odbc", "av", "rsvg", "xslt", "protolite"
)

# Sources queried per package manager. yum platforms reuse the dnf names at
# run time, so no separate yum rows are stored.
ppm_sources <- list(
  apt = list(distribution = "ubuntu", release = "22.04"),
  dnf = list(distribution = "redhat", release = "9"),
  zypper = list(distribution = "opensuse", release = "15.6")
)

# Toolchain packages are advice for setup_advice(), not per-package
# requirements; drop them wherever Package Manager reports them.
build_tool_excludes <- c(
  "make", "automake", "autoconf", "cmake", "gcc", "gcc-c++", "g++",
  "build-essential", "pkg-config", "pkgconf", "pkgconf-pkg-config"
)

# Portability overrides applied to apt names, so the committed names work on
# both Debian and Ubuntu.
apt_overrides <- c(
  "libfreetype6-dev" = "libfreetype-dev",
  "libgsl0-dev" = "libgsl-dev",
  "libmysqlclient-dev" = "default-libmysqlclient-dev",
  "libxslt-dev" = "libxslt1-dev"
)

# Hand-curated Alpine (apk) names. Alpine is not covered by Package Manager;
# names follow the Alpine 3.20 main/community repositories. V8 is omitted:
# Alpine has no maintained libnode/libv8 development package.
apk_sysreqs <- list(
  curl = c("curl-dev", "openssl-dev"),
  xml2 = "libxml2-dev",
  openssl = "openssl-dev",
  ragg = c(
    "freetype-dev", "libjpeg-turbo-dev", "libpng-dev", "tiff-dev",
    "libwebp-dev"
  ),
  systemfonts = c("fontconfig-dev", "freetype-dev"),
  textshaping = c("freetype-dev", "fribidi-dev", "harfbuzz-dev"),
  sf = c("gdal-dev", "gdal-tools", "geos-dev", "proj-dev", "sqlite-dev"),
  terra = c("gdal-dev", "gdal-tools", "geos-dev", "proj-dev", "sqlite-dev"),
  units = "udunits-dev",
  git2r = c("libgit2-dev", "libssh2-dev", "openssl-dev"),
  gert = "libgit2-dev",
  magick = "imagemagick-dev",
  pdftools = c("poppler-data", "poppler-dev"),
  tesseract = c("leptonica-dev", "tesseract-ocr-dev"),
  RPostgres = "libpq-dev",
  RMariaDB = "mariadb-connector-c-dev",
  RMySQL = "mariadb-connector-c-dev",
  RODBC = "unixodbc-dev",
  sodium = "libsodium-dev",
  stringi = "icu-dev",
  webp = "libwebp-dev",
  png = "libpng-dev",
  jpeg = "libjpeg-turbo-dev",
  tiff = c("libjpeg-turbo-dev", "tiff-dev"),
  gsl = "gsl-dev",
  RcppGSL = "gsl-dev",
  gmp = "gmp-dev",
  Rmpfr = c("gmp-dev", "mpfr-dev"),
  fftwtools = "fftw-dev",
  hdf5r = "hdf5-dev",
  ncdf4 = "netcdf-dev",
  igraph = c("glpk-dev", "libxml2-dev"),
  rJava = "openjdk21-jdk",
  jqr = "jq-dev",
  odbc = "unixodbc-dev",
  av = "ffmpeg-dev",
  rsvg = "librsvg-dev",
  xslt = "libxslt-dev",
  protolite = "protobuf-dev"
)

quote_chr <- function(x) {
  paste0("\"", gsub("([\"\\\\])", "\\\\\\1", x), "\"")
}

format_chr_vector <- function(x, indent = "    ") {
  if (!length(x)) {
    return(paste0(indent, "character()"))
  }

  out <- paste0(indent, quote_chr(x), ifelse(seq_along(x) < length(x), ",", ""))
  out
}

ppm_sysreqs_url <- function(base_url, repo, distribution, release) {
  paste0(
    trim_slashes(base_url),
    "/__api__/repos/",
    url_encode(repo),
    "/sysreqs?all=true&distribution=",
    url_encode(distribution),
    "&release=",
    url_encode(release)
  )
}

download_ppm_sysreqs <- function(base_url, repo, distribution, release) {
  url <- ppm_sysreqs_url(base_url, repo, distribution, release)
  tmp <- tempfile("sysreqr-ppm-", fileext = ".json")
  on.exit(unlink(tmp), add = TRUE)
  utils::download.file(url, tmp, quiet = FALSE, mode = "wb")
  json_read_file(tmp)
}

normalize_ppm_packages <- function(response, package_manager) {
  items <- response$requirements %||% list()
  rows <- list()

  for (item in items) {
    r_package <- item$name %||% NA_character_
    req <- item$requirements %||% list()
    system_packages <- compact_chr(as_chr(req$packages))
    system_packages <- setdiff(system_packages, build_tool_excludes)
    if (!length(system_packages) || is.na(r_package) || !nzchar(r_package)) {
      next
    }

    for (system_package in system_packages) {
      rows[[length(rows) + 1L]] <- data.frame(
        r_package = r_package,
        package_manager = package_manager,
        system_package = system_package,
        stringsAsFactors = FALSE
      )
    }
  }

  if (!length(rows)) {
    stop("No system requirement rows were returned by Posit Package Manager.", call. = FALSE)
  }

  out <- unique(do.call(rbind, rows))
  out <- out[out$r_package %in% bundled_packages, , drop = FALSE]
  if (!nrow(out)) {
    stop(
      "No curated packages were found in the Package Manager response.",
      call. = FALSE
    )
  }
  out
}

apk_rows <- function() {
  rows <- lapply(names(apk_sysreqs), function(r_package) {
    data.frame(
      r_package = r_package,
      package_manager = "apk",
      system_package = apk_sysreqs[[r_package]],
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

bundled_data_lines <- function(data) {
  c(
    "# BEGIN BUNDLED SYSREQS DATA",
    "bundled_sysreqs_db <- data.frame(",
    "  r_package = c(",
    format_chr_vector(data$r_package),
    "  ),",
    "  package_manager = c(",
    format_chr_vector(data$package_manager),
    "  ),",
    "  system_package = c(",
    format_chr_vector(data$system_package),
    "  ),",
    "  stringsAsFactors = FALSE",
    ")",
    "# END BUNDLED SYSREQS DATA"
  )
}

replace_between_markers <- function(path, replacement) {
  lines <- readLines(path, warn = FALSE)
  start <- match("# BEGIN BUNDLED SYSREQS DATA", lines)
  end <- match("# END BUNDLED SYSREQS DATA", lines)

  if (is.na(start) || is.na(end) || start >= end) {
    stop("Could not find bundled data markers in ", path, call. = FALSE)
  }

  writeLines(c(lines[seq_len(start - 1L)], replacement, lines[-seq_len(end)]), path)
  invisible(path)
}

arg_or <- function(args, i, default) {
  if (length(args) >= i && nzchar(args[[i]])) args[[i]] else default
}

args <- commandArgs(trailingOnly = TRUE)
repo <- arg_or(args, 1L, "cran")
base_url <- arg_or(args, 2L, "https://packagemanager.posit.co")

parts <- lapply(names(ppm_sources), function(pm) {
  src <- ppm_sources[[pm]]
  response <- download_ppm_sysreqs(
    base_url = base_url,
    repo = repo,
    distribution = src$distribution,
    release = src$release
  )
  normalize_ppm_packages(response, package_manager = pm)
})
data <- do.call(rbind, c(parts, list(apk_rows())))

idx <- match(data$system_package, names(apt_overrides))
override <- data$package_manager == "apt" & !is.na(idx)
data$system_package[override] <- unname(apt_overrides[idx[override]])

data <- unique(data)
pm_order <- match(data$package_manager, c("apt", "dnf", "zypper", "apk"))
data <- data[order(pm_order, tolower(data$r_package), data$system_package), , drop = FALSE]

for (pm in c("apt", "dnf", "zypper", "apk")) {
  covered <- unique(data$r_package[data$package_manager == pm])
  missing <- setdiff(bundled_packages, covered)
  if (length(missing)) {
    message(
      "No ", pm, " rows for: ", paste(missing, collapse = ", "),
      " (bundled_sysreqs() will report these in the plan notes)."
    )
  }
}

replace_between_markers(
  path = file.path("R", "bundled-sysreqs.R"),
  replacement = bundled_data_lines(data)
)

message(
  "Updated bundled sysreq data with ",
  nrow(data),
  " rows across ",
  length(unique(data$package_manager)),
  " package managers."
)
