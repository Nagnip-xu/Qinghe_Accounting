import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/formatter.dart';

class DateGroupHeader extends StatefulWidget {
  final DateTime date;
  final double income;
  final double expense;

  const DateGroupHeader({
    super.key,
    required this.date,
    required this.income,
    required this.expense,
  });

  @override
  State<DateGroupHeader> createState() => _DateGroupHeaderState();
}

class _DateGroupHeaderState extends State<DateGroupHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 获取当前日期
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    // 日期格式化
    String dateText;

    if (widget.date.year == now.year &&
        widget.date.month == now.month &&
        widget.date.day == now.day) {
      dateText = '今天';
    } else if (widget.date.year == yesterday.year &&
        widget.date.month == yesterday.month &&
        widget.date.day == yesterday.day) {
      dateText = '昨天';
    } else {
      // 如果是今年的日期，只显示月日，否则显示年月日
      if (widget.date.year == now.year) {
        dateText = DateFormat('MM月dd日', 'zh_CN').format(widget.date);
      } else {
        dateText = DateFormat('yyyy年MM月dd日', 'zh_CN').format(widget.date);
      }
    }

    // 添加星期几
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekday = weekdays[widget.date.weekday - 1];
    dateText = '$dateText $weekday';

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                // 日期
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // 收入（始终显示，不再用if条件判断）
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '收 ',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.black54,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatWithoutSymbol(widget.income),
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8), // 收入和支出之间的间距
                // 支出（始终显示，不再用if条件判断）
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '支 ',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.black54,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatWithoutSymbol(widget.expense),
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
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
}
