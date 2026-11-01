# Seeds the Windows Terminal "_quake" drop-down window with the Hermes Console
# profile, then minimizes it so it stays out of the way until summoned.
# Designed to run once at logon (see Startup shortcut) or manually.

$profileName = "Hermes Console"

# 1. Create (or add a tab to) the _quake window with the Hermes profile.
#    The profile name MUST keep its quotes: Start-Process joins -ArgumentList
#    with bare spaces, so an unquoted "Hermes Console" reaches wt.exe as
#    `--profile Hermes Console` — wt then takes the stray `Console` token as the
#    command to run and fails with
#    "[error 2147942402 (0x80070002) when launching `Console']".
Start-Process -FilePath "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe" `
    -ArgumentList '-w', '_quake', 'nt', '--profile', "`"$profileName`""

# 2. Give Terminal a moment to create the window.
Start-Sleep -Seconds 4

# 3. Minimize it so it waits quietly in the taskbar for Alt+`.
Add-Type -Namespace Native -Name Win -MemberDefinition @"
[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
"@
$minimized = $false
Get-Process WindowsTerminal -ErrorAction SilentlyContinue |
    Where-Object { $_.MainWindowTitle -match [regex]::Escape($profileName) } |
    ForEach-Object {
        if ([Native.Win]::ShowWindow($_.MainWindowHandle, 6)) { $minimized = $true }  # 6 = SW_MINIMIZE
    }

if ($minimized) {
    Write-Output "Quake window seeded with '$profileName' and minimized."
} else {
    Write-Warning "Seeded, but could not find/minimize the '$profileName' window. Run hermes-quake.cmd manually."
}
