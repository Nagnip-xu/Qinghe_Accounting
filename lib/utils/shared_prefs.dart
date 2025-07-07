import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  static final SharedPrefs _instance = SharedPrefs._internal();
  factory SharedPrefs() => _instance;
  SharedPrefs._internal();

  // 主题相关
  static const String _themeMode = 'theme_mode';
  static const String _themeColor = 'theme_color';

  // 语言相关
  static const String _locale = 'locale';

  // 通用设置
  static const String _firstLaunch = 'first_launch';
  static const String _onboardingCompleted = 'onboarding_completed';

  // 获取主题模式索引（0：系统默认，1：浅色，2：深色）
  Future<int> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_themeMode) ?? 0;
  }

  // 设置主题模式
  Future<void> setThemeMode(int mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeMode, mode);
  }

  // 获取主题颜色值
  Future<int?> getThemeColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_themeColor);
  }

  // 设置主题颜色
  Future<void> setThemeColor(int colorValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeColor, colorValue);
  }

  // 获取语言代码（默认为中文：zh）
  Future<String> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_locale) ?? 'zh';
  }

  // 设置语言代码
  Future<void> setLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_locale, languageCode);
  }

  // 检查是否首次启动应用
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstLaunch) ?? true;
  }

  // 设置应用已启动
  Future<void> setAppLaunched() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunch, false);
  }

  // 检查是否已完成引导
  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleted) ?? false;
  }

  // 设置引导已完成
  Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleted, true);
  }

  // 清除所有数据（用于重置应用）
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
