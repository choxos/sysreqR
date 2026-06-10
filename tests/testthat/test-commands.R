test_that("install_command, dockerfile, and github_actions generate snippets", {
  withr::local_options(
    sysreqr.ppm_get = mock_ppm_get,
    sysreqr.installed_system_packages = character()
  )

  plan <- check_packages(c("xml2", "curl"), platform = "ubuntu-22.04")

  cmd <- install_command(plan)
  expect_true(any(grepl("apt-get update", cmd, fixed = TRUE)))
  expect_true(any(grepl("libxml2-dev", cmd, fixed = TRUE)))

  docker <- dockerfile(plan)
  expect_match(docker, "RUN apt-get update", fixed = TRUE)
  expect_match(docker, "libcurl4-openssl-dev", fixed = TRUE)

  gha <- github_actions(plan)
  expect_match(gha, "Install Linux system dependencies", fixed = TRUE)
  expect_match(gha, "sudo apt-get update", fixed = TRUE)
})

test_that("gha is an alias of github_actions", {
  withr::local_options(sysreqr.installed_system_packages = character())
  plan <- check_packages("xml2", platform = "ubuntu-22.04")
  expect_identical(gha(plan), github_actions(plan))
})

test_that("admin_request includes package names and command", {
  withr::local_options(
    sysreqr.ppm_get = mock_ppm_get,
    sysreqr.installed_system_packages = character()
  )

  plan <- check_packages("xml2", platform = "ubuntu-22.04")
  request <- admin_request(plan)
  expect_match(request, "libxml2-dev", fixed = TRUE)
  expect_match(request, "xml2", fixed = TRUE)
})

test_that("empty plans do not emit package manager update commands", {
  plan <- diagnose_log(text = "unrelated compiler output", platform = "ubuntu-22.04")

  expect_equal(install_command(plan), character())
  expect_match(github_actions(plan), "No external system requirements detected", fixed = TRUE)
  expect_match(admin_request(plan), "No administrator action is needed", fixed = TRUE)

  tmp <- withr::local_tempfile(pattern = "sysreqr-empty-", fileext = ".sh")
  expect_equal(write_install_script(plan, tmp), tmp)
  script <- paste(readLines(tmp, warn = FALSE), collapse = "\n")
  expect_match(script, "No external system requirements detected", fixed = TRUE)
})

test_that("install_command does not double-prefix sudo", {
  withr::local_options(sysreqr.installed_system_packages = character())
  plan <- check_packages("xml2", platform = "ubuntu-22.04")
  cmd <- install_command(plan, sudo = TRUE)
  expect_false(any(grepl("sudo sudo", cmd, fixed = TRUE)))
})

test_that("add_sudo prefixes package manager commands", {
  add_sudo <- getFromNamespace("add_sudo", "sysreqr")
  expect_equal(
    add_sudo("apt-get install -y libxml2-dev"),
    "sudo apt-get install -y libxml2-dev"
  )
  expect_equal(
    add_sudo("dnf install -y libxml2-devel"),
    "sudo dnf install -y libxml2-devel"
  )
  expect_equal(
    add_sudo("zypper --non-interactive install libxml2-devel"),
    "sudo zypper --non-interactive install libxml2-devel"
  )
})

test_that("add_sudo prefixes privileged repository commands", {
  add_sudo <- getFromNamespace("add_sudo", "sysreqr")
  expect_equal(
    add_sudo("add-apt-repository -y ppa:xtradeb/apps"),
    "sudo add-apt-repository -y ppa:xtradeb/apps"
  )
})

test_that("add_sudo preserves already-prefixed sudo commands", {
  add_sudo <- getFromNamespace("add_sudo", "sysreqr")
  expect_equal(
    add_sudo("sudo apt-get install -y libxml2-dev"),
    "sudo apt-get install -y libxml2-dev"
  )
})

test_that("add_sudo leaves compound shell commands unchanged", {
  add_sudo <- getFromNamespace("add_sudo", "sysreqr")
  rust <- "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
  expect_equal(add_sudo(rust), rust)

  redirect <- "echo deb-src ... > /etc/apt/sources.list.d/foo.list"
  expect_equal(add_sudo(redirect), redirect)

  chained <- "apt-get update && apt-get install -y foo"
  expect_equal(add_sudo(chained), chained)
})

test_that("add_sudo leaves user-level commands unchanged", {
  add_sudo <- getFromNamespace("add_sudo", "sysreqr")
  expect_equal(add_sudo("brew install pkg-config"), "brew install pkg-config")
  expect_equal(add_sudo("R CMD javareconf"), "R CMD javareconf")
  expect_equal(
    add_sudo("curl -fsSL https://example.com/install.sh"),
    "curl -fsSL https://example.com/install.sh"
  )
})

test_that("add_sudo prefixes update-alternatives and systemctl", {
  add_sudo <- getFromNamespace("add_sudo", "sysreqr")
  expect_equal(
    add_sudo("update-alternatives --install /usr/bin/x x /opt/x 1"),
    "sudo update-alternatives --install /usr/bin/x x /opt/x 1"
  )
  expect_equal(
    add_sudo("systemctl restart postgresql"),
    "sudo systemctl restart postgresql"
  )
})

test_that("install_command missing_only=FALSE includes installed packages", {
  withr::local_options(sysreqr.installed_system_packages = "libxml2-dev")
  plan <- check_packages("xml2", platform = "ubuntu-22.04")

  only_missing <- install_command(plan, missing_only = TRUE)
  all_pkgs <- install_command(plan, missing_only = FALSE)

  # libxml2-dev is marked installed, so missing_only drops it but
  # missing_only = FALSE keeps it.
  expect_false(any(grepl("libxml2-dev", only_missing, fixed = TRUE)))
  expect_true(any(grepl("libxml2-dev", all_pkgs, fixed = TRUE)))
})

test_that("add_sudo is vectorised", {
  add_sudo <- getFromNamespace("add_sudo", "sysreqr")
  out <- add_sudo(c(
    "apt-get update",
    "curl ... | sh",
    "sudo apt-get install -y foo"
  ))
  expect_equal(
    out,
    c(
      "sudo apt-get update",
      "curl ... | sh",
      "sudo apt-get install -y foo"
    )
  )
})

test_that("install_command output stays in the expected shape", {
  withr::local_options(sysreqr.installed_system_packages = character())
  plan <- check_packages(c("xml2", "curl"), platform = "ubuntu-22.04")
  cmd <- install_command(plan)

  expect_true(any(startsWith(cmd, "sudo apt-get update")))
  install_line <- cmd[grepl("apt-get install", cmd)]
  expect_length(install_line, 1L)
  expect_match(install_line, "libxml2-dev", fixed = TRUE)
  expect_match(install_line, "libcurl4-openssl-dev", fixed = TRUE)
})

test_that("dockerfile output stays in the expected shape", {
  withr::local_options(sysreqr.installed_system_packages = character())
  plan <- check_packages(c("xml2", "curl"), platform = "ubuntu-22.04")
  out <- dockerfile(plan)

  expect_match(out, "RUN apt-get update", fixed = TRUE)
  expect_match(out, "apt-get install -y --no-install-recommends", fixed = TRUE)
  expect_match(out, "rm -rf /var/lib/apt/lists/*", fixed = TRUE)
  expect_match(out, "libxml2-dev", fixed = TRUE)
})

test_that("diagnose-based plans generate non-apt install commands", {
  withr::local_options(sysreqr.installed_system_packages = character())
  log <- "fatal error: libxml/parser.h: No such file or directory"

  fedora <- diagnose_log(text = log, platform = "fedora-40")
  expect_true("libxml2-devel" %in% fedora$system_package)
  cmd <- install_command(fedora)
  expect_true(any(grepl("dnf install -y libxml2-devel", cmd, fixed = TRUE)))

  alpine <- diagnose_log(text = log, platform = "alpine-3.20")
  expect_true("libxml2-dev" %in% alpine$system_package)
  cmd <- install_command(alpine)
  expect_true(any(grepl("apk add --no-cache libxml2-dev", cmd, fixed = TRUE)))

  suse <- diagnose_log(text = log, platform = "opensuse156")
  expect_true("libxml2-devel" %in% suse$system_package)
  cmd <- install_command(suse)
  expect_true(any(grepl(
    "zypper --non-interactive install libxml2-devel",
    cmd,
    fixed = TRUE
  )))

  centos <- diagnose_log(text = log, platform = "centos7")
  cmd <- install_command(centos)
  expect_true(any(grepl("yum install -y libxml2-devel", cmd, fixed = TRUE)))
})

test_that("dockerfile handles non-apt platforms", {
  withr::local_options(sysreqr.installed_system_packages = character())
  plan <- diagnose_log(
    text = "fatal error: libxml/parser.h: No such file or directory",
    platform = "alpine-3.20"
  )

  out <- dockerfile(plan)
  expect_match(out, "^RUN apk add --no-cache libxml2-dev$")
})

test_that("gitlab_ci generates a YAML job without sudo", {
  withr::local_options(sysreqr.installed_system_packages = character())
  plan <- check_packages(c("xml2", "curl"), platform = "ubuntu-22.04")
  out <- gitlab_ci(plan)

  expect_match(out, "install_system_requirements:", fixed = TRUE)
  expect_match(out, "  script:", fixed = TRUE)
  expect_match(out, "    - apt-get update", fixed = TRUE)
  expect_match(out, "libxml2-dev", fixed = TRUE)
  expect_false(grepl("sudo", out, fixed = TRUE))
})

test_that("gitlab_ci handles empty plans and custom job names", {
  plan <- diagnose_log(text = "unrelated compiler output", platform = "ubuntu-22.04")
  out <- gitlab_ci(plan, job = "sysreqs")

  expect_match(out, "^sysreqs:")
  expect_match(out, "No external system requirements detected", fixed = TRUE)
})

test_that("install_command drops system package names with unsafe characters", {
  mock <- function(endpoint, query, base_url) {
    if (identical(endpoint, "status")) {
      return(mock_ppm_get(endpoint, query, base_url))
    }
    list(requirements = list(list(
      name = "demo",
      requirements = list(packages = list("libdemo-dev", "evil; rm -rf /tmp/x"))
    )))
  }
  withr::local_options(
    sysreqr.ppm_get = mock,
    sysreqr.installed_system_packages = character()
  )

  plan <- ppm_sysreqs("demo", platform = "ubuntu-22.04")
  expect_warning(cmd <- install_command(plan), "unexpected characters")
  expect_true(any(grepl("libdemo-dev", cmd, fixed = TRUE)))
  expect_false(any(grepl("rm -rf", cmd, fixed = TRUE)))
})

test_that("github_actions output stays in the expected shape", {
  withr::local_options(sysreqr.installed_system_packages = character())
  plan <- check_packages(c("xml2", "curl"), platform = "ubuntu-22.04")
  out <- github_actions(plan)

  expect_match(out, "- name: Install Linux system dependencies", fixed = TRUE)
  expect_match(out, "  run: |", fixed = TRUE)
  expect_match(out, "sudo apt-get update", fixed = TRUE)
  expect_match(out, "libxml2-dev", fixed = TRUE)
})
