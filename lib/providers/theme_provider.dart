import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';

class ThemeProvider with ChangeNotifier {
  final String _themeKey = 'app_theme';
  final String _colorKey = 'app_theme_color';
  ThemeMode _themeMode = ThemeMode.light;
  Color _themeColor = AppColors.primary; // 默认主色调

  ThemeProvider() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;
  Color get themeColor => _themeColor;

  // 获取当前是否为暗黑模式
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // 设置主题
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    // 保存主题设置
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _getModeString(mode));
  }

  // 设置主题颜色
  Future<void> setThemeColor(Color color) async {
    if (_themeColor == color) return;

    _themeColor = color;
    notifyListeners();

    // 保存颜色设置（保存为十六进制字符串）
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_colorKey, color.value.toRadixString(16));
  }

  // 设置暗黑模式状态
  Future<void> setDarkMode(bool isDark) async {
    await setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  // 从字符串获取主题模式
  ThemeMode _getThemeMode(String? value) {
    switch (value) {
      case 'system':
        return ThemeMode.system;
      case 'dark':
        return ThemeMode.dark;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }

  // 将主题模式转换为字符串
  String _getModeString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'system';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
      default:
        return 'light';
    }
  }

  // 加载保存的主题
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final String? themeString = prefs.getString(_themeKey);
    _themeMode = _getThemeMode(themeString);

    // 加载保存的颜色
    final String? colorString = prefs.getString(_colorKey);
    if (colorString != null && colorString.isNotEmpty) {
      try {
        _themeColor = Color(int.parse(colorString, radix: 16));
      } catch (e) {
        _themeColor = AppColors.primary; // 解析失败时使用默认颜色
      }
    }

    notifyListeners();
  }
}
