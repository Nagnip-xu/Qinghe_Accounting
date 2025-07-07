import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  // 静态方法，用于获取当前上下文的 AppLocalizations 实例
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('zh'));
  }

  // 静态委托
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // 属性
  String get home => '首页';
  String get statistics => '统计';
  String get account => '账户';
  String get profile => '我的';
  String get hello => '你好';
  String get today => '今天是';
  String get user => '用户';
  String get totalAssets => '总资产';
  String get income => '收入';
  String get expense => '支出';
  String get notLoggedIn => '未登录';
  String get loginToSyncData => '点击登录账号，同步您的数据';
  String get login => '登录';
  String get budgetManagement => '财务管理';
  String get categoryBudget => '我的预算';
  String get dataBackup => '数据管理';
  String get backup => '数据备份';
  String get restore => '数据恢复';
  String get exportData => '导出报表';
  String get settings => '应用设置';
  String get themeSettings => '主题设置';
  String get languageSettings => '语言设置';
  String get aboutApp => '关于应用';
  String get defaultTheme => '默认';
  String get lightTheme => '浅色';
  String get darkTheme => '深色';
  String get cancel => '取消';
  String get save => '保存';
  String get operationSuccess => '操作成功';
  String get appTitle => '青禾记账';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // 支持中文和英文
    return ['zh', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
