@echo off
setlocal
rem ====================================================================
rem  Register Markdown Viewer as a handler for .md / .markdown files.
rem  Per-user (HKCU) — no administrator rights required.
rem  Self-referencing: works wherever this published folder lives.
rem ====================================================================

rem Resolve the publish root (this script lives in <root>\install\).
pushd "%~dp0.."
set "APPDIR=%CD%"
popd

set "EXE=%APPDIR%\MarkdownViewer.exe"
rem Use the icon embedded in the exe (no separate .ico file needed at runtime).
set "ICON=%EXE%"

if not exist "%EXE%" (
    echo ERROR: Could not find "%EXE%".
    echo Make sure you ran this from the published app folder.
    pause
    exit /b 1
)

echo Registering Markdown Viewer for the current user...
echo   App:  "%EXE%"
echo.

rem --- ProgId definition -------------------------------------------------
reg add "HKCU\Software\Classes\MarkdownViewer.Document" /ve /t REG_SZ /d "Markdown Document" /f >nul
reg add "HKCU\Software\Classes\MarkdownViewer.Document" /v "FriendlyTypeName" /t REG_SZ /d "Markdown Document" /f >nul
reg add "HKCU\Software\Classes\MarkdownViewer.Document\DefaultIcon" /ve /t REG_SZ /d "%ICON%,0" /f >nul
reg add "HKCU\Software\Classes\MarkdownViewer.Document\shell\open" /ve /t REG_SZ /d "Open with Markdown Viewer" /f >nul
reg add "HKCU\Software\Classes\MarkdownViewer.Document\shell\open\command" /ve /t REG_SZ /d "\"%EXE%\" \"%%1\"" /f >nul

rem --- Associate the extensions -----------------------------------------
for %%X in (.md .markdown) do (
    reg add "HKCU\Software\Classes\%%X\OpenWithProgids" /v "MarkdownViewer.Document" /t REG_NONE /d "" /f >nul
    reg add "HKCU\Software\Classes\%%X" /ve /t REG_SZ /d "MarkdownViewer.Document" /f >nul
)

rem --- Tell the shell associations changed ------------------------------
powershell -NoProfile -Command "Add-Type -Namespace Shell -Name Notify -MemberDefinition '[System.Runtime.InteropServices.DllImport(\"shell32.dll\")] public static extern void SHChangeNotify(int eventId, int flags, System.IntPtr a, System.IntPtr b);'; [Shell.Notify]::SHChangeNotify(0x08000000,0,[System.IntPtr]::Zero,[System.IntPtr]::Zero)" >nul 2>&1

echo Done.
echo.
echo If double-clicking a .md file still opens another app, Windows has a
echo saved "UserChoice" for that extension. Right-click a .md file once,
echo choose "Open with" - "Choose another app" - "Markdown Viewer" and
echo tick "Always use this app".
echo.
pause
endlocal
