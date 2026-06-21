# Security Policy

## Supported Versions

Security updates are provided for the current CRAN release and the current
development version on the default branch.

| Version | Supported |
| ------- | --------- |
| 0.1.x   | Yes       |

## Reporting a Vulnerability

Please do not report security vulnerabilities in public issues.

Send a report to Ahmad Sofi-Mahmudi at a.sofimahmudi@gmail.com with:

* a short description of the vulnerability;
* steps to reproduce it;
* affected versions or commits, if known;
* any relevant logs or output with secrets removed.

You should receive an acknowledgment within 7 days. The maintainer will review
the report, ask follow-up questions if needed, and coordinate a fix and release
timeline based on severity.

## Scope

Relevant security reports include:

* unsafe command generation;
* unexpected writes outside user-supplied paths;
* handling of untrusted logs or project files;
* disclosure of local paths, credentials, tokens, or private package names.

Reports about missing system packages or ordinary installation failures should
use the issue templates instead.
