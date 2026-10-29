Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WR {
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
    public struct RECT { public int Left, Top, Right, Bottom; }
}
"@
$p = Get-Process -Name Calculator -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $p) { "NO PROCESS" | Out-File "$PSScriptRoot\win_info.txt" -Encoding utf8; exit }
$h = $p.MainWindowHandle
$r = New-Object WR+RECT
[WR]::GetWindowRect($h, [ref]$r) | Out-Null
$info = "PID=$($p.Id)`nVisible=$([WR]::IsWindowVisible($h))`nIconic=$([WR]::IsIconic($h))`nRect=L$($r.Left) T$($r.Top) R$($r.Right) B$($r.Bottom)`nW=$($r.Right-$r.Left) H=$($r.Bottom-$r.Top)"
$info | Out-File "$PSScriptRoot\win_info.txt" -Encoding utf8
$info
