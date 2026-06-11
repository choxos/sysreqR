# Package index

## Preflight checks

Resolve the system packages your R packages need on a given platform.

- [`check_library()`](https://choxos.github.io/sysreqR/reference/check_library.md)
  : Check system requirements for installed R packages
- [`check_packages()`](https://choxos.github.io/sysreqR/reference/check_packages.md)
  : Check system requirements for R packages
- [`check_project()`](https://choxos.github.io/sysreqR/reference/check_project.md)
  : Check system requirements for a project
- [`detect_project_packages()`](https://choxos.github.io/sysreqR/reference/detect_project_packages.md)
  : Detect R packages used by a project

## Platform detection

Detect or specify the platform under inspection.

- [`detect_package_manager()`](https://choxos.github.io/sysreqR/reference/detect_package_manager.md)
  : Detect the platform package manager
- [`detect_platform()`](https://choxos.github.io/sysreqR/reference/detect_platform.md)
  : Detect the current platform
- [`resolve_platform()`](https://choxos.github.io/sysreqR/reference/resolve_platform.md)
  : Resolve a platform specification

## Output and commands

Turn a plan into install commands, Docker snippets, GitHub Actions YAML,
or administrator request templates.

- [`admin_request()`](https://choxos.github.io/sysreqR/reference/admin_request.md)
  : Create an administrator request
- [`dockerfile()`](https://choxos.github.io/sysreqR/reference/dockerfile.md)
  : Generate Dockerfile lines
- [`github_actions()`](https://choxos.github.io/sysreqR/reference/github_actions.md)
  [`gha()`](https://choxos.github.io/sysreqR/reference/github_actions.md)
  : Generate a GitHub Actions snippet
- [`gitlab_ci()`](https://choxos.github.io/sysreqR/reference/gitlab_ci.md)
  : Generate a GitLab CI snippet
- [`install_command()`](https://choxos.github.io/sysreqR/reference/install_command.md)
  : Generate an installation command

## Diagnose failed installs

Match installation logs and failed package names to likely missing
system packages.

- [`check_error()`](https://choxos.github.io/sysreqR/reference/check_error.md)
  : Check the most recent install error for likely system requirements
- [`diagnose_failed_packages()`](https://choxos.github.io/sysreqR/reference/diagnose_failed_packages.md)
  : Diagnose failed R packages
- [`diagnose_log()`](https://choxos.github.io/sysreqR/reference/diagnose_log.md)
  [`diagnose_install_log()`](https://choxos.github.io/sysreqR/reference/diagnose_log.md)
  : Diagnose an R package installation log

## Posit Package Manager

Query the Posit Package Manager API and build repository URLs.

- [`check_ppm()`](https://choxos.github.io/sysreqR/reference/check_ppm.md)
  : Check Posit Package Manager support
- [`ppm_platforms()`](https://choxos.github.io/sysreqR/reference/ppm_platforms.md)
  : List Posit Package Manager platforms
- [`ppm_repo()`](https://choxos.github.io/sysreqR/reference/ppm_repo.md)
  : Build a Posit Package Manager repository URL
- [`ppm_sysreqs()`](https://choxos.github.io/sysreqR/reference/ppm_sysreqs.md)
  : Query Package Manager system requirements
- [`use_ppm()`](https://choxos.github.io/sysreqR/reference/use_ppm.md) :
  Configure Package Manager repository options

## File writers

Persist plans as JSON, Markdown, install scripts, or Dockerfile
snippets.

- [`as_install_plan()`](https://choxos.github.io/sysreqR/reference/as_install_plan.md)
  : Return backend install plan data
- [`write_dockerfile_snippet()`](https://choxos.github.io/sysreqR/reference/write_dockerfile_snippet.md)
  : Write a Dockerfile snippet
- [`write_install_script()`](https://choxos.github.io/sysreqR/reference/write_install_script.md)
  : Write an install script
- [`write_json()`](https://choxos.github.io/sysreqR/reference/write_json.md)
  : Write a sysreqr plan as JSON
- [`write_report()`](https://choxos.github.io/sysreqR/reference/write_report.md)
  : Write a Markdown report

## The plan object

Introspect and coerce `sysreqr_plan` objects.

- [`as_data_frame()`](https://choxos.github.io/sysreqR/reference/as_data_frame.md)
  : Coerce a plan to a plain data frame
- [`is_sysreqr_plan()`](https://choxos.github.io/sysreqR/reference/is_sysreqr_plan.md)
  : Test whether an object is a sysreqr plan
- [`print(`*`<sysreqr_plan>`*`)`](https://choxos.github.io/sysreqR/reference/print.sysreqr_plan.md)
  : Print a sysreqr plan

## Setup advice

Beginner-focused setup checklists and explanations.

- [`explain()`](https://choxos.github.io/sysreqR/reference/explain.md) :
  Explain system requirements
- [`print(`*`<sysreqr_setup_advice>`*`)`](https://choxos.github.io/sysreqR/reference/print.sysreqr_setup_advice.md)
  : Print setup advice
- [`setup_advice()`](https://choxos.github.io/sysreqR/reference/setup_advice.md)
  : Get beginner setup advice for R package installation on Linux
