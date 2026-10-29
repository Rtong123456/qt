# Get button global coordinates from qDebug output
$ErrorActionPreference = "Stop"
$env:Path = "C:\Qt\6.11.2\mingw_64\bin;" + $env:Path
Get-Process Calculator -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 800
$out = "C:\Users\111\Documents\calculator\Calculator\测试脚本\btn_coords.txt"
$err = "C:\Users\111\Documents\calculator\Calculator\测试脚本\btn_err.txt"
Remove-Item $out, $err -ErrorAction SilentlyContinue
$p = Start-Process "C:\Users\111\Documents\calculator\Calculator\build\Calculator.exe" -PassThru -RedirectStandardOutput $out -RedirectStandardError $err
Start-Sleep -Seconds 3
Stop-Process -Id $p.Id -Force
Get-Content $err -Encoding UTF8 | Where-Object { $_ -match "BTN" }
