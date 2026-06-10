test_that("explain prints a beginner-friendly summary", {
  withr::local_options(sysreqr.installed_system_packages = character())
  plan <- check_packages("xml2", platform = "ubuntu-22.04")

  out <- capture.output(result <- explain(plan))
  expect_match(paste(out, collapse = "\n"), "libxml2-dev", fixed = TRUE)
  expect_invisible(explain(plan))
})

test_that("explain handles empty plans gracefully", {
  plan <- diagnose_log(text = "unrelated output", platform = "ubuntu-22.04")
  out <- capture.output(explain(plan))
  expect_match(paste(out, collapse = "\n"), "No external system requirements", fixed = TRUE)
})

test_that("explain handles diagnose plans without R package names", {
  withr::local_options(sysreqr.installed_system_packages = character())
  plan <- diagnose_log(
    text = "fatal error: libxml/parser.h: No such file or directory",
    platform = "ubuntu-22.04"
  )

  out <- paste(capture.output(explain(plan)), collapse = "\n")
  expect_match(out, "libxml2-dev is needed", fixed = TRUE)
  expect_false(grepl("NA needs", out, fixed = TRUE))
})
