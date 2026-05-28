test_that("auto backend uses bundled data for known packages on apt", {
  withr::local_options(sysreqr.installed_system_packages = character())

  plan <- check_packages(c("xml2", "curl"), platform = "ubuntu-22.04")

  expect_equal(attr(plan, "backend"), "bundled")
  expect_true("libxml2-dev" %in% plan$system_package)
  expect_true("libcurl4-openssl-dev" %in% plan$system_package)
})

test_that("auto backend does not pick bundled on non-apt platforms (regression)", {
  # Regression test: previously, select_backend() returned "bundled" for any
  # apt-keyed package set even on Fedora/Rocky/SUSE, which then hard-errored
  # with "Bundled fallback data currently supports apt platforms only."
  fedora <- resolve_platform("fedora-40")
  expect_false(identical(select_backend("xml2", "auto", fedora), "bundled"))

  rocky <- resolve_platform("rockylinux-9")
  expect_false(identical(select_backend("xml2", "auto", rocky), "bundled"))

  ubuntu <- resolve_platform("ubuntu-22.04")
  expect_equal(select_backend("xml2", "auto", ubuntu), "bundled")
})

test_that("check_packages on Fedora falls through without the apt-only error", {
  # When auto routing previously chose bundled on any platform with known
  # packages, this call errored with "Bundled fallback data currently supports
  # apt platforms only." Mock pak so the test does not depend on a real pak
  # install and pin the route to ppm with a mock that returns a Fedora plan.
  fedora_ppm_mock <- function(endpoint, query, base_url) {
    if (identical(endpoint, "status")) {
      return(list(
        version = "test",
        distros = list(list(
          os = "linux", distribution = "fedora", release = "40",
          name = "fedora-40", binaryURL = "fedora-40",
          sysReqs = TRUE, binaries = TRUE
        ))
      ))
    }
    list(requirements = list(list(
      name = "xml2",
      requirements = list(
        packages = list("libxml2-devel"),
        install_scripts = list("dnf install -y libxml2-devel")
      )
    )))
  }

  pak_mock <- function(pkg, ...) {
    list(
      packages = data.frame(
        sysreq = "libxml2",
        packages = I(list("xml2")),
        system_packages = I(list("libxml2-devel")),
        pre_install = I(list(character())),
        post_install = I(list(character())),
        stringsAsFactors = FALSE
      ),
      pre_install = character(),
      post_install = character()
    )
  }

  withr::local_options(
    sysreqr.ppm_get = fedora_ppm_mock,
    sysreqr.pak_pkg_sysreqs = pak_mock,
    sysreqr.installed_system_packages = character()
  )

  expect_no_error(
    plan <- check_packages("xml2", platform = "fedora-40", backend = "auto")
  )
  expect_s3_class(plan, "sysreqr_plan")
  expect_false(identical(attr(plan, "backend"), "bundled"))
})

test_that("check_packages errors when given no packages", {
  expect_error(check_packages(character(), platform = "ubuntu-22.04"),
               "at least one package")
})

test_that("ppm backend honours the requested platform", {
  withr::local_options(
    sysreqr.ppm_get = mock_ppm_get,
    sysreqr.installed_system_packages = character()
  )

  plan <- check_packages(
    c("xml2", "curl"),
    platform = "ubuntu-22.04",
    backend = "ppm"
  )

  expect_equal(attr(plan, "backend"), "ppm")
  expect_true(all(plan$platform == "ubuntu-22.04"))
})

test_that("bundled backend tracks unresolved packages for user visibility", {
  withr::local_options(sysreqr.installed_system_packages = character())

  plan <- check_packages(
    c("xml2", "anUnknownPackage"),
    platform = "ubuntu-22.04",
    backend = "bundled"
  )

  expect_equal(attr(plan, "unresolved"), "anUnknownPackage")

  out <- paste(capture.output(print(plan)), collapse = "\n")
  expect_match(out, "no bundled data was found for: anUnknownPackage", fixed = TRUE)
})

test_that("empty bundled plan surfaces all unresolved packages", {
  withr::local_options(sysreqr.installed_system_packages = character())

  plan <- check_packages(
    "totallyUnknown",
    platform = "ubuntu-22.04",
    backend = "bundled"
  )

  expect_equal(nrow(plan), 0L)
  expect_equal(attr(plan, "unresolved"), "totallyUnknown")

  out <- paste(capture.output(print(plan)), collapse = "\n")
  expect_match(out, "no bundled data was found for: totallyUnknown", fixed = TRUE)
})

test_that("column subsets do not keep plan class when required columns are absent", {
  plan <- check_packages("xml2", platform = "ubuntu-22.04")
  subset <- plan[, c("r_package", "system_package")]

  expect_false(inherits(subset, "sysreqr_plan"))
  expect_true(inherits(subset, "data.frame"))
})

test_that("check_library validates the package vector and accepts overrides", {
  withr::local_options(sysreqr.installed_system_packages = character())

  expect_error(
    check_library(packages = character(), platform = "ubuntu-22.04"),
    "No installed packages"
  )

  plan <- check_library(
    packages = "xml2",
    platform = "ubuntu-22.04",
    backend = "bundled"
  )
  expect_s3_class(plan, "sysreqr_plan")
  expect_true("libxml2-dev" %in% plan$system_package)
  expect_false(is.null(attr(plan, "library")))
})
