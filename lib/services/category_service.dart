import 'package:sqflite/sqflite.dart';
import '../models/category.dart';
import 'database_service.dart';

class CategoryService {
  final DatabaseService _databaseService = DatabaseService();

  // 获取所有分类
  Future<List<Category>> getAllCategories() async {
    final Database db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  // 获取所有支出分类
  Future<List<Category>> getAllExpenseCategories() async {
    final Database db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: ['支出'],
    );
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  // 获取所有收入分类
  Future<List<Category>> getAllIncomeCategories() async {
    final Database db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: ['收入'],
    );
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  // 获取单个分类
  Future<Category?> getCategory(int id) async {
    final Database db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }

  // 添加分类
  Future<int> addCategory(Category category) async {
    final Database db = await _databaseService.database;
    return await db.insert('categories', category.toMap());
  }

  // 更新分类
  Future<int> updateCategory(Category category) async {
    final Database db = await _databaseService.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  // 删除分类
  Future<int> deleteCategory(int id) async {
    final Database db = await _databaseService.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
