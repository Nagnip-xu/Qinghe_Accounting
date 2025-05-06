import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/theme_provider.dart';

class MonthYearPicker extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;

  const MonthYearPicker({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeColor = themeProvider.themeColor;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? themeColor.withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIconButton(
            context: context,
            icon: CupertinoIcons.chevron_left,
            onPressed: () {
              final previousMonth = DateTime(
                selectedDate.year,
                selectedDate.month - 1,
                1,
              );
              onDateChanged(previousMonth);
            },
          ),
          GestureDetector(
            onTap: () => _showMonthYearPicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Text(
                    '${_getChineseMonth(selectedDate.month)} ${selectedDate.year}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    CupertinoIcons.chevron_down,
                    size: 16,
                    color: isDarkMode ? Colors.white70 : themeColor,
                  ),
                ],
              ),
            ),
          ),
          _buildIconButton(
            context: context,
            icon: CupertinoIcons.chevron_right,
            onPressed: () {
              final nextMonth = DateTime(
                selectedDate.year,
                selectedDate.month + 1,
                1,
              );
              onDateChanged(nextMonth);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeColor = themeProvider.themeColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: isDarkMode ? Colors.white : themeColor,
            size: 18,
          ),
        ),
      ),
    );
  }

  void _showMonthYearPicker(BuildContext context) async {
    final DateTime? picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return MonthYearPickerDialog(initialDate: selectedDate);
      },
    );

    if (picked != null) {
      onDateChanged(picked);
    }
  }

  String _getChineseMonth(int month) {
    final List<String> months = [
      '一月',
      '二月',
      '三月',
      '四月',
      '五月',
      '六月',
      '七月',
      '八月',
      '九月',
      '十月',
      '十一月',
      '十二月',
    ];
    return months[month - 1];
  }
}

class MonthYearPickerDialog extends StatefulWidget {
  final DateTime initialDate;

  const MonthYearPickerDialog({super.key, required this.initialDate});

  @override
  State<MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<MonthYearPickerDialog>
    with TickerProviderStateMixin {
  late int _selectedYear;
  late int _selectedMonth;

  // 动画控制器
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // 月份名称
  final List<String> _months = [
    '一月',
    '二月',
    '三月',
    '四月',
    '五月',
    '六月',
    '七月',
    '八月',
    '九月',
    '十月',
    '十一月',
    '十二月',
  ];

  // 年份列表
  late List<int> _years;

  // 滚轮控制器
  late FixedExtentScrollController _monthScrollController;
  late FixedExtentScrollController _yearScrollController;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;

    // 生成年份列表：当前年份前后10年
    final int currentYear = DateTime.now().year;
    _years = List.generate(21, (index) => currentYear - 10 + index);

    // 初始化滚轮控制器
    _monthScrollController = FixedExtentScrollController(
      initialItem: _selectedMonth - 1,
    );

    _yearScrollController = FixedExtentScrollController(
      initialItem: _years.indexOf(_selectedYear),
    );

    // 初始化动画控制器
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // 启动动画
    _animationController.forward();
  }

  @override
  void dispose() {
    _monthScrollController.dispose();
    _yearScrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeColor = themeProvider.themeColor;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, (1 - value) * 50),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              children: [
                // 顶部拖动条
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // 标题
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                  child: Text(
                    '选择月份和年份',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),

                // 选择器区域
                Expanded(child: _buildWheelPickers(isDarkMode, themeColor)),

                // 底部按钮
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    bottom: 20.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          '取消',
                          style: TextStyle(
                            color:
                                isDarkMode
                                    ? Colors.white70
                                    : AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        color: themeColor,
                        borderRadius: BorderRadius.circular(24),
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pop(DateTime(_selectedYear, _selectedMonth, 1));
                        },
                        child: const Text(
                          '确定',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWheelPickers(bool isDarkMode, Color themeColor) {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // 月份选择器
          Expanded(
            flex: 1,
            child: CupertinoPicker.builder(
              scrollController: _monthScrollController,
              itemExtent: 44,
              diameterRatio: 2.0,
              selectionOverlay: _buildSelectionOverlay(themeColor),
              squeeze: 0.95,
              useMagnifier: true,
              magnification: 1.1,
              itemBuilder: (context, index) {
                return Center(
                  child: Text(
                    '${index + 1}月',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.0,
                    ),
                  ),
                );
              },
              childCount: 12,
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedMonth = index + 1;
                });
              },
            ),
          ),

          // 年份选择器
          Expanded(
            flex: 1,
            child: CupertinoPicker.builder(
              scrollController: _yearScrollController,
              itemExtent: 44,
              diameterRatio: 2.0,
              selectionOverlay: _buildSelectionOverlay(themeColor),
              squeeze: 0.95,
              useMagnifier: true,
              magnification: 1.1,
              itemBuilder: (context, index) {
                return Center(
                  child: Text(
                    '${_years[index]}年',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.0,
                    ),
                  ),
                );
              },
              childCount: _years.length,
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedYear = _years[index];
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // 选择器高亮覆盖层
  Widget _buildSelectionOverlay(Color themeColor) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: themeColor.withOpacity(0.25), width: 1.5),
          bottom: BorderSide(color: themeColor.withOpacity(0.25), width: 1.5),
        ),
        color: themeColor.withOpacity(0.05),
      ),
    );
  }
}
