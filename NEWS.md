# sysreqr 0.1.0

First public release.

## Preflight checks

* `check_packages()` resolves the system packages an R package needs on a
  given Linux platform. Four backends are available: `"auto"` (default),
  `"bundled"`, `"ppm"`, and `"pak"`.
* `check_library()` audits installed packages in an R library path.
* `check_project()` and `detect_project_packages()` scan a project directory,
  preferring `renv.lock`, then `DESCRIPTION`, then source files.

## Platform handling

* `detect_platform()` reads `/etc/os-release` on Linux, `sw_vers` on macOS,
  and parses fixture files for tests.
* `detect_package_manager()` returns the package manager for a platform
  (`apt`, `dnf`, `yum`, `zypper`, `apk`, `brew`).
* `resolve_platform()` accepts `NULL`, an existing platform object,
  `<distro>-<version>` shorthand, or a codename alias (`jammy`, `noble`,
  `resolute`, `bookworm`, `trixie`).

## Commands and outputs

* `install_command()` generates platform-appropriate install commands.
* `dockerfile()` and `write_dockerfile_snippet()` produce Dockerfile snippets.
* `github_actions()` (alias `gha()`) produces a GitHub Actions YAML step.
* `admin_request()` drafts a plain-text request for system administrators.
* `write_install_script()` writes a POSIX shell script.
* `write_report()` and `write_json()` persist a plan to disk.
* `as_install_plan()` returns a structured list suitable for downstream
  tooling.

## Diagnostics

* `diagnose_log()` (alias `diagnose_install_log()`) matches common compiler
  and linker error patterns and resolves failed package names back to system
  requirements.
* `check_error()` is a convenience wrapper that reads `geterrmessage()`.
* `diagnose_failed_packages()` resolves a known list of failed R packages.

## Posit Package Manager

* `ppm_platforms()`, `check_ppm()`, `ppm_repo()`, `ppm_sysreqs()`, and
  `use_ppm()` integrate with the Posit Package Manager API and binary
  repository URLs.

## Setup guidance

* `setup_advice()` produces a practical, beginner-friendly Linux setup
  checklist with optional shell-script output.
* `explain()` prints a friendly per-package explanation.

## Documentation

* Five HTML vignettes: preflight setup, diagnosing failures, GNU/Linux
  fundamentals (for newcomers to Linux), Docker and CI workflows, and an FAQ.
* Every exported function has a runnable example.
* Reference index grouped by topic on the pkgdown site.

## Correctness and portability

* Bundled system-package names are now portable across Debian and Ubuntu:
  `default-libmysqlclient-dev` (was `libmysqlclient-dev`, which does not exist
  on Debian), `libgsl-dev` (was `libgsl0-dev`), and `libfreetype-dev` (was
  `libfreetype6-dev`).
* `detect_project_packages()` now detects `requireNamespace()` calls and
  ignores package names that appear only in line comments.
* `setup_advice()` generates Debian repository setup using the modern deb822
  `Signed-By` keyring format (matching CRAN's current Debian instructions),
  drops a no-op Fedora `repoquery` line, and presents the Fedora COPR step as
  optional.
* Added AlmaLinux 9 and 10 as known platforms so `ppm_repo()` and `check_ppm()`
  work for them.
* The internal JSON parser now rejects unescaped control characters, per the
  JSON specification.

## Design notes

* `sysreqr` has **zero required dependencies**: no `Imports`, no `Depends`
  beyond base R. The `Suggests` field lists `testthat`, `knitr`, `rmarkdown`,
  and `withr`, used only for tests and vignette building; none of them are
  loaded at run time.
* Optional live backends can use Posit Package Manager (over HTTPS) and
  `pak::pkg_sysreqs()`, both of which are detected at run time and never
  required.
* The package ships a static bundled database of system requirements for
  common CRAN packages. The database is refreshed with each release. Use
  `backend = "ppm"` or `backend = "pak"` when newer live metadata is needed.
