import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // 获取数据库实例
  Future<Database> get database async {
    // 先检查数据库是否刚刚被恢复
    await checkDatabaseRestored();

    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  // 检查数据库是否刚刚被恢复
  Future<void> checkDatabaseRestored() async {
    try {
      // 如果有共享首选项标记表明数据库刚刚被恢复，那么我们确保重置数据库连接
      final prefs = await SharedPreferences.getInstance();
      final wasRestored = prefs.getBool('db_restored') ?? false;

      if (wasRestored) {
        print('检测到数据库刚刚被恢复，重置数据库连接');
        // 如果有现存连接，关闭它
        if (_database != null) {
          await _database!.close();
          _database = null;
        }

        // 重置恢复标记
        await prefs.setBool('db_restored', false);
        print('数据库恢复标记已重置');
      }
    } catch (e) {
      print('检查数据库恢复状态出错: $e');
    }
  }

  // 初始化数据库
  Future<Database> initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'qinghe_accounting.db');

    // 确保目录存在
    try {
      await Directory(dirname(path)).create(recursive: true);
    } catch (_) {}

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // 创建数据库表
  Future<void> _createDB(Database db, int version) async {
    // 账户表
    await db.execute('''
    CREATE TABLE accounts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      balance REAL NOT NULL,
      icon TEXT,
      color TEXT,
      isDebt INTEGER DEFAULT 0
    )
    ''');

    // 交易表
    await db.execute('''
    CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type TEXT NOT NULL,
      amount REAL NOT NULL,
      categoryId INTEGER,
      categoryName TEXT NOT NULL,
      categoryIcon TEXT,
      categoryColor TEXT,
      accountId INTEGER NOT NULL,
      accountName TEXT NOT NULL,
      date TEXT NOT NULL,
      note TEXT,
      toAccountId INTEGER,
      FOREIGN KEY (accountId) REFERENCES accounts (id) ON DELETE CASCADE
    )
    ''');

    // 预算表
    await db.execute('''
    CREATE TABLE budgets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      categoryId INTEGER,
      categoryName TEXT NOT NULL,
      amount REAL NOT NULL,
      year INTEGER NOT NULL,
      month INTEGER NOT NULL,
      spent REAL DEFAULT 0
    )
    ''');

    // 类别表
    await db.execute('''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      icon TEXT,
      color TEXT
    )
    ''');

    // 用户表
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL,
      password TEXT,
      email TEXT,
      profilePicture TEXT,
      createdAt TEXT,
      lastLogin TEXT
    )
    ''');

    // 财务目标表
    await db.execute('''
    CREATE TABLE financial_goals (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      targetAmount REAL NOT NULL,
      currentAmount REAL DEFAULT 0,
      targetDate TEXT NOT NULL,
      completed INTEGER DEFAULT 0,
      icon TEXT,
      color TEXT
    )
    ''');

    // 账单提醒表
    await db.execute('''
    CREATE TABLE reminders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      amount REAL NOT NULL,
      dueDate TEXT NOT NULL,
      recurring INTEGER DEFAULT 0,
      recurringType TEXT,
      notificationId INTEGER,
      completed INTEGER DEFAULT 0
    )
    ''');

    // 插入默认数据
    _insertDefaultData(db);
  }

  // 数据库升级
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      // 在此添加迁移逻辑
    }
  }

  // 插入默认数据
  Future<void> _insertDefaultData(Database db) async {
    // 插入默认账户
    await db.insert('accounts', {
      'name': '现金',
      'type': '现金钱包',
      'balance': 0.0,
      'icon': 'wallet',
      'color': '0xFF4CAF50',
      'isDebt': 0,
    });

    await db.insert('accounts', {
      'name': '银行卡',
      'type': '银行卡',
      'balance': 0.0,
      'icon': 'credit-card',
      'color': '0xFF2196F3',
      'isDebt': 0,
    });

    // 插入默认支出类别
    final expenseCategories = [
      {'name': '餐饮', 'icon': 'utensils', 'color': '0xFFF44336'},
      {'name': '交通', 'icon': 'car', 'color': '0xFF2196F3'},
      {'name': '购物', 'icon': 'cart-shopping', 'color': '0xFFFF9800'},
      {'name': '娱乐', 'icon': 'film', 'color': '0xFF9C27B0'},
      {'name': '居住', 'icon': 'house', 'color': '0xFF3F51B5'},
      {'name': '医疗', 'icon': 'pills', 'color': '0xFF4CAF50'},
      {'name': '教育', 'icon': 'book', 'color': '0xFF795548'},
    ];

    for (var category in expenseCategories) {
      await db.insert('categories', {
        'name': category['name'],
        'type': '支出',
        'icon': category['icon'],
        'color': category['color'],
      });
    }

    // 插入默认收入类别
    final incomeCategories = [
      {'name': '工资', 'icon': 'money-bill', 'color': '0xFF4CAF50'},
      {'name': '奖金', 'icon': 'gift', 'color': '0xFFFF9800'},
      {'name': '投资收益', 'icon': 'chart-line', 'color': '0xFF2196F3'},
      {'name': '兼职', 'icon': 'briefcase', 'color': '0xFF9C27B0'},
    ];

    for (var category in incomeCategories) {
      await db.insert('categories', {
        'name': category['name'],
        'type': '收入',
        'icon': category['icon'],
        'color': category['color'],
      });
    }

    // 插入转账类别
    await db.insert('categories', {
      'name': '转账',
      'type': '转账',
      'icon': 'exchange',
      'color': '0xFF607D8B',
    });

    // 插入默认用户
    await db.insert('users', {
      'username': 'default',
      'password': 'default123',
      'email': 'default@example.com',
      'createdAt': DateTime.now().toIso8601String(),
      'lastLogin': DateTime.now().toIso8601String(),
    });
  }

  // 关闭数据库
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  // 重置数据库连接
  Future<void> resetDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
