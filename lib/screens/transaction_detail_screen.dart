import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import '../models/transaction.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../constants/colors.dart';
import '../utils/formatter.dart';
import '../widgets/common/toast_message.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  bool _isLoading = false;
  bool _isEditMode = false;

  // 编辑状态的变量
  late String _transactionType;
  late double _amount;
  late int? _categoryId;
  late String _categoryName;
  late String _categoryIcon;
  late int? _accountId;
  late String _accountName;
  late DateTime _date;
  late TextEditingController _noteController;
  late int? _toAccountId;
  late String? _toAccountName;

  // 是否显示数字键盘
  bool _showNumpad = false;
  final FocusNode _amountFocusNode = FocusNode();
  String _amountString = '';

  @override
  void initState() {
    super.initState();
    _initializeEditValues();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  // 初始化编辑状态的值
  void _initializeEditValues() {
    final transaction = widget.transaction;
    _transactionType = transaction.type;
    _amount = transaction.amount;
    _amountString = _amount.toString();
    _categoryId = transaction.categoryId;
    _categoryName = transaction.categoryName;
    _categoryIcon = transaction.categoryIcon;
    _accountId = transaction.accountId;
    _accountName = transaction.accountName;
    _date = transaction.date;
    _noteController = TextEditingController(text: transaction.note);
    _toAccountId = transaction.toAccountId;
    _toAccountName = transaction.toAccountName;
  }

  // 切换编辑模式
  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        // 退出编辑模式时重置为原始值
        _initializeEditValues();
      }
    });
  }

  // 保存修改后的交易记录
  Future<void> _saveTransaction() async {
    if (_transactionType != '转账' &&
        (_categoryId == null || _categoryName.isEmpty)) {
      ToastMessage.show(
        context,
        '请选择分类',
        icon: Icons.category,
        backgroundColor: Colors.orange.withOpacity(0.9),
      );
      return;
    }

    if (_accountId == null || _accountName.isEmpty) {
      ToastMessage.show(
        context,
        '请选择账户',
        icon: Icons.account_balance_wallet,
        backgroundColor: Colors.orange.withOpacity(0.9),
      );
      return;
    }

    if (_transactionType == '转账') {
      if (_toAccountId == null ||
          _toAccountName == null ||
          _toAccountName!.isEmpty) {
        ToastMessage.show(
          context,
          '请选择转入账户',
          icon: Icons.account_balance_wallet,
          backgroundColor: Colors.orange.withOpacity(0.9),
        );
        return;
      }

      if (_accountId == _toAccountId) {
        ToastMessage.show(
          context,
          '转出和转入账户不能相同',
          icon: Icons.error_outline,
          backgroundColor: Colors.red.withOpacity(0.9),
        );
        return;
      }
    }

    if (_amount <= 0) {
      ToastMessage.show(
        context,
        '请输入大于0的金额',
        icon: Icons.monetization_on,
        backgroundColor: Colors.orange.withOpacity(0.9),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 创建更新后的交易记录
      final updatedTransaction = Transaction(
        id: widget.transaction.id,
        type: _transactionType,
        amount: _amount,
        categoryId: _categoryId ?? 0,
        categoryName: _categoryName,
        categoryIcon: _categoryIcon,
        accountId: _accountId!,
        accountName: _accountName,
        date: _date,
        note: _noteController.text,
        toAccountId: _transactionType == '转账' ? _toAccountId : null,
        toAccountName: _transactionType == '转账' ? _toAccountName : null,
      );

      // 更新交易记录
      final success = await Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).updateTransaction(updatedTransaction, context: context);

      if (success) {
        // 退出编辑模式并显示成功消息
        setState(() {
          _isEditMode = false;
          _isLoading = false;
        });

        ToastMessage.show(
          context,
          '保存成功',
          icon: Icons.check_circle_outline,
          backgroundColor: Colors.green.withOpacity(0.9),
        );

        // 返回上一页，并传递更新信号
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isLoading = false;
        });
        ToastMessage.show(
          context,
          '保存失败',
          icon: Icons.error_outline,
          backgroundColor: Colors.red.withOpacity(0.9),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // 处理特定的错误消息
      String errorMsg = e.toString();
      if (errorMsg.contains('账户余额不足')) {
        ToastMessage.show(
          context,
          '$_accountName余额不足，请检查账户余额或选择负债账户',
          icon: Icons.account_balance_wallet,
          backgroundColor: Colors.red.withOpacity(0.9),
        );
      } else {
        ToastMessage.show(
          context,
          '保存失败: $e',
          icon: Icons.error_outline,
          backgroundColor: Colors.red.withOpacity(0.9),
        );
      }
    }
  }

  // 获取对应的图标
  IconData _getCategoryIcon() {
    switch (widget.transaction.categoryIcon) {
      case 'utensils':
        return FontAwesomeIcons.utensils;
      case 'car':
        return FontAwesomeIcons.car;
      case 'cart-shopping':
        return FontAwesomeIcons.cartShopping;
      case 'film':
        return FontAwesomeIcons.film;
      case 'house':
        return FontAwesomeIcons.house;
      case 'pills':
        return FontAwesomeIcons.pills;
      case 'book':
        return FontAwesomeIcons.book;
      case 'money-bill':
        return FontAwesomeIcons.moneyBill;
      case 'chart-line':
        return FontAwesomeIcons.chartLine;
      case 'gift':
        return FontAwesomeIcons.gift;
      case 'briefcase':
        return FontAwesomeIcons.briefcase;
      case 'exchange':
        return FontAwesomeIcons.rightLeft;
      default:
        return FontAwesomeIcons.receipt;
    }
  }

  // 根据图标名称获取对应的图标
  IconData _getCategoryIconFromName(String iconName) {
    switch (iconName) {
      case 'utensils':
        return FontAwesomeIcons.utensils;
      case 'car':
        return FontAwesomeIcons.car;
      case 'cart-shopping':
        return FontAwesomeIcons.cartShopping;
      case 'film':
        return FontAwesomeIcons.film;
      case 'house':
        return FontAwesomeIcons.house;
      case 'pills':
        return FontAwesomeIcons.pills;
      case 'book':
        return FontAwesomeIcons.book;
      case 'money-bill':
        return FontAwesomeIcons.moneyBill;
      case 'chart-line':
        return FontAwesomeIcons.chartLine;
      case 'gift':
        return FontAwesomeIcons.gift;
      case 'briefcase':
        return FontAwesomeIcons.briefcase;
      case 'exchange':
        return FontAwesomeIcons.rightLeft;
      default:
        return FontAwesomeIcons.receipt;
    }
  }

  // 构建类型选择按钮
  Widget _buildTypeButton(String type, IconData icon, Color color) {
    final bool isSelected = _transactionType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _transactionType = type;
            // 重置选择的分类
            if (type == '转账') {
              _categoryId = 0;
              _categoryName = '转账';
              _categoryIcon = 'exchange';
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color:
                isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white70,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                type,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 选择分类
  void _selectCategory() async {
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    final categories =
        _transactionType == '支出'
            ? categoryProvider.expenseCategories
            : categoryProvider.incomeCategories;

    // 显示分类选择对话框
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '选择分类',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                  ),
                ),
              ),
              const Divider(),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context, {
                          'id': category.id,
                          'name': category.name,
                          'icon': category.icon,
                          'color': category.color,
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(int.parse(category.color)),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: FaIcon(
                                _getCategoryIconFromName(category.icon),
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        _categoryId = result['id'];
        _categoryName = result['name'];
        _categoryIcon = result['icon'];
      });
    }
  }

  // 选择账户
  void _selectAccount() async {
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );
    final accounts = accountProvider.accounts;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '选择账户',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                  ),
                ),
              ),
              const Divider(),
              ListView.builder(
                shrinkWrap: true,
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  return ListTile(
                    leading: const Icon(Icons.account_balance_wallet),
                    title: Text(account.name),
                    subtitle: Text(CurrencyFormatter.format(account.balance)),
                    onTap: () {
                      Navigator.pop(context, {
                        'id': account.id,
                        'name': account.name,
                      });
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        _accountId = result['id'];
        _accountName = result['name'];
      });
    }
  }

  // 选择转入账户
  void _selectTargetAccount() async {
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );
    final accounts =
        accountProvider.accounts.where((a) => a.id != _accountId).toList();

    if (accounts.isEmpty) {
      ToastMessage.show(
        context,
        '没有其他可选账户',
        icon: Icons.account_balance_wallet,
        backgroundColor: Colors.orange.withOpacity(0.9),
      );
      return;
    }

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '选择转入账户',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                  ),
                ),
              ),
              const Divider(),
              ListView.builder(
                shrinkWrap: true,
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  return ListTile(
                    leading: const Icon(Icons.account_balance_wallet),
                    title: Text(account.name),
                    subtitle: Text(CurrencyFormatter.format(account.balance)),
                    onTap: () {
                      Navigator.pop(context, {
                        'id': account.id,
                        'name': account.name,
                      });
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        _toAccountId = result['id'];
        _toAccountName = result['name'];
      });
    }
  }

  // 选择日期
  void _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      // 选择时间
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_date),
      );

      if (pickedTime != null) {
        setState(() {
          _date = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  // 编辑备注
  void _editNote() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _noteController.text);
        return AlertDialog(
          title: const Text('编辑备注'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '请输入备注',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        _noteController.text = result;
      });
    }
  }

  // 构建数字键盘
  Widget _buildNumPad() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            alignment: Alignment.centerRight,
            child: Text(
              _amountString.isEmpty ? '0' : _amountString,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const Divider(),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            childAspectRatio: 1.5,
            children: [
              _buildNumKey('1'),
              _buildNumKey('2'),
              _buildNumKey('3'),
              _buildDelKey(Icons.backspace_outlined),
              _buildNumKey('4'),
              _buildNumKey('5'),
              _buildNumKey('6'),
              _buildNumKey('+'),
              _buildNumKey('7'),
              _buildNumKey('8'),
              _buildNumKey('9'),
              _buildNumKey('-'),
              _buildNumKey('.'),
              _buildNumKey('0'),
              _buildNumKey('00'),
              _buildDoneKey('完成'),
            ],
          ),
        ],
      ),
    );
  }

  // 构建数字键
  Widget _buildNumKey(String text) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => _onNumKeyPressed(text),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  // 构建删除键
  Widget _buildDelKey(IconData icon) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        if (_amountString.isNotEmpty) {
          setState(() {
            _amountString = _amountString.substring(
              0,
              _amountString.length - 1,
            );
            _updateAmount();
          });
        }
      },
      child: Center(
        child: Icon(icon, color: isDarkMode ? Colors.white70 : Colors.black54),
      ),
    );
  }

  // 构建完成键
  Widget _buildDoneKey(String text) {
    return InkWell(
      onTap: () {
        setState(() {
          _showNumpad = false;
          _updateAmount();
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  // 数字键盘按键处理
  void _onNumKeyPressed(String key) {
    setState(() {
      // 处理特殊按键
      if (key == '+' || key == '-') {
        // 忽略操作符
        return;
      } else if (key == '.') {
        // 处理小数点
        if (!_amountString.contains('.') && _amountString.isNotEmpty) {
          _amountString += '.';
        }
      } else {
        // 处理数字
        if (_amountString == '0') {
          _amountString = key;
        } else {
          _amountString += key;
        }
      }

      _updateAmount();
    });
  }

  // 更新金额
  void _updateAmount() {
    try {
      if (_amountString.isNotEmpty) {
        _amount = double.parse(_amountString);
      } else {
        _amount = 0;
      }
    } catch (e) {
      _amount = 0;
    }
  }

  // 获取颜色
  Color _getCategoryColor() {
    if (widget.transaction.categoryColor != null &&
        widget.transaction.categoryColor!.isNotEmpty) {
      try {
        return Color(int.parse(widget.transaction.categoryColor!));
      } catch (e) {
        // 默认颜色
      }
    }

    // 根据交易类型返回默认颜色
    if (widget.transaction.type == '支出') {
      return const Color(0xFFE53935); // 红色
    } else if (widget.transaction.type == '收入') {
      return const Color(0xFF4CAF50); // 绿色
    } else {
      return const Color(0xFF9C27B0); // 紫色，用于转账
    }
  }

  // 删除交易
  void _deleteTransaction() async {
    if (widget.transaction.id == null) {
      ToastMessage.show(
        context,
        '无法删除此交易',
        icon: Icons.error_outline,
        backgroundColor: Colors.red.withOpacity(0.9),
      );
      return;
    }

    // 显示确认对话框
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text('确定要删除此交易记录吗？此操作无法撤销。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('删除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).deleteTransaction(widget.transaction.id!, context: context);

      if (success) {
        // 返回上一页
        if (mounted) Navigator.of(context).pop(true);
      } else {
        if (mounted) {
          ToastMessage.show(
            context,
            '删除失败',
            icon: Icons.error_outline,
            backgroundColor: Colors.red.withOpacity(0.9),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ToastMessage.show(
          context,
          '删除失败: $e',
          icon: Icons.error_outline,
          backgroundColor: Colors.red.withOpacity(0.9),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 使用正确的数据来源（根据是否为编辑模式）
    final transaction = widget.transaction;
    final type = _isEditMode ? _transactionType : transaction.type;
    final amount = _isEditMode ? _amount : transaction.amount;
    final categoryName = _isEditMode ? _categoryName : transaction.categoryName;
    final categoryIcon =
        _isEditMode
            ? _getCategoryIconFromName(_categoryIcon)
            : _getCategoryIcon();
    final categoryColor = _getCategoryColor();
    final accountName = _isEditMode ? _accountName : transaction.accountName;
    final note = _isEditMode ? _noteController.text : transaction.note;
    final date = _isEditMode ? _date : transaction.date;

    // 获取目标账户名称（如果是转账）
    String? targetAccountName;
    if (type == '转账') {
      if (_isEditMode) {
        targetAccountName = _toAccountName;
      } else if (transaction.toAccountId != null) {
        final accountProvider = Provider.of<AccountProvider>(
          context,
          listen: false,
        );
        final targetAccount = accountProvider.accounts.firstWhere(
          (account) => account.id == transaction.toAccountId,
          orElse: () => accountProvider.accounts.first,
        );
        targetAccountName = targetAccount.name;
      }
    }

    // 金额显示
    String amountPrefix = '';
    if (type == '支出') {
      amountPrefix = '- ';
    } else if (type == '收入') {
      amountPrefix = '+ ';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('$type详情'),
        actions: [
          // 添加编辑/保存按钮
          if (!_isLoading)
            IconButton(
              icon: Icon(_isEditMode ? Icons.check : Icons.edit),
              onPressed: _isEditMode ? _saveTransaction : _toggleEditMode,
            ),
          if (!_isEditMode && !_isLoading)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteTransaction,
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 顶部金额区域
                        Container(
                          width: double.infinity,
                          color: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // 编辑模式下显示交易类型选择器
                              if (_isEditMode)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildTypeButton(
                                        '支出',
                                        Icons.arrow_downward,
                                        Colors.red,
                                      ),
                                      _buildTypeButton(
                                        '收入',
                                        Icons.arrow_upward,
                                        Colors.green,
                                      ),
                                      _buildTypeButton(
                                        '转账',
                                        Icons.swap_horiz,
                                        Colors.purple,
                                      ),
                                    ],
                                  ),
                                ),

                              // 分类图标
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: FaIcon(
                                    categoryIcon,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 金额 - 编辑模式下可点击编辑
                              GestureDetector(
                                onTap:
                                    _isEditMode
                                        ? () => setState(
                                          () => _showNumpad = !_showNumpad,
                                        )
                                        : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration:
                                      _isEditMode
                                          ? BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          )
                                          : null,
                                  child: Text(
                                    '$amountPrefix${CurrencyFormatter.format(amount)}',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // 分类名称 - 编辑模式下可点击选择
                              GestureDetector(
                                onTap:
                                    _isEditMode && type != '转账'
                                        ? _selectCategory
                                        : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration:
                                      _isEditMode && type != '转账'
                                          ? BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          )
                                          : null,
                                  child: Text(
                                    categoryName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 详情信息列表
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '详细信息',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 账户信息 - 编辑模式下可点击选择
                              _buildDetailItem(
                                icon: Icons.account_balance_wallet,
                                title: '账户',
                                content: accountName,
                                onTap: _isEditMode ? _selectAccount : null,
                              ),

                              // 目标账户（仅转账）- 编辑模式下可点击选择
                              if (type == '转账' && targetAccountName != null)
                                _buildDetailItem(
                                  icon: Icons.arrow_forward,
                                  title: '转入账户',
                                  content: targetAccountName,
                                  onTap:
                                      _isEditMode ? _selectTargetAccount : null,
                                ),

                              // 日期 - 编辑模式下可点击选择
                              _buildDetailItem(
                                icon: Icons.calendar_today,
                                title: '日期',
                                content:
                                    '${date.year}-'
                                    '${date.month.toString().padLeft(2, '0')}-'
                                    '${date.day.toString().padLeft(2, '0')} '
                                    '${date.hour.toString().padLeft(2, '0')}:'
                                    '${date.minute.toString().padLeft(2, '0')}',
                                onTap: _isEditMode ? _selectDate : null,
                              ),

                              // 备注 - 编辑模式下可点击编辑
                              _buildDetailItem(
                                icon: Icons.note,
                                title: '备注',
                                content: note?.isNotEmpty == true ? note! : '无',
                                onTap: _isEditMode ? _editNote : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 数字键盘（条件显示）
                  if (_isEditMode && _showNumpad)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildNumPad(),
                    ),
                ],
              ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String content,
    VoidCallback? onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool isClickable = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color:
              isClickable
                  ? (isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.05))
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isClickable)
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
