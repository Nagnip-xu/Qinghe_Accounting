class Budget {
  final dynamic id; // 改为动态类型以兼容字符串和整数
  final dynamic categoryId; // 改为动态类型以兼容字符串和整数
  final String categoryName;
  final double amount;
  final String period; // monthly, weekly, yearly
  final String color;
  final String icon;
  final String? month; // 添加月份字段

  // 添加额外属性以兼容现有服务
  String get categoryIcon => icon;
  String get categoryColor => color;

  Budget({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.period,
    required this.color,
    required this.icon,
    this.month,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'amount': amount,
      'period': period,
      'color': color,
      'icon': icon,
      'month': month,
    };
  }

  // 添加toMap方法以兼容BudgetService
  Map<String, dynamic> toMap() {
    final map = {
      'categoryId':
          categoryId is String ? int.tryParse(categoryId) ?? 0 : categoryId,
      'categoryName': categoryName,
      'amount': amount,
      'categoryColor': color,
      'categoryIcon': icon,
      'month':
          month ?? DateTime.now().toString().substring(0, 7), // 使用传入的月份或当前月份
      'isMonthly':
          (period == 'monthly' &&
                  (categoryId == 0 || categoryId == '0' || categoryId == ''))
              ? 1
              : 0, // 月度总预算 isMonthly=1，分类预算 isMonthly=0
    };

    // 只有在id不为空且不是0的情况下，才添加id字段
    if (id != null && id != '' && id != 0) {
      // 确保id是整数类型
      map['id'] = id is String ? int.tryParse(id) ?? 0 : id;
    }

    return map;
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      amount: json['amount'].toDouble(),
      period: json['period'],
      color: json['color'],
      icon: json['icon'],
      month: json['month'],
    );
  }

  // 添加fromMap方法以兼容BudgetService
  factory Budget.fromMap(Map<String, dynamic> map) {
    // 处理金额为整数类型的情况
    double amount = 0.0;
    if (map['amount'] != null) {
      amount = map['amount'] is int ? map['amount'].toDouble() : map['amount'];
    }

    return Budget(
      id: map['id']?.toString() ?? '',
      categoryId: map['categoryId']?.toString() ?? '',
      categoryName: map['categoryName'] ?? '',
      amount: amount,
      period: map['period'] ?? (map['isMonthly'] == 1 ? 'monthly' : 'category'),
      color: map['color'] ?? map['categoryColor'] ?? '',
      icon: map['icon'] ?? map['categoryIcon'] ?? '',
      month: map['month'],
    );
  }

  Budget copyWith({
    dynamic id,
    dynamic categoryId,
    String? categoryName,
    double? amount,
    String? period,
    String? color,
    String? icon,
    String? month,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      month: month ?? this.month,
    );
  }
}
