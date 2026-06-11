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

test_that("diagnose_log maps system package names per package manager", {
  withr::local_options(sysreqr.installed_system_packages = character())
  log <- "fatal error: libxml/parser.h: No such file or directory"

  fedora <- diagnose_log(text = log, platform = "fedora-40")
  expect_equal(fedora$system_package, "libxml2-devel")
  expect_match(fedora$notes, "mapped for dnf", fixed = TRUE)

  pkgconf <- diagnose_log(
    text = "pkg-config was not found",
    platform = "fedora-40"
  )
  expect_equal(pkgconf$system_package, "pkgconf-pkg-config")

  # yum platforms reuse the dnf (EL) names.
  centos <- diagnose_log(text = log, platform = "centos7")
  expect_equal(centos$system_package, "libxml2-devel")

  # apt output is unchanged and carries no mapping caveat.
  ubuntu <- diagnose_log(text = log, platform = "ubuntu-22.04")
  expect_equal(ubuntu$system_package, "libxml2-dev")
  expect_false(any(grepl("mapped for", ubuntu$notes, fixed = TRUE)))
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

test_that("diagnose_log propagates unresolved when the ppm backend falls back to bundled", {
  # Force the PPM call to fail so ppm_sysreqs() falls back to the bundled
  # database, which tags the unknown package as unresolved. That attribute
  # must survive the merge in diagnose_log().
  failing_mock <- function(endpoint, query, base_url) {
    stop("simulated PPM outage", call. = FALSE)
  }
  withr::local_options(
    sysreqr.ppm_get = failing_mock,
    sysreqr.installed_system_packages = character()
  )

  plan <- diagnose_log(
    text = "installation of package 'unknownpkg' had non-zero exit status",
    platform = "ubuntu-22.04",
    backend = "ppm"
  )

  expect_equal(attr(plan, "unresolved"), "unknownpkg")
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

test_that("expanded log patterns map common libraries per package manager", {
  cases <- list(
    list("fatal error: png.h: No such file or directory", "ubuntu-22.04", "libpng-dev"),
    list("fatal error: png.h: No such file or directory", "fedora-40", "libpng-devel"),
    list("/usr/bin/ld: cannot find -lpq", "ubuntu-22.04", "libpq-dev"),
    list("/usr/bin/ld: cannot find -lpq", "fedora-40", "libpq-devel"),
    list("fatal error: sqlite3.h: No such file or directory", "opensuse156", "sqlite3-devel"),
    list("fatal error: Magick++.h: No such file or directory", "ubuntu-22.04", "libmagick++-dev"),
    list("fatal error: ft2build.h: No such file or directory", "alpine-3.20", "freetype-dev"),
    list("fatal error: unicode/ucnv.h: No such file or directory", "fedora-40", "libicu-devel"),
    list("/usr/bin/ld: cannot find -lz", "ubuntu-22.04", "zlib1g-dev"),
    list("fatal error: cairo.h: No such file or directory", "ubuntu-22.04", "libcairo2-dev"),
    list(
      "fatal error: mysql.h: No such file or directory",
      "ubuntu-22.04", "default-libmysqlclient-dev"
    ),
    list(
      "fatal error: tesseract/baseapi.h: No such file or directory",
      "fedora-40", "tesseract-devel"
    )
  )
  for (case in cases) {
    plan <- diagnose_log(text = case[[1]], platform = case[[2]], check_installed = FALSE)
    expect_true(
      case[[3]] %in% plan$system_package,
      label = paste0(case[[2]], " / ", case[[1]], " -> ", case[[3]])
    )
  }
})

test_that("linker patterns do not over-match similar library names", {
  # -lzstd must not trigger the zlib rule, -lgmpxx must not trigger gmp.
  zstd <- diagnose_log(
    text = "/usr/bin/ld: cannot find -lzstd",
    platform = "ubuntu-22.04",
    check_installed = FALSE
  )
  expect_false("zlib1g-dev" %in% zstd$system_package)

  gmpxx <- diagnose_log(
    text = "/usr/bin/ld: cannot find -lgmpxx",
    platform = "ubuntu-22.04",
    check_installed = FALSE
  )
  expect_false("libgmp3-dev" %in% gmpxx$system_package)
})

test_that("a header and linker hit for the same library produce one suggestion", {
  text <- paste(
    "fatal error: png.h: No such file or directory",
    "/usr/bin/ld: cannot find -lpng",
    sep = "\n"
  )
  plan <- diagnose_log(text = text, platform = "ubuntu-22.04", check_installed = FALSE)
  expect_equal(sum(plan$system_package == "libpng-dev"), 1L)
})
