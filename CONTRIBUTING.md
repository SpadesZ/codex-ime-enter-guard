# Contributing

Thanks for helping improve Codex IME Enter Guard.

## Good Bug Reports

Please include:

- Windows version
- Codex desktop version, if known
- IME language and vendor
- Guard mode used: `composition`, `plain`, or `all`
- Whether the issue happens during active composition or after candidate commit

Do not include private prompts, API keys, screenshots with secrets, or account
details.

## Development Notes

Run the self-test before proposing changes:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\codex-ime-enter-guard.ps1 -SelfTest
```

Keep the project narrow: avoid application patching, prompt capture, telemetry,
or global behavior outside the Codex foreground window.
