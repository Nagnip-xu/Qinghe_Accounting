import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/formatter.dart';

class BudgetProgressCard extends StatelessWidget {
  final String categoryName;
  final String categoryIcon;
  final String? categoryColor;
  final double budgetAmount;
  final double expenseAmount;
  final double percentage;
  final VoidCallback? onTap;

  const BudgetProgressCard({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
    this.categoryColor,
    required this.budgetAmount,
    required this.expenseAmount,
    required this.percentage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 获取分类图标
    IconData icon = FontAwesomeIcons.receipt;
    Color iconColor = Colors.orange;

    // 解析颜色字符串
    if (categoryColor != null && categoryColor!.isNotEmpty) {
      try {
        iconColor = Color(int.parse(categoryColor!));
      } catch (e) {
        // 保持默认颜色
      }
    }

    // 解析图标字符串
    switch (categoryIcon) {
      case 'utensils':
        icon = FontAwesomeIcons.utensils;
        break;
      case 'car':
        icon = FontAwesomeIcons.car;
        break;
      case 'cart-shopping':
        icon = FontAwesomeIcons.cartShopping;
        break;
      case 'film':
        icon = FontAwesomeIcons.film;
        break;
      case 'house':
        icon = FontAwesomeIcons.house;
        break;
      case 'pills':
        icon = FontAwesomeIcons.pills;
        break;
      case 'book':
        icon = FontAwesomeIcons.book;
        break;
      case 'money-bill':
        icon = FontAwesomeIcons.moneyBill;
        break;
      case 'chart-line':
        icon = FontAwesomeIcons.chartLine;
        break;
      case 'gift':
        icon = FontAwesomeIcons.gift;
        break;
      case 'briefcase':
        icon = FontAwesomeIcons.briefcase;
        break;
      case 'ellipsis':
      default:
        icon = FontAwesomeIcons.ellipsis;
        break;
    }

    // 颜色逻辑：根据百分比改变进度条颜色
    Color progressColor;
    if (percentage <= 50) {
      progressColor = Colors.green;
    } else if (percentage <= 80) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    // 剩余预算
    final double remaining = budgetAmount - expenseAmount;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 分类图标
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: FaIcon(icon, color: iconColor, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 分类名称
                  Expanded(
                    child: Text(
                      categoryName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // 预算使用情况
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${CurrencyFormatter.formatWithoutSymbol(expenseAmount)} / ${CurrencyFormatter.formatWithoutSymbol(budgetAmount)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '剩余: ${CurrencyFormatter.formatWithoutSymbol(remaining)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: remaining < 0 ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 进度条
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[200],
                        color: progressColor,
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${percentage.toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: progressColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
