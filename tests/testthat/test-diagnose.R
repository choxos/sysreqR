test_that("diagnose_log maps common headers to system packages", {
  log <- "fatal error: libxml/parser.h: No such file or directory"
  plan <- diagnose_log(text = log, platform = "ubuntu-22.04")

  expect_s3_class(plan, "sysreqr_plan")
  expect_equal(plan$system_package, "libxml2-dev")
  expect_equal(plan$confidence, "high")
})

test_that("diagnose_log handles pkg-config failures", {
  log <- "pkg-config was not found"
  plan <- diagnose_log(text = log, platform = "ubuntu-22.04")

  expect_equal(plan$system_package, "pkg-config")
  expect_equal(plan$confidence, "medium")
})

test_that("failed package extraction reads common install failures", {
  text <- paste(
    "ERROR: configuration failed for package 'xml2'",
    "installation of package 'curl' had non-zero exit status",
    "ERROR: dependency 'openssl' is not available for package 'httr'",
    sep = "\n"
  )

  expect_equal(extract_failed_packages(text), c("xml2", "curl", "openssl"))
})

test_that("failed package extraction handles curly quotes and dependency lists", {
  text <- paste0(
    "ERROR: dependencies ‘curl’, ‘openssl’ are not available ",
    "for package ‘httr’"
  )

  expect_equal(extract_failed_packages(text), c("curl", "openssl"))
})

test_that("extract_dependency_failures does not split package names containing 'and'", {
  text <- "ERROR: dependency 'sandbox' is not available for package 'demo'"
  expect_equal(extract_dependency_failures(text), "sandbox")
})

test_that("check_error returns system requirements for failed packages", {
  withr::local_options(sysreqr.installed_system_packages = character())

  plan <- check_error(
    text = "ERROR: configuration failed for package 'xml2'",
    platform = "ubuntu-22.04",
    backend = "bundled"
  )

  expect_s3_class(plan, "sysreqr_plan")
  expect_equal(attr(plan, "failed_packages"), "xml2")
  expect_equal(plan$system_package, "libxml2-dev")
  expect_equal(plan$source, "failed-package-lookup")
  expect_equal(plan$confidence, "medium")
})

test_that("diagnose_log combines direct patterns and failed package lookup", {
  withr::local_options(sysreqr.installed_system_packages = character())

  text <- paste(
    "fatal error: libxml/parser.h: No such file or directory",
    "ERROR: configuration failed for package 'curl'",
    sep = "\n"
  )
  plan <- diagnose_log(text = text, platform = "ubuntu-22.04", backend = "bundled")

  expect_true("libxml2-dev" %in% plan$system_package)
  expect_true("libcurl4-openssl-dev" %in% plan$system_package)
  expect_true("manual-log-pattern" %in% plan$source)
  expect_true("failed-package-lookup" %in% plan$source)
  expect_equal(attr(plan, "failed_packages"), "curl")
})

test_that("unknown failed packages do not crash diagnosis", {
  plan <- diagnose_log(
    text = "installation of package 'unknownpkg' had non-zero exit status",
    platform = "ubuntu-22.04",
    backend = "bundled"
  )

  expect_s3_class(plan, "sysreqr_plan")
  expect_equal(nrow(plan), 0L)
  expect_equal(attr(plan, "failed_packages"), "unknownpkg")
})

test_that("diagnose_log preserves unresolved through the merged plan", {
  # Regression: merge_sysreqr_plans() previously dropped the `unresolved`
  # attribute, leading to a misleading "no requirements" message when the
  # only failed package was outside the bundled database.
  plan <- diagnose_log(
    text = "installation of package 'unknownpkg' had non-zero exit status",
    platform = "ubuntu-22.04",
    backend = "bundled"
  )

  expect_equal(attr(plan, "unresolved"), "unknownpkg")

  out <- paste(capture.output(print(plan)), collapse = "\n")
  expect_match(out, "no system requirement data was found for the failed package", fixed = TRUE)
  expect_match(out, "unknownpkg", fixed = TRUE)
})

test_that("diagnose_log surfaces direct hits and unresolved failed packages together", {
  text <- paste(
    "fatal error: libxml/parser.h: No such file or directory",
    "installation of package 'unknownpkg' had non-zero exit status",
    sep = "\n"
  )
  plan <- diagnose_log(
    text = text,
    platform = "ubuntu-22.04",
    backend = "bundled"
  )

  expect_true("libxml2-dev" %in% plan$system_package)
  expect_equal(attr(plan, "unresolved"), "unknownpkg")

  out <- paste(capture.output(print(plan)), collapse = "\n")
  expect_match(out, "libxml2-dev", fixed = TRUE)
  expect_match(out, "unknownpkg", fixed = TRUE)
})

test_that("diagnose_log rejects empty text", {
  expect_error(diagnose_log(text = ""), "Provide `path` or non-empty `text`.")
})

test_that("diagnose_failed_packages handles an empty package vector", {
  plan <- diagnose_failed_packages(character(), platform = "ubuntu-22.04")
  expect_s3_class(plan, "sysreqr_plan")
  expect_equal(nrow(plan), 0L)
})
