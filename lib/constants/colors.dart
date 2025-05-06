import 'package:flutter/material.dart';

class AppColors {
  // Base colors
  static const Color primary = Color(0xFF3F51B5);
  static const Color secondary = Color(0xFF2196F3);
  static const Color accent = Color(0xFFF44336);
  static const Color background = Color(0xFFF5F5F5);
  static const Color card = Color(0xFFFFFFFF);

  // Dark mode colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkSurface = Color(0xFF2C2C2C);

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Dark mode text colors
  static const Color darkTextPrimary = Color(0xFFEEEEEE);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);

  // Transaction type colors
  static const Color income = Color(0xFF4CAF50);
  static const Color expense = Color(0xFFF44336);
  static const Color transfer = Color(0xFF9C27B0);

  // Category colors
  static const Color foodColor = Color(0xFFF44336); // 红色
  static const Color transportColor = Color(0xFF2196F3); // 蓝色
  static const Color shoppingColor = Color(0xFF673AB7); // 紫色
  static const Color entertainmentColor = Color(0xFFFF9800); // 橙色
  static const Color billsColor = Color(0xFF795548); // 棕色
  static const Color otherColor = Color(0xFF607D8B); // 蓝灰色

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
}
