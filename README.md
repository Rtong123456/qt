# 带键盘事件的计算器（Qt 6）

东莞理工学院 · Qt 应用程序开发 · 实验一

## 功能

- 四则运算（+ − × ÷）、小数输入、退格（⌫）、清除（CE / C）
- 一元运算：% 、1/x、x²、²√x，正负号切换（+/−）
- 键盘输入与鼠标输入完全复用同一套处理逻辑（`handle*` 函数）
- 异常输入处理：连续小数点、连续操作符、除零、负数开方、
  计算完成后继续输入、输入中退格、清除后重算、鼠标键盘混合输入

## 构建运行

### 方式一：Qt Creator（推荐）

1. 用 Qt Creator 打开 `Calculator.pro`
2. 选择 Qt 6.x Kit（MinGW / MSVC 均可）
3. 直接构建并运行

### 方式二：命令行 qmake

```bash
qmake Calculator.pro
mingw32-make      # 或 nmake / make，取决于编译器
```

### 方式三：CMake

```bash
cmake -S . -B build -G "MinGW Makefiles" ^
      -DCMAKE_PREFIX_PATH=C:/Qt/6.11.2/mingw_64 ^
      -DCMAKE_CXX_COMPILER=C:/Qt/Tools/mingw1310_64/bin/g++.exe
cmake --build build
```

## 键盘映射

| 按键 | 功能 |
|---|---|
| 0-9 | 数字 |
| . 或 , | 小数点 |
| Backspace | 退格 |
| Delete | CE（清除当前输入） |
| Esc 或 C | 全部清除 |
| Enter / = | 等号 |
| + - * / | 四则运算 |
| % | 百分比 |

## 开发与测试记录

- **迭代 1**：项目骨架 + UI 布局（Qt Designer `.ui` 文件，QGridLayout 网格布局）
- **迭代 2**：核心计算逻辑（四则运算、小数、退格、清除、一元运算、状态管理）
- **迭代 3**：异常输入处理（连续小数点、连续操作符、除零、负数开方）
- **迭代 4**：键盘事件，与鼠标输入复用同一套 `handle*` 逻辑
- **问题修复**：
  - 只读显示控件（QLineEdit）拦截退格/Delete 键 → 设置 `setFocusPolicy(Qt::NoFocus)`
  - `%` 键经输入法/WM_CHAR 到达时 `key()` 为 0 → 键盘处理优先按 `event->text()` 字符判断
  - 等号按钮由跨两行改为与最后一行平行，界面更紧凑
- **测试**：`测试脚本/` 下提供键盘（PostMessage）与鼠标（UI Automation 定位）黑盒测试脚本，
  运行截图见 `docs/screenshots/`（键盘 13 项 + 鼠标 8 项全部通过）

## Git 提交历史

```text
<git log 输出见实验报告>
```
