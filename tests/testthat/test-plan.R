test_that("is_sysreqr_plan recognizes the class", {
  withr::local_options(sysreqr.installed_system_packages = character())
  plan <- check_packages("xml2", platform = "ubuntu-22.04")
  expect_true(is_sysreqr_plan(plan))
  expect_false(is_sysreqr_plan(data.frame(x = 1)))
})

test_that("as.data.frame removes the plan class", {
  withr::local_options(sysreqr.installed_system_packages = character())
  plan <- check_packages("xml2", platform = "ubuntu-22.04")
  df <- as.data.frame(plan)
  expect_false(inherits(df, "sysreqr_plan"))
  expect_s3_class(df, "data.frame")
})

test_that("as_data_frame removes the plan class", {
  withr::local_options(sysreqr.installed_system_packages = character())
  plan <- check_packages("xml2", platform = "ubuntu-22.04")
  df <- as_data_frame(plan)
  expect_false(inherits(df, "sysreqr_plan"))
  expect_s3_class(df, "data.frame")
})

test_that("print.sysreqr_plan emits the expected sections", {
  withr::local_options(sysreqr.installed_system_packages = character())
  plan <- check_packages("xml2", platform = "ubuntu-22.04")

  out <- paste(capture.output(print(plan)), collapse = "\n")
  expect_match(out, "System requirement preflight", fixed = TRUE)
  expect_match(out, "Platform:", fixed = TRUE)
  expect_match(out, "Package manager:", fixed = TRUE)
  expect_match(out, "Backend:", fixed = TRUE)
  expect_match(out, "libxml2-dev", fixed = TRUE)
})
