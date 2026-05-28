# Changelog

## sysreqr 0.1.0

First public release.

### Preflight checks

- [`check_packages()`](https://choxos.github.io/sysreqR/reference/check_packages.md)
  resolves the system packages an R package needs on a given Linux
  platform. Four backends are available: `"auto"` (default),
  `"bundled"`, `"ppm"`, and `"pak"`.
- [`check_library()`](https://choxos.github.io/sysreqR/reference/check_library.md)
  audits installed packages in an R library path.
- [`check_project()`](https://choxos.github.io/sysreqR/reference/check_project.md)
  and
  [`detect_project_packages()`](https://choxos.github.io/sysreqR/reference/detect_project_packages.md)
  scan a project directory, preferring `renv.lock`, then `DESCRIPTION`,
  then source files.

### Platform handling

- [`detect_platform()`](https://choxos.github.io/sysreqR/reference/detect_platform.md)
  reads `/etc/os-release` on Linux, `sw_vers` on macOS, and parses
  fixture files for tests.
- [`detect_package_manager()`](https://choxos.github.io/sysreqR/reference/detect_package_manager.md)
  returns the package manager for a platform (`apt`, `dnf`, `yum`,
  `zypper`, `apk`, `brew`).
- [`resolve_platform()`](https://choxos.github.io/sysreqR/reference/resolve_platform.md)
  accepts `NULL`, an existing platform object, `<distro>-<version>`
  shorthand, or a codename alias (`jammy`, `noble`, `resolute`,
  `bookworm`, `trixie`).

### Commands and outputs

- [`install_command()`](https://choxos.github.io/sysreqR/reference/install_command.md)
  generates platform-appropriate install commands.
- [`dockerfile()`](https://choxos.github.io/sysreqR/reference/dockerfile.md)
  and
  [`write_dockerfile_snippet()`](https://choxos.github.io/sysreqR/reference/write_dockerfile_snippet.md)
  produce Dockerfile snippets.
- [`github_actions()`](https://choxos.github.io/sysreqR/reference/github_actions.md)
  (alias
  [`gha()`](https://choxos.github.io/sysreqR/reference/github_actions.md))
  produces a GitHub Actions YAML step.
- [`admin_request()`](https://choxos.github.io/sysreqR/reference/admin_request.md)
  drafts a plain-text request for system administrators.
- [`write_install_script()`](https://choxos.github.io/sysreqR/reference/write_install_script.md)
  writes a POSIX shell script.
- [`write_report()`](https://choxos.github.io/sysreqR/reference/write_report.md)
  and
  [`write_json()`](https://choxos.github.io/sysreqR/reference/write_json.md)
  persist a plan to disk.
- [`as_install_plan()`](https://choxos.github.io/sysreqR/reference/as_install_plan.md)
  returns a structured list suitable for downstream tooling.

### Diagnostics

- [`diagnose_log()`](https://choxos.github.io/sysreqR/reference/diagnose_log.md)
  (alias
  [`diagnose_install_log()`](https://choxos.github.io/sysreqR/reference/diagnose_log.md))
  matches common compiler and linker error patterns and resolves failed
  package names back to system requirements.
- [`check_error()`](https://choxos.github.io/sysreqR/reference/check_error.md)
  is a convenience wrapper that reads
  [`geterrmessage()`](https://rdrr.io/r/base/stop.html).
- [`diagnose_failed_packages()`](https://choxos.github.io/sysreqR/reference/diagnose_failed_packages.md)
  resolves a known list of failed R packages.

### Posit Package Manager

- [`ppm_platforms()`](https://choxos.github.io/sysreqR/reference/ppm_platforms.md),
  [`check_ppm()`](https://choxos.github.io/sysreqR/reference/check_ppm.md),
  [`ppm_repo()`](https://choxos.github.io/sysreqR/reference/ppm_repo.md),
  [`ppm_sysreqs()`](https://choxos.github.io/sysreqR/reference/ppm_sysreqs.md),
  and
  [`use_ppm()`](https://choxos.github.io/sysreqR/reference/use_ppm.md)
  integrate with the Posit Package Manager API and binary repository
  URLs.

### Setup guidance

- [`setup_advice()`](https://choxos.github.io/sysreqR/reference/setup_advice.md)
  produces a practical, beginner-friendly Linux setup checklist with
  optional shell-script output.
- [`explain()`](https://choxos.github.io/sysreqR/reference/explain.md)
  prints a friendly per-package explanation.

### Documentation

- Five HTML vignettes: preflight setup, diagnosing failures, GNU/Linux
  fundamentals (for newcomers to Linux), Docker and CI workflows, and an
  FAQ.
- Every exported function has a runnable example.
- Reference index grouped by topic on the pkgdown site.

### Design notes

- `sysreqr` has **zero required dependencies**: no `Imports`, no
  `Depends` beyond base R. The `Suggests` field lists `testthat`,
  `knitr`, `rmarkdown`, and `withr`, used only for tests and vignette
  building; none of them are loaded at run time.
- Optional live backends can use Posit Package Manager (over HTTPS) and
  [`pak::pkg_sysreqs()`](https://pak.r-lib.org/reference/pkg_sysreqs.html),
  both of which are detected at run time and never required.
- The package ships a static bundled database of system requirements for
  common CRAN packages. The database is refreshed with each release. Use
  `backend = "ppm"` or `backend = "pak"` when newer live metadata is
  needed.
