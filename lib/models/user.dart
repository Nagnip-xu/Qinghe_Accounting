class User {
  final int? id;
  final String username;
  final String? email;
  final String? avatar;
  final bool isLoggedIn;

  User({
    this.id,
    required this.username,
    this.email,
    this.avatar,
    this.isLoggedIn = false,
  });

  // 创建匿名用户
  factory User.guest() {
    return User(username: '未登录', isLoggedIn: false);
  }

  // 从Map转换
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'] ?? '未登录',
      email: map['email'],
      avatar: map['avatar'],
      isLoggedIn: map['isLoggedIn'] ?? false,
    );
  }

  // 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatar': avatar,
      'isLoggedIn': isLoggedIn,
    };
  }

  // 创建用户副本
  User copyWith({
    int? id,
    String? username,
    String? email,
    String? avatar,
    bool? isLoggedIn,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}
