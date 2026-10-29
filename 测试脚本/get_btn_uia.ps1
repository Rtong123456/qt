# Get button coordinates via UI Automation (works with Qt accessibility)
$ErrorActionPreference = "Stop"
$env:Path = "C:\Qt\6.11.2\mingw_64\bin;" + $env:Path
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Get-Process Calculator -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 800
$p = Start-Process "C:\Users\111\Documents\calculator\Calculator\build\Calculator.exe" -PassThru
Start-Sleep -Seconds 2
$h = $p.MainWindowHandle
$root = [System.Windows.Automation.AutomationElement]::FromHandle($h)
$cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button)
$buttons = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cond)
$out = @()
foreach ($b in $buttons) {
    $r = $b.Current.BoundingRectangle
    $out += ("{0}|{1}|{2}|{3}|{4}" -f $b.Current.Name, [int]$r.X, [int]$r.Y, [int]$r.Width, [int]$r.Height)
}
$out | Out-File "C:\Users\111\Documents\calculator\Calculator\测试脚本\btn_uia.txt" -Encoding utf8
$out
Stop-Process -Id $p.Id -Force
Write-Output "UIA DONE"
