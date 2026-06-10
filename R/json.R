json_read_file <- function(path) {
  json_parse(paste(readLines(path, warn = FALSE), collapse = "\n"))
}

json_read_text <- function(text) {
  json_parse(text)
}

json_write <- function(x, path) {
  writeLines(json_serialize(x, pretty = TRUE), path)
  invisible(path)
}

json_parse <- function(text) {
  state <- new.env(parent = emptyenv())
  state$text <- paste(text, collapse = "\n")
  state$pos <- 1L
  state$n <- nchar(state$text, type = "chars")
  value <- json_parse_value(state)
  json_skip_ws(state)
  if (state$pos <= state$n) {
    stop("Invalid JSON: trailing content.", call. = FALSE)
  }
  value
}

json_parse_value <- function(state) {
  json_skip_ws(state)
  ch <- json_peek(state)

  if (identical(ch, "{")) {
    return(json_parse_object(state))
  }
  if (identical(ch, "[")) {
    return(json_parse_array(state))
  }
  if (identical(ch, '"')) {
    return(json_parse_string(state))
  }
  if (grepl("[-0-9]", ch)) {
    return(json_parse_number(state))
  }
  if (json_starts_with(state, "true")) {
    state$pos <- state$pos + 4L
    return(TRUE)
  }
  if (json_starts_with(state, "false")) {
    state$pos <- state$pos + 5L
    return(FALSE)
  }
  if (json_starts_with(state, "null")) {
    state$pos <- state$pos + 4L
    return(NULL)
  }

  stop("Invalid JSON value.", call. = FALSE)
}

json_parse_object <- function(state) {
  json_expect(state, "{")
  json_skip_ws(state)
  out <- list()
  if (identical(json_peek(state), "}")) {
    state$pos <- state$pos + 1L
    return(out)
  }

  repeat {
    key <- json_parse_string(state)
    json_skip_ws(state)
    json_expect(state, ":")
    out[[key]] <- json_parse_value(state)
    json_skip_ws(state)

    ch <- json_peek(state)
    if (identical(ch, "}")) {
      state$pos <- state$pos + 1L
      break
    }
    json_expect(state, ",")
  }

  out
}

json_parse_array <- function(state) {
  json_expect(state, "[")
  json_skip_ws(state)
  out <- list()
  if (identical(json_peek(state), "]")) {
    state$pos <- state$pos + 1L
    return(out)
  }

  repeat {
    out[[length(out) + 1L]] <- json_parse_value(state)
    json_skip_ws(state)
    ch <- json_peek(state)
    if (identical(ch, "]")) {
      state$pos <- state$pos + 1L
      break
    }
    json_expect(state, ",")
  }

  out
}

json_parse_string <- function(state) {
  json_expect(state, '"')
  chars <- character()

  repeat {
    if (state$pos > state$n) {
      stop("Invalid JSON string.", call. = FALSE)
    }
    ch <- substr(state$text, state$pos, state$pos)
    state$pos <- state$pos + 1L

    if (identical(ch, '"')) {
      break
    }

    code <- utf8ToInt(ch)
    if (length(code) && code <= 31L) {
      stop("Invalid JSON: unescaped control character.", call. = FALSE)
    }

    if (identical(ch, "\\")) {
      esc <- substr(state$text, state$pos, state$pos)
      state$pos <- state$pos + 1L
      ch <- switch(
        esc,
        '"' = '"',
        "\\" = "\\",
        "/" = "/",
        "b" = "\b",
        "f" = "\f",
        "n" = "\n",
        "r" = "\r",
        "t" = "\t",
        "u" = json_parse_unicode_escape(state),
        stop("Invalid JSON escape.", call. = FALSE)
      )
    }

    chars <- c(chars, ch)
  }

  paste(chars, collapse = "")
}

json_parse_unicode_escape <- function(state) {
  int <- json_parse_hex4(state)

  # High surrogate: must be followed by an escaped low surrogate; combine
  # the pair into a single supplementary code point (e.g. emoji).
  if (int >= 0xD800L && int <= 0xDBFFL) {
    if (!identical(substr(state$text, state$pos, state$pos + 1L), "\\u")) {
      stop("Invalid JSON unicode escape: unpaired surrogate.", call. = FALSE)
    }
    state$pos <- state$pos + 2L
    low <- json_parse_hex4(state)
    if (low < 0xDC00L || low > 0xDFFFL) {
      stop("Invalid JSON unicode escape: unpaired surrogate.", call. = FALSE)
    }
    int <- 0x10000L + (int - 0xD800L) * 0x400L + (low - 0xDC00L)
  } else if (int >= 0xDC00L && int <= 0xDFFFL) {
    stop("Invalid JSON unicode escape: unpaired surrogate.", call. = FALSE)
  }

  intToUtf8(int)
}

json_parse_hex4 <- function(state) {
  hex <- substr(state$text, state$pos, state$pos + 3L)
  if (!grepl("^[0-9a-fA-F]{4}$", hex)) {
    stop("Invalid JSON unicode escape.", call. = FALSE)
  }
  state$pos <- state$pos + 4L
  strtoi(hex, base = 16L)
}

json_parse_number <- function(state) {
  rest <- substr(state$text, state$pos, state$n)
  match <- regexpr("^-?(0|[1-9][0-9]*)([.][0-9]+)?([eE][+-]?[0-9]+)?", rest)
  if (match < 0) {
    stop("Invalid JSON number.", call. = FALSE)
  }
  token <- regmatches(rest, match)
  state$pos <- state$pos + nchar(token, type = "chars")
  value <- as.numeric(token)
  if (is.na(value)) {
    stop("Invalid JSON number.", call. = FALSE)
  }
  value
}

json_skip_ws <- function(state) {
  while (state$pos <= state$n) {
    ch <- substr(state$text, state$pos, state$pos)
    if (!ch %in% c(" ", "\n", "\r", "\t")) {
      break
    }
    state$pos <- state$pos + 1L
  }
}

json_peek <- function(state) {
  if (state$pos > state$n) {
    return("")
  }
  substr(state$text, state$pos, state$pos)
}

json_expect <- function(state, expected) {
  json_skip_ws(state)
  actual <- json_peek(state)
  if (!identical(actual, expected)) {
    stop("Invalid JSON syntax.", call. = FALSE)
  }
  state$pos <- state$pos + 1L
}

json_starts_with <- function(state, token) {
  substr(state$text, state$pos, state$pos + nchar(token) - 1L) == token
}

json_serialize <- function(x, pretty = FALSE, indent = 0L) {
  if (is.data.frame(x)) {
    x <- lapply(seq_len(nrow(x)), function(i) as.list(x[i, , drop = FALSE]))
  }

  if (is.null(x)) {
    return("null")
  }

  if (is.character(x)) {
    if (length(x) != 1L) {
      return(json_serialize_array(as.list(x), pretty, indent))
    }
    return(json_quote(x))
  }

  if (is.logical(x)) {
    if (length(x) != 1L) {
      return(json_serialize_array(as.list(x), pretty, indent))
    }
    if (is.na(x)) "null" else if (x) "true" else "false"
  } else if (is.numeric(x) || is.integer(x)) {
    if (length(x) != 1L) {
      return(json_serialize_array(as.list(x), pretty, indent))
    }
    if (is.na(x)) "null" else as.character(x)
  } else if (is.list(x)) {
    if (is.null(names(x)) || all(!nzchar(names(x)))) {
      json_serialize_array(x, pretty, indent)
    } else {
      json_serialize_object(x, pretty, indent)
    }
  } else {
    json_quote(as.character(x))
  }
}

json_serialize_array <- function(x, pretty, indent) {
  values <- vapply(x, json_serialize, character(1), pretty = pretty, indent = indent + 2L)
  if (!pretty) {
    return(paste0("[", paste(values, collapse = ","), "]"))
  }
  pad <- paste(rep(" ", indent + 2L), collapse = "")
  end <- paste(rep(" ", indent), collapse = "")
  paste0("[\n", paste0(pad, values, collapse = ",\n"), "\n", end, "]")
}

json_serialize_object <- function(x, pretty, indent) {
  names <- names(x)
  values <- vapply(x, json_serialize, character(1), pretty = pretty, indent = indent + 2L)
  entries <- paste0(json_quote(names), if (pretty) ": " else ":", values)
  if (!pretty) {
    return(paste0("{", paste(entries, collapse = ","), "}"))
  }
  pad <- paste(rep(" ", indent + 2L), collapse = "")
  end <- paste(rep(" ", indent), collapse = "")
  paste0("{\n", paste0(pad, entries, collapse = ",\n"), "\n", end, "}")
}

json_quote <- function(x) {
  # All replacements run with fixed = TRUE, where gsub() uses the
  # replacement text literally: "\\n" is the two characters backslash + n.
  x <- gsub("\\", "\\\\", x, fixed = TRUE)
  x <- gsub('"', '\\"', x, fixed = TRUE)
  x <- gsub("\n", "\\n", x, fixed = TRUE)
  x <- gsub("\r", "\\r", x, fixed = TRUE)
  x <- gsub("\t", "\\t", x, fixed = TRUE)
  x <- gsub("\b", "\\b", x, fixed = TRUE)
  x <- gsub("\f", "\\f", x, fixed = TRUE)
  x <- vapply(x, json_escape_control, character(1), USE.NAMES = FALSE)
  paste0('"', x, '"')
}

json_escape_control <- function(x) {
  if (is.na(x) || !grepl("[\x01-\x1F]", x)) {
    return(x)
  }
  chars <- strsplit(x, "", fixed = TRUE)[[1]]
  codes <- vapply(chars, utf8ToInt, integer(1), USE.NAMES = FALSE)
  control <- !is.na(codes) & codes <= 31L
  chars[control] <- sprintf("\\u%04x", codes[control])
  paste(chars, collapse = "")
}
