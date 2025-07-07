import 'package:flutter/material.dart';

class AppColors {
  // 主题色
  static const Color primary = Color(0xFF5C6AC4); // 主色，类似知乎蓝
  static const Color primaryDark = Color(0xFF3E4784); // 深色主题下的主色
  static const Color primaryLight = Color(0xFF7D88D8); // 浅色主题下的主色

  // 辅助色
  static const Color secondary = Color(0xFF42B883); // 辅助色，绿色
  static const Color accent = Color(0xFFFFC107); // 强调色，橙黄色

  // 功能色
  static const Color success = Color(0xFF4CAF50); // 成功，绿色
  static const Color warning = Color(0xFFFF9800); // 警告，橙色
  static const Color error = Color(0xFFF44336); // 错误，红色
  static const Color info = Color(0xFF2196F3); // 信息，蓝色

  // 文本色
  static const Color textPrimary = Color(0xFF333333); // 主要文本
  static const Color textSecondary = Color(0xFF666666); // 次要文本
  static const Color textHint = Color(0xFF999999); // 提示文本
  static const Color textDisabled = Color(0xFFCCCCCC); // 禁用文本

  // 深色模式文本色
  static const Color darkTextPrimary = Color(0xFFEEEEEE); // 深色模式主文本
  static const Color darkTextSecondary = Color(0xFFB0B0B0); // 深色模式次文本

  // 背景色
  static const Color background = Color(0xFFF5F5F5); // 背景色
  static const Color surface = Colors.white; // 表面色
  static const Color card = Colors.white; // 卡片色

  // 分隔线和边框
  static const Color divider = Color(0xFFEEEEEE); // 分隔线
  static const Color border = Color(0xFFE0E0E0); // 边框

  // 功能型颜色
  static const Color income = Color(0xFF4CAF50); // 收入
  static const Color expense = Color(0xFFF44336); // 支出
  static const Color transfer = Color(0xFF2196F3); // 转账

  // 深色主题相关
  static const Color darkBackground = Color(0xFF121212); // 深色背景
  static const Color darkSurface = Color(0xFF1E1E1E); // 深色表面
  static const Color darkCard = Color(0xFF2C2C2C); // 深色卡片

  // 分类颜色
  static const Color foodColor = Color(0xFFF44336); // 餐饮，红色
  static const Color transportColor = Color(0xFF2196F3); // 交通，蓝色
  static const Color shoppingColor = Color(0xFF673AB7); // 购物，紫色
  static const Color entertainmentColor = Color(0xFFFF9800); // 娱乐，橙色
  static const Color billsColor = Color(0xFF795548); // 账单，棕色
  static const Color otherColor = Color(0xFF607D8B); // 其他，蓝灰色

  // 分类颜色列表
  static const List<Color> categoryColors = [
    Color(0xFF5C6AC4), // 主题蓝
    Color(0xFF42B883), // 绿色
    Color(0xFFFFC107), // 橙黄
    Color(0xFFF44336), // 红色
    Color(0xFF2196F3), // 蓝色
    Color(0xFF9C27B0), // 紫色
    Color(0xFF795548), // 棕色
    Color(0xFF607D8B), // 蓝灰
    Color(0xFFE91E63), // 粉红
    Color(0xFF009688), // 蓝绿
  ];

  // 主题颜色选项
  static const Map<String, Color> themeColors = {
    '蓝色(默认)': Color(0xFF3F51B5), // Indigo
    '红色': Color(0xFFE53935), // Red
    '粉色': Color(0xFFEC407A), // Pink
    '紫色': Color(0xFF8E24AA), // Purple
    '深紫': Color(0xFF5E35B1), // Deep Purple
    '青色': Color(0xFF00ACC1), // Cyan
    '蓝绿': Color(0xFF00897B), // Teal
    '绿色': Color(0xFF43A047), // Green
    '橙色': Color(0xFFFF9800), // Orange
    '棕色': Color(0xFF795548), // Brown
  };

  // 获取所有主题颜色列表
  static List<Color> get allThemeColors => themeColors.values.toList();

  // 根据颜色获取颜色名称
  static String getColorName(Color color) {
    for (var entry in themeColors.entries) {
      if (entry.value.value == color.value) {
        return entry.key;
      }
    }
    return '自定义';
  }

  // 渐变色
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFF44336), Color(0xFFFF9800)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient transferGradient = LinearGradient(
    colors: [Color(0xFF2196F3), Color(0xFF03A9F4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
