import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// 定义分类图标映射关系
class CategoryIcons {
  // 支出分类图标
  static final Map<String, IconData> expenseIcons = {
    '餐饮': FontAwesomeIcons.utensils,
    '购物': FontAwesomeIcons.bagShopping,
    '日用': FontAwesomeIcons.toiletPaper,
    '交通': FontAwesomeIcons.car,
    '饮品': FontAwesomeIcons.mugHot,
    '蔬菜': FontAwesomeIcons.carrot,
    '水果': FontAwesomeIcons.apple,
    '零食': FontAwesomeIcons.cookieBite,
    '运动': FontAwesomeIcons.personRunning,
    '娱乐': FontAwesomeIcons.gamepad,
    '通讯': FontAwesomeIcons.phone,
    '小吃': FontAwesomeIcons.drumstickBite,
    '服饰': FontAwesomeIcons.shirt,
    '美容': FontAwesomeIcons.sprayCan,
    '住房': FontAwesomeIcons.house,
    '居家': FontAwesomeIcons.couch,
    '长辈': FontAwesomeIcons.personCane,
    '社交': FontAwesomeIcons.userGroup,
    '旅行': FontAwesomeIcons.plane,
    '烟酒': FontAwesomeIcons.wineGlass,
    '数码': FontAwesomeIcons.mobileScreen,
    '汽车': FontAwesomeIcons.carRear,
    '医疗': FontAwesomeIcons.suitcaseMedical,
    '书籍': FontAwesomeIcons.book,
    '学习': FontAwesomeIcons.graduationCap,
    '宠物': FontAwesomeIcons.dog,
    '礼金': FontAwesomeIcons.moneyBill1,
    '礼物': FontAwesomeIcons.gift,
    '办公': FontAwesomeIcons.briefcase,
    '维修': FontAwesomeIcons.screwdriverWrench,
    '捐赠': FontAwesomeIcons.handHoldingHeart,
    '彩票': FontAwesomeIcons.ticket,
    '亲友': FontAwesomeIcons.userFriends,
    '快递': FontAwesomeIcons.box,
    '游戏': FontAwesomeIcons.gamepad,
    '设置': FontAwesomeIcons.gear,
    '其他': FontAwesomeIcons.ellipsis,
  };

  // 收入分类图标
  static final Map<String, IconData> incomeIcons = {
    '工资': FontAwesomeIcons.moneyBill1,
    '奖金': FontAwesomeIcons.award,
    '兼职': FontAwesomeIcons.briefcase,
    '投资': FontAwesomeIcons.chartLine,
    '理财': FontAwesomeIcons.piggyBank,
    '退款': FontAwesomeIcons.rotateLeft,
    '报销': FontAwesomeIcons.receipt,
    '红包': FontAwesomeIcons.envelopeOpen,
    '生活费': FontAwesomeIcons.wallet,
    '其他': FontAwesomeIcons.ellipsis,
  };

  // 获取图标
  static IconData getIconData(String iconName, String type) {
    if (type == '支出') {
      return expenseIcons[iconName] ?? FontAwesomeIcons.question;
    } else {
      return incomeIcons[iconName] ?? FontAwesomeIcons.question;
    }
  }
}

// 分类颜色列表
class CategoryColors {
  static const Map<String, Color> colors = {
    '餐饮': Color(0xFFFF9800), // 橙色
    '购物': Color(0xFF9C27B0), // 紫色
    '日用': Color(0xFF795548), // 棕色
    '交通': Color(0xFF2196F3), // 蓝色
    '饮品': Color(0xFF4CAF50), // 绿色
    '蔬菜': Color(0xFF8BC34A), // 浅绿色
    '水果': Color(0xFFCDDC39), // 酸橙色
    '零食': Color(0xFFFF9800), // 橙色 - 与餐饮一致
    '运动': Color(0xFFFF5722), // 深橙色
    '娱乐': Color(0xFFE91E63), // 粉色
    '通讯': Color(0xFF3F51B5), // 靛蓝色
    '小吃': Color(0xFFFF9800), // 橙色 - 与餐饮一致
    '服饰': Color(0xFF9E9E9E), // 灰色
    '美容': Color(0xFFFF4081), // 粉红色
    '住房': Color(0xFF00BCD4), // 青色
    '居家': Color(0xFF607D8B), // 蓝灰色
    '长辈': Color(0xFFFF6D00), // 深橙色
    '社交': Color(0xFF7B1FA2), // 深紫色
    '旅行': Color(0xFF1976D2), // 深蓝色
    '烟酒': Color(0xFF455A64), // 深灰蓝色
    '数码': Color(0xFF006064), // 深青色
    '汽车': Color(0xFF546E7A), // 蓝灰色
    '医疗': Color(0xFFFF5252), // 红色
    '书籍': Color(0xFF3F51B5), // 靛蓝色
    '学习': Color(0xFF00BFA5), // 青绿色
    '宠物': Color(0xFFEF6C00), // 深橙色
    '礼金': Color(0xFFFFD54F), // 琥珀色
    '礼物': Color(0xFFD81B60), // 深粉色
    '办公': Color(0xFF0288D1), // 浅蓝色
    '维修': Color(0xFF455A64), // 蓝灰色
    '捐赠': Color(0xFFC2185B), // 粉色
    '彩票': Color(0xFFFFB300), // 琥珀色
    '亲友': Color(0xFF689F38), // 浅绿色
    '快递': Color(0xFF795548), // 棕色
    '游戏': Color(0xFF673AB7), // 深紫色
    '设置': Color(0xFF607D8B), // 蓝灰色
    '其他': Color(0xFF9E9E9E), // 灰色
    '工资': Color(0xFF4CAF50), // 绿色
    '奖金': Color(0xFFFFB300), // 琥珀色
    '兼职': Color(0xFF9C27B0), // 紫色
    '投资': Color(0xFF2196F3), // 蓝色
    '理财': Color(0xFF00BCD4), // 青色
    '退款': Color(0xFFFF9800), // 橙色
    '报销': Color(0xFF607D8B), // 蓝灰色
    '红包': Color(0xFFF44336), // 红色
    '生活费': Color(0xFF8BC34A), // 浅绿色
    // 新增：确保"早餐"和"午餐"使用与"餐饮"相同的颜色
    '早餐': Color(0xFFFF9800), // 橙色 - 与餐饮一致
    '午餐': Color(0xFFFF9800), // 橙色 - 与餐饮一致
    '晚餐': Color(0xFFFF9800), // 橙色 - 与餐饮一致
    // 新增：确保"水费"、"电费"等使用与"住房"相同的颜色
    '水费': Color(0xFF00BCD4), // 青色 - 与住房一致
    '电费': Color(0xFF00BCD4), // 青色 - 与住房一致
    '燃气费': Color(0xFF00BCD4), // 青色 - 与住房一致
    '网费': Color(0xFF00BCD4), // 青色 - 与住房一致
    '话费': Color(0xFF00BCD4), // 青色 - 与住房一致
    // 新增：确保"药品"和"挂号"使用与"医疗"相同的颜色
    '药品': Color(0xFFFF5252), // 红色 - 与医疗一致
    '挂号': Color(0xFFFF5252), // 红色 - 与医疗一致
    // 新增：确保"学费"和"书籍"使用与"教育"相同的颜色
    '教育': Color(0xFF3F51B5), // 靛蓝色 - 与书籍一致
    '学费': Color(0xFF3F51B5), // 靛蓝色 - 与书籍一致
    // 新增：确保交通相关分类颜色一致
    '打车': Color(0xFF2196F3), // 蓝色 - 与交通一致
    '公交': Color(0xFF2196F3), // 蓝色 - 与交通一致
    '地铁': Color(0xFF2196F3), // 蓝色 - 与交通一致
    // 新增：确保购物相关分类颜色一致
    '服装': Color(0xFF9C27B0), // 紫色 - 与购物一致
    '化妆': Color(0xFF9C27B0), // 紫色 - 与购物一致
    // 新增：确保其他可能出现的分类
    '家庭': Color(0xFF607D8B), // 蓝灰色 - 与居家一致
    '孩子': Color(0xFFFF6D00), // 深橙色 - 与长辈类似
    '房租': Color(0xFF00BCD4), // 青色 - 与住房一致
    '电影': Color(0xFFE91E63), // 粉色 - 与娱乐一致
    '旅游': Color(0xFF1976D2), // 深蓝色 - 与旅行一致
  };

  // 获取颜色
  static Color getColor(String categoryName) {
    // 直接匹配
    if (colors.containsKey(categoryName)) {
      return colors[categoryName]!;
    }

    // 如果找不到精确匹配，尝试基于前缀或关键词匹配
    if (categoryName.contains('餐') ||
        categoryName.contains('吃') ||
        categoryName.contains('食')) {
      return colors['餐饮']!;
    } else if (categoryName.contains('车') ||
        categoryName.contains('交通') ||
        categoryName.contains('公共交通')) {
      return colors['交通']!;
    } else if (categoryName.contains('购') ||
        categoryName.contains('买') ||
        categoryName.contains('商场')) {
      return colors['购物']!;
    } else if (categoryName.contains('娱乐') ||
        categoryName.contains('游戏') ||
        categoryName.contains('玩')) {
      return colors['娱乐']!;
    } else if (categoryName.contains('房') ||
        categoryName.contains('住') ||
        categoryName.contains('家')) {
      return colors['住房']!;
    } else if (categoryName.contains('医') ||
        categoryName.contains('病') ||
        categoryName.contains('药')) {
      return colors['医疗']!;
    } else if (categoryName.contains('学') ||
        categoryName.contains('教育') ||
        categoryName.contains('书')) {
      return colors['教育']!;
    } else if (categoryName.contains('工资') ||
        categoryName.contains('薪') ||
        categoryName.contains('收入')) {
      return colors['工资']!;
    }

    // 如果所有匹配都失败，返回默认颜色
    return const Color(0xFF9E9E9E); // 默认灰色
  }
}
