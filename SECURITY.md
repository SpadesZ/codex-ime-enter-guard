# Security Policy

## Supported Scope

This project is a local Windows keyboard guard. It should not collect prompts,
credentials, clipboard contents, API keys, or account information.

## Reporting

Please open a GitHub issue for behavior bugs. If a report contains sensitive
details, remove secrets before posting publicly.

## Design Boundary

The guard must stay local-only and should not patch installed applications,
upload user input, or persist typed text.
