# Mouse click test via UI Automation coordinates + PostMessage
# 启动后动态获取按钮坐标，点击真实按钮验证 connect 链路

$ErrorActionPreference = "Stop"
$env:Path = "C:\Qt\6.11.2\mingw_64\bin;" + $env:Path
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class MT {
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint msg, IntPtr wp, IntPtr lp);
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hwnd, IntPtr hdc, uint flags);
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    public struct RECT { public int Left, Top, Right, Bottom; }
    public struct POINT { public int X, Y; }
}
"@
[MT]::SetProcessDPIAware() | Out-Null

$outDir = "C:\Users\111\Documents\calculator\实验截图"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

Get-Process Calculator -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 800
$p = Start-Process "C:\Users\111\Documents\calculator\Calculator\build\Calculator.exe" -PassThru
Start-Sleep -Seconds 2
$h = $p.MainWindowHandle

# 用 UIA 获取所有按钮的屏幕中心坐标
$root = [System.Windows.Automation.AutomationElement]::FromHandle($h)
$cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button)
$buttons = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cond)
$btn = @{}
foreach ($b in $buttons) {
    $r = $b.Current.BoundingRectangle
    $btn[$b.Current.Name] = @([int]($r.X + $r.Width / 2), [int]($r.Y + $r.Height / 2))
}

# 客户区原点（屏幕坐标）
$pt = New-Object MT+POINT
[MT]::ClientToScreen($h, [ref]$pt) | Out-Null
$cx0 = $pt.X
$cy0 = $pt.Y

$WM_LBUTTONDOWN = 0x0201
$WM_LBUTTONUP   = 0x0202

function Click([string]$name) {
    if (-not $btn.ContainsKey($name)) { throw "no such button: $name" }
    $c = $btn[$name]
    $cx = $c[0] - $cx0
    $cy = $c[1] - $cy0
    $lp = [IntPtr](($cy -shl 16) -bor ($cx -band 0xFFFF))
    [MT]::PostMessage($h, $WM_LBUTTONDOWN, [IntPtr]1, $lp) | Out-Null
    Start-Sleep -Milliseconds 60
    [MT]::PostMessage($h, $WM_LBUTTONUP,   [IntPtr]0, $lp) | Out-Null
    Start-Sleep -Milliseconds 120
    Write-Output ("clicked: " + $name)
}

function Shot([string]$name) {
    Start-Sleep -Milliseconds 300
    $r = New-Object MT+RECT
    [MT]::GetWindowRect($h, [ref]$r) | Out-Null
    $w = $r.Right - $r.Left
    $hh = $r.Bottom - $r.Top
    $bmp = New-Object System.Drawing.Bitmap($w, $hh)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::Black)
    $hdc = $g.GetHdc()
    [MT]::PrintWindow($h, $hdc, 2) | Out-Null   # PW_RENDERFULLCONTENT=2
    $g.ReleaseHdc($hdc)
    $bmp.Save((Join-Path $outDir $name), [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    Write-Output ("saved: " + $name)
}

# ---- 鼠标测试用例 ----
Shot "m01_init.png"

# 1 鼠标四则: 5 + 3 = 8
Click "5"; Click "+"; Click "3"; Click "="
Shot "m02_mouse_5plus3_8.png"

# 2 C 清除
Click "C"
Shot "m03_mouse_clear_0.png"

# 3 鼠标小数乘法: 1 . 2 5 x 2 = 2.5
Click "1"; Click "."; Click "2"; Click "5"; Click "×"; Click "2"; Click "="
Shot "m04_mouse_float_125x2_25.png"

# 4 鼠标退格: 9 8 7 + BS -> 98
Click "C"; Click "9"; Click "8"; Click "7"; Click "⌫"
Shot "m05_mouse_bs_98.png"

# 5 鼠标百分比: 5 0 + % -> 0.5
Click "C"; Click "5"; Click "0"; Click "%"
Shot "m06_mouse_percent_05.png"

# 6 鼠标减法/除法: 9 - 6 = 3 ; 8 / 2 = 4
Click "C"; Click "9"; Click "−"; Click "6"; Click "="
Shot "m07_mouse_9minus6_3.png"
Click "C"; Click "8"; Click "÷"; Click "2"; Click "="
Shot "m08_mouse_8div2_4.png"

Stop-Process -Id $p.Id -Force
Write-Output "MOUSE TESTS DONE"
