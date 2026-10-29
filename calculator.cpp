#include "calculator.h"
#include "ui_calculator.h"

#include <QButtonGroup>
#include <QKeyEvent>
#include <QLabel>
#include <QLineEdit>
#include <QPushButton>
#include <cmath>

Calculator::Calculator(QWidget *parent)
    : QWidget(parent)
    , ui(new Ui::Calculator)
{
    ui->setupUi(this);

    // 只读显示控件不参与焦点链，避免拦截键盘事件
    ui->display->setFocusPolicy(Qt::NoFocus);

    // 使用样式表改善界面观感
    setStyleSheet(R"(
        QLineEdit#display {
            background: #f7f8fa;
            border: 1px solid #d5d9e0;
            border-radius: 8px;
            font-size: 30px;
            font-weight: bold;
            color: #1f2329;
            padding: 4px 12px;
        }
        QPushButton {
            font-size: 17px;
            border: 1px solid #d5d9e0;
            border-radius: 8px;
            background: #ffffff;
            color: #1f2329;
            padding: 10px;
        }
        QPushButton:hover  { background: #ecf2ff; }
        QPushButton:pressed { background: #d4e2ff; }
        QPushButton#btnEquals {
            background: #2f6fed;
            color: #ffffff;
            font-size: 24px;
        }
        QPushButton#btnEquals:hover   { background: #2a63d6; }
        QPushButton#btnEquals:pressed { background: #1f4fb0; }
    )");

    connectButtons();
}

Calculator::~Calculator()
{
    delete ui;
}

// ---------------------------------------------------------------------------
// 按钮信号关联：所有按钮最终都调用同一套 handle* 函数，
// 与键盘事件处理完全复用，保证鼠标输入与键盘输入行为一致。
// ---------------------------------------------------------------------------
void Calculator::connectButtons()
{
    // 数字键 0-9
    auto *digitGroup = new QButtonGroup(this);
    QPushButton *digitButtons[10] = {
        ui->btn0, ui->btn1, ui->btn2, ui->btn3, ui->btn4,
        ui->btn5, ui->btn6, ui->btn7, ui->btn8, ui->btn9
    };
    for (int i = 0; i < 10; ++i)
        digitGroup->addButton(digitButtons[i], i);
    connect(digitGroup, &QButtonGroup::idClicked, this, [this](int id) {
        handleDigit(QString::number(id));
    });

    // 二元操作符 + - × ÷
    auto *opGroup = new QButtonGroup(this);
    opGroup->addButton(ui->btnPlus, 0);
    opGroup->addButton(ui->btnMinus, 1);
    opGroup->addButton(ui->btnMultiply, 2);
    opGroup->addButton(ui->btnDivide, 3);
    connect(opGroup, &QButtonGroup::idClicked, this, [this](int id) {
        const QString ops[] = { "+", "-", "×", "÷" };
        handleOperator(ops[id]);
    });

    // 其余功能键
    connect(ui->btnDecimal,   &QPushButton::clicked, this, &Calculator::handleDecimalPoint);
    connect(ui->btnBackspace, &QPushButton::clicked, this, &Calculator::handleBackspace);
    connect(ui->btnClearEntry,&QPushButton::clicked, this, &Calculator::handleClearEntry);
    connect(ui->btnClear,     &QPushButton::clicked, this, &Calculator::handleClearAll);
    connect(ui->btnEquals,    &QPushButton::clicked, this, &Calculator::handleEquals);
    connect(ui->btnNegate,    &QPushButton::clicked, this, &Calculator::handleNegate);

    connect(ui->btnPercent,    &QPushButton::clicked, this, [this] { handleUnary("%"); });
    connect(ui->btnReciprocal, &QPushButton::clicked, this, [this] { handleUnary("1/x"); });
    connect(ui->btnSquare,     &QPushButton::clicked, this, [this] { handleUnary("x2"); });
    connect(ui->btnSqrt,       &QPushButton::clicked, this, [this] { handleUnary("sqrt"); });
}

// ---------------------------------------------------------------------------
// 键盘事件：把按键映射到与鼠标按钮相同的处理函数
// ---------------------------------------------------------------------------
void Calculator::keyPressEvent(QKeyEvent *event)
{
    // 优先按字符处理，兼容输入法与 WM_CHAR 产生的事件（此时 key 可能为 0）
    const QString text = event->text();
    if (text.length() == 1) {
        const QChar ch = text.at(0);
        if (ch >= '0' && ch <= '9') { handleDigit(QString(ch)); return; }
        if (ch == '.')   { handleDecimalPoint(); return; }
        if (ch == '+')   { handleOperator("+"); return; }
        if (ch == '-')   { handleOperator("-"); return; }
        if (ch == '*')   { handleOperator("×"); return; }
        if (ch == '/')   { handleOperator("÷"); return; }
        if (ch == '%')   { handleUnary("%"); return; }
        if (ch == '=')   { handleEquals(); return; }
        if (ch == 'c' || ch == 'C') { handleClearAll(); return; }
    }

    const int key = event->key();
    switch (key) {
    case Qt::Key_Backspace:     // 退格
        handleBackspace();
        break;
    case Qt::Key_Delete:        // Delete 对应 CE
        handleClearEntry();
        break;
    case Qt::Key_Escape:        // Esc / C 对应全部清除
    case Qt::Key_C:
        handleClearAll();
        break;
    case Qt::Key_Return:        // Enter 对应等号
    case Qt::Key_Enter:
    case Qt::Key_Equal:
        handleEquals();
        break;
    case Qt::Key_Plus:
        handleOperator("+");
        break;
    case Qt::Key_Minus:
        handleOperator("-");
        break;
    case Qt::Key_Asterisk:      // *
        handleOperator("×");
        break;
    case Qt::Key_Slash:         // /
        handleOperator("÷");
        break;
    case Qt::Key_Period:        // . （含小键盘小数点）
    case Qt::Key_Comma:
        handleDecimalPoint();
        break;
    case Qt::Key_Percent:
        handleUnary("%");
        break;
    default:
        QWidget::keyPressEvent(event);
        break;
    }
}

// ---------------------------------------------------------------------------
// 输入处理
// ---------------------------------------------------------------------------

// 数字输入：等号/操作符后输入新数字时清空旧显示；避免前导零
void Calculator::handleDigit(const QString &digit)
{
    if (m_error)
        return;

    QString text = ui->display->text();
    if (m_waitingForOperand) {
        text = "0";
        m_waitingForOperand = false;
    }
    if (text == "0" && digit != ".") {
        text = digit;
    } else {
        if (text.length() >= 18)   // 限制长度，防止溢出显示区域
            return;
        text += digit;
    }
    updateDisplay(text);
}

// 小数点：同一操作数内已存在小数点时忽略（异常输入处理）
void Calculator::handleDecimalPoint()
{
    if (m_error)
        return;

    QString text = ui->display->text();
    if (m_waitingForOperand) {
        text = "0";
        m_waitingForOperand = false;
    }
    if (text.contains('.'))
        return;
    updateDisplay(text + ".");
}

// 退格：删除当前输入的最后一位；等待新操作数时无意义
void Calculator::handleBackspace()
{
    if (m_error || m_waitingForOperand)
        return;

    QString text = ui->display->text();
    if (text == "0" || text.isEmpty())
        return;
    text.chop(1);
    if (text.isEmpty() || text == "-")
        text = "0";
    updateDisplay(text);
}



// CE：仅清除当前输入，保留第一个操作数与操作符
void Calculator::handleClearEntry()
{
    if (m_error) {
        handleClearAll();   // 错误状态下 CE 与 C 等效，恢复计算器
        return;
    }
    updateDisplay("0");
    m_waitingForOperand = true;
}

// C：全部状态复位
void Calculator::handleClearAll()
{
    m_firstOperand = 0.0;
    m_operator.clear();
    m_waitingForOperand = false;
    m_error = false;
    updateDisplay("0");
}

// 二元操作符：连续操作符时替换当前操作符；否则先结算中间结果（连续运算）
void Calculator::handleOperator(const QString &op)
{
    if (m_error)
        return;

    if (m_waitingForOperand) {
        m_operator = op;        // 连续输入操作符：替换，不改变操作数
        return;
    }

    double value = 0.0;
    if (!tryParse(ui->display->text(), value))
        return;

    if (m_operator.isEmpty()) {
        m_firstOperand = value;          // 记录第一个操作数
    } else {
        double result = applyOperator(m_firstOperand, value, m_operator);
        if (std::isinf(result) || std::isnan(result)) {
            showError("不能除以 0");
            return;
        }
        m_firstOperand = result;         // 连续运算：中间结果作为新操作数
        updateDisplay(formatNumber(result));
    }

    m_operator = op;
    m_waitingForOperand = true;
}

// 等号：结算并显示结果；之后输入数字将开始新的计算
void Calculator::handleEquals()
{
    if (m_error || m_operator.isEmpty())
        return;

    double second = 0.0;
    if (!tryParse(ui->display->text(), second))
        return;

    double result = applyOperator(m_firstOperand, second, m_operator);
    if (std::isinf(result) || std::isnan(result)) {
        showError("不能除以 0");
        return;
    }

    updateDisplay(formatNumber(result));
    m_firstOperand = result;
    m_operator.clear();
    m_waitingForOperand = true;   // 结果已就绪，等待新操作数
}

// 一元运算：% 1/x x² ²√x，作用于当前显示值
void Calculator::handleUnary(const QString &op)
{
    if (m_error)
        return;

    double value = 0.0;
    if (!tryParse(ui->display->text(), value))
        return;

    double result = 0.0;
    if (op == "%") {
        result = value / 100.0;
    } else if (op == "1/x") {
        if (std::fabs(value) < 1e-12) {
            showError("不能除以 0");
            return;
        }
        result = 1.0 / value;
    } else if (op == "x2") {
        result = value * value;
    } else if (op == "sqrt") {
        if (value < 0) {
            showError("负数无法开方");
            return;
        }
        result = std::sqrt(value);
    }

    // 一元运算结果作为新的当前输入，可继续参与后续运算
    m_waitingForOperand = false;
    updateDisplay(formatNumber(result));
}

// 正负号切换：作用于当前输入
void Calculator::handleNegate()
{
    if (m_error)
        return;

    QString text = ui->display->text();
    if (text == "0" || text.isEmpty())
        return;
    if (text.startsWith('-'))
        text.remove(0, 1);
    else
        text.prepend('-');
    m_waitingForOperand = false;
    updateDisplay(text);
}

// ---------------------------------------------------------------------------
// 辅助函数
// ---------------------------------------------------------------------------

double Calculator::applyOperator(double a, double b, const QString &op) const
{
    if (op == "+") return a + b;
    if (op == "-") return a - b;
    if (op == "×") return a * b;
    if (op == "÷") return a / b;   // 除零由调用方通过 isinf/isnan 检查
    return b;
}

void Calculator::showError(const QString &msg)
{
    m_error = true;
    updateDisplay(msg);
}

void Calculator::updateDisplay(const QString &text)
{
    ui->display->setText(text);
}

// 使用 15 位有效数字格式化，自动去除多余的尾随零
QString Calculator::formatNumber(double value) const
{
    return QString::number(value, 'g', 15);
}

bool Calculator::tryParse(const QString &text, double &value) const
{
    bool ok = false;
    value = text.toDouble(&ok);
    return ok;
}
