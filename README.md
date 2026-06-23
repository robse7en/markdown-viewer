# Markdown Viewer

A small native Windows app that opens `.md` files and renders them GitHub-style.
Built with **WPF + WebView2 + Markdig**. View-only.

Features:

- GitHub-Flavored Markdown (tables, task lists, strikethrough, autolinks, …)
- Syntax-highlighted code blocks (highlight.js)
- Mermaid diagrams (` ```mermaid ` blocks)
- Light / dark theme toggle (remembered between runs)
- Open via toolbar, drag-and-drop, command line, or `.md` file association

> **Internet required to render.** The styling/diagram libraries
> (github-markdown-css, highlight.js, Mermaid) are loaded from the jsDelivr CDN
> at view time. Only `Assets\app.css` is bundled locally. To make the app fully
> offline, vendor those files into `Assets\` and point `Assets\template.html` at
> local `{{ASSETS}}/…` URLs instead of the `cdn.jsdelivr.net` ones.

## Install (for users)

1. Go to the [Releases](../../releases) page and download the latest
   **`MarkdownViewer-Setup-x.y.z.exe`**.
2. Run it. It installs just for your account — **no admin prompt** — and
   associates `.md` / `.markdown` files so you can double-click to open them.
3. Launch from the Start Menu, or double-click any Markdown file.

To uninstall: **Settings → Apps → Markdown Viewer → Uninstall** (or use the
Start Menu uninstall shortcut). This also removes the file association.

> Windows may keep a remembered choice for `.md` from a previous app. If
> double-clicking still opens something else, right-click a `.md` file →
> **Open with** → **Choose another app** → **Markdown Viewer** → tick **Always**.

## Prerequisites (to build)

- .NET 9 SDK (to build)
- [Inno Setup 6](https://jrsoftware.org/isdl.php) (`winget install JRSoftware.InnoSetup`) — only to build the installer
- WebView2 Runtime (preinstalled on current Windows 10/11)
- Internet connection (for CDN-hosted rendering assets)

## Setup

### 1. Build & run (development)

From the project root:

```bat
dotnet run -- "sample.md"
```

Omit the argument to launch with no document open, then use the toolbar or
drag-and-drop to open a file.

### 2. Publish a portable app (self-contained single exe)

```bat
dotnet publish -c Release -r win-x64 --self-contained true ^
  -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true
```

Output lands in `bin\Release\net9.0-windows\win-x64\publish\`, containing
`MarkdownViewer.exe`, the `Assets\` folder, and `install\`. You can move this
whole folder anywhere — the install scripts are self-referencing.

### 3. Build the installer (Setup.exe)

Builds the user-facing installer with [Inno Setup](https://jrsoftware.org/isdl.php).
The script publishes the app to `publish\` and compiles
`installer\MarkdownViewer.iss`:

```bat
powershell -ExecutionPolicy Bypass -File installer\build.ps1 -Version 1.0.0
```

The finished `MarkdownViewer-Setup-1.0.0.exe` lands in `dist\`. It's a per-user
installer (no admin), creates a Start Menu shortcut, optionally associates
`.md` / `.markdown`, and registers an entry in **Apps & Features** for clean
uninstall.

## Releasing on GitHub

Releases are automated by `.github/workflows/release.yml`. Push a version tag
and the workflow publishes the app, builds the installer, and attaches it to a
new GitHub Release:

```bat
git tag v1.0.0
git push origin v1.0.0
```

The version comes from the tag (`v1.0.0` → `1.0.0`). You can also run the
workflow manually from the **Actions** tab (it builds the installer as a
downloadable artifact without publishing a release).

## Registering the `.md` file association (portable / dev)

The installer above handles this automatically. If you're running the
**portable** build instead, register it manually **from the published folder**
so it points at the moved `MarkdownViewer.exe`:

```bat
install\register.bat
```

This is per-user (HKCU) — no admin needed. It registers a `MarkdownViewer.Document`
ProgId and associates the `.md` and `.markdown` extensions with it, so
double-clicking a `.md` file opens it in Markdown Viewer.

> If Windows had previously remembered another app for `.md`, it stores a
> protected "UserChoice" that the script can't override. Fix it once:
> right-click a `.md` file → **Open with** → **Choose another app** →
> **Markdown Viewer** → tick **Always**.

To remove the association:

```bat
install\unregister.bat
```

## Regenerate the icon (optional)

```bat
python install\make_icon.py
```

## How it works

`MainWindow` hosts a `WebView2`. On open, `MarkdownRenderer` (Markdig with
advanced extensions) converts the file to HTML, which is injected into
`Assets\template.html` and written to `%LOCALAPPDATA%\MarkdownViewer\render\preview.html`.
Local assets (`Assets\app.css`) and the document's own folder (for relative
images) are exposed to the WebView via virtual-host mappings, so no web server
is needed. The github-markdown-css, highlight.js, and Mermaid libraries are
still pulled from the jsDelivr CDN at view time, so an internet connection is
required for full rendering. The theme choice is saved to
`%APPDATA%\MarkdownViewer\settings.json`.
