test_that("write helpers create files", {
  withr::local_options(
    sysreqr.ppm_get = mock_ppm_get,
    sysreqr.installed_system_packages = character()
  )

  tmp <- withr::local_tempdir()
  plan <- check_packages("xml2", platform = "ubuntu-22.04")

  report <- file.path(tmp, "SYSREQS.md")
  json <- file.path(tmp, "sysreqs.json")
  script <- file.path(tmp, "install-sysreqs.sh")
  dock <- file.path(tmp, "Dockerfile.sysreqs")

  expect_equal(write_report(plan, report), report)
  expect_equal(write_json(plan, json), json)
  expect_equal(write_install_script(plan, script), script)
  expect_equal(write_dockerfile_snippet(plan, dock), dock)

  expect_true(file.exists(report))
  expect_true(file.exists(json))
  expect_true(file.exists(script))
  expect_true(file.exists(dock))
})

test_that("as_install_plan returns a structured list with platform and commands", {
  withr::local_options(sysreqr.installed_system_packages = character())
  plan <- check_packages("xml2", platform = "ubuntu-22.04")
  installed <- as_install_plan(plan)

  expect_type(installed, "list")
  expect_true(all(c(
    "platform", "backend", "pre_install", "install", "post_install", "packages"
  ) %in% names(installed)))
  expect_s3_class(installed$packages, "data.frame")
})
