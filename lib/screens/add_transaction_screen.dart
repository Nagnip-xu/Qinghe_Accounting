import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../providers/category_provider.dart';
import '../providers/account_provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../widgets/common/toast_message.dart';

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
  String _amountString = '0';
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

  @override
  void initState() {
    super.initState();
    // 设置初始账户
    if (widget.initialAccountId != null && widget.initialAccountName != null) {
      _selectedAccountId = widget.initialAccountId;
      _selectedAccountName = widget.initialAccountName;
    }
  }

  @override
  void dispose() {
    _amountFocusNode.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('添加交易'), elevation: 0),
      body: Stack(
        children: [
          // 主要内容区域
          Container(
            padding: const EdgeInsets.all(16),
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
                      _noteController.text.isEmpty ? '无' : _noteController.text,
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
                            : const Text('保存', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
          // 数字键盘（条件显示）
          if (_showNumpad)
            Positioned(bottom: 0, left: 0, right: 0, child: _buildNumPad()),
        ],
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
        borderRadius: BorderRadius.circular(8),
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
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? color : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
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
              const SizedBox(width: 8),
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

  // 构建金额输入
  Widget _buildAmountInput() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _showNumpad = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(8),
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
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _amountString,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(8),
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
        setState(() {
          if (_amountString.length > 1) {
            _amountString = _amountString.substring(
              0,
              _amountString.length - 1,
            );
            // 如果删除后是小数点结尾，也删除小数点
            if (_amountString.endsWith('.')) {
              _amountString = _amountString.substring(
                0,
                _amountString.length - 1,
              );
            }
          } else {
            _amountString = '0';
          }
        });
        break;
      case '完成':
        // 隐藏键盘并尝试解析金额
        setState(() {
          _showNumpad = false;
          try {
            _amount = double.parse(_amountString);
            // 格式化显示金额
            if (_amount == 0) {
              _amountString = '0';
            } else {
              // 移除末尾无用的0和小数点
              if (_amountString.contains('.')) {
                _amountString = _amount.toString().replaceAll(
                  RegExp(r'\.0+$'),
                  '',
                );
                _amountString = _amountString.replaceAll(
                  RegExp(r'(\.\d+?)0+$'),
                  r'$1',
                );
              }
            }
          } catch (_) {
            _amount = 0;
            _amountString = '0';
          }
        });
        break;
      case '+':
      case '-':
        // 暂不实现运算功能
        break;
      default:
        setState(() {
          // 限制最大金额位数
          if (!_amountString.contains('.')) {
            // 整数部分不超过9位
            if (_amountString.length >= 9 && value != '.') {
              return;
            }
          }

          if (_amountString == '0' && value != '.') {
            _amountString = value;
          } else {
            // 处理小数点
            if (value == '.' && _amountString.contains('.')) {
              return; // 已有小数点，不再添加
            }
            // 小数点后限制两位
            if (_amountString.contains('.')) {
              List<String> parts = _amountString.split('.');
              if (parts[1].length >= 2) {
                return; // 已有两位小数，不再添加
              }
            }
            _amountString += value;
          }
        });
    }

    // 实时更新金额值并添加震动反馈
    try {
      _amount = double.parse(_amountString);
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
    final categories =
        _transactionType == '支出'
            ? categoryProvider.expenseCategories
            : categoryProvider.incomeCategories;

    if (categories.isEmpty) {
      ToastMessage.show(
        context,
        '请先添加分类',
        icon: Icons.category,
        backgroundColor: Colors.orange.withOpacity(0.9),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder:
          (context) => GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategoryId = category.id;
                    _selectedCategoryName = category.name;
                    _selectedCategoryIcon = category.icon;
                  });
                  Navigator.pop(context);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.category,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category.name,
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  // 选择日期
  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // 添加备注
  void _addNote() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('添加备注'),
            content: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.2,
              ),
              child: TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  hintText: '输入备注内容',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {});
                  Navigator.pop(context);
                },
                child: const Text('确定'),
              ),
            ],
          ),
      barrierDismissible: true,
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
      if (_selectedCategoryId == null || _selectedCategoryName.isEmpty) {
        _showErrorDialog('请选择分类');
        return;
      }
    }

    if (_amount <= 0) {
      _showErrorDialog('请输入大于0的金额');
      return;
    }

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
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('错误'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('确定'),
              ),
            ],
          ),
    );
  }
}
