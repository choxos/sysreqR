# sysreqr 0.2.0

## New features

* The bundled fallback database is now cross-distro: it stores system
  package names for `apt`, `dnf` (also used by `yum` platforms), `zypper`,
  and `apk`, so `backend = "bundled"` and offline fallbacks work on Fedora,
  RHEL and its rebuilds, openSUSE, and Alpine, not only on Debian and
  Ubuntu. The `apt`, `dnf`, and `zypper` names are generated from the Posit
  Package Manager database; the Alpine names are hand curated. The `"auto"`
  backend now prefers bundled data on all of these platforms.
* Log diagnosis recognizes many more missing libraries. The direct error
  patterns grew from 12 to 33 and now cover, among others, zlib, bzip2, xz,
  png, jpeg, tiff, freetype, fontconfig, cairo, SQLite, PostgreSQL,
  MariaDB, libsodium, GMP, MPFR, GLPK, GEOS, ImageMagick, poppler,
  leptonica, tesseract, ICU, webp, and Cyrus SASL, each with names for all
  supported package managers.
* New `gitlab_ci()` generates a GitLab CI YAML job that installs the system
  packages a plan needs. GitLab CI jobs usually run as root inside a
  container image, so the commands are emitted without `sudo`.
* The bundled fallback database now also covers `igraph`, `rJava`, `jqr`,
  `odbc`, `av`, `rsvg`, `xslt`, and `protolite` (40 curated packages in
  total).
* Installed-state detection now works on Alpine: `missing_only` filtering
  and the `installed` plan column use `apk info` when running on an `apk`
  platform.
* The startup message suggests `setup_advice()` with the detected platform
  instead of a hardcoded `ubuntu-24.04` example when the current host is a
  supported Linux distribution.

## Documentation

* The README, the FAQ, and the setup, fundamentals, and Docker vignettes
  now describe distribution-native binary repositories that resolve system
  dependencies automatically: `r2u` (Ubuntu), `cran2copr` (Fedora),
  `CRAN2OBS` (openSUSE), and the `bspm` bridge, with a pointer to Ucar and
  Eddelbuettel (2021, arXiv:2103.08069). `setup_advice()` mentions `r2u`
  on Ubuntu and credits the `cran2copr` project on Fedora. Suggested by
  Dirk Eddelbuettel (#1).

## Bug fixes

* `diagnose_log()`, `check_error()`, and the other log-diagnosis helpers now
  report package names that match the platform's package manager. Previously
  the direct log patterns always suggested apt names, so Fedora users were
  told to run `dnf install -y libxml2-dev` instead of
  `dnf install -y libxml2-devel`. Mapped names on non-apt platforms carry a
  note asking the user to verify the exact name on their distribution.
* `explain()` no longer prints lines such as `NA needs libxml2-dev.` for
  diagnosis results that have no associated R package name; it now says
  `libxml2-dev is needed.` instead.
* The internal JSON writer no longer double-escapes newline, carriage
  return, and tab characters, and now escapes backspace, form feed, and the
  remaining control characters, so written JSON always parses back to the
  original strings.
* The internal JSON parser now validates `\u` escape sequences (rejecting
  truncated escapes) and decodes UTF-16 surrogate pairs, so characters
  outside the Basic Multilingual Plane survive parsing. Unpaired surrogates
  are rejected.
* Generated shell commands, Dockerfile snippets, and CI snippets drop
  system package names that contain unexpected characters (with a warning)
  instead of pasting them into the command line.
* Posit Package Manager requirements that consist only of post-install
  commands (for example `R CMD javareconf`) now keep their row in the plan.
* When a Posit Package Manager query fails (for example with no network),
  the fallback no longer stops with "Bundled fallback data currently
  supports apt platforms only." on non-apt platforms. The bundled fallback
  now serves platform-matching names, and on platforms outside the bundled
  data (such as Homebrew) an empty plan is returned with the original
  error recorded in the `fallback_error` attribute.
* `detect_platform()` now reports Alpine hosts as supported, matching
  `resolve_platform("alpine-3.20")` and the documented platform list.
* `use_ppm()` documentation no longer claims that `scope` selects which
  `.Rprofile` is edited; `path` is always required for writing, and the
  error message now suggests a scope-appropriate path.

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
