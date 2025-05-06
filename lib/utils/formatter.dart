import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'zh_CN',
    symbol: '¥',
    decimalDigits: 2,
  );

  static final NumberFormat _formatterWithoutSymbol = NumberFormat.currency(
    locale: 'zh_CN',
    symbol: '',
    decimalDigits: 2,
  );

  // 格式化货币数字
  static String format(double amount) {
    // 处理金额为0的情况
    if (amount == 0) return '¥0.00';

    // 判断是否为负数
    bool isNegative = amount < 0;

    // 取绝对值后格式化
    String formatted =
        '¥${isNegative ? '-' : ''}${amount.abs().toStringAsFixed(2)}';

    return formatted;
  }

  // 格式化货币，不包含货币符号
  static String formatWithoutSymbol(double amount) {
    return _formatterWithoutSymbol.format(amount).trim();
  }

  // 格式化货币，使用紧凑格式（如1.2K, 1.5M等）
  static String formatCompact(double amount) {
    if (amount.abs() >= 1000000) {
      // 百万以上用M
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount.abs() >= 1000) {
      // 千以上用K
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      // 原样返回
      return format(amount);
    }
  }

  // 格式化金额为整数
  static String formatInteger(double amount) {
    return '¥ ${amount.toInt()}';
  }

  // 格式化金额为加号或减号前缀
  static String formatWithSign(double amount) {
    if (amount > 0) {
      return '+${format(amount)}';
    } else if (amount < 0) {
      return format(amount);
    } else {
      return format(0);
    }
  }

  // 格式化金额为加号或减号前缀，但不带符号
  static String formatWithSignNoSymbol(double amount) {
    if (amount > 0) {
      return '+${formatWithoutSymbol(amount)}';
    } else if (amount < 0) {
      return formatWithoutSymbol(amount);
    } else {
      return formatWithoutSymbol(0);
    }
  }
}
