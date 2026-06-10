# Release utility for refreshing the bundled apt system requirement data.
# Run from the package root as part of release preparation, e.g.
#   Rscript data-raw/update-bundled-sysreqs.R ubuntu 22.04
#
# The bundled table is a small, hand-curated fallback for common CRAN
# packages. It targets an apt baseline (Ubuntu 22.04 by default), but the
# committed names in R/bundled-sysreqs.R are deliberately chosen to be
# portable across Debian (bookworm/trixie) and Ubuntu (jammy/noble) -- for
# example "default-libmysqlclient-dev" rather than the Ubuntu-only
# "libmysqlclient-dev". Posit Package Manager returns Ubuntu-specific names,
# so the maintainer must review the diff this script produces and re-apply
# any portable substitutions before committing. The committed
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

normalize_ppm_packages <- function(response) {
  items <- response$requirements %||% list()
  rows <- list()

  for (item in items) {
    r_package <- item$name %||% NA_character_
    req <- item$requirements %||% list()
    system_packages <- compact_chr(as_chr(req$packages))
    if (!length(system_packages) || is.na(r_package) || !nzchar(r_package)) {
      next
    }

    for (system_package in system_packages) {
      rows[[length(rows) + 1L]] <- data.frame(
        r_package = r_package,
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
  out[order(tolower(out$r_package), out$system_package), , drop = FALSE]
}

bundled_data_lines <- function(data) {
  c(
    "# BEGIN BUNDLED SYSREQS DATA",
    "bundled_sysreqs_db <- data.frame(",
    "  r_package = c(",
    format_chr_vector(data$r_package),
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
distribution <- arg_or(args, 1L, "ubuntu")
release <- arg_or(args, 2L, "22.04")
repo <- arg_or(args, 3L, "cran")
base_url <- arg_or(args, 4L, "https://packagemanager.posit.co")

response <- download_ppm_sysreqs(
  base_url = base_url,
  repo = repo,
  distribution = distribution,
  release = release
)
data <- normalize_ppm_packages(response)
replace_between_markers(
  path = file.path("R", "bundled-sysreqs.R"),
  replacement = bundled_data_lines(data)
)

message(
  "Updated bundled sysreq data for ",
  distribution,
  " ",
  release,
  " with ",
  nrow(data),
  " rows."
)
