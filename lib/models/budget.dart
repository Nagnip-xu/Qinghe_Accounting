class Budget {
  final dynamic id; // 改为动态类型以兼容字符串和整数
  final dynamic categoryId; // 改为动态类型以兼容字符串和整数
  final String categoryName;
  final double amount;
  final String period; // monthly, weekly, yearly
  final String color;
  final String icon;

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
    };
  }

  // 添加toMap方法以兼容BudgetService
  Map<String, dynamic> toMap() {
    final map = {
      'categoryId':
          categoryId is String ? int.tryParse(categoryId) ?? 0 : categoryId,
      'categoryName': categoryName,
      'amount': amount,
      'period': period,
      'color': color,
      'icon': icon,
      'month': DateTime.now().toString().substring(0, 7), // 添加当前年月作为month字段
      'isMonthly': period == 'monthly' ? 1 : 0, // 兼容isMonthly字段
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
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }
}
