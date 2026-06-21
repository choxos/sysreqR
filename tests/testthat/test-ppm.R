test_that("ppm_sysreqs normalizes package requirements", {
  withr::local_options(
    sysreqr.ppm_get = mock_ppm_get,
    sysreqr.installed_system_packages = character()
  )

  plan <- ppm_sysreqs(c("xml2", "curl"), platform = "ubuntu-22.04")

  expect_s3_class(plan, "sysreqr_plan")
  expect_equal(sort(unique(plan$r_package)), c("curl", "xml2"))
  expect_true("libxml2-dev" %in% plan$system_package)
  expect_true("libcurl4-openssl-dev" %in% plan$system_package)
  expect_false(any(plan$installed, na.rm = TRUE))
})

test_that("ppm_repo creates binary repository URL", {
  url <- ppm_repo(platform = "ubuntu-24.04")
  expect_equal(url, "https://packagemanager.posit.co/cran/__linux__/noble/latest")
})

test_that("ppm_repo errors when no binary URL is known", {
  macos <- list(
    os = "macos", distro = "macos", version = "14",
    codename = NA_character_, package_manager = "brew",
    ppm_binary_url = NA_character_, supported = FALSE, label = "macOS"
  )
  expect_error(ppm_repo(platform = macos), "No Package Manager binary URL")
})

test_that("ppm_platforms lists distros via the mock", {
  withr::local_options(sysreqr.ppm_get = mock_ppm_get)
  df <- ppm_platforms()
  expect_s3_class(df, "data.frame")
  expect_true(all(c("name", "distribution", "release") %in% names(df)))
})

test_that("check_ppm reports support", {
  withr::local_options(sysreqr.ppm_get = mock_ppm_get)
  status <- check_ppm("ubuntu-22.04")

  expect_true(status$supported)
  expect_true(status$binaries)
})

test_that("check_ppm reports unsupported platforms", {
  withr::local_options(sysreqr.ppm_get = mock_ppm_get)
  status <- check_ppm("debian-12")
  expect_false(status$supported)
})

test_that("ppm_sysreqs handles missing install scripts", {
  mock <- function(endpoint, query, base_url) {
    if (identical(endpoint, "status")) {
      return(mock_ppm_get(endpoint, query, base_url))
    }
    list(requirements = list(list(
      name = "demo",
      requirements = list(packages = list("libdemo-dev"))
    )))
  }
  withr::local_options(
    sysreqr.ppm_get = mock,
    sysreqr.installed_system_packages = character()
  )

  plan <- ppm_sysreqs("demo", platform = "ubuntu-22.04")

  expect_s3_class(plan, "sysreqr_plan")
  expect_equal(plan$system_package, "libdemo-dev")
  expect_equal(plan$install_script, "apt-get install -y libdemo-dev")
})

test_that("ppm_sysreqs falls back to bundled data on API error", {
  failing_mock <- function(endpoint, query, base_url) {
    stop("simulated PPM outage", call. = FALSE)
  }
  withr::local_options(
    sysreqr.ppm_get = failing_mock,
    sysreqr.installed_system_packages = character()
  )

  plan <- ppm_sysreqs("xml2", platform = "ubuntu-22.04")

  expect_s3_class(plan, "sysreqr_plan")
  expect_true("libxml2-dev" %in% plan$system_package)
  expect_match(attr(plan, "fallback_error"), "simulated PPM outage")
})

test_that("ppm_sysreqs API-error fallback uses platform-matching bundled names", {
  failing_mock <- function(endpoint, query, base_url) {
    stop("simulated PPM outage", call. = FALSE)
  }
  withr::local_options(
    sysreqr.ppm_get = failing_mock,
    sysreqr.installed_system_packages = character()
  )

  suse <- ppm_sysreqs("xml2", platform = "opensuse156")
  expect_true("libxml2-devel" %in% suse$system_package)
  expect_match(attr(suse, "fallback_error"), "simulated PPM outage")

  rocky <- ppm_sysreqs("xml2", platform = "rockylinux-9")
  expect_true("libxml2-devel" %in% rocky$system_package)
  expect_match(rocky$install_script, "^dnf install")
})

test_that("ppm_sysreqs API-error fallback returns an empty plan on brew", {
  # Regression test: this previously hard-errored with "Bundled fallback data
  # currently supports apt platforms only." instead of reporting the original
  # Package Manager failure.
  failing_mock <- function(endpoint, query, base_url) {
    stop("simulated PPM outage", call. = FALSE)
  }
  withr::local_options(
    sysreqr.ppm_get = failing_mock,
    sysreqr.installed_system_packages = character()
  )
  platform <- resolve_platform("ubuntu-22.04")
  platform$package_manager <- "brew"

  plan <- ppm_sysreqs("xml2", platform = platform)
  expect_s3_class(plan, "sysreqr_plan")
  expect_equal(nrow(plan), 0L)
  expect_equal(attr(plan, "unresolved"), "xml2")
  expect_match(attr(plan, "fallback_error"), "simulated PPM outage")
})

test_that("use_ppm dry_run returns repo configuration lines", {
  lines <- use_ppm("user", platform = "ubuntu-22.04", dry_run = TRUE)
  expect_true(any(grepl("packagemanager.posit.co", lines, fixed = TRUE)))
  expect_true(any(grepl("CRAN =", lines, fixed = TRUE)))
})

test_that("use_ppm writes to a path when dry_run is FALSE", {
  tmp <- withr::local_tempfile(pattern = "Rprofile-")
  result <- use_ppm(
    "project",
    platform = "ubuntu-22.04",
    dry_run = FALSE,
    path = tmp
  )
  content <- readLines(tmp, warn = FALSE)
  expect_true(any(grepl("# Added by sysreqr", content, fixed = TRUE)))
  expect_true(any(grepl("packagemanager.posit.co", content, fixed = TRUE)))
  expect_true(any(grepl("packagemanager.posit.co", result, fixed = TRUE)))
})

test_that("use_ppm requires an explicit path when dry_run is FALSE", {
  expect_error(
    use_ppm("user", platform = "ubuntu-22.04", dry_run = FALSE),
    "`path` must be supplied",
    fixed = TRUE
  )
})

test_that("use_ppm path error suggests a scope-appropriate file", {
  expect_error(
    use_ppm("project", platform = "ubuntu-22.04", dry_run = FALSE),
    "project scope"
  )
  expect_error(
    use_ppm("user", platform = "ubuntu-22.04", dry_run = FALSE),
    "user scope"
  )
})

test_that("ppm_sysreqs keeps requirements with only post-install commands", {
  mock <- function(endpoint, query, base_url) {
    if (identical(endpoint, "status")) {
      return(mock_ppm_get(endpoint, query, base_url))
    }
    list(requirements = list(list(
      name = "demo",
      requirements = list(
        post_install = list(list(command = "R CMD javareconf"))
      )
    )))
  }
  withr::local_options(
    sysreqr.ppm_get = mock,
    sysreqr.installed_system_packages = character()
  )

  plan <- ppm_sysreqs("demo", platform = "ubuntu-22.04")

  expect_equal(nrow(plan), 1L)
  expect_equal(plan$r_package, "demo")
  expect_match(plan$post_install, "javareconf", fixed = TRUE)
  expect_true("R CMD javareconf" %in% attr(plan, "post_install"))
})
