class Account {
  final int? id;
  final String name;
  final String type; // 银行卡、现金钱包、信用卡、支付宝等
  final double balance;
  final String? icon;
  final String? color;
  final bool isDebt; // 是否为负债账户

  Account({
    this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.icon,
    this.color,
    this.isDebt = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'balance': balance,
      'icon': icon,
      'color': color,
      'isDebt': isDebt ? 1 : 0,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      balance: map['balance'],
      icon: map['icon'],
      color: map['color'],
      isDebt: map['isDebt'] == 1,
    );
  }

  Account copyWith({
    int? id,
    String? name,
    String? type,
    double? balance,
    String? icon,
    String? color,
    bool? isDebt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDebt: isDebt ?? this.isDebt,
    );
  }
}
