# Bundled data is updated with each release.
# BEGIN BUNDLED SYSREQS DATA
bundled_sysreqs_db <- data.frame(
  r_package = c(
    "curl", "curl",
    "xml2",
    "openssl",
    "ragg", "ragg", "ragg", "ragg", "ragg",
    "systemfonts", "systemfonts",
    "textshaping", "textshaping", "textshaping",
    "sf", "sf", "sf", "sf", "sf",
    "terra", "terra", "terra", "terra", "terra",
    "units",
    "git2r", "git2r", "git2r",
    "gert",
    "magick", "magick",
    "pdftools", "pdftools",
    "tesseract", "tesseract", "tesseract",
    "RPostgres",
    "RMariaDB",
    "RMySQL",
    "RODBC",
    "V8",
    "sodium",
    "stringi",
    "webp",
    "png",
    "jpeg",
    "tiff",
    "gsl",
    "RcppGSL",
    "gmp",
    "Rmpfr", "Rmpfr",
    "fftwtools",
    "hdf5r",
    "ncdf4",
    "igraph", "igraph",
    "rJava",
    "jqr",
    "odbc",
    "av",
    "rsvg",
    "xslt",
    "protolite", "protolite", "protolite"
  ),
  system_package = c(
    "libcurl4-openssl-dev", "libssl-dev",
    "libxml2-dev",
    "libssl-dev",
    "libfreetype-dev", "libjpeg-dev", "libpng-dev", "libtiff-dev", "libwebp-dev",
    "libfontconfig1-dev", "libfreetype-dev",
    "libfreetype-dev", "libfribidi-dev", "libharfbuzz-dev",
    "libgdal-dev", "gdal-bin", "libgeos-dev", "libproj-dev", "libsqlite3-dev",
    "libgdal-dev", "gdal-bin", "libgeos-dev", "libproj-dev", "libsqlite3-dev",
    "libudunits2-dev",
    "libgit2-dev", "libssh2-1-dev", "libssl-dev",
    "libgit2-dev",
    "libmagick++-dev", "gsfonts",
    "poppler-data", "libpoppler-cpp-dev",
    "libleptonica-dev", "libtesseract-dev", "tesseract-ocr-eng",
    "libpq-dev",
    "default-libmysqlclient-dev",
    "default-libmysqlclient-dev",
    "unixodbc-dev",
    "libnode-dev",
    "libsodium-dev",
    "libicu-dev",
    "libwebp-dev",
    "libpng-dev",
    "libjpeg-dev",
    "libtiff-dev",
    "libgsl-dev",
    "libgsl-dev",
    "libgmp3-dev",
    "libgmp3-dev", "libmpfr-dev",
    "libfftw3-dev",
    "libhdf5-dev",
    "libnetcdf-dev",
    "libglpk-dev", "libxml2-dev",
    "default-jdk",
    "libjq-dev",
    "unixodbc-dev",
    "libavfilter-dev",
    "librsvg2-dev",
    "libxslt1-dev",
    "libprotobuf-dev", "protobuf-compiler", "libprotoc-dev"
  ),
  stringsAsFactors = FALSE
)
# END BUNDLED SYSREQS DATA

bundled_sysreqs <- function(packages, platform, repo = "cran", error = NULL) {
  if (!identical(platform$package_manager, "apt")) {
    if (!is.null(error)) {
      stop(error)
    }
    stop("Bundled fallback data currently supports apt platforms only.", call. = FALSE)
  }

  packages <- compact_chr(packages)
  data <- bundled_sysreqs_db[bundled_sysreqs_db$r_package %in% packages, , drop = FALSE]
  unresolved <- setdiff(packages, bundled_sysreqs_db$r_package)

  if (!nrow(data)) {
    if (!is.null(error)) {
      stop(error)
    }
    plan <- new_sysreqr_plan(platform_info = platform, backend = "bundled")
    attr(plan, "unresolved") <- unresolved
    return(plan)
  }

  data$sysreq <- NA_character_
  data$install_script <- vapply(
    data$system_package,
    install_script_for_package,
    character(1),
    platform = platform
  )
  data$pre_install <- NA_character_
  data$post_install <- NA_character_
  data$platform <- paste0(platform$distro, "-", platform$version)
  data$package_manager <- platform$package_manager
  data$installed <- NA
  data$source <- "bundled"
  data$confidence <- "medium"
  data$notes <- paste0(
    "Requirement from bundled sysreqR fallback data for repository `",
    repo,
    "`."
  )

  plan <- new_sysreqr_plan(
    data,
    platform_info = platform,
    backend = "bundled"
  )
  attr(plan, "unresolved") <- unresolved
  plan
}

bundled_has_packages <- function(packages) {
  all(compact_chr(packages) %in% bundled_sysreqs_db$r_package)
}
