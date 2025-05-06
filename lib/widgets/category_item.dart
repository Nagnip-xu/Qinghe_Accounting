import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/category.dart';

class CategoryItem extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;
  final bool isSelected;

  const CategoryItem({
    super.key,
    required this.category,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    // 获取分类图标
    IconData categoryIcon = FontAwesomeIcons.receipt;
    Color categoryIconColor = Colors.orange;

    // 解析颜色字符串
    try {
      categoryIconColor = Color(int.parse(category.color));
    } catch (e) {
      // 保持默认颜色
    }

    // 解析图标字符串
    switch (category.icon) {
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
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? categoryIconColor.withOpacity(0.4)
                      : categoryIconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border:
                  isSelected
                      ? Border.all(color: categoryIconColor, width: 2)
                      : null,
            ),
            child: Center(
              child: FaIcon(categoryIcon, color: categoryIconColor, size: 24),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
