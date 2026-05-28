test_that("setup_advice gives Ubuntu guidance and package commands", {
  withr::local_options(sysreqr.installed_system_packages = character())

  advice <- setup_advice(
    "xml2",
    platform = "ubuntu-24.04",
    backend = "bundled"
  )

  expect_s3_class(advice, "sysreqr_setup_advice")
  expect_equal(advice$ppm_repo, "https://packagemanager.posit.co/cran/__linux__/noble/latest")
  expect_true(any(grepl("r-base-dev", advice$build_commands, fixed = TRUE)))
  expect_true(any(grepl("noble-cran40", advice$r_project_commands, fixed = TRUE)))
  expect_true(any(grepl("libxml2-dev", advice$package_commands, fixed = TRUE)))
})

test_that("setup_advice handles Ubuntu 26.04 (resolute)", {
  withr::local_options(sysreqr.installed_system_packages = character())

  advice <- setup_advice(
    "xml2",
    platform = "ubuntu-26.04",
    backend = "bundled"
  )

  expect_s3_class(advice, "sysreqr_setup_advice")
  expect_equal(
    advice$ppm_repo,
    "https://packagemanager.posit.co/cran/__linux__/resolute/latest"
  )
  expect_true(any(grepl("resolute-cran40", advice$r_project_commands, fixed = TRUE)))
})

test_that("setup_advice includes Debian and Fedora repository guidance", {
  debian <- setup_advice(platform = "debian-12")
  fedora <- setup_advice(platform = "fedora-40")

  expect_true(any(grepl("bookworm-cran46", debian$r_project_commands, fixed = TRUE)))
  expect_true(any(grepl("r-base-dev", debian$build_commands, fixed = TRUE)))
  expect_true(any(grepl("iucar/cran", fedora$r_project_commands, fixed = TRUE)))
  expect_true(any(grepl("R-CoprManager", fedora$r_project_commands, fixed = TRUE)))
})

test_that("setup_advice writes executable shell script", {
  withr::local_options(sysreqr.installed_system_packages = character())

  script <- withr::local_tempfile(pattern = "sysreqr-setup-", fileext = ".sh")
  advice <- setup_advice(
    "xml2",
    platform = "ubuntu-22.04",
    backend = "bundled",
    script = script
  )

  lines <- readLines(script, warn = FALSE)
  expect_s3_class(advice, "sysreqr_setup_advice")
  expect_true(file.exists(script))
  expect_true(any(grepl("libxml2-dev", lines, fixed = TRUE)))
  expect_true(any(grepl("# sudo add-apt-repository", lines, fixed = TRUE)))
})

test_that("setup_advice does not write a script unless requested", {
  script <- tempfile("sysreqr-setup-", fileext = ".sh")
  advice <- setup_advice(platform = "ubuntu-22.04")

  expect_s3_class(advice, "sysreqr_setup_advice")
  expect_false(file.exists(script))
  expect_equal(advice$script, NULL)
})

test_that("setup_advice handles platforms without bundled repository commands", {
  macos <- list(
    os = "macos",
    distro = "macos",
    version = "14",
    codename = NA_character_,
    package_manager = "brew",
    ppm_binary_url = "macos",
    supported = FALSE,
    label = "macOS"
  )
  advice <- setup_advice(platform = macos)

  expect_s3_class(advice, "sysreqr_setup_advice")
  expect_equal(advice$r_project_commands, character())
  expect_match(advice$r_project_notes, "No R Project repository commands", fixed = TRUE)
})

test_that("setup_advice print emits the expected sections", {
  withr::local_options(sysreqr.installed_system_packages = character())
  advice <- setup_advice(
    "xml2",
    platform = "ubuntu-22.04",
    backend = "bundled"
  )

  out <- paste(capture.output(print(advice)), collapse = "\n")
  expect_match(out, "R package installation setup advice", fixed = TRUE)
  expect_match(out, "Prefer binary R packages", fixed = TRUE)
  expect_match(out, "Install source build tools", fixed = TRUE)
  expect_match(out, "Package-specific system requirements", fixed = TRUE)
  expect_match(out, "libxml2-dev", fixed = TRUE)
})
