# Codex IME Enter Guard

Helps avoid sending a Codex message while you are still choosing Chinese, Japanese, or Korean characters.

Press Enter to confirm a character candidate; the guard attempts to keep that key from also sending the message while composition is active.

**Windows only. Early public release.** Behavior depends on your input method and selected mode; the default mode needs Windows to report active composition.

[Start, stop, and self-test](#quick-start) | [Choose a mode](#modes) | [Detection limits](#detection-and-safety-notes)

## Quick Start

Requirements: Windows, Windows PowerShell (`powershell.exe`), and the Codex desktop app. Clone this repo first:

```powershell
git clone https://github.com/SpadesZ/codex-ime-enter-guard.git
cd codex-ime-enter-guard
```

Start in the default `composition` mode:

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

The self-test compiles the embedded C# helper. It does not simulate an IME, install the keyboard hook, or prove that your input method is detected.

After starting, try composing a short message in Codex with your own input method. Check candidate confirmation and message submission before relying on the guard. If composition is not detected, see the stricter modes below.

## Why

Chinese, Japanese, and Korean IME users often press Enter to confirm a
composition candidate. In chat-style coding tools, the same key can also submit
the message. This tool adds a narrow Windows keyboard guard to block Enter when a window is identified as Codex and the Windows IME API reports active composition text.

## Features

- Windows-only PowerShell helper with an embedded low-level keyboard hook.
- Default `composition` mode checks for active composition through Windows IME APIs before blocking Enter.
- Optional `plain` and `all` modes for debugging stricter behavior.
- Preserves Shift+Enter, Ctrl+Enter, and Alt+Enter in `plain` mode.
- Uses a PID file to avoid starting a second guard from the same tools folder.
- Does not patch Codex, ChatGPT, or any installed application files.

## Modes

- `composition`: default; block Enter when Windows reports an active IME composition string.
- `plain`: block plain Enter in Codex while preserving modified Enter keys.
- `all`: block every Enter in Codex; useful only for short debugging sessions.

Example:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\start-codex-ime-enter-guard.ps1 -Mode plain
```

## Detection and Safety Notes

The helper identifies the foreground window by process name or a window title containing `Codex`. Composition detection uses Windows IMM APIs and can vary by input method and application version.

Stop from the same checkout that started the guard. If its PID file is missing, the stop script searches for matching guard processes and can stop guards from other folders too.

This project is intentionally narrow. It checks the foreground process/window
for Codex and does not inspect, collect, upload, or persist typed content. It
only asks Windows IME APIs whether composition text currently exists.

This project is not affiliated with OpenAI.

## Status

Early public release. Built from repeated local use while coding with Codex on
Windows using Traditional Chinese IME.
