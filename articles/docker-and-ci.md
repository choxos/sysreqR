# Docker and CI workflows

This vignette shows how to use `sysreqr` to generate system-requirement
snippets for Docker images and CI pipelines. It assumes basic
familiarity with both. See
[`vignette("linux-fundamentals")`](https://choxos.github.io/sysreqR/articles/linux-fundamentals.md)
for a primer.

## The simple case: one project, one Dockerfile

If you have a project directory and want a Dockerfile snippet that
installs its system requirements, pipe
[`check_project()`](https://choxos.github.io/sysreqR/reference/check_project.md)
into
[`dockerfile()`](https://choxos.github.io/sysreqR/reference/dockerfile.md).

``` r

plan <- check_project(".", platform = "ubuntu-22.04")
cat(dockerfile(plan))
```

The output looks like this:

``` dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends \
    libxml2-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*
```

Paste it into a `Dockerfile` immediately after the base image, or write
it to a side file with
[`write_dockerfile_snippet()`](https://choxos.github.io/sysreqR/reference/write_dockerfile_snippet.md)
and `INCLUDE` it from your build pipeline.

## Always pass `platform` for Docker builds

When you build a Docker image, the *container’s* operating system is
what matters, not your laptop. If you build a `rocker/r-ver` image from
a Mac, the container is Debian-based. So always supply `platform`
explicitly when generating Dockerfile snippets.

``` r

plan <- check_packages("xml2", platform = "ubuntu-22.04")
cat(dockerfile(plan))
#> RUN apt-get update && apt-get install -y --no-install-recommends \
#>     libxml2-dev \
#>     && rm -rf /var/lib/apt/lists/*
```

## Recommended base images

The Rocker Project maintains opinionated R images.

| Image | What you get | When to use |
|----|----|----|
| `rocker/r-ver:<version>` | Versioned R on Debian | Small server-side base |
| `rocker/rstudio:<version>` | The above plus RStudio Server | Interactive development |
| `rocker/tidyverse:<version>` | `tidyverse` and friends pre-installed | Data-science containers |
| `rocker/geospatial:<version>` | The above plus GDAL, PROJ, GEOS, etc. | Spatial work |
| `rocker/r-base:<version>` | Plain R from the R Project Debian repository | Quick experiments |

`sysreqr` is independent of which base image you pick: it only generates
the install commands for the system packages your R packages need.

## A two-stage Docker pattern

A common practice is to separate the *build* image (which has compilers
and `-dev` headers) from the *runtime* image (which only has runtime
libraries). This keeps the deployed image small.

``` dockerfile
# ---- Stage 1: build ----
FROM rocker/r-ver:4.4 AS build

# System build deps (compilers and headers)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libxml2-dev libcurl4-openssl-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/*

COPY . /src
WORKDIR /src
RUN R -e 'install.packages(c("xml2", "curl"))'

# ---- Stage 2: runtime ----
FROM rocker/r-ver:4.4

# Runtime libraries only (note: no -dev suffix)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libxml2 libcurl4 libssl3 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/local/lib/R/site-library /usr/local/lib/R/site-library
COPY --from=build /src /app
WORKDIR /app
CMD ["R", "--no-save"]
```

[`sysreqr::dockerfile()`](https://choxos.github.io/sysreqR/reference/dockerfile.md)
produces the build-stage block. The runtime block, which uses the
non-`-dev` variants, is a manual mirror.

## Pinning Posit Package Manager snapshots

For reproducible Docker images, point R at a *dated* PPM snapshot rather
than `latest`.

``` r

url <- ppm_repo(platform = "ubuntu-22.04", snapshot = "2026-04-01")
url
#> [1] "https://packagemanager.posit.co/cran/__linux__/jammy/2026-04-01"
```

Drop those lines into your Dockerfile by way of `Rscript -e` or an
`.Rprofile` written into the image:

``` dockerfile
RUN echo 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/jammy/2026-04-01"))' \
    >> /usr/local/lib/R/etc/Rprofile.site
```

Combined with the system-package install above, this gives bit-for-bit
reproducible installs.

## GitHub Actions

[`github_actions()`](https://choxos.github.io/sysreqR/reference/github_actions.md)
(alias
[`gha()`](https://choxos.github.io/sysreqR/reference/github_actions.md))
generates a YAML step that runs the same install commands inside a
GitHub-hosted Ubuntu runner.

``` r

plan <- check_packages(c("xml2", "curl"), platform = "ubuntu-22.04")
cat(github_actions(plan))
#> - name: Install Linux system dependencies
#>   run: |
#>     sudo apt-get update
#>     sudo apt-get install -y libcurl4-openssl-dev libssl-dev libxml2-dev
```

Paste it into `.github/workflows/<your-workflow>.yaml` after the
`actions/setup-r` step:

``` yaml
jobs:
  R-CMD-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: r-lib/actions/setup-r@v2
        with:
          use-public-rspm: true

      - name: Install Linux system dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y libxml2-dev libcurl4-openssl-dev libssl-dev

      - uses: r-lib/actions/setup-r-dependencies@v2
        with:
          needs: check
```

If you prefer to let the `r-lib/actions` ecosystem handle system
requirements for you, use the `extra-packages` and `needs` inputs of
`setup-r-dependencies`. `sysreqr` is then most useful for two things:

1.  **Pre-CI auditing**: run `check_project(".")` locally before
    pushing.
2.  **CI for non-R-package projects** (Shiny apps, scripts, reports),
    where the standard r-lib actions are less of a fit.

## Beyond GitHub Actions

The
[`install_command()`](https://choxos.github.io/sysreqR/reference/install_command.md)
output is portable across CI systems. For GitLab CI:

``` yaml
test:
  image: rocker/r-ver:4.4
  before_script:
    - apt-get update
    - apt-get install -y libxml2-dev libcurl4-openssl-dev libssl-dev
  script:
    - Rscript -e 'devtools::check()'
```

For Jenkins, Drone, or shell-driven CI, write the install script once:

``` r

write_install_script(plan, "ci/install-sysreqs.sh")
```

Then call `sh ci/install-sysreqs.sh` from any CI runner.

## Posit Workbench and Posit Connect

Both Posit Workbench and Posit Connect benefit from Posit Package
Manager binary R packages, which avoid source compilation entirely for
the distributions they support. `use_ppm("user")` writes the `.Rprofile`
fragment that points R at the right binary repository.

For Connect specifically, server administrators usually configure the
repository at the server level, so end users only need the application
code, not `.Rprofile` edits.

## See also

- [`vignette("preflight-setup")`](https://choxos.github.io/sysreqR/articles/preflight-setup.md)
  for the basic workflow.
- [`vignette("linux-fundamentals")`](https://choxos.github.io/sysreqR/articles/linux-fundamentals.md)
  for the system-level concepts.
- [`vignette("faq")`](https://choxos.github.io/sysreqR/articles/faq.md)
  for common gotchas.
