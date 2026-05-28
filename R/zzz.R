.onAttach <- function(libname, pkgname) {
  if (!interactive()) {
    return()
  }
  ver <- utils::packageVersion(pkgname)
  msg <- c(
    sprintf("sysreqr %s", ver),
    "GitHub: https://github.com/choxos/sysreqR",
    "Docs:   https://choxos.github.io/sysreqR/",
    "",
    "New here? Start with:",
    "  setup_advice(platform = \"ubuntu-24.04\")",
    "  vignette(\"preflight-setup\", package = \"sysreqr\")",
    "  vignette(\"linux-fundamentals\", package = \"sysreqr\")",
    "",
    "Suppress this message with suppressPackageStartupMessages()."
  )
  packageStartupMessage(paste(msg, collapse = "\n"))
}
