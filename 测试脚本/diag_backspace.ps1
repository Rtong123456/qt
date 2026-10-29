# Backspace diagnostic test
$ErrorActionPreference = "Stop"
$env:Path = "C:\Qt\6.11.2\mingw_64\bin;" + $env:Path
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class W2 {
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    public struct RECT { public int Left, Top, Right, Bottom; }
}
"@
[W2]::SetProcessDPIAware() | Out-Null
$p = Start-Process "C:\Users\111\Documents\calculator\Calculator\build\Calculator.exe" -PassThru
Start-Sleep -Seconds 2
$h = $p.MainWindowHandle
function Shot([string]$name) {
    [W2]::SetForegroundWindow($h) | Out-Null
    Start-Sleep -Milliseconds 400
    $r = New-Object W2+RECT
    [W2]::GetWindowRect($h, [ref]$r) | Out-Null
    $w = $r.Right - $r.Left; $hh = $r.Bottom - $r.Top
    $bmp = New-Object System.Drawing.Bitmap($w, $hh)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($r.Left, $r.Top, 0, 0, $bmp.Size)
    $bmp.Save("C:\Users\111\Documents\calculator\实验截图\$name", [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    Write-Output ("saved: " + $name)
}
function Keys([string]$seq, [string]$desc) {
    [W2]::SetForegroundWindow($h) | Out-Null
    Start-Sleep -Milliseconds 300
    [System.Windows.Forms.SendKeys]::SendWait($seq)
    Start-Sleep -Milliseconds 600
    Write-Output ("sent: " + $desc)
}
Keys "{ESC}987" "ESC 987"
Shot "t1_987.png"
Keys "{BS}" "single Backspace"
Shot "t2_after_BS.png"
Stop-Process -Id $p.Id -Force
Write-Output "DIAG DONE"
