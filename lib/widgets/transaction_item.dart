import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../constants/category_icons.dart';
import '../constants/colors.dart';

class TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const TransactionItem({
    super.key,
    required this.transaction,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDarkMode ? Colors.white : AppColors.textPrimary;
    final subtitleColor = isDarkMode ? Colors.white70 : AppColors.textSecondary;

    // 格式化金额显示
    final formattedAmount = NumberFormat.currency(
      locale: 'zh_CN',
      symbol: '',
      decimalDigits: 2,
    ).format(transaction.amount);

    // 交易日期格式 "MM-dd HH:mm" 如 "04-23 14:30"
    final formattedDate = DateFormat(
      'MM-dd HH:mm',
      'zh_CN',
    ).format(transaction.date);

    // 根据交易类型设置颜色
    Color typeColor;
    switch (transaction.type) {
      case '支出':
        typeColor = AppColors.expense;
        break;
      case '收入':
        typeColor = AppColors.income;
        break;
      case '转账':
        typeColor = AppColors.transfer;
        break;
      default:
        typeColor = AppColors.textSecondary;
        break;
    }

    // 设置分类图标
    IconData categoryIcon;

    // 解析图标字符串
    switch (transaction.categoryIcon) {
      // 餐饮类
      case 'utensils':
      case '餐饮':
        categoryIcon = FontAwesomeIcons.utensils;
        break;
      case 'bread-slice':
      case '早餐':
        categoryIcon = FontAwesomeIcons.breadSlice;
        break;
      case 'bowl-food':
      case '午餐':
        categoryIcon = FontAwesomeIcons.bowlFood;
        break;
      case 'bowl-rice':
      case '晚餐':
        categoryIcon = FontAwesomeIcons.bowlRice;
        break;
      case 'candy-cane':
      case '零食':
        categoryIcon = FontAwesomeIcons.candyCane;
        break;

      // 交通类
      case 'car':
      case '交通':
        categoryIcon = FontAwesomeIcons.car;
        break;
      case 'taxi':
      case '打车':
        categoryIcon = FontAwesomeIcons.taxi;
        break;
      case 'bus':
      case '公交':
        categoryIcon = FontAwesomeIcons.bus;
        break;
      case 'train-subway':
      case 'subway':
      case '地铁':
        categoryIcon = FontAwesomeIcons.trainSubway;
        break;

      // 购物类
      case 'bag-shopping':
      case 'shopping_bag':
      case 'shopping_cart':
      case 'shopping':
      case '购物':
        categoryIcon = FontAwesomeIcons.bagShopping;
        break;
      case 'shirt':
      case '服装':
        categoryIcon = FontAwesomeIcons.shirt;
        break;
      case 'spray-can':
      case '化妆':
        categoryIcon = FontAwesomeIcons.sprayCan;
        break;
      case 'laptop':
      case '数码':
        categoryIcon = FontAwesomeIcons.laptop;
        break;
      case 'couch':
      case '家居':
        categoryIcon = FontAwesomeIcons.couch;
        break;

      // 娱乐类
      case 'gamepad':
      case 'movie':
      case 'entertainment':
      case 'videogame':
      case '娱乐':
        categoryIcon = FontAwesomeIcons.gamepad;
        break;
      case 'film':
      case '电影':
        categoryIcon = FontAwesomeIcons.film;
        break;
      case 'chess':
      case '游戏':
        categoryIcon = FontAwesomeIcons.chess;
        break;
      case 'plane':
      case '旅游':
        categoryIcon = FontAwesomeIcons.plane;
        break;

      // 住房类
      case 'house':
      case '住房':
        categoryIcon = FontAwesomeIcons.house;
        break;
      case 'house-chimney':
      case '房租':
        categoryIcon = FontAwesomeIcons.houseChimney;
        break;
      case 'droplet':
      case '水费':
        categoryIcon = FontAwesomeIcons.droplet;
        break;
      case 'bolt':
      case '电费':
        categoryIcon = FontAwesomeIcons.bolt;
        break;
      case 'fire':
      case '燃气费':
        categoryIcon = FontAwesomeIcons.fire;
        break;
      case 'wifi':
      case '网费':
        categoryIcon = FontAwesomeIcons.wifi;
        break;
      case 'phone':
      case '话费':
        categoryIcon = FontAwesomeIcons.phone;
        break;

      // 医疗类
      case 'suitcase-medical':
      case '医疗':
        categoryIcon = FontAwesomeIcons.suitcaseMedical;
        break;
      case 'pills':
      case '药品':
        categoryIcon = FontAwesomeIcons.pills;
        break;
      case 'hospital-user':
      case '挂号':
        categoryIcon = FontAwesomeIcons.hospitalUser;
        break;

      // 教育类
      case 'graduation-cap':
      case '教育':
        categoryIcon = FontAwesomeIcons.graduationCap;
        break;
      case 'book':
      case '学费':
        categoryIcon = FontAwesomeIcons.book;
        break;
      case 'book-open':
      case '书籍':
        categoryIcon = FontAwesomeIcons.bookOpen;
        break;

      // 收入类
      case 'money-bill-1':
      case '工资':
        categoryIcon = FontAwesomeIcons.moneyBill1;
        break;
      case 'award':
      case '奖金':
        categoryIcon = FontAwesomeIcons.award;
        break;
      case 'briefcase':
      case '兼职':
        categoryIcon = FontAwesomeIcons.briefcase;
        break;
      case 'chart-line':
      case '投资':
        categoryIcon = FontAwesomeIcons.chartLine;
        break;

      // 其他支出
      case 'baby':
      case '孩子':
        categoryIcon = FontAwesomeIcons.baby;
        break;
      case 'paw':
      case '宠物':
        categoryIcon = FontAwesomeIcons.paw;
        break;
      case 'money-bill-trend-up':
      case '理财':
        categoryIcon = FontAwesomeIcons.moneyBillTrendUp;
        break;
      case 'user-group':
      case '社交':
        categoryIcon = FontAwesomeIcons.userGroup;
        break;
      case 'gift':
      case '礼物':
        categoryIcon = FontAwesomeIcons.gift;
        break;

      // 其他
      case 'more':
      case 'more_horiz':
      case 'other':
      case 'ellipsis':
      case '其他':
        categoryIcon = FontAwesomeIcons.ellipsis;
        break;
      case 'tag':
      case 'custom':
        categoryIcon = FontAwesomeIcons.tag;
        break;
      default:
        categoryIcon = FontAwesomeIcons.receipt;
        break;
    }

    // 获取分类对应的颜色 - 使用CategoryColors而非硬编码颜色
    Color categoryColor = CategoryColors.getColor(transaction.categoryName);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // 分类图标 - 修改这里，不再使用灰色背景，而是使用分类对应的颜色
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: categoryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(categoryIcon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 16),
            // 分类名称和备注
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.categoryName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: titleColor,
                    ),
                  ),
                  if (transaction.note != null && transaction.note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        transaction.note!,
                        style: TextStyle(fontSize: 13, color: subtitleColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            // 金额和日期
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      TextSpan(
                        text: transaction.type == '支出' ? '-' : '+',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                        ),
                      ),
                      TextSpan(
                        text: '¥$formattedAmount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 12, color: subtitleColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
