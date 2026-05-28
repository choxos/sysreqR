# Diagnosing failed R package installations

## When the preflight check did not happen

Sometimes preflight checks do not happen. A user runs
[`install.packages()`](https://rdrr.io/r/utils/install.packages.html), a
package compiles from source, and the installation fails. The useful
next step is to turn the error into a small list of likely system
packages, not to ask the user to read a long compiler log alone.

`sysreqr` has two diagnosis paths:

- **Direct log patterns**, for common missing headers, linker errors,
  and `pkg-config` failures.
- **Failed R package lookup**, where the failed R package names are
  matched against the bundled or optional live system requirement
  database.

Both paths return a regular `sysreqr_plan`, so the output can be passed
to the same command, report, script, Dockerfile, GitHub Actions, and
administrator helpers used for preflight checks.

## Check the last error

After a failed install in the current R session:

``` r

install.packages("xml2")
check_error(platform = "ubuntu-22.04")
```

[`check_error()`](https://choxos.github.io/sysreqR/reference/check_error.md)
reads [`geterrmessage()`](https://rdrr.io/r/base/stop.html) by default.
You can also pass text explicitly:

``` r

check_error(
  text = "ERROR: configuration failed for package 'xml2'",
  platform = "ubuntu-22.04",
  backend = "bundled"
)
#> System requirement preflight
#> 
#> Platform: Ubuntu 22.04
#> Package manager: apt
#> Backend: diagnose-log
#> 
#> R packages checked:
#>   xml2
#> 
#> System packages to install: 
#>   libxml2-dev  needed by: xml2  status: unknown
#> 
#> Run:
#>   sudo apt-get update
#>   sudo apt-get install -y libxml2-dev
```

## Diagnose a log file

Use
[`diagnose_log()`](https://choxos.github.io/sysreqR/reference/diagnose_log.md)
for an install log on disk:

``` r

plan <- diagnose_log("install.log", platform = "ubuntu-22.04")
```

Use the `text` argument when the log text is already in R:

``` r

diagnose_log(
  text = "fatal error: libxml/parser.h: No such file or directory",
  platform = "ubuntu-22.04"
)
#> System requirement preflight
#> 
#> Platform: Ubuntu 22.04
#> Package manager: apt
#> Backend: diagnose-log
#> 
#> System packages to install: 
#>   libxml2-dev  needed by:   status: unknown
#> 
#> Run:
#>   sudo apt-get update
#>   sudo apt-get install -y libxml2-dev
```

[`diagnose_install_log()`](https://choxos.github.io/sysreqR/reference/diagnose_log.md)
is an alias for
[`diagnose_log()`](https://choxos.github.io/sysreqR/reference/diagnose_log.md).

## Start from failed package names

If the user already knows which R packages failed, skip log parsing:

``` r

diagnose_failed_packages(
  c("xml2", "curl"),
  platform = "ubuntu-22.04",
  backend = "bundled"
)
#> System requirement preflight
#> 
#> Platform: Ubuntu 22.04
#> Package manager: apt
#> Backend: failed-package-lookup
#> 
#> R packages checked:
#>   curl, xml2
#> 
#> System packages to install: 
#>   libcurl4-openssl-dev  needed by: curl  status: unknown
#>   libssl-dev  needed by: curl  status: unknown
#>   libxml2-dev  needed by: xml2  status: unknown
#> 
#> Run:
#>   sudo apt-get update
#>   sudo apt-get install -y libcurl4-openssl-dev libssl-dev libxml2-dev
```

This is useful when the log only says that an R package had non-zero
exit status. It is a medium-confidence result, because package
installation can fail for reasons unrelated to system libraries.

## Turn diagnosis into action

Diagnosis returns a `sysreqr_plan`. Use the same helpers as in the
preflight workflow:

``` r

plan <- diagnose_log("install.log", platform = "ubuntu-22.04")
install_command(plan)
write_install_script(plan, "install-sysreqs.sh")
admin_request(plan)
write_report(plan, "SYSREQS.md")
```

For automation:

``` r

dockerfile(plan)
github_actions(plan)
write_json(plan, "sysreqs.json")
```

For explanation:

``` r

explain(plan)
as_data_frame(plan)
```

## Check a whole project

When one package fails, dependencies nearby in the project may fail
next.
[`check_project()`](https://choxos.github.io/sysreqR/reference/check_project.md)
scans a project before the next installation attempt. It reads
`renv.lock`, then `DESCRIPTION`, then source files.

``` r

project_plan <- check_project(".")
```

Include `Suggests` when preparing a development or testing environment:

``` r

project_plan <- check_project(".", include_suggests = TRUE)
```

To inspect only package detection:

``` r

detect_project_packages(".")
detect_project_packages(".", include_suggests = TRUE)
```

## Check an installed library

[`check_library()`](https://choxos.github.io/sysreqR/reference/check_library.md)
checks installed packages in an R library. This is useful when a machine
already has many packages installed and you want to see whether their
common external requirements are present.

``` r

check_library()
check_library(c("xml2", "curl"))
```

## Interpret confidence

`sysreqr` uses conservative confidence labels:

- `high`: a direct missing-header or linker pattern, or structured
  upstream requirement data.
- `medium`: a likely tool failure, or a failed package lookup against
  the bundled fallback.
- `low`: reserved for future broader heuristics.

A medium-confidence result is still useful, but it is not proof that a
missing system library caused the failure. R version mismatches, network
problems, locked libraries, compiler bugs, unsupported package versions,
and permission problems can all produce failed installs that are outside
the system requirement database.

## When setup advice is the better answer

If repeated installs fail, run
[`setup_advice()`](https://choxos.github.io/sysreqR/reference/setup_advice.md)
instead of chasing one error at a time:

``` r

setup_advice(
  packages = c("xml2", "curl"),
  platform = "ubuntu-22.04",
  script = "setup-sysreqr.sh"
)
```

That gives the user a broader checklist: binary R packages, source build
tools, optional R Project operating system repositories, and
package-specific system requirements.

## See also

- [`vignette("preflight-setup")`](https://choxos.github.io/sysreqR/articles/preflight-setup.md)
  for the preventive workflow.
- [`vignette("faq")`](https://choxos.github.io/sysreqR/articles/faq.md)
  for common diagnosis questions.
- [`vignette("linux-fundamentals")`](https://choxos.github.io/sysreqR/articles/linux-fundamentals.md)
  for the underlying GNU/Linux concepts.
