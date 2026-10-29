# Calculator black-box keyboard test via PostMessage WM_KEYDOWN
# 直接向窗口发送键盘消息，不依赖前台焦点，结果稳定

$ErrorActionPreference = "Stop"
$env:Path = "C:\Qt\6.11.2\mingw_64\bin;" + $env:Path

Add-Type -AssemblyName System.Drawing

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class K {
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint msg, IntPtr wp, IntPtr lp);
    public struct RECT { public int Left, Top, Right, Bottom; }
}
"@

[K]::SetProcessDPIAware() | Out-Null

$outDir = "C:\Users\111\Documents\calculator\实验截图"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$p = Start-Process "C:\Users\111\Documents\calculator\Calculator\build\Calculator.exe" -PassThru
Start-Sleep -Seconds 2
$h = $p.MainWindowHandle
if ($h -eq [IntPtr]::Zero) { throw "window not found" }

$WM_KEYDOWN = 0x0100
$WM_CHAR    = 0x0102

function Vk([int]$vk)  { [K]::PostMessage($h, $WM_KEYDOWN, [IntPtr]$vk, [IntPtr]0) | Out-Null; Start-Sleep -Milliseconds 60 }
function Ch([char]$c)  { [K]::PostMessage($h, $WM_CHAR, [IntPtr][int]$c, [IntPtr]0) | Out-Null; Start-Sleep -Milliseconds 60 }

# 虚拟键码
$VK_0=0x30; $VK_1=0x31; $VK_2=0x32; $VK_3=0x33; $VK_4=0x34
$VK_5=0x35; $VK_6=0x36; $VK_7=0x37; $VK_8=0x38; $VK_9=0x39
$VK_ADD=0x6B; $VK_SUBTRACT=0x6D; $VK_MULTIPLY=0x6A; $VK_DIVIDE=0x6F
$VK_DECIMAL=0x6E; $VK_RETURN=0x0D; $VK_BACK=0x08; $VK_ESCAPE=0x1B; $VK_DELETE=0x2E

function Send-Digit([int]$d) { Vk ($VK_0 + $d) }
function Send-Plus()  { Vk $VK_ADD }
function Send-Minus() { Vk $VK_SUBTRACT }
function Send-Mult()  { Vk $VK_MULTIPLY }
function Send-Div()   { Vk $VK_DIVIDE }
function Send-Dot()   { Vk $VK_DECIMAL }
function Send-Enter() { Vk $VK_RETURN }
function Send-BS()    { Vk $VK_BACK }
function Send-Esc()   { Vk $VK_ESCAPE }
function Send-Percent() { Ch '%' }

function Shot([string]$name) {
    Start-Sleep -Milliseconds 300
    $r = New-Object K+RECT
    [K]::GetWindowRect($h, [ref]$r) | Out-Null
    $w = $r.Right - $r.Left
    $hh = $r.Bottom - $r.Top
    $bmp = New-Object System.Drawing.Bitmap($w, $hh)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($r.Left, $r.Top, 0, 0, $bmp.Size)
    $bmp.Save((Join-Path $outDir $name), [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    Write-Output ("saved: " + $name)
}

# ---- 用例 ----
# 1 初始
Shot "01_init.png"

# 2 小数运算 12.5 + 7.5 = 20
Send-Digit 1; Send-Digit 2; Send-Dot; Send-Digit 5; Send-Plus
Send-Digit 7; Send-Dot; Send-Digit 5; Send-Enter
Shot "02_float_add_result20.png"

# 3 除零 1/0=
Send-Esc; Send-Digit 1; Send-Div; Send-Digit 0; Send-Enter
Shot "03_div_zero_error.png"

# 4 连续运算 5+3=8
Send-Esc; Send-Digit 5; Send-Plus; Send-Digit 3; Send-Enter
Shot "04_5plus3_8.png"

# 5 连续运算 8*2=16
Send-Mult; Send-Digit 2; Send-Enter
Shot "05_8times2_16.png"

# 6 连续小数点 1.2.3 -> 1.23
Send-Esc; Send-Digit 1; Send-Dot; Send-Digit 2; Send-Dot; Send-Digit 3
Shot "06_double_decimal_123.png"

# 7 连续操作符 5+-3= -> 2
Send-Esc; Send-Digit 5; Send-Plus; Send-Minus; Send-Digit 3; Send-Enter
Shot "07_double_operator_2.png"

# 8 退格 987{BS} -> 98
Send-Esc; Send-Digit 9; Send-Digit 8; Send-Digit 7; Send-BS
Shot "08_backspace_98.png"

# 9 计算完成后继续输入 8+2=10, 再按5
Send-Esc; Send-Digit 8; Send-Plus; Send-Digit 2; Send-Enter
Shot "09_result_10.png"
Send-Digit 5
Shot "10_after_equal_continue_5.png"

# 10 百分比 50% -> 0.5
Send-Esc; Send-Digit 5; Send-Digit 0; Send-Percent
Shot "11_percent_05.png"

# 11 连续退格 123{BS}{BS} -> 1
Send-Esc; Send-Digit 1; Send-Digit 2; Send-Digit 3; Send-BS; Send-BS
Shot "12_backspace_twice_1.png"

# 12 Delete=CE 12{Del} -> 0
Send-Esc; Send-Digit 1; Send-Digit 2; Vk $VK_DELETE
Shot "13_delete_ce_0.png"

Stop-Process -Id $p.Id -Force
Write-Output "ALL KEYBOARD TESTS DONE"
