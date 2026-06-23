@echo off
setlocal
rem ====================================================================
rem  Remove the Markdown Viewer file association (per-user / HKCU).
rem ====================================================================

echo Removing Markdown Viewer file association for the current user...

rem Remove the ProgId.
reg delete "HKCU\Software\Classes\MarkdownViewer.Document" /f >nul 2>&1

rem Remove our entries from the extensions.
for %%X in (.md .markdown) do (
    reg delete "HKCU\Software\Classes\%%X\OpenWithProgids" /v "MarkdownViewer.Document" /f >nul 2>&1
    rem Clear the per-user default value only if it points at us.
    for /f "tokens=2,*" %%A in ('reg query "HKCU\Software\Classes\%%X" /ve 2^>nul ^| find "REG_SZ"') do (
        if "%%B"=="MarkdownViewer.Document" reg delete "HKCU\Software\Classes\%%X" /ve /f >nul 2>&1
    )
)

powershell -NoProfile -Command "Add-Type -Namespace Shell -Name Notify -MemberDefinition '[System.Runtime.InteropServices.DllImport(\"shell32.dll\")] public static extern void SHChangeNotify(int eventId, int flags, System.IntPtr a, System.IntPtr b);'; [Shell.Notify]::SHChangeNotify(0x08000000,0,[System.IntPtr]::Zero,[System.IntPtr]::Zero)" >nul 2>&1

echo Done. (A saved Windows "UserChoice" for .md, if any, must be changed
echo via right-click - Open with - Choose another app.)
echo.
pause
endlocal
