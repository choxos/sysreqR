test_that("parse_os_release strips double and single quoted values", {
  props <- parse_os_release(c(
    'ID="ubuntu"',
    "VERSION_ID='24.04'",
    "VERSION_CODENAME=noble",
    "# this is a comment",
    "MALFORMED no equals"
  ))

  expect_equal(props[["ID"]], "ubuntu")
  expect_equal(props[["VERSION_ID"]], "24.04")
  expect_equal(props[["VERSION_CODENAME"]], "noble")
  expect_false("# this is a comment" %in% names(props))
})

test_that("detect_platform reads Ubuntu os-release fixtures", {
  skip_on_os("windows")
  os_release <- test_path("fixtures", "os-release-ubuntu-22.04")
  platform <- detect_platform(os_release = os_release)

  expect_equal(platform$distro, "ubuntu")
  expect_equal(platform$version, "22.04")
  expect_equal(platform$codename, "jammy")
  expect_equal(platform$package_manager, "apt")
  expect_true(platform$supported)
})

test_that("detect_platform reads Ubuntu 26.04 (resolute) fixtures", {
  skip_on_os("windows")
  platform <- detect_platform(
    os_release = test_path("fixtures", "os-release-ubuntu-26.04")
  )

  expect_equal(platform$distro, "ubuntu")
  expect_equal(platform$version, "26.04")
  expect_equal(platform$codename, "resolute")
  expect_equal(platform$package_manager, "apt")
  expect_equal(platform$ppm_binary_url, "resolute")
  expect_true(platform$supported)
})

test_that("resolve_platform handles Ubuntu 26.04 and the resolute alias", {
  resolute <- resolve_platform("resolute")
  expect_equal(resolute$distro, "ubuntu")
  expect_equal(resolute$version, "26.04")
  expect_equal(resolute$ppm_binary_url, "resolute")

  by_key <- resolve_platform("ubuntu-26.04")
  expect_equal(by_key$codename, "resolute")
  expect_equal(by_key$package_manager, "apt")
})

test_that("detect_platform reads Debian fixtures", {
  skip_on_os("windows")
  platform <- detect_platform(
    os_release = test_path("fixtures", "os-release-debian-12")
  )

  expect_equal(platform$distro, "debian")
  expect_equal(platform$version, "12")
  expect_equal(platform$codename, "bookworm")
  expect_equal(platform$package_manager, "apt")
})

test_that("detect_platform reads Fedora fixtures", {
  skip_on_os("windows")
  platform <- detect_platform(
    os_release = test_path("fixtures", "os-release-fedora-40")
  )

  expect_equal(platform$distro, "fedora")
  expect_equal(platform$version, "40")
  expect_equal(platform$package_manager, "dnf")
  expect_true(platform$supported)
})

test_that("detect_platform reads Alpine fixtures", {
  skip_on_os("windows")
  platform <- detect_platform(
    os_release = test_path("fixtures", "os-release-alpine-3.20")
  )

  expect_equal(platform$distro, "alpine")
  expect_equal(platform$package_manager, "apk")
})

test_that("detect_platform reads Rocky Linux fixtures", {
  skip_on_os("windows")
  platform <- detect_platform(
    os_release = test_path("fixtures", "os-release-rockylinux-9")
  )

  expect_equal(platform$distro, "rocky")
  expect_equal(platform$package_manager, "dnf")
})

test_that("detect_platform falls back when os-release is missing", {
  platform <- detect_platform(os_release = tempfile("nonexistent-"))

  expect_s3_class(platform, "sysreqr_platform")
  expect_false(isTRUE(platform$supported))
})

test_that("resolve_platform handles supported Ubuntu and Debian aliases", {
  jammy <- resolve_platform("jammy")
  expect_equal(jammy$distro, "ubuntu")
  expect_equal(jammy$version, "22.04")
  expect_equal(jammy$package_manager, "apt")
  expect_equal(jammy$ppm_binary_url, "jammy")

  bookworm <- resolve_platform("bookworm")
  expect_equal(bookworm$distro, "debian")
  expect_equal(bookworm$version, "12")
})

test_that("resolve_platform accepts an existing platform object", {
  platform <- resolve_platform("ubuntu-22.04")
  expect_identical(resolve_platform(platform), platform)
})

test_that("resolve_platform rejects malformed input", {
  expect_error(resolve_platform("garbage"), "Unknown platform")
  expect_error(resolve_platform(""), "must be NULL")
})

test_that("detect_package_manager returns the manager for a platform", {
  expect_equal(detect_package_manager("ubuntu-22.04"), "apt")
  expect_equal(detect_package_manager("fedora-40"), "dnf")
  expect_equal(detect_package_manager("opensuse156"), "zypper")
})

test_that("resolve_platform supports AlmaLinux with a PPM binary URL", {
  alma9 <- resolve_platform("almalinux-9")
  expect_equal(alma9$distro, "almalinux")
  expect_equal(alma9$version, "9")
  expect_equal(alma9$package_manager, "dnf")
  expect_equal(alma9$ppm_binary_url, "rhel9")

  alma10 <- resolve_platform("almalinux-10")
  expect_equal(alma10$ppm_binary_url, "rhel10")
})

test_that("ppm_repo builds a URL for AlmaLinux", {
  expect_equal(
    ppm_repo(platform = "almalinux-9"),
    "https://packagemanager.posit.co/cran/__linux__/rhel9/latest"
  )
})
