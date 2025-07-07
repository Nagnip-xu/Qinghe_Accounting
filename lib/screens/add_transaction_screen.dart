import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../constants/category_icons.dart';
import '../providers/category_provider.dart';
import '../providers/account_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../providers/transaction_provider.dart';
import '../utils/toast_message.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AddTransactionScreen extends StatefulWidget {
  final int? initialAccountId;
  final String? initialAccountName;

  const AddTransactionScreen({
    super.key,
    this.initialAccountId,
    this.initialAccountName,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  // 交易类型，默认为支出
  String _transactionType = '支出';
  // 金额
  double _amount = 0.0;
  // 使用TextEditingController代替字符串变量
  final TextEditingController _amountController = TextEditingController(
    text: '0',
  );
  // 选中的分类和账户
  int? _selectedCategoryId;
  String _selectedCategoryName = '';
  int? _selectedAccountId;
  String? _selectedAccountName = '';
  // 日期
  DateTime _selectedDate = DateTime.now();
  // 备注
  final TextEditingController _noteController = TextEditingController();
  // 文本输入焦点
  final FocusNode _amountFocusNode = FocusNode();
  // 是否显示数字键盘
  bool _showNumpad = false;
  // 目标账户
  int? _targetAccountId;
  String? _targetAccountName = '';
  String _selectedCategoryIcon = '';
  bool _isLoading = false;
  // 光标闪烁定时器
  bool _showCursor = true;

  @override
  void initState() {
    super.initState();
    // 设置初始账户
    if (widget.initialAccountId != null && widget.initialAccountName != null) {
      _selectedAccountId = widget.initialAccountId;
      _selectedAccountName = widget.initialAccountName;
    }

    // 启动光标闪烁
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _showNumpad = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _amountFocusNode.dispose();
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('添加交易'), elevation: 0),
      body: SafeArea(
        child: Stack(
          children: [
            // 主要内容区域 - 添加SingleChildScrollView使内容可滚动
            SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16),
                // 添加底部padding以防止内容被数字键盘遮挡
                margin: EdgeInsets.only(bottom: _showNumpad ? 240 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 类型选择器
                    _buildTypeSelector(),
                    const SizedBox(height: 16),
                    // 金额输入
                    _buildAmountInput(),
                    const SizedBox(height: 16),
                    // 账户选择
                    _buildAccountItem(
                      title: '选择账户',
                      value: _selectedAccountName ?? '请选择',
                      onTap: _selectAccount,
                    ),
                    // 如果是转账类型，显示目标账户选择
                    if (_transactionType == '转账')
                      Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildAccountItem(
                            title: '转入账户',
                            value: _targetAccountName ?? '请选择',
                            onTap: _selectTargetAccount,
                          ),
                        ],
                      ),
                    // 如果不是转账类型，显示分类选择
                    if (_transactionType != '转账')
                      Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildAccountItem(
                            title: '选择分类',
                            value: _selectedCategoryName ?? '请选择',
                            onTap: _selectCategory,
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    // 日期选择
                    _buildAccountItem(
                      title: '选择日期',
                      value: DateFormat('yyyy-MM-dd').format(_selectedDate),
                      onTap: _selectDate,
                    ),
                    const SizedBox(height: 16),
                    // 备注
                    _buildAccountItem(
                      title: '添加备注',
                      value:
                          _noteController.text.isEmpty
                              ? '无'
                              : _noteController.text,
                      onTap: _addNote,
                    ),
                    const SizedBox(height: 40),
                    // 保存按钮
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child:
                            _isLoading
                                ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                )
                                : const Text(
                                  '保存',
                                  style: TextStyle(fontSize: 16),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 数字键盘（条件显示）
            if (_showNumpad)
              Positioned(bottom: 0, left: 0, right: 0, child: _buildNumPad()),
          ],
        ),
      ),
    );
  }

  // 构建类型选择器
  Widget _buildTypeSelector() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTypeButton('支出', Icons.arrow_downward, Colors.red),
          _buildTypeButton('收入', Icons.arrow_upward, Colors.green),
          _buildTypeButton('转账', Icons.swap_horiz, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String type, IconData icon, Color color) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    bool isSelected = _transactionType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _transactionType = type;
            // 重置选择的分类
            if (type == '转账') {
              _selectedCategoryId = 0;
              _selectedCategoryName = '转账';
              _selectedCategoryIcon = 'exchange';
            } else {
              _selectedCategoryId = null;
              _selectedCategoryName = '';
              _selectedCategoryIcon = '';
            }
          });
          // 添加触觉反馈
          HapticFeedback.selectionClick();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? color.withOpacity(isDarkMode ? 0.3 : 0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border(
              bottom: BorderSide(
                color: isSelected ? color : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color:
                    isSelected
                        ? color
                        : isDarkMode
                        ? Colors.white70
                        : Colors.grey,
              ),
              const SizedBox(height: 4),
              Text(
                type,
                style: TextStyle(
                  color:
                      isSelected
                          ? color
                          : isDarkMode
                          ? Colors.white70
                          : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 重新实现金额输入框，添加光标和选择功能
  Widget _buildAmountInput() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor =
        _transactionType == '支出'
            ? Colors.red
            : _transactionType == '收入'
            ? Colors.green
            : Colors.purple;

    return GestureDetector(
      onTap: () {
        setState(() {
          _showNumpad = true;
        });
        // 将焦点设置到输入框
        FocusScope.of(context).requestFocus(_amountFocusNode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '金额',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '¥',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    focusNode: _amountFocusNode,
                    readOnly: true, // 使用自定义键盘，而不是系统键盘
                    showCursor: true,
                    cursorColor: textColor,
                    cursorWidth: 2,
                    cursorHeight: 32,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    keyboardType: TextInputType.none,
                    onTap: () {
                      // 确保点击输入框时也能显示数字键盘
                      setState(() {
                        _showNumpad = true;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 构建条目项
  Widget _buildAccountItem({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: isDarkMode ? Colors.white70 : Colors.black45,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 数字键盘
  Widget _buildNumPad() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final buttonStyle = ElevatedButton.styleFrom(
      foregroundColor: isDarkMode ? Colors.white : Colors.black87,
      backgroundColor: isDarkMode ? AppColors.darkSurface : Colors.white,
      elevation: 0,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
    );

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      height: 240, // 限制键盘高度
      child: GridView.count(
        crossAxisCount: 4,
        childAspectRatio: 1.5,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          _buildNumPadButton('1', buttonStyle),
          _buildNumPadButton('2', buttonStyle),
          _buildNumPadButton('3', buttonStyle),
          _buildNumPadButton('删除', buttonStyle, isFunction: true),
          _buildNumPadButton('4', buttonStyle),
          _buildNumPadButton('5', buttonStyle),
          _buildNumPadButton('6', buttonStyle),
          _buildNumPadButton('+', buttonStyle, isFunction: true),
          _buildNumPadButton('7', buttonStyle),
          _buildNumPadButton('8', buttonStyle),
          _buildNumPadButton('9', buttonStyle),
          _buildNumPadButton('-', buttonStyle, isFunction: true),
          _buildNumPadButton('.', buttonStyle),
          _buildNumPadButton('0', buttonStyle),
          _buildNumPadButton('00', buttonStyle),
          _buildNumPadButton('完成', buttonStyle, isFunction: true, isDone: true),
        ],
      ),
    );
  }

  Widget _buildNumPadButton(
    String text,
    ButtonStyle style, {
    bool isFunction = false,
    bool isDone = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(1),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: ElevatedButton(
          style:
              isDone
                  ? ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Theme.of(context).primaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                  : style,
          onPressed: () => _handleNumPadInput(text),
          child:
              text == '删除'
                  ? Icon(
                    Icons.backspace_outlined,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  )
                  : Text(
                    text,
                    style: TextStyle(
                      fontSize: isDone ? 16 : 20,
                      color:
                          isDone
                              ? Colors.white
                              : isFunction
                              ? Theme.of(context).primaryColor
                              : isDarkMode
                              ? Colors.white
                              : Colors.black87,
                      fontWeight:
                          isFunction ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
        ),
      ),
    );
  }

  // 处理数字键盘输入
  void _handleNumPadInput(String value) {
    switch (value) {
      case '删除':
        // 获取当前选择范围
        TextSelection selection = _amountController.selection;

        if (selection.isCollapsed) {
          // 如果没有选中文本，则删除光标前的字符
          if (selection.baseOffset > 0) {
            final String newText = _amountController.text.replaceRange(
              selection.baseOffset - 1,
              selection.baseOffset,
              '',
            );
            _amountController.text = newText;
            // 更新光标位置
            _amountController.selection = TextSelection.collapsed(
              offset: selection.baseOffset - 1,
            );
          }
        } else {
          // 如果选中了文本，则删除选中部分
          final String newText = _amountController.text.replaceRange(
            selection.start,
            selection.end,
            '',
          );
          _amountController.text = newText;
          // 更新光标位置
          _amountController.selection = TextSelection.collapsed(
            offset: selection.start,
          );
        }

        // 如果文本为空，设为0
        if (_amountController.text.isEmpty) {
          _amountController.text = '0';
          _amountController.selection = TextSelection.collapsed(offset: 1);
        }
        break;

      case '完成':
        // 隐藏键盘并尝试解析金额
        setState(() {
          _showNumpad = false;
          try {
            _amount = double.parse(_amountController.text);
            // 格式化显示金额
            if (_amount == 0) {
              _amountController.text = '0';
            } else {
              // 移除末尾无用的0和小数点
              if (_amountController.text.contains('.')) {
                _amountController.text = _amount.toString().replaceAll(
                  RegExp(r'\.0+$'),
                  '',
                );
                _amountController.text = _amountController.text.replaceAll(
                  RegExp(r'(\.\d+?)0+$'),
                  r'$1',
                );
              }
            }
          } catch (_) {
            _amount = 0;
            _amountController.text = '0';
          }
        });
        break;

      case '+':
      case '-':
        // 暂不实现运算功能
        break;

      default:
        // 获取当前选择范围
        TextSelection selection = _amountController.selection;
        String currentText = _amountController.text;
        String newText;
        int newCursorPosition;

        // 处理选中范围
        if (selection.isValid) {
          if (selection.isCollapsed) {
            // 在光标位置插入数字
            newText =
                currentText.substring(0, selection.baseOffset) +
                value +
                currentText.substring(selection.baseOffset);
            newCursorPosition = selection.baseOffset + 1;
          } else {
            // 替换选中的文本
            newText =
                currentText.substring(0, selection.start) +
                value +
                currentText.substring(selection.end);
            newCursorPosition = selection.start + 1;
          }
        } else {
          // 如果没有有效的选择，追加到末尾
          newText = currentText + value;
          newCursorPosition = newText.length;
        }

        // 特殊处理：如果当前文本为"0"且输入的不是小数点，则替换而不是添加
        if (currentText == '0' && value != '.') {
          newText = value;
          newCursorPosition = 1;
        }

        // 检查小数点
        if (value == '.' && currentText.contains('.')) {
          return; // 已有小数点，不再添加
        }

        // 检查小数位数限制
        if (currentText.contains('.')) {
          final parts = newText.split('.');
          if (parts.length > 1 && parts[1].length > 2) {
            return; // 已有两位小数，不再添加
          }
        }

        // 限制整数位数
        if (!currentText.contains('.')) {
          if (newText.length > 9 && value != '.') {
            return; // 整数部分不超过9位
          }
        }

        // 更新文本和光标位置
        _amountController.text = newText;
        _amountController.selection = TextSelection.collapsed(
          offset: newCursorPosition,
        );
    }

    // 实时更新金额值并添加震动反馈
    try {
      _amount = double.parse(_amountController.text);
      HapticFeedback.lightImpact(); // 添加轻微震动效果增强用户体验
    } catch (_) {
      _amount = 0;
    }
  }

  // 选择账户
  void _selectAccount() {
    final accounts =
        Provider.of<AccountProvider>(context, listen: false).accounts;
    if (accounts.isEmpty) {
      ToastMessage.show(
        context,
        '请先添加账户',
        icon: Icons.account_balance_wallet,
        backgroundColor: Colors.orange.withOpacity(0.9),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder:
          (context) => ListView.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return ListTile(
                title: Text(account.name),
                subtitle: Text('余额: ${account.balance}'),
                leading: const Icon(Icons.account_balance_wallet),
                onTap: () {
                  setState(() {
                    _selectedAccountId = account.id;
                    _selectedAccountName = account.name;
                  });
                  Navigator.pop(context);

                  // 如果是转账类型，自动提示选择目标账户
                  if (_transactionType == '转账' && _targetAccountId == null) {
                    _selectTargetAccount();
                  }
                },
              );
            },
          ),
    );
  }

  // 选择转账目标账户
  void _selectTargetAccount() {
    final accounts =
        Provider.of<AccountProvider>(context, listen: false).accounts;
    if (accounts.isEmpty || accounts.length < 2) {
      ToastMessage.show(
        context,
        '请先添加多个账户才能进行转账',
        icon: Icons.account_balance_wallet,
        backgroundColor: Colors.orange.withOpacity(0.9),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                child: Text(
                  '选择转入账户',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    // 不显示已选择的源账户
                    if (account.id == _selectedAccountId) {
                      return const SizedBox.shrink();
                    }

                    return ListTile(
                      title: Text(account.name),
                      subtitle: Text('余额: ${account.balance}'),
                      leading: const Icon(Icons.account_balance_wallet),
                      onTap: () {
                        setState(() {
                          _targetAccountId = account.id;
                          _targetAccountName = account.name;
                          // 为转账交易设置一个默认分类
                          _selectedCategoryId = 0;
                          _selectedCategoryName = '转账';
                          _selectedCategoryIcon = 'exchange';
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
    );
  }

  // 选择分类
  void _selectCategory() {
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );

    // 获取所有已有分类
    final userCategories =
        _transactionType == '支出'
            ? categoryProvider.expenseCategories
            : categoryProvider.incomeCategories;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    // 按大类分组的支出分类
    final Map<String, List<Map<String, dynamic>>> expenseCategoriesByGroup = {
      '餐饮': [
        {
          'name': '餐饮',
          'icon': FontAwesomeIcons.utensils,
          'color': CategoryColors.getColor('餐饮'),
        },
        {
          'name': '早餐',
          'icon': FontAwesomeIcons.breadSlice,
          'color': CategoryColors.getColor('餐饮'),
        },
        {
          'name': '午餐',
          'icon': FontAwesomeIcons.bowlFood,
          'color': CategoryColors.getColor('餐饮'),
        },
        {
          'name': '晚餐',
          'icon': FontAwesomeIcons.bowlRice,
          'color': CategoryColors.getColor('餐饮'),
        },
        {
          'name': '零食',
          'icon': FontAwesomeIcons.candyCane,
          'color': CategoryColors.getColor('餐饮'),
        },
      ],
      '交通': [
        {
          'name': '交通',
          'icon': FontAwesomeIcons.car,
          'color': CategoryColors.getColor('交通'),
        },
        {
          'name': '打车',
          'icon': FontAwesomeIcons.taxi,
          'color': CategoryColors.getColor('交通'),
        },
        {
          'name': '公交',
          'icon': FontAwesomeIcons.bus,
          'color': CategoryColors.getColor('交通'),
        },
        {
          'name': '地铁',
          'icon': FontAwesomeIcons.trainSubway,
          'color': CategoryColors.getColor('交通'),
        },
      ],
      '购物': [
        {
          'name': '购物',
          'icon': FontAwesomeIcons.bagShopping,
          'color': CategoryColors.getColor('购物'),
        },
        {
          'name': '服装',
          'icon': FontAwesomeIcons.shirt,
          'color': CategoryColors.getColor('购物'),
        },
        {
          'name': '化妆',
          'icon': FontAwesomeIcons.sprayCan,
          'color': CategoryColors.getColor('购物'),
        },
        {
          'name': '数码',
          'icon': FontAwesomeIcons.laptop,
          'color': CategoryColors.getColor('数码'),
        },
        {
          'name': '家居',
          'icon': FontAwesomeIcons.couch,
          'color': CategoryColors.getColor('家居'),
        },
      ],
      '娱乐': [
        {
          'name': '娱乐',
          'icon': FontAwesomeIcons.gamepad,
          'color': CategoryColors.getColor('娱乐'),
        },
        {
          'name': '电影',
          'icon': FontAwesomeIcons.film,
          'color': CategoryColors.getColor('娱乐'),
        },
        {
          'name': '游戏',
          'icon': FontAwesomeIcons.chess,
          'color': CategoryColors.getColor('娱乐'),
        },
        {
          'name': '旅游',
          'icon': FontAwesomeIcons.plane,
          'color': CategoryColors.getColor('旅游'),
        },
      ],
      '住房': [
        {
          'name': '住房',
          'icon': FontAwesomeIcons.house,
          'color': CategoryColors.getColor('住房'),
        },
        {
          'name': '房租',
          'icon': FontAwesomeIcons.houseChimney,
          'color': CategoryColors.getColor('住房'),
        },
        {
          'name': '水费',
          'icon': FontAwesomeIcons.droplet,
          'color': CategoryColors.getColor('水费'),
        },
        {
          'name': '电费',
          'icon': FontAwesomeIcons.bolt,
          'color': CategoryColors.getColor('电费'),
        },
        {
          'name': '燃气费',
          'icon': FontAwesomeIcons.fire,
          'color': CategoryColors.getColor('燃气费'),
        },
        {
          'name': '网费',
          'icon': FontAwesomeIcons.wifi,
          'color': CategoryColors.getColor('网费'),
        },
        {
          'name': '话费',
          'icon': FontAwesomeIcons.phone,
          'color': CategoryColors.getColor('话费'),
        },
      ],
      '医疗': [
        {
          'name': '医疗',
          'icon': FontAwesomeIcons.suitcaseMedical,
          'color': CategoryColors.getColor('医疗'),
        },
        {
          'name': '药品',
          'icon': FontAwesomeIcons.pills,
          'color': CategoryColors.getColor('医疗'),
        },
        {
          'name': '挂号',
          'icon': FontAwesomeIcons.hospitalUser,
          'color': CategoryColors.getColor('医疗'),
        },
      ],
      '教育': [
        {
          'name': '教育',
          'icon': FontAwesomeIcons.graduationCap,
          'color': CategoryColors.getColor('学习'),
        },
        {
          'name': '学费',
          'icon': FontAwesomeIcons.book,
          'color': CategoryColors.getColor('学习'),
        },
        {
          'name': '书籍',
          'icon': FontAwesomeIcons.bookOpen,
          'color': CategoryColors.getColor('学习'),
        },
      ],
      '其他': [
        {
          'name': '孩子',
          'icon': FontAwesomeIcons.baby,
          'color': CategoryColors.getColor('孩子'),
        },
        {
          'name': '宠物',
          'icon': FontAwesomeIcons.paw,
          'color': CategoryColors.getColor('宠物'),
        },
        {
          'name': '理财',
          'icon': FontAwesomeIcons.moneyBillTrendUp,
          'color': CategoryColors.getColor('理财'),
        },
        {
          'name': '社交',
          'icon': FontAwesomeIcons.userGroup,
          'color': CategoryColors.getColor('社交'),
        },
        {
          'name': '礼物',
          'icon': FontAwesomeIcons.gift,
          'color': CategoryColors.getColor('礼物'),
        },
        {
          'name': '其他',
          'icon': FontAwesomeIcons.ellipsis,
          'color': CategoryColors.getColor('其他'),
        },
      ],
    };

    // 按大类分组的收入分类
    final Map<String, List<Map<String, dynamic>>> incomeCategoriesByGroup = {
      '工作': [
        {
          'name': '工资',
          'icon': FontAwesomeIcons.moneyBill1,
          'color': CategoryColors.getColor('工资'),
        },
        {
          'name': '奖金',
          'icon': FontAwesomeIcons.award,
          'color': CategoryColors.getColor('奖金'),
        },
        {
          'name': '兼职',
          'icon': FontAwesomeIcons.briefcase,
          'color': CategoryColors.getColor('兼职'),
        },
      ],
      '投资': [
        {
          'name': '投资',
          'icon': FontAwesomeIcons.chartLine,
          'color': CategoryColors.getColor('投资'),
        },
        {
          'name': '理财',
          'icon': FontAwesomeIcons.piggyBank,
          'color': CategoryColors.getColor('理财'),
        },
        {
          'name': '股票',
          'icon': FontAwesomeIcons.chartSimple,
          'color': CategoryColors.getColor('股票'),
        },
        {
          'name': '基金',
          'icon': FontAwesomeIcons.buildingColumns,
          'color': CategoryColors.getColor('基金'),
        },
        {
          'name': '房租',
          'icon': FontAwesomeIcons.houseChimney,
          'color': CategoryColors.getColor('房租'),
        },
      ],
      '其他': [
        {
          'name': '红包',
          'icon': FontAwesomeIcons.envelopeOpen,
          'color': CategoryColors.getColor('红包'),
        },
        {
          'name': '退款',
          'icon': FontAwesomeIcons.rotateLeft,
          'color': CategoryColors.getColor('退款'),
        },
        {
          'name': '补贴',
          'icon': FontAwesomeIcons.handHoldingDollar,
          'color': CategoryColors.getColor('补贴'),
        },
        {
          'name': '其他',
          'icon': FontAwesomeIcons.ellipsis,
          'color': CategoryColors.getColor('其他'),
        },
      ],
    };

    // 根据交易类型选择使用的分类分组
    final categoriesByGroup =
        _transactionType == '支出'
            ? expenseCategoriesByGroup
            : incomeCategoriesByGroup;

    // 获取用户自定义分类（排除预设分类）
    List<Map<String, dynamic>> customCategories = [];
    // 将预设分类名称放入一个集合，用于快速查找
    final Set<String> presetCategoryNames = {};

    // 收集所有预设分类名称
    categoriesByGroup.forEach((_, categories) {
      for (var category in categories) {
        presetCategoryNames.add(category['name']);
      }
    });

    // 找出自定义分类（即不在预设分类中的分类）
    for (var category in userCategories) {
      if (!presetCategoryNames.contains(category.name)) {
        IconData iconData;
        Color color;

        // 尝试解析颜色
        try {
          if (category.color != null && category.color!.isNotEmpty) {
            if (category.color!.startsWith('0x')) {
              color = Color(int.parse(category.color!));
            } else {
              color = Color(
                int.parse('0xFF${category.color!.replaceAll('#', '')}'),
              );
            }
          } else {
            color = CategoryColors.getColor(category.name);
          }
        } catch (e) {
          color = CategoryColors.getColor('其他');
        }

        // 尝试解析图标，默认使用通用图标
        try {
          iconData = FontAwesomeIcons.tag;
        } catch (e) {
          iconData = FontAwesomeIcons.tag;
        }

        customCategories.add({
          'name': category.name,
          'icon': iconData,
          'color': color,
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 顶部标题
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color:
                            isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '选择分类',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.close,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                // 分类网格
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...categoriesByGroup.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 分类组标题
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  top: 20,
                                  bottom: 12,
                                ),
                                child: Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDarkMode
                                            ? Colors.white70
                                            : Colors.black54,
                                  ),
                                ),
                              ),
                              // 该组内的分类
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Center(
                                  child: Wrap(
                                    spacing: 12, // 水平间距
                                    runSpacing: 16, // 垂直间距
                                    alignment: WrapAlignment.center, // 居中对齐
                                    children: [
                                      ...entry.value.map(
                                        (category) => _buildPresetCategoryItem(
                                          category['name'],
                                          category['icon'],
                                          category['color'],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8), // 组之间的间距
                              const Divider(height: 16),
                            ],
                          );
                        }),

                        // 自定义分类区域
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                top: 20,
                                bottom: 12,
                              ),
                              child: Text(
                                '自定义分类',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDarkMode
                                          ? Colors.white70
                                          : Colors.black54,
                                ),
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Center(
                                child: Wrap(
                                  spacing: 12, // 水平间距
                                  runSpacing: 16, // 垂直间距
                                  alignment: WrapAlignment.center, // 居中对齐
                                  children: [
                                    // 显示所有自定义分类
                                    ...customCategories.map(
                                      (category) => _buildPresetCategoryItem(
                                        category['name'],
                                        category['icon'],
                                        category['color'],
                                      ),
                                    ),
                                    // 添加分类按钮
                                    _buildAddCategoryButton(
                                      isDarkMode,
                                      primaryColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // 构建预设分类项
  Widget _buildPresetCategoryItem(String name, IconData iconData, Color color) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryName = name;
          _selectedCategoryIcon = name; // 使用名称作为图标标识符

          // 查找已有分类中的ID，如果找不到，则创建一个临时ID并标记为需要创建新分类
          final categoryProvider = Provider.of<CategoryProvider>(
            context,
            listen: false,
          );
          final categories =
              _transactionType == '支出'
                  ? categoryProvider.expenseCategories
                  : categoryProvider.incomeCategories;

          final category = categories.firstWhere(
            (c) => c.name == name,
            orElse: () {
              // 如果找不到分类，创建一个新的分类并添加到数据库
              final newCategory = Category(
                name: name,
                type: _transactionType,
                icon: name,
                color: color.value.toRadixString(16),
              );

              // 异步添加分类，不等待结果
              categoryProvider.addCategory(newCategory).then((success) {
                if (success) {
                  print('成功添加分类: $name');
                } else {
                  print('添加分类失败: $name');
                }
              });

              // 返回一个临时分类用于设置ID
              return newCategory;
            },
          );

          // 不管是现有分类还是新分类，都设置ID
          _selectedCategoryId = category.id ?? -999; // 如果是新分类没有ID，使用临时ID
        });

        // 额外输出调试信息
        print('已选择分类: $_selectedCategoryName, ID: $_selectedCategoryId');

        Navigator.pop(context);
      },
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, size: 20, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // 构建添加自定义分类按钮
  Widget _buildAddCategoryButton(bool isDarkMode, Color primaryColor) {
    return GestureDetector(
      onTap: () {
        // 显示添加分类对话框
        _showAddCategoryDialog();
      },
      child: SizedBox(
        width: 65, // 与分类项保持一致
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 45, // 与分类项保持一致
              height: 45, // 与分类项保持一致
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.add,
                size: 20,
                color: Colors.blue,
              ), // 调整图标大小
            ),
            const SizedBox(height: 4), // 减小间距
            Text(
              '自定义',
              style: TextStyle(
                fontSize: 12, // 减小字体大小
                color: isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 显示添加分类对话框
  void _showAddCategoryDialog() {
    final TextEditingController categoryNameController =
        TextEditingController();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('添加自定义分类'),
            content: TextField(
              controller: categoryNameController,
              decoration: const InputDecoration(
                labelText: '分类名称',
                hintText: '请输入分类名称',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  if (categoryNameController.text.trim().isNotEmpty) {
                    // 创建并添加新分类
                    final categoryName = categoryNameController.text.trim();
                    final newCategory = Category(
                      name: categoryName,
                      type: _transactionType,
                      icon: 'custom', // 自定义图标标识
                      color: CategoryColors.getColor(
                        categoryName,
                      ).value.toRadixString(16),
                    );

                    Provider.of<CategoryProvider>(
                      context,
                      listen: false,
                    ).addCategory(newCategory).then((success) {
                      if (success) {
                        Navigator.pop(context); // 关闭对话框
                        // 刷新分类列表并重新打开选择器
                        Future.delayed(const Duration(milliseconds: 300), () {
                          _selectCategory();
                        });
                      } else {
                        // 显示错误提示
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('添加分类失败')));
                      }
                    });
                  }
                },
                child: const Text('添加'),
              ),
            ],
          ),
    );
  }

  // 选择日期
  void _selectDate() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    // 显示自定义日期选择器
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // 允许内容超出默认高度
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: CustomDatePicker(
              initialDate: _selectedDate,
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                });
              },
            ),
          ),
    );
  }

  // 添加备注
  void _addNote() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.darkCard : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '添加备注',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: '输入备注内容',
                      filled: true,
                      fillColor: isDarkMode ? Colors.black26 : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    maxLines: 4,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('确定', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // 保存交易
  void _saveTransaction() {
    if (_selectedAccountId == null ||
        _selectedAccountName == null ||
        _selectedAccountName!.isEmpty) {
      _showErrorDialog('请选择账户');
      return;
    }

    if (_transactionType == '转账') {
      if (_targetAccountId == null ||
          _targetAccountName == null ||
          _targetAccountName!.isEmpty) {
        _showErrorDialog('请选择转入账户');
        return;
      }

      if (_selectedAccountId == _targetAccountId) {
        _showErrorDialog('转出账户和转入账户不能相同');
        return;
      }
    } else {
      // 修改验证逻辑，允许临时ID通过验证
      if ((_selectedCategoryId == null || _selectedCategoryId == 0) &&
          _selectedCategoryName.isEmpty) {
        _showErrorDialog('请选择分类');
        return;
      }
    }

    if (_amount <= 0) {
      _showErrorDialog('请输入大于0的金额');
      return;
    }

    // 对于新添加的分类，先获取其真正的ID
    if (_selectedCategoryId == -999 && _selectedCategoryName.isNotEmpty) {
      // 如果是临时ID，尝试查找真实ID或创建新分类
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );

      // 查找分类或创建新分类
      categoryProvider
          .findOrCreateCategory(
            _selectedCategoryName,
            _transactionType,
            _selectedCategoryIcon,
          )
          .then((categoryId) {
            if (categoryId != null) {
              _selectedCategoryId = categoryId;
              _completeSaveTransaction();
            } else {
              _showErrorDialog('无法创建分类，请重试');
            }
          });
    } else {
      // 直接完成保存
      _completeSaveTransaction();
    }
  }

  // 完成保存交易的实际步骤
  void _completeSaveTransaction() {
    // 构建交易对象
    final transaction = Transaction(
      type: _transactionType,
      amount: _amount,
      categoryId: _transactionType == '转账' ? 0 : _selectedCategoryId!,
      categoryName: _transactionType == '转账' ? '转账' : _selectedCategoryName,
      categoryIcon: _selectedCategoryIcon,
      accountId: _selectedAccountId!,
      accountName: _selectedAccountName!,
      date: _selectedDate,
      note: _noteController.text,
      toAccountId: _transactionType == '转账' ? _targetAccountId : null,
      toAccountName: _transactionType == '转账' ? _targetAccountName : null,
    );

    // 保存交易
    setState(() {
      _isLoading = true;
    });

    Provider.of<TransactionProvider>(
      context,
      listen: false,
    ).addTransaction(transaction, context: context).then((success) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        Navigator.pop(context, true); // 返回并传递成功标志
      } else {
        final error =
            Provider.of<TransactionProvider>(context, listen: false).error;
        _showErrorDialog(error ?? '添加交易失败');
      }
    });
  }

  void _showErrorDialog(String message) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: isDarkMode ? AppColors.darkCard : Colors.white,
            title: Text(
              '错误',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            content: Text(
              message,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  '确定',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ),
    );
  }
}

// 自定义日期选择器
class CustomDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateSelected;

  const CustomDatePicker({
    Key? key,
    required this.initialDate,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  // 获取月份中的天数
  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  // 获取月份第一天的星期
  int _getFirstDayOfWeek(DateTime date) {
    return DateTime(date.year, date.month, 1).weekday % 7;
  }

  // 构建月份导航
  Widget _buildMonthNavigation() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 下拉选择年月
          InkWell(
            onTap: _showYearMonthPicker,
            child: Row(
              children: [
                Text(
                  '${_currentMonth.year}年${_currentMonth.month}月',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: textColor),
              ],
            ),
          ),
          // 前后月导航按钮
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: textColor),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(
                      _currentMonth.year,
                      _currentMonth.month - 1,
                    );
                  });
                },
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(Icons.chevron_right, color: textColor),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(
                      _currentMonth.year,
                      _currentMonth.month + 1,
                    );
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 显示年月选择器
  void _showYearMonthPicker() {
    // 此处简单实现，可以根据需要扩展为更复杂的年月选择器
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('选择年月'),
            content: SizedBox(
              height: 200,
              child: Column(
                children: [
                  // 年份选择
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            _currentMonth = DateTime(
                              _currentMonth.year - 1,
                              _currentMonth.month,
                            );
                            Navigator.of(context).pop();
                          });
                        },
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '${_currentMonth.year}年',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            _currentMonth = DateTime(
                              _currentMonth.year + 1,
                              _currentMonth.month,
                            );
                            Navigator.of(context).pop();
                          });
                        },
                      ),
                    ],
                  ),
                  // 月份选择
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            _currentMonth = DateTime(
                              _currentMonth.year,
                              _currentMonth.month - 1,
                            );
                            Navigator.of(context).pop();
                          });
                        },
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '${_currentMonth.month}月',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            _currentMonth = DateTime(
                              _currentMonth.year,
                              _currentMonth.month + 1,
                            );
                            Navigator.of(context).pop();
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('确定'),
              ),
            ],
          ),
    );
  }

  // 构建星期头部
  Widget _buildWeekHeader() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white70 : Colors.black54;

    final weekdays = ['日', '一', '二', '三', '四', '五', '六'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children:
            weekdays
                .map(
                  (day) => SizedBox(
                    width: 40,
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  // 构建日历网格
  Widget _buildCalendarGrid() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    final daysInMonth = _getDaysInMonth(_currentMonth);
    final firstDayOfWeek = _getFirstDayOfWeek(_currentMonth);

    final List<Widget> dayWidgets = [];

    // 前一个月的剩余天数
    for (int i = 0; i < firstDayOfWeek; i++) {
      dayWidgets.add(const SizedBox(width: 40, height: 40));
    }

    // 当前月的天数
    for (int i = 1; i <= daysInMonth; i++) {
      final currentDate = DateTime(_currentMonth.year, _currentMonth.month, i);
      final isToday =
          DateTime.now().year == currentDate.year &&
          DateTime.now().month == currentDate.month &&
          DateTime.now().day == currentDate.day;
      final isSelected =
          _selectedDate.year == currentDate.year &&
          _selectedDate.month == currentDate.month &&
          _selectedDate.day == currentDate.day;

      dayWidgets.add(
        InkWell(
          onTap: () {
            setState(() {
              _selectedDate = currentDate;
            });
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? primaryColor : Colors.transparent,
              shape: BoxShape.circle,
              border:
                  isToday && !isSelected
                      ? Border.all(color: primaryColor, width: 1)
                      : null,
            ),
            child: Center(
              child: Text(
                '$i',
                style: TextStyle(
                  fontSize: 16,
                  color:
                      isSelected
                          ? Colors.white
                          : isDarkMode
                          ? Colors.white
                          : Colors.black87,
                  fontWeight:
                      isSelected || isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // 计算总行数并填充空白
    final totalCells = dayWidgets.length;
    final rows = (totalCells / 7).ceil();
    final totalSlots = rows * 7;

    for (int i = totalCells; i < totalSlots; i++) {
      dayWidgets.add(const SizedBox(width: 40, height: 40));
    }

    // 构建网格
    return Wrap(alignment: WrapAlignment.start, children: dayWidgets);
  }

  // 构建底部按钮
  Widget _buildBottomButtons() {
    final primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () {
              widget.onDateSelected(_selectedDate);
              Navigator.of(context).pop();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 构建日期显示
  Widget _buildDateDisplay() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final weekday = _getWeekday(_selectedDate.weekday);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_selectedDate.month}月${_selectedDate.day}日 $weekday',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          Icon(Icons.edit, color: isDarkMode ? Colors.white70 : Colors.black54),
        ],
      ),
    );
  }

  String _getWeekday(int weekday) {
    switch (weekday) {
      case 1:
        return '周一';
      case 2:
        return '周二';
      case 3:
        return '周三';
      case 4:
        return '周四';
      case 5:
        return '周五';
      case 6:
        return '周六';
      case 7:
        return '周日';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDateDisplay(),
            _buildMonthNavigation(),
            _buildWeekHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: _buildCalendarGrid(),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }
}
