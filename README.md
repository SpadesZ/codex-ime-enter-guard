# Codex IME Enter Guard

A small Windows helper that prevents accidental message submission while a CJK
IME composition is active in the Codex desktop app.

## Why

Chinese, Japanese, and Korean IME users often press Enter to confirm a
composition candidate. In chat-style coding tools, the same key can also submit
the message. This tool adds a narrow Windows keyboard guard so Enter is blocked
only when Codex is focused and the IME still has active composition text.

## Features

- Windows-only PowerShell helper with an embedded low-level keyboard hook.
- Default `composition` mode blocks Enter only during active IME composition.
- Optional `plain` and `all` modes for debugging stricter behavior.
- Preserves Shift+Enter, Ctrl+Enter, and Alt+Enter in `plain` mode.
- Uses a PID file so duplicate guards are avoided.
- Does not patch Codex, ChatGPT, or any installed application files.

## Quick Start

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\start-codex-ime-enter-guard.ps1
```

Stop the guard:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\stop-codex-ime-enter-guard.ps1
```

Run a lightweight self-test:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\codex-ime-enter-guard.ps1 -SelfTest
```

## Modes

- `composition`: default; block Enter only while an IME composition string is present.
- `plain`: block plain Enter in Codex while preserving modified Enter keys.
- `all`: block every Enter in Codex; useful only for short debugging sessions.

Example:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\start-codex-ime-enter-guard.ps1 -Mode plain
```

## Safety Notes

This project is intentionally narrow. It checks the foreground process/window
for Codex and does not inspect, collect, upload, or persist typed content. It
only asks Windows IME APIs whether composition text currently exists.

This project is not affiliated with OpenAI.

## Status

Early public release. Built from repeated local use while coding with Codex on
Windows using Traditional Chinese IME.
