import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/financial_goal_provider.dart';
import '../constants/colors.dart';

class FinancialGoalsScreen extends StatefulWidget {
  const FinancialGoalsScreen({super.key});

  @override
  State<FinancialGoalsScreen> createState() => _FinancialGoalsScreenState();
}

class _FinancialGoalsScreenState extends State<FinancialGoalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // 新目标表单字段
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 365));

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalProvider = Provider.of<FinancialGoalProvider>(context);
    final activeGoals = goalProvider.getActiveGoals();
    final completedGoals = goalProvider.getCompletedGoals();

    return Scaffold(
      appBar: AppBar(
        title: const Text('财务目标'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: '进行中'), Tab(text: '已完成')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 进行中的目标
          activeGoals.isEmpty
              ? _buildEmptyState('暂无进行中的财务目标')
              : _buildGoalsList(activeGoals, isCompleted: false),

          // 已完成的目标
          completedGoals.isEmpty
              ? _buildEmptyState('暂无已完成的财务目标')
              : _buildGoalsList(completedGoals, isCompleted: true),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddGoalDialog(context),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('添加目标'),
            onPressed: () => _showAddGoalDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList(
    List<FinancialGoal> goals, {
    required bool isCompleted,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goal = goals[index];

        // 计算进度百分比
        final progress = goal.currentAmount / goal.targetAmount;
        final progressPercent = (progress * 100).toStringAsFixed(1);

        // 计算剩余天数
        final remainingDays = goal.targetDate.difference(DateTime.now()).inDays;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        goal.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!isCompleted)
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditGoalDialog(context, goal);
                          } else if (value == 'delete') {
                            _showDeleteConfirmDialog(context, goal);
                          } else if (value == 'update') {
                            _showUpdateProgressDialog(context, goal);
                          } else if (value == 'complete') {
                            _showCompleteConfirmDialog(context, goal);
                          }
                        },
                        itemBuilder:
                            (context) => [
                              const PopupMenuItem(
                                value: 'update',
                                child: Text('更新进度'),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('编辑目标'),
                              ),
                              const PopupMenuItem(
                                value: 'complete',
                                child: Text('标记完成'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('删除'),
                              ),
                            ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '目标金额: ${NumberFormat.currency(locale: 'zh_CN', symbol: '¥', decimalDigits: 2).format(goal.targetAmount)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '当前进度: ${NumberFormat.currency(locale: 'zh_CN', symbol: '¥', decimalDigits: 2).format(goal.currentAmount)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '目标日期: ${DateFormat('yyyy/MM/dd').format(goal.targetDate)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        if (!isCompleted && remainingDays > 0)
                          Text(
                            '剩余时间: $remainingDays 天',
                            style: const TextStyle(fontSize: 14),
                          ),
                        if (isCompleted)
                          const Text(
                            '已完成',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '进度: $progressPercent%',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          '剩余: ${NumberFormat.currency(locale: 'zh_CN', symbol: '¥', decimalDigits: 2).format(goal.targetAmount - goal.currentAmount)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress < 0.5
                            ? Colors.orange
                            : progress < 1.0
                            ? Colors.blue
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    _nameController.clear();
    _amountController.clear();
    _targetDate = DateTime.now().add(const Duration(days: 365));

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('添加财务目标'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '目标名称',
                        hintText: '例如: 买车基金',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入目标名称';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: '目标金额',
                        hintText: '例如: 50000',
                        prefixText: '¥ ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入目标金额';
                        }
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0) {
                          return '请输入有效的金额';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: '目标日期'),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('yyyy年MM月dd日').format(_targetDate)),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // 添加新目标
                    Provider.of<FinancialGoalProvider>(
                      context,
                      listen: false,
                    ).addGoal(
                      FinancialGoal(
                        name: _nameController.text,
                        targetAmount: double.parse(_amountController.text),
                        targetDate: _targetDate,
                        icon: 'flag',
                        color: '0xFF2196F3',
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('添加'),
              ),
            ],
          ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null && picked != _targetDate) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  void _showEditGoalDialog(BuildContext context, FinancialGoal goal) {
    _nameController.text = goal.name;
    _amountController.text = goal.targetAmount.toString();
    _targetDate = goal.targetDate;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('编辑财务目标'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: '目标名称'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入目标名称';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: '目标金额',
                        prefixText: '¥ ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入目标金额';
                        }
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0) {
                          return '请输入有效的金额';
                        }
                        if (double.parse(value) < goal.currentAmount) {
                          return '目标金额不能小于当前已存金额';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: '目标日期'),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('yyyy年MM月dd日').format(_targetDate)),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // 更新目标
                    Provider.of<FinancialGoalProvider>(
                      context,
                      listen: false,
                    ).updateGoal(
                      goal.copyWith(
                        name: _nameController.text,
                        targetAmount: double.parse(_amountController.text),
                        targetDate: _targetDate,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('保存'),
              ),
            ],
          ),
    );
  }

  void _showUpdateProgressDialog(BuildContext context, FinancialGoal goal) {
    final TextEditingController amountController = TextEditingController();
    bool isDeposit = true;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('更新进度'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '当前进度: ${NumberFormat.currency(locale: 'zh_CN', symbol: '¥', decimalDigits: 2).format(goal.currentAmount)}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '目标金额: ${NumberFormat.currency(locale: 'zh_CN', symbol: '¥', decimalDigits: 2).format(goal.targetAmount)}',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('存入'),
                            value: true,
                            groupValue: isDeposit,
                            onChanged: (value) {
                              setState(() {
                                isDeposit = value!;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('取出'),
                            value: false,
                            groupValue: isDeposit,
                            onChanged: (value) {
                              setState(() {
                                isDeposit = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: '金额',
                        prefixText: '¥ ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () {
                      final amount = double.tryParse(amountController.text);
                      if (amount != null && amount > 0) {
                        final provider = Provider.of<FinancialGoalProvider>(
                          context,
                          listen: false,
                        );
                        final updateAmount = isDeposit ? amount : -amount;

                        // 如果是取出，确保不会超过当前金额
                        if (!isDeposit && amount > goal.currentAmount) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('取出金额不能超过当前进度')),
                          );
                          return;
                        }

                        provider.updateGoalProgress(goal.id!, updateAmount);
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请输入有效的金额')),
                        );
                      }
                    },
                    child: const Text('确定'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, FinancialGoal goal) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('删除目标'),
            content: Text('确定要删除 "${goal.name}" 目标吗？此操作不可撤销。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  Provider.of<FinancialGoalProvider>(
                    context,
                    listen: false,
                  ).deleteGoal(goal.id!);
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('删除'),
              ),
            ],
          ),
    );
  }

  void _showCompleteConfirmDialog(BuildContext context, FinancialGoal goal) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('标记完成'),
            content: Text('确定要将 "${goal.name}" 目标标记为已完成吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  Provider.of<FinancialGoalProvider>(
                    context,
                    listen: false,
                  ).markGoalAsCompleted(goal.id!);
                  Navigator.pop(context);
                },
                child: const Text('确定'),
              ),
            ],
          ),
    );
  }
}
