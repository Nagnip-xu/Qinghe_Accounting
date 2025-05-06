import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  final String _storageKey = 'app_language';
  Locale _locale = const Locale('zh', 'CN'); // 默认中文

  // 添加中英文文本映射
  final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Qinghe Accounting',
      'home': 'Home',
      'statistics': 'Statistics',
      'account': 'Account',
      'profile': 'Profile',
      'addRecord': 'Add Record',
      'totalAssets': 'Total Assets',
      'income': 'Income',
      'expense': 'Expense',
      'transfer': 'Transfer',
      'budgetManagement': 'Budget Management',
      'categoryBudget': 'Category Budget',
      'add': 'Add',
      'edit': 'Edit',
      'save': 'Save',
      'cancel': 'Cancel',
      'settings': 'Settings',
      'themeSettings': 'Theme Settings',
      'languageSettings': 'Language Settings',
      'aboutApp': 'About App',
      'operationSuccess': 'Operation Successful',
    },
    'zh': {
      'appTitle': '轻合记账',
      'home': '首页',
      'statistics': '统计',
      'account': '账户',
      'profile': '我的',
      'addRecord': '记一笔',
      'totalAssets': '总资产',
      'income': '收入',
      'expense': '支出',
      'transfer': '转账',
      'budgetManagement': '预算管理',
      'categoryBudget': '分类预算',
      'add': '添加',
      'edit': '编辑',
      'save': '保存',
      'cancel': '取消',
      'settings': '设置',
      'themeSettings': '主题设置',
      'languageSettings': '语言设置',
      'aboutApp': '关于应用',
      'operationSuccess': '操作成功',
    },
  };

  LanguageProvider() {
    _loadLanguage();
  }

  Locale get locale => _locale;

  // 获取当前语言的本地化文本
  String getText(String key) {
    final langCode = _locale.languageCode;
    return _localizedValues[langCode]?[key] ??
        _localizedValues['zh']?[key] ??
        key;
  }

  // 设置语言
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();

    // 保存语言设置
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      '${locale.languageCode}_${locale.countryCode}',
    );
  }

  // 加载保存的语言
  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageString = prefs.getString(_storageKey);

    if (languageString != null && languageString.isNotEmpty) {
      final parts = languageString.split('_');
      if (parts.length >= 2) {
        _locale = Locale(parts[0], parts[1]);
      }
    }

    notifyListeners();
  }

  // 中文
  Future<void> setChinese() async {
    await setLocale(const Locale('zh', 'CN'));
  }

  // 英文
  Future<void> setEnglish() async {
    await setLocale(const Locale('en', 'US'));
  }
}
