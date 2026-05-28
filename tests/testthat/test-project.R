test_that("detect_project_packages reads DESCRIPTION", {
  tmp <- withr::local_tempdir()
  writeLines(c(
    "Package: demo",
    "Version: 0.0.1",
    "Imports: xml2, curl",
    "Suggests: tinytest"
  ), file.path(tmp, "DESCRIPTION"))

  expect_equal(detect_project_packages(tmp), c("curl", "xml2"))
  expect_equal(
    detect_project_packages(tmp, include_suggests = TRUE),
    c("curl", "tinytest", "xml2")
  )
})

test_that("detect_project_packages reads renv.lock", {
  tmp <- withr::local_tempdir()
  writeLines(
    '{"Packages":{"R":{},"xml2":{},"curl":{}}}',
    file.path(tmp, "renv.lock")
  )

  expect_equal(detect_project_packages(tmp), c("curl", "xml2"))
})

test_that("detect_project_packages scans source files when no manifest exists", {
  tmp <- withr::local_tempdir()
  writeLines(
    c("library(xml2)", "curl::curl_fetch_memory('https://example.com')"),
    file.path(tmp, "main.R")
  )

  pkgs <- detect_project_packages(tmp)
  expect_true("xml2" %in% pkgs)
  expect_true("curl" %in% pkgs)
})

test_that("detect_project_packages detects requireNamespace()", {
  tmp <- withr::local_tempdir()
  writeLines(
    c(
      "requireNamespace(\"xml2\")",
      "if (requireNamespace('jsonlite', quietly = TRUE)) {}"
    ),
    file.path(tmp, "main.R")
  )

  pkgs <- detect_project_packages(tmp)
  expect_true("xml2" %in% pkgs)
  expect_true("jsonlite" %in% pkgs)
})

test_that("detect_project_packages ignores names in line comments", {
  tmp <- withr::local_tempdir()
  writeLines(
    c(
      "# foo::bar is just a comment",
      "# library(commentedpkg)",
      "library(xml2)"
    ),
    file.path(tmp, "main.R")
  )

  pkgs <- detect_project_packages(tmp)
  expect_true("xml2" %in% pkgs)
  expect_false("foo" %in% pkgs)
  expect_false("commentedpkg" %in% pkgs)
})

test_that("check_project routes through check_packages", {
  withr::local_options(
    sysreqr.ppm_get = mock_ppm_get,
    sysreqr.installed_system_packages = character()
  )

  tmp <- withr::local_tempdir()
  writeLines(c(
    "Package: demo",
    "Version: 0.0.1",
    "Imports: xml2"
  ), file.path(tmp, "DESCRIPTION"))

  plan <- check_project(tmp, platform = "ubuntu-22.04", backend = "bundled")
  expect_s3_class(plan, "sysreqr_plan")
  expect_true("libxml2-dev" %in% plan$system_package)
})
