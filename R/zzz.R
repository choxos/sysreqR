.onAttach <- function(libname, pkgname) {
  if (!interactive()) {
    return()
  }
  ver <- utils::packageVersion(pkgname)
  msg <- c(
    sprintf("sysreqr %s", ver),
    "",
    "New here? Try setup_advice(platform = \"ubuntu-24.04\"),",
    "or help(package = \"sysreqr\") for the function reference.",
    "",
    "Guides and articles: https://choxos.github.io/sysreqR/articles/",
    "Source and issues:   https://github.com/choxos/sysreqR",
    "",
    "Suppress this message with suppressPackageStartupMessages()."
  )
  packageStartupMessage(paste(msg, collapse = "\n"))
}
