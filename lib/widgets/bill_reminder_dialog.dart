import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reminder_provider.dart';
import '../constants/colors.dart';
import '../utils/toast_message.dart';

class BillReminderDialog extends StatefulWidget {
  const BillReminderDialog({Key? key}) : super(key: key);

  @override
  State<BillReminderDialog> createState() => _BillReminderDialogState();
}

class _BillReminderDialogState extends State<BillReminderDialog> {
  bool _isEnabled = true;
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isRecurring = false;
  String _recurringType = 'monthly';

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final reminderProvider = Provider.of<ReminderProvider>(
      context,
      listen: false,
    );
    setState(() {
      _isEnabled = reminderProvider.hasPermission;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // 验证表单
  bool _validateForm() {
    if (_titleController.text.trim().isEmpty) {
      _showErrorToast('请输入账单名称');
      return false;
    }

    if (_amountController.text.trim().isEmpty) {
      _showErrorToast('请输入账单金额');
      return false;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showErrorToast('请输入有效的金额');
      return false;
    }

    return true;
  }

  void _showErrorToast(String message) {
    ToastMessage.show(
      context,
      message,
      icon: Icons.error_outline,
      backgroundColor: Colors.red.withOpacity(0.9),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.only(
              left: 16,
              top: 42,
              right: 16,
              bottom: 16,
            ),
            margin: const EdgeInsets.only(top: 36),
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: isDarkMode ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 10),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '账单提醒设置',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  // 启用开关
                  SwitchListTile(
                    title: const Text('启用账单提醒'),
                    subtitle: const Text('接收到期前的提醒通知'),
                    value: _isEnabled,
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: (value) {
                      setState(() {
                        _isEnabled = value;
                      });
                    },
                  ),
                  const Divider(),
                  // 添加新提醒
                  if (_isEnabled) ...[
                    const SizedBox(height: 12),
                    const Text(
                      '添加新账单提醒',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 账单名称
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: '账单名称',
                        hintText: '例如：水电费、房租',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 账单金额
                    TextField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: '金额',
                        hintText: '例如：500',
                        prefixText: '¥ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    // 到期日期
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '到期日期',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日',
                            ),
                            const Icon(Icons.calendar_today, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 是否重复
                    SwitchListTile(
                      title: const Text('重复提醒'),
                      subtitle: Text(
                        _isRecurring ? _getRecurringTypeText() : '仅提醒一次',
                      ),
                      value: _isRecurring,
                      activeColor: Theme.of(context).primaryColor,
                      onChanged: (value) {
                        setState(() {
                          _isRecurring = value;
                        });
                      },
                    ),
                    // 重复类型
                    if (_isRecurring) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: '重复周期',
                          border: OutlineInputBorder(),
                        ),
                        value: _recurringType,
                        items: const [
                          DropdownMenuItem(value: 'daily', child: Text('每天')),
                          DropdownMenuItem(value: 'weekly', child: Text('每周')),
                          DropdownMenuItem(value: 'monthly', child: Text('每月')),
                          DropdownMenuItem(value: 'yearly', child: Text('每年')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _recurringType = value;
                            });
                          }
                        },
                      ),
                    ],
                  ],
                  const SizedBox(height: 20),
                  // 操作按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Text('保存'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // 圆形图标
          Positioned(
            left: 16,
            right: 16,
            child: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              radius: 26,
              child: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveSettings() async {
    final reminderProvider = Provider.of<ReminderProvider>(
      context,
      listen: false,
    );

    // 如果提醒禁用，直接返回
    if (!_isEnabled) {
      Navigator.of(context).pop();
      return;
    }

    // 如果没有输入信息，直接返回
    if (_titleController.text.isEmpty && _amountController.text.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    // 验证表单
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);

      // 创建提醒
      final newReminder = BillReminder(
        title: _titleController.text.trim(),
        amount: amount,
        dueDate: _selectedDate,
        recurring: _isRecurring,
        recurringType: _isRecurring ? _recurringType : null,
      );

      // 添加提醒
      final success = await reminderProvider.addReminder(newReminder);

      if (success) {
        if (mounted) {
          ToastMessage.show(
            context,
            '账单提醒已设置',
            icon: Icons.check_circle_outline,
            backgroundColor: Colors.green.withOpacity(0.9),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          _showErrorToast(reminderProvider.error ?? '设置提醒失败');
        }
      }
    } catch (e) {
      _showErrorToast('设置提醒失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getRecurringTypeText() {
    switch (_recurringType) {
      case 'daily':
        return '每天';
      case 'weekly':
        return '每周';
      case 'monthly':
        return '每月';
      case 'yearly':
        return '每年';
      default:
        return '每月';
    }
  }
}
