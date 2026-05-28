`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

empty_chr <- function() {
  character()
}

compact_chr <- function(x) {
  x <- x[!is.na(x) & nzchar(x)]
  unique(x)
}

as_chr <- function(x) {
  if (is.null(x)) {
    character()
  } else {
    as.character(unlist(x, recursive = TRUE, use.names = FALSE))
  }
}

extract_commands <- function(x) {
  if (is.null(x)) {
    return(character())
  }

  if (is.character(x)) {
    return(compact_chr(x))
  }

  if (is.list(x)) {
    out <- unlist(lapply(x, function(elt) {
      if (is.list(elt) && !is.null(elt$command)) {
        elt$command
      } else {
        elt
      }
    }), recursive = TRUE, use.names = FALSE)
    return(compact_chr(as.character(out)))
  }

  compact_chr(as.character(x))
}

trim_slashes <- function(x) {
  sub("/+$", "", x)
}

url_encode <- function(x) {
  utils::URLencode(as.character(x), reserved = TRUE)
}

build_query <- function(query) {
  query <- query[!vapply(query, is.null, logical(1))]
  if (!length(query)) {
    return("")
  }

  parts <- unlist(Map(function(name, value) {
    if (is.logical(value)) {
      value <- ifelse(value, "true", "false")
    }
    paste0(url_encode(name), "=", url_encode(value))
  }, names(query), query), use.names = FALSE)

  paste(parts, collapse = "&")
}

is_simple_package_name <- function(x) {
  grepl("^[A-Za-z][A-Za-z0-9.]*$", x)
}

package_manager_for_distro <- function(distro, version = NA_character_) {
  distro <- tolower(distro %||% "")
  version <- as.character(version %||% NA_character_)

  if (distro %in% c("ubuntu", "debian")) {
    "apt"
  } else if (distro %in% c("fedora", "rocky", "rockylinux", "almalinux")) {
    "dnf"
  } else if (distro %in% c("redhat", "rhel", "centos")) {
    major <- sub("[.].*$", "", version)
    if (major %in% c("6", "7")) "yum" else "dnf"
  } else if (distro %in% c("opensuse", "opensuse-leap", "sles", "sle")) {
    "zypper"
  } else if (distro == "alpine") {
    "apk"
  } else if (distro == "macos") {
    "brew"
  } else {
    NA_character_
  }
}

platform_label <- function(platform) {
  if (is.null(platform)) {
    return("unknown")
  }

  if (!is.null(platform$label)) {
    return(platform$label)
  }

  distro <- platform$distro %||% platform$os %||% "unknown"
  version <- platform$version %||% ""
  paste(compact_chr(c(distro, version)), collapse = " ")
}

read_lines_if_exists <- function(path) {
  if (!file.exists(path)) {
    return(character())
  }
  readLines(path, warn = FALSE)
}

is_package_installed <- function(package) {
  nzchar(system.file(package = package))
}

list_to_data_frame <- function(x) {
  if (!length(x)) {
    return(data.frame())
  }

  names <- unique(unlist(lapply(x, names), use.names = FALSE))
  cols <- lapply(names, function(name) {
    values <- lapply(x, `[[`, name)
    I(values)
  })
  names(cols) <- names
  out <- as.data.frame(cols, stringsAsFactors = FALSE)

  for (name in names(out)) {
    values <- out[[name]]
    scalar <- vapply(values, function(value) length(value) <= 1 && !is.list(value), logical(1))
    if (all(scalar)) {
      out[[name]] <- unlist(values, use.names = FALSE)
    }
  }

  out
}
