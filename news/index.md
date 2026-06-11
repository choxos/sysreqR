# Changelog

## sysreqr 0.2.0

### New features

- The bundled fallback database is now cross-distro: it stores system
  package names for `apt`, `dnf` (also used by `yum` platforms),
  `zypper`, and `apk`, so `backend = "bundled"` and offline fallbacks
  work on Fedora, RHEL and its rebuilds, openSUSE, and Alpine, not only
  on Debian and Ubuntu. The `apt`, `dnf`, and `zypper` names are
  generated from the Posit Package Manager database; the Alpine names
  are hand curated. The `"auto"` backend now prefers bundled data on all
  of these platforms.
- Log diagnosis recognizes many more missing libraries. The direct error
  patterns grew from 12 to 33 and now cover, among others, zlib, bzip2,
  xz, png, jpeg, tiff, freetype, fontconfig, cairo, SQLite, PostgreSQL,
  MariaDB, libsodium, GMP, MPFR, GLPK, GEOS, ImageMagick, poppler,
  leptonica, tesseract, ICU, webp, and Cyrus SASL, each with names for
  all supported package managers.
- New
  [`gitlab_ci()`](https://choxos.github.io/sysreqR/reference/gitlab_ci.md)
  generates a GitLab CI YAML job that installs the system packages a
  plan needs. GitLab CI jobs usually run as root inside a container
  image, so the commands are emitted without `sudo`.
- The bundled fallback database now also covers `igraph`, `rJava`,
  `jqr`, `odbc`, `av`, `rsvg`, `xslt`, and `protolite` (40 curated
  packages in total).
- Installed-state detection now works on Alpine: `missing_only`
  filtering and the `installed` plan column use `apk info` when running
  on an `apk` platform.
- The startup message suggests
  [`setup_advice()`](https://choxos.github.io/sysreqR/reference/setup_advice.md)
  with the detected platform instead of a hardcoded `ubuntu-24.04`
  example when the current host is a supported Linux distribution.

### Documentation

- The README, the FAQ, and the setup, fundamentals, and Docker vignettes
  now describe distribution-native binary repositories that resolve
  system dependencies automatically: `r2u` (Ubuntu), `cran2copr`
  (Fedora), `CRAN2OBS` (openSUSE), and the `bspm` bridge, with a pointer
  to Ucar and Eddelbuettel (2021, arXiv:2103.08069).
  [`setup_advice()`](https://choxos.github.io/sysreqR/reference/setup_advice.md)
  mentions `r2u` on Ubuntu and credits the `cran2copr` project on
  Fedora. Suggested by Dirk Eddelbuettel
  ([\#1](https://github.com/choxos/sysreqR/issues/1)).

### Bug fixes

- [`diagnose_log()`](https://choxos.github.io/sysreqR/reference/diagnose_log.md),
  [`check_error()`](https://choxos.github.io/sysreqR/reference/check_error.md),
  and the other log-diagnosis helpers now report package names that
  match the platform’s package manager. Previously the direct log
  patterns always suggested apt names, so Fedora users were told to run
  `dnf install -y libxml2-dev` instead of
  `dnf install -y libxml2-devel`. Mapped names on non-apt platforms
  carry a note asking the user to verify the exact name on their
  distribution.
- [`explain()`](https://choxos.github.io/sysreqR/reference/explain.md)
  no longer prints lines such as `NA needs libxml2-dev.` for diagnosis
  results that have no associated R package name; it now says
  `libxml2-dev is needed.` instead.
- The internal JSON writer no longer double-escapes newline, carriage
  return, and tab characters, and now escapes backspace, form feed, and
  the remaining control characters, so written JSON always parses back
  to the original strings.
- The internal JSON parser now validates `\u` escape sequences
  (rejecting truncated escapes) and decodes UTF-16 surrogate pairs, so
  characters outside the Basic Multilingual Plane survive parsing.
  Unpaired surrogates are rejected.
- Generated shell commands, Dockerfile snippets, and CI snippets drop
  system package names that contain unexpected characters (with a
  warning) instead of pasting them into the command line.
- Posit Package Manager requirements that consist only of post-install
  commands (for example `R CMD javareconf`) now keep their row in the
  plan.
- When a Posit Package Manager query fails (for example with no
  network), the fallback no longer stops with “Bundled fallback data
  currently supports apt platforms only.” on non-apt platforms. The
  bundled fallback now serves platform-matching names, and on platforms
  outside the bundled data (such as Homebrew) an empty plan is returned
  with the original error recorded in the `fallback_error` attribute.
- [`detect_platform()`](https://choxos.github.io/sysreqR/reference/detect_platform.md)
  now reports Alpine hosts as supported, matching
  `resolve_platform("alpine-3.20")` and the documented platform list.
- [`use_ppm()`](https://choxos.github.io/sysreqR/reference/use_ppm.md)
  documentation no longer claims that `scope` selects which `.Rprofile`
  is edited; `path` is always required for writing, and the error
  message now suggests a scope-appropriate path.

## sysreqr 0.1.0

CRAN release: 2026-06-11

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

### Correctness and portability

- Bundled system-package names are now portable across Debian and
  Ubuntu: `default-libmysqlclient-dev` (was `libmysqlclient-dev`, which
  does not exist on Debian), `libgsl-dev` (was `libgsl0-dev`), and
  `libfreetype-dev` (was `libfreetype6-dev`).
- [`detect_project_packages()`](https://choxos.github.io/sysreqR/reference/detect_project_packages.md)
  now detects
  [`requireNamespace()`](https://rdrr.io/r/base/ns-load.html) calls and
  ignores package names that appear only in line comments.
- [`setup_advice()`](https://choxos.github.io/sysreqR/reference/setup_advice.md)
  generates Debian repository setup using the modern deb822 `Signed-By`
  keyring format (matching CRAN’s current Debian instructions), drops a
  no-op Fedora `repoquery` line, and presents the Fedora COPR step as
  optional.
- Added AlmaLinux 9 and 10 as known platforms so
  [`ppm_repo()`](https://choxos.github.io/sysreqR/reference/ppm_repo.md)
  and
  [`check_ppm()`](https://choxos.github.io/sysreqR/reference/check_ppm.md)
  work for them.
- The internal JSON parser now rejects unescaped control characters, per
  the JSON specification.

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
