# Release utility for updating bundled apt system requirement data.
# Run from the package root as part of release preparation.

source(file.path("R", "utils.R"))
source(file.path("R", "json.R"))

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

args <- commandArgs(trailingOnly = TRUE)
distribution <- args[[1L]] %||% "ubuntu"
release <- args[[2L]] %||% "22.04"
repo <- args[[3L]] %||% "cran"
base_url <- args[[4L]] %||% "https://packagemanager.posit.co"

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
