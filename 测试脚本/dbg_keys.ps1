# Debug keyboard events: start app, send keys via PostMessage, capture qDebug output
$ErrorActionPreference = "Stop"
$env:Path = "C:\Qt\6.11.2\mingw_64\bin;" + $env:Path
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class D {
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint msg, IntPtr wp, IntPtr lp);
}
"@
$p = Start-Process "C:\Users\111\Documents\calculator\Calculator\build\Calculator.exe" -PassThru -RedirectStandardError "C:\Users\111\Documents\calculator\Calculator\测试脚本\dbg_stderr.txt" -RedirectStandardOutput "C:\Users\111\Documents\calculator\Calculator\测试脚本\dbg_stdout.txt"
Start-Sleep -Seconds 2
$h = $p.MainWindowHandle
$WM_KEYDOWN = 0x0100
$WM_CHAR = 0x0102
function Vk([int]$vk) { [D]::PostMessage($h, $WM_KEYDOWN, [IntPtr]$vk, [IntPtr]0) | Out-Null; Start-Sleep -Milliseconds 200 }
function Ch([char]$c) { [D]::PostMessage($h, $WM_CHAR, [IntPtr][int]$c, [IntPtr]0) | Out-Null; Start-Sleep -Milliseconds 200 }

# 数字 5
Vk 0x35
# 退格 VK_BACK
Vk 0x08
# 等号 Enter
Vk 0x0D
# 百分比 (WM_CHAR)
Ch '%'
# Delete
Vk 0x2E
# Esc
Vk 0x1B

Start-Sleep -Seconds 1
Stop-Process -Id $p.Id -Force
Write-Output "--- stderr (qDebug) ---"
Get-Content "C:\Users\111\Documents\calculator\Calculator\测试脚本\dbg_stderr.txt" -Encoding UTF8
