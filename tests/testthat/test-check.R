test_that("auto backend uses bundled data for known packages on apt", {
  withr::local_options(sysreqr.installed_system_packages = character())

  plan <- check_packages(c("xml2", "curl"), platform = "ubuntu-22.04")

  expect_equal(attr(plan, "backend"), "bundled")
  expect_true("libxml2-dev" %in% plan$system_package)
  expect_true("libcurl4-openssl-dev" %in% plan$system_package)
})

test_that("auto backend picks bundled for known packages on all bundled managers", {
  # Since the bundled table carries per-package-manager names, auto routing
  # uses it on apt, dnf, yum, zypper, and apk platforms alike.
  expect_equal(select_backend("xml2", "auto", resolve_platform("ubuntu-22.04")), "bundled")
  expect_equal(select_backend("xml2", "auto", resolve_platform("fedora-40")), "bundled")
  expect_equal(select_backend("xml2", "auto", resolve_platform("rockylinux-9")), "bundled")
  expect_equal(select_backend("xml2", "auto", resolve_platform("centos7")), "bundled")
  expect_equal(select_backend("xml2", "auto", resolve_platform("opensuse156")), "bundled")
  expect_equal(select_backend("xml2", "auto", resolve_platform("alpine-3.20")), "bundled")
})

test_that("select_backend routes around bundled when it cannot help", {
  # Unknown packages route to ppm even when the platform is bundled-capable.
  expect_equal(
    select_backend("definitelynotbundled", "auto", resolve_platform("fedora-40")),
    "ppm"
  )
  # brew has no bundled name set, so known packages route to ppm there.
  expect_equal(select_backend("xml2", "auto", resolve_platform("macos-14")), "ppm")
})

test_that("bundled database uses cross-distro-portable package names", {
  withr::local_options(sysreqr.installed_system_packages = character())

  mariadb <- check_packages("RMariaDB", platform = "ubuntu-22.04", backend = "bundled")
  expect_true("default-libmysqlclient-dev" %in% mariadb$system_package)
  expect_false("libmysqlclient-dev" %in% mariadb$system_package)

  gsl <- check_packages("gsl", platform = "ubuntu-22.04", backend = "bundled")
  expect_true("libgsl-dev" %in% gsl$system_package)

  ragg <- check_packages("ragg", platform = "ubuntu-22.04", backend = "bundled")
  expect_true("libfreetype-dev" %in% ragg$system_package)
  expect_false("libfreetype6-dev" %in% ragg$system_package)
})

test_that("check_packages on Fedora resolves dnf names without error", {
  withr::local_options(sysreqr.installed_system_packages = character())

  expect_no_error(
    plan <- check_packages("xml2", platform = "fedora-40", backend = "auto")
  )
  expect_s3_class(plan, "sysreqr_plan")
  expect_equal(attr(plan, "backend"), "bundled")
  expect_true("libxml2-devel" %in% plan$system_package)
  expect_false("libxml2-dev" %in% plan$system_package)
})

test_that("auto routing on Fedora falls through to pak for unknown packages", {
  # Packages outside the bundled table route to ppm; Package Manager has no
  # Fedora support, so auto routing must continue to the mocked pak backend
  # instead of erroring.
  pak_mock <- function(pkg, ...) {
    list(
      packages = data.frame(
        sysreq = "libxml2",
        packages = I(list("definitelynotbundled")),
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
    sysreqr.pak_pkg_sysreqs = pak_mock,
    sysreqr.installed_system_packages = character()
  )

  expect_no_error(
    plan <- check_packages("definitelynotbundled", platform = "fedora-40", backend = "auto")
  )
  expect_s3_class(plan, "sysreqr_plan")
  expect_equal(attr(plan, "backend"), "pak")
})

test_that("bundled database covers the expanded package set", {
  withr::local_options(sysreqr.installed_system_packages = character())

  bundled_has_packages <- getFromNamespace("bundled_has_packages", "sysreqr")
  expect_true(bundled_has_packages(
    c("igraph", "rJava", "jqr", "odbc", "av", "rsvg", "xslt", "protolite")
  ))

  igraph <- check_packages("igraph", platform = "ubuntu-22.04", backend = "bundled")
  expect_true(all(c("libglpk-dev", "libxml2-dev") %in% igraph$system_package))

  rjava <- check_packages("rJava", platform = "ubuntu-22.04", backend = "bundled")
  expect_true("default-jdk" %in% rjava$system_package)
})

test_that("bundled backend resolves per-package-manager names", {
  withr::local_options(sysreqr.installed_system_packages = character())

  fedora <- check_packages("xml2", platform = "fedora-40", backend = "bundled")
  expect_equal(fedora$system_package, "libxml2-devel")
  expect_equal(fedora$package_manager, "dnf")
  expect_match(fedora$notes, "verify the exact name", fixed = TRUE)

  centos <- check_packages("RPostgres", platform = "centos7", backend = "bundled")
  expect_equal(centos$system_package, "libpq-devel")
  expect_equal(centos$package_manager, "yum")
  expect_match(centos$install_script, "^yum install")

  suse <- check_packages("curl", platform = "opensuse156", backend = "bundled")
  expect_true(all(c("libcurl-devel", "libopenssl-devel") %in% suse$system_package))

  alpine <- check_packages("sf", platform = "alpine-3.20", backend = "bundled")
  expect_true(all(
    c("gdal-dev", "geos-dev", "proj-dev", "sqlite-dev") %in% alpine$system_package
  ))

  ubuntu <- check_packages("xml2", platform = "ubuntu-22.04", backend = "bundled")
  expect_false(any(grepl("verify the exact name", ubuntu$notes, fixed = TRUE)))
})

test_that("bundled backend reports packages with no name set for the platform", {
  withr::local_options(sysreqr.installed_system_packages = character())

  plan <- check_packages("V8", platform = "opensuse156", backend = "bundled")
  expect_equal(nrow(plan), 0L)
  expect_true("V8" %in% attr(plan, "unresolved"))

  apt <- check_packages("V8", platform = "ubuntu-22.04", backend = "bundled")
  expect_true("libnode-dev" %in% apt$system_package)
})

test_that("bundled backend still rejects unsupported package managers", {
  platform <- resolve_platform("ubuntu-22.04")
  platform$package_manager <- "brew"
  expect_error(
    check_packages("xml2", platform = platform, backend = "bundled"),
    "apt, dnf, yum, zypper"
  )
})

test_that("bundled database has well-formed cross-distro rows", {
  db <- getFromNamespace("bundled_sysreqs_db", "sysreqr")

  expect_setequal(unique(db$package_manager), c("apt", "dnf", "zypper", "apk"))
  expect_false(any(is.na(db$system_package)))
  expect_true(all(grepl("^[A-Za-z0-9][A-Za-z0-9._+:@-]*$", db$system_package)))

  # Every curated package must at least have apt names; the apt set is the
  # baseline the package has shipped since 0.1.0.
  known <- unique(db$r_package)
  apt_known <- unique(db$r_package[db$package_manager == "apt"])
  expect_setequal(known, apt_known)
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
