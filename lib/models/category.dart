class Category {
  final int? id;
  final String name;
  final String type; // 支出或收入
  final String icon;
  final String color;

  Category({
    this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'type': type, 'icon': icon, 'color': color};
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      icon: map['icon'],
      color: map['color'],
    );
  }

  Category copyWith({
    int? id,
    String? name,
    String? type,
    String? icon,
    String? color,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }
}
