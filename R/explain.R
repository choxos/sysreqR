#' Explain system requirements
#'
#' Prints a short, friendly explanation for each system package an R package
#' needs and the command to install it. Useful for teaching and for emails to
#' less-experienced collaborators.
#'
#' @param x A package name, package vector, or `sysreqr_plan`.
#' @param platform Platform specification accepted by [resolve_platform()].
#' @param ... Passed to [check_packages()] when `x` is not a plan.
#'
#' @return A character vector of explanation lines, invisibly.
#' @family setup
#' @export
#' @examples
#' plan <- check_packages("xml2", platform = "ubuntu-22.04")
#' explain(plan)
explain <- function(x, platform = NULL, ...) {
  plan <- ensure_plan(x, platform = platform, ...)
  if (!nrow(plan)) {
    out <- "No external system requirements were detected."
    cat(out, "\n", sep = "")
    return(invisible(out))
  }

  df <- as_data_frame(plan)
  pairs <- unique(df[, c("r_package", "system_package", "sysreq")])
  lines <- c("System requirement explanation", "")

  for (i in seq_len(nrow(pairs))) {
    rpkg <- pairs$r_package[[i]]
    spkg <- pairs$system_package[[i]]
    sysreq <- pairs$sysreq[[i]]
    if (is.na(spkg) || !nzchar(spkg)) {
      next
    }
    need <- if (!is.na(sysreq) && nzchar(sysreq)) {
      paste0(" for ", sysreq)
    } else {
      ""
    }
    lines <- c(
      lines,
      paste0(rpkg, " needs ", spkg, need, "."),
      paste0("Install it with: ", install_script_for_package(spkg, attr(plan, "platform_info"))),
      ""
    )
  }

  cat(paste(lines, collapse = "\n"), "\n", sep = "")
  invisible(lines)
}
