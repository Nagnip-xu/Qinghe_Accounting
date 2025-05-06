import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/transaction.dart';
import '../utils/formatter.dart';

class TransactionItem extends StatefulWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  const TransactionItem({super.key, required this.transaction, this.onTap});

  @override
  State<TransactionItem> createState() => _TransactionItemState();
}

class _TransactionItemState extends State<TransactionItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;

    // 判断交易类型获取显示颜色
    Color amountColor = Theme.of(context).primaryColor;
    String amountPrefix = '';

    if (transaction.type == '支出') {
      amountColor = const Color(0xFFE53935); // 红色
      amountPrefix = '- ';
    } else if (transaction.type == '收入') {
      amountColor = const Color(0xFF4CAF50); // 绿色
      amountPrefix = '+ ';
    }

    // 获取分类图标
    IconData categoryIcon = FontAwesomeIcons.receipt;
    Color categoryIconColor = Colors.orange;

    // 解析颜色字符串
    if (transaction.categoryColor != null &&
        transaction.categoryColor!.isNotEmpty) {
      try {
        categoryIconColor = Color(int.parse(transaction.categoryColor!));
      } catch (e) {
        // 保持默认颜色
      }
    }

    // 解析图标字符串
    switch (transaction.categoryIcon) {
      case 'utensils':
        categoryIcon = FontAwesomeIcons.utensils;
        break;
      case 'car':
        categoryIcon = FontAwesomeIcons.car;
        break;
      case 'cart-shopping':
        categoryIcon = FontAwesomeIcons.cartShopping;
        break;
      case 'film':
        categoryIcon = FontAwesomeIcons.film;
        break;
      case 'house':
        categoryIcon = FontAwesomeIcons.house;
        break;
      case 'pills':
        categoryIcon = FontAwesomeIcons.pills;
        break;
      case 'book':
        categoryIcon = FontAwesomeIcons.book;
        break;
      case 'money-bill':
        categoryIcon = FontAwesomeIcons.moneyBill;
        break;
      case 'chart-line':
        categoryIcon = FontAwesomeIcons.chartLine;
        break;
      case 'gift':
        categoryIcon = FontAwesomeIcons.gift;
        break;
      case 'briefcase':
        categoryIcon = FontAwesomeIcons.briefcase;
        break;
      case 'ellipsis':
      default:
        categoryIcon = FontAwesomeIcons.ellipsis;
        break;
    }

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 16.0,
              ),
              child: Row(
                children: [
                  // 分类图标
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: categoryIconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: categoryIconColor.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: FaIcon(
                        categoryIcon,
                        color: categoryIconColor,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 交易内容区域
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.categoryName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${transaction.accountName} · ${transaction.formattedDate}',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white60
                                        : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 金额
                  Text(
                    '$amountPrefix${CurrencyFormatter.formatWithoutSymbol(transaction.amount)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: amountColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
