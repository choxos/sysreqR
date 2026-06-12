# FAQ and troubleshooting

This vignette collects answers to common questions that come up when
using `sysreqr` or, more generally, when installing R packages from
source on GNU/Linux.

## My install failed but `sysreqr` reports nothing missing

Not every install failure is caused by a missing system library. Other
causes:

- **R version too old.** Some CRAN packages require recent R. Run
  `R.version.string`.
- **Package source too old.** A pinned older package version may need a
  library you no longer have at that version. Try a newer package
  version.
- **Disk full or read-only library path.** Check with `df -h` and
  [`.libPaths()`](https://rdrr.io/r/base/libPaths.html).
- **Network failure mid-download.** Re-run.
- **Locked package.** A `00LOCK-<name>` directory in your library path
  from a previous failed install. Remove it.

When in doubt, run
[`setup_advice()`](https://choxos.github.io/sysreqR/reference/setup_advice.md)
to confirm the broader checklist, then ask for help with the specific
log.

## I’m on a server without `sudo`. What now?

Use
[`admin_request()`](https://choxos.github.io/sysreqR/reference/admin_request.md)
to draft a message you can send to your administrator:

``` r

plan <- check_packages(c("xml2", "curl"), platform = "ubuntu-22.04")
cat(admin_request(plan))
```

The message lists the missing system packages, which R packages need
them, and the exact install command. Many administrators appreciate
having all of that in one place.

## How does `sysreqr` differ from `pak`, `remotes`, and `renv`?

| Tool | Strengths | Limitations |
|----|----|----|
| [`pak::pkg_sysreqs()`](https://pak.r-lib.org/reference/pkg_sysreqs.html) | Authoritative live resolver | Requires `pak`; no log diagnosis |
| `remotes::system_requirements()` | Light; widely available | No log diagnosis, no project scanner |
| `renv::sysreqs()` | Project-oriented; integrates with `renv` workflow | Requires `renv` |
| `sysreqr` | Zero runtime deps; log diagnosis; beginner UX | Bundled DB is small; biased to `apt` |

`sysreqr` can use `pak` as one of its backends (`backend = "pak"`) when
it is installed. The two tools are complementary, not competitors.

## Can I skip source compilation entirely?

Often, yes. Two families of solutions exist:

- **Posit Package Manager** serves pre-compiled CRAN binaries for many
  distributions through a drop-in CRAN repository URL.
  [`use_ppm()`](https://choxos.github.io/sysreqR/reference/use_ppm.md)
  prints the `.Rprofile` lines. Note that PPM binaries do not install
  the *runtime* system libraries a package needs, so a second step
  (which `sysreqr` can generate) may still be required.
- **Distribution-native binary repositories** package CRAN for the
  system package manager itself, so system dependencies install
  automatically: [r2u](https://eddelbuettel.github.io/r2u/) for Ubuntu,
  [cran2copr](https://github.com/cran4linux/cran2copr) for Fedora (the
  `iucar/cran` Copr repository), and
  [CRAN2OBS](https://gitlab.com/dsteuer/CRAN2OBS/-/wikis/home) for
  openSUSE. The [bspm](https://cran.r-project.org/package=bspm) package
  bridges
  [`install.packages()`](https://rdrr.io/r/utils/install.packages.html)
  to the system package manager so these integrate with the normal R
  workflow.

Ucar and Eddelbuettel (2021), [*Binary R Packages for Linux: Past,
Present and Future*](https://arxiv.org/abs/2103.08069), is a good
overview of this landscape.

If your distribution is covered by one of these projects, use it;
`sysreqr` then matters mostly for the packages those repositories
exclude, for distributions they do not cover, and for Docker/CI
generation and log diagnosis.

## I’m in Docker and platform detection seems wrong

When you run
[`detect_platform()`](https://choxos.github.io/sysreqR/reference/detect_platform.md)
*outside* a container, R sees the host operating system. When you run it
*inside* a container, R sees the container operating system. If you are
generating a Dockerfile from your laptop for a different base image,
always specify the `platform` argument explicitly:

``` r

dockerfile(check_packages("xml2", platform = "ubuntu-22.04"))
```

See the Docker vignette for more detail.

## How do I keep the bundled database current?

The bundled database is refreshed with each package release. There is no
runtime “update” function, because CRAN policy forbids packages from
writing to their installed location.

If you need newer data than the latest release, use `backend = "ppm"`
for live Posit Package Manager data, or `backend = "pak"` for live `pak`
resolution.

## Why is `sysreqr` suggesting `r-base-dev`?

`r-base-dev` is the Debian/Ubuntu package that contains the development
headers and Makefile fragments needed to compile R packages from source.
You only need it if you build R packages from source (which is the
default on Linux).
[`setup_advice()`](https://choxos.github.io/sysreqR/reference/setup_advice.md)
includes it in the build-tools step.

On Fedora/RHEL, the equivalent comes with the `R` package itself. On
openSUSE, the equivalent is `R-base`.

## I’m on Alpine. What’s supported?

Alpine uses `apk` and is detected as `alpine`. Install commands use
`apk add --no-cache`. The bundled fallback database currently uses
Debian/Ubuntu names, so prefer the `ppm` or `pak` backend on Alpine.
Many common system libraries on Alpine are in the [community
repository](https://pkgs.alpinelinux.org/packages?branch=v3.20&repo=community).

## I’m behind a corporate proxy. PPM queries fail

Posit Package Manager queries use
[`utils::download.file()`](https://rdrr.io/r/utils/download.file.html).
Set the standard `http_proxy` and `https_proxy` environment variables
before starting R, or configure them in your `.Renviron`.

If outbound HTTP is blocked entirely, use `backend = "bundled"` or
`backend = "pak"` (pak has its own download tooling and may already be
configured for your network).

## What do the confidence levels mean?

- **`high`**: direct evidence: a missing-header or linker error pattern
  was matched in the log, or live upstream metadata reported the
  requirement.
- **`medium`**: indirect evidence: a tool failure (such as
  `pkg-config not found`) or a failed-package lookup against the bundled
  fallback database.
- **`low`**: reserved for future, broader heuristics.

A medium-confidence result is still useful, but it is not proof. R
version mismatches, locked libraries, and permission problems can all
cause failed installs unrelated to system requirements.

## `sysreqr` says the platform is unsupported but I want to try anyway

Use the `platform` argument with an explicit platform string. If you
supply `backend = "ppm"`, the package will ask Posit Package Manager
which is authoritative.

If you are experimenting with an unknown platform, please open an issue
at <https://github.com/choxos/sysreqR/issues> with the contents of
`/etc/os-release` so support can be added properly.

## Why does this package use a custom JSON parser?

A small custom parser keeps the package free of runtime dependencies, in
line with its design goal. `jsonlite` would also work, but it would add
a dependency that the rest of the package does not need. The parser is
exercised by the test suite and handles unicode escapes, nested arrays,
and the JSON dialect used by Posit Package Manager and `renv.lock`.

## See also

- [`vignette("preflight-setup")`](https://choxos.github.io/sysreqR/articles/preflight-setup.md)
  for the preventive workflow.
- [`vignette("diagnosing-failures")`](https://choxos.github.io/sysreqR/articles/diagnosing-failures.md)
  for log diagnosis.
- [`vignette("linux-fundamentals")`](https://choxos.github.io/sysreqR/articles/linux-fundamentals.md)
  for GNU/Linux background.
- [`vignette("docker-and-ci")`](https://choxos.github.io/sysreqR/articles/docker-and-ci.md)
  for container and CI workflows.
