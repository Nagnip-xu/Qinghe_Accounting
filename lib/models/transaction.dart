import 'package:intl/intl.dart';

class Transaction {
  final int? id;
  final String type; // 支出、收入、转账
  final double amount;
  final dynamic categoryId; // 修改为动态类型以兼容整数和字符串
  final String categoryName;
  final String categoryIcon;
  final String? categoryColor;
  final dynamic accountId; // 修改为动态类型以兼容整数和字符串
  final String accountName;
  final DateTime date;
  final String? note;
  final dynamic toAccountId; // 修改为动态类型以兼容整数和字符串
  final String? toAccountName; // 仅用于转账

  Transaction({
    this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    this.categoryColor,
    required this.accountId,
    required this.accountName,
    required this.date,
    this.note,
    this.toAccountId,
    this.toAccountName,
  });

  Map<String, dynamic> toMap() {
    // 移除id字段如果为null，让数据库自动生成
    final map = {
      'type': type,
      'amount': amount,
      'categoryId':
          categoryId is String
              ? int.tryParse(categoryId) ?? 0
              : categoryId, // 确保转换为整数
      'categoryName': categoryName,
      'categoryIcon':
          categoryIcon.isEmpty ? 'default' : categoryIcon, // 确保icon字段不为空
      'categoryColor': categoryColor ?? '',
      'accountId':
          accountId is String
              ? int.tryParse(accountId) ?? 0
              : accountId, // 确保转换为整数
      'accountName': accountName,
      'date': DateFormat('yyyy-MM-dd HH:mm:ss').format(date),
      'note': note ?? '',
    };

    // 如果是转账交易，添加目标账户ID信息
    if (type == '转账' && toAccountId != null) {
      map['toAccountId'] =
          toAccountId is String ? int.tryParse(toAccountId) ?? 0 : toAccountId;
      // 不添加toAccountName字段，因为数据库表中不存在这个列
    } else {
      // 如果不是转账交易，确保toAccountId字段为null
      map['toAccountId'] = null;
    }

    // 如果id不为null，才添加id字段
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    DateTime parseDateTime(String dateStr) {
      try {
        return DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateStr);
      } catch (e) {
        try {
          return DateFormat('yyyy-MM-dd HH:mm').parse(dateStr);
        } catch (e) {
          return DateTime.now(); // 如果无法解析，返回当前时间
        }
      }
    }

    return Transaction(
      id: map['id'],
      type: map['type'],
      amount: map['amount'],
      categoryId: map['categoryId'],
      categoryName: map['categoryName'],
      categoryIcon: map['categoryIcon'],
      categoryColor: map['categoryColor'],
      accountId: map['accountId'],
      accountName: map['accountName'],
      date: parseDateTime(map['date']),
      note: map['note'],
      toAccountId: map['toAccountId'],
      toAccountName: null, // 数据库中不存在该字段，需要在显示时通过toAccountId查询
    );
  }

  Transaction copyWith({
    int? id,
    String? type,
    double? amount,
    dynamic categoryId,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    dynamic accountId,
    String? accountName,
    DateTime? date,
    String? note,
    dynamic toAccountId,
    String? toAccountName,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      date: date ?? this.date,
      note: note ?? this.note,
      toAccountId: toAccountId ?? this.toAccountId,
      toAccountName: toAccountName ?? this.toAccountName,
    );
  }

  // 格式化日期显示
  String get formattedDate {
    // 判断是否为今天
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return '今天 ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('MM-dd').format(date);
    }
  }
}
