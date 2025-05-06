import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// 支出分类图标
class ExpenseCategoryIcons {
  static const IconData food = FontAwesomeIcons.utensils;
  static const IconData transport = FontAwesomeIcons.car;
  static const IconData shopping = FontAwesomeIcons.cartShopping;
  static const IconData entertainment = FontAwesomeIcons.film;
  static const IconData housing = FontAwesomeIcons.house;
  static const IconData medical = FontAwesomeIcons.pills;
  static const IconData education = FontAwesomeIcons.book;
  static const IconData other = FontAwesomeIcons.ellipsis;
}

// 收入分类图标
class IncomeCategoryIcons {
  static const IconData salary = FontAwesomeIcons.moneyBill;
  static const IconData investment = FontAwesomeIcons.chartLine;
  static const IconData bonus = FontAwesomeIcons.gift;
  static const IconData partTime = FontAwesomeIcons.briefcase;
  static const IconData other = FontAwesomeIcons.ellipsis;
}

// 账户类型图标
class AccountTypeIcons {
  static const IconData bankCard = FontAwesomeIcons.creditCard;
  static const IconData cash = FontAwesomeIcons.wallet;
  static const IconData alipay = FontAwesomeIcons.mobileScreen;
  static const IconData wechatPay = FontAwesomeIcons.comments;
  static const IconData creditCard = FontAwesomeIcons.ccVisa;
  static const IconData fundAccount = FontAwesomeIcons.moneyBillTrendUp;
}

// 分类颜色列表
class CategoryColors {
  static const Map<String, Color> colors = {
    'food': Color(0xFFFF9800), // 餐饮-橙色
    'transport': Color(0xFF2196F3), // 交通-蓝色
    'shopping': Color(0xFF9C27B0), // 购物-紫色
    'entertainment': Color(0xFFE91E63), // 娱乐-粉色
    'housing': Color(0xFF4CAF50), // 住房-绿色
    'medical': Color(0xFFFF5252), // 医疗-红色
    'education': Color(0xFF3F51B5), // 教育-靛蓝色
    'other': Color(0xFF607D8B), // 其他-灰蓝色
    'salary': Color(0xFF4CAF50), // 工资-绿色
    'investment': Color(0xFF2196F3), // 投资-蓝色
    'bonus': Color(0xFFFF9800), // 奖金-橙色
    'partTime': Color(0xFF9C27B0), // 兼职-紫色
  };
}
