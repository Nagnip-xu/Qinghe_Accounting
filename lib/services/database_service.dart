import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'qinghe_accounting.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // 创建账户表
    await db.execute('''
      CREATE TABLE accounts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL,
        icon TEXT,
        color TEXT,
        isDebt INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 创建分类表
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT NOT NULL,
        color TEXT NOT NULL
      )
    ''');

    // 创建交易记录表
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        categoryId INTEGER,
        categoryName TEXT NOT NULL,
        categoryIcon TEXT NOT NULL,
        categoryColor TEXT,
        accountId INTEGER NOT NULL,
        accountName TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        toAccountId INTEGER,
        FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE SET NULL,
        FOREIGN KEY (accountId) REFERENCES accounts (id) ON DELETE CASCADE,
        FOREIGN KEY (toAccountId) REFERENCES accounts (id) ON DELETE SET NULL
      )
    ''');

    // 创建预算表
    await db.execute('''
      CREATE TABLE budgets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoryId INTEGER,
        categoryName TEXT,
        categoryIcon TEXT,
        categoryColor TEXT,
        amount REAL NOT NULL,
        month TEXT NOT NULL,
        isMonthly INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    // 插入默认分类数据
    await _insertDefaultCategories(db);

    // 插入默认账户
    await _insertDefaultAccounts(db);
  }

  Future<void> _insertDefaultCategories(Database db) async {
    // 支出分类
    Batch batch = db.batch();

    // 餐饮
    batch.insert('categories', {
      'name': '餐饮',
      'type': '支出',
      'icon': 'utensils',
      'color': '0xFFFF9800',
    });

    // 交通
    batch.insert('categories', {
      'name': '交通',
      'type': '支出',
      'icon': 'car',
      'color': '0xFF2196F3',
    });

    // 购物
    batch.insert('categories', {
      'name': '购物',
      'type': '支出',
      'icon': 'cart-shopping',
      'color': '0xFF9C27B0',
    });

    // 娱乐
    batch.insert('categories', {
      'name': '娱乐',
      'type': '支出',
      'icon': 'film',
      'color': '0xFFE91E63',
    });

    // 住房
    batch.insert('categories', {
      'name': '住房',
      'type': '支出',
      'icon': 'house',
      'color': '0xFF4CAF50',
    });

    // 医疗
    batch.insert('categories', {
      'name': '医疗',
      'type': '支出',
      'icon': 'pills',
      'color': '0xFFFF5252',
    });

    // 教育
    batch.insert('categories', {
      'name': '教育',
      'type': '支出',
      'icon': 'book',
      'color': '0xFF3F51B5',
    });

    // 其他
    batch.insert('categories', {
      'name': '其他',
      'type': '支出',
      'icon': 'ellipsis',
      'color': '0xFF607D8B',
    });

    await batch.commit();

    // 收入分类
    batch = db.batch();

    // 工资
    batch.insert('categories', {
      'name': '工资',
      'type': '收入',
      'icon': 'money-bill',
      'color': '0xFF4CAF50',
    });

    // 投资
    batch.insert('categories', {
      'name': '投资',
      'type': '收入',
      'icon': 'chart-line',
      'color': '0xFF2196F3',
    });

    // 奖金
    batch.insert('categories', {
      'name': '奖金',
      'type': '收入',
      'icon': 'gift',
      'color': '0xFFFF9800',
    });

    // 兼职
    batch.insert('categories', {
      'name': '兼职',
      'type': '收入',
      'icon': 'briefcase',
      'color': '0xFF9C27B0',
    });

    // 其他
    batch.insert('categories', {
      'name': '其他',
      'type': '收入',
      'icon': 'ellipsis',
      'color': '0xFF607D8B',
    });

    await batch.commit();
  }

  Future<void> _insertDefaultAccounts(Database db) async {
    // 现金钱包
    await db.insert('accounts', {
      'name': '现金钱包',
      'type': '现金',
      'balance': 0.0,
      'icon': 'wallet',
      'color': '0xFF4CAF50',
      'isDebt': 0,
    });

    // 微信钱包
    await db.insert('accounts', {
      'name': '微信钱包',
      'type': '电子钱包',
      'balance': 0.0,
      'icon': 'mobile-screen',
      'color': '0xFF07C160', // 微信绿色
      'isDebt': 0,
    });

    // 支付宝
    await db.insert('accounts', {
      'name': '支付宝',
      'type': '电子钱包',
      'balance': 0.0,
      'icon': 'mobile-screen',
      'color': '0xFF1677FF', // 支付宝蓝色
      'isDebt': 0,
    });

    // 工商银行
    await db.insert('accounts', {
      'name': '工商银行',
      'type': '银行卡',
      'balance': 0.0,
      'icon': 'credit-card',
      'color': '0xFFE53935',
      'isDebt': 0,
    });

    // 基金钱包
    await db.insert('accounts', {
      'name': '基金钱包',
      'type': '投资',
      'balance': 0.0,
      'icon': 'money-bill-trend-up',
      'color': '0xFFFF9800',
      'isDebt': 0,
    });
  }
}
