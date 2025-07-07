import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';
import '../services/category_service.dart';

class CategoryProvider with ChangeNotifier {
  final CategoryService _categoryService = CategoryService();

  List<Category> _categories = [];
  List<Category> _expenseCategories = [];
  List<Category> _incomeCategories = [];
  bool _isLoading = false;
  String? _error;

  List<Category> get categories => _categories;
  List<Category> get expenseCategories => _expenseCategories;
  List<Category> get incomeCategories => _incomeCategories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 初始化分类数据
  Future<void> initCategories() async {
    _setLoading(true);

    try {
      await _fetchAllCategories();
      await _fetchExpenseCategories();
      await _fetchIncomeCategories();
      _setError(null);
    } catch (e) {
      _setError('获取分类数据失败：$e');
    } finally {
      _setLoading(false);
    }
  }

  // 获取所有分类
  Future<void> _fetchAllCategories() async {
    _categories = await _categoryService.getAllCategories();
    notifyListeners();
  }

  // 获取所有支出分类
  Future<void> _fetchExpenseCategories() async {
    _expenseCategories = await _categoryService.getAllExpenseCategories();
    notifyListeners();
  }

  // 获取所有收入分类
  Future<void> _fetchIncomeCategories() async {
    _incomeCategories = await _categoryService.getAllIncomeCategories();
    notifyListeners();
  }

  // 添加分类
  Future<bool> addCategory(Category category) async {
    _setLoading(true);

    try {
      await _categoryService.addCategory(category);
      // 根据分类类型刷新对应列表
      if (category.type == '支出') {
        await _fetchExpenseCategories();
      } else if (category.type == '收入') {
        await _fetchIncomeCategories();
      }
      await _fetchAllCategories();
      _setError(null);
      return true;
    } catch (e) {
      _setError('添加分类失败：$e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 更新分类
  Future<bool> updateCategory(Category category) async {
    _setLoading(true);

    try {
      await _categoryService.updateCategory(category);
      // 刷新所有分类列表
      await _fetchAllCategories();
      await _fetchExpenseCategories();
      await _fetchIncomeCategories();
      _setError(null);
      return true;
    } catch (e) {
      _setError('更新分类失败：$e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 删除分类
  Future<bool> deleteCategory(int id) async {
    _setLoading(true);

    try {
      await _categoryService.deleteCategory(id);
      // 刷新所有分类列表
      await _fetchAllCategories();
      await _fetchExpenseCategories();
      await _fetchIncomeCategories();
      _setError(null);
      return true;
    } catch (e) {
      _setError('删除分类失败：$e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 查找分类，如果不存在则创建新分类并返回ID
  Future<int?> findOrCreateCategory(
    String name,
    String type,
    String icon,
  ) async {
    // 先检查是否已存在相同名称的分类
    List<Category> categories =
        type == '支出' ? _expenseCategories : _incomeCategories;

    // 查找已有分类
    try {
      Category existingCategory = categories.firstWhere((c) => c.name == name);
      // 如果找到已有分类，直接返回ID
      return existingCategory.id;
    } catch (e) {
      // 如果抛出异常，说明分类不存在，需要创建
      // 根据类型为分类选择默认颜色
      String defaultColor;
      if (type == '支出') {
        // 为支出分类选择一个默认颜色
        defaultColor = "FF5252"; // 红色
      } else {
        // 为收入分类选择一个默认颜色
        defaultColor = "4CAF50"; // 绿色
      }

      final newCategory = Category(
        name: name,
        type: type,
        icon: icon,
        color: defaultColor,
      );

      final success = await addCategory(newCategory);
      if (success) {
        // 创建成功后，重新获取分类列表查找新分类的ID
        await initCategories();

        // 再次尝试查找
        categories = type == '支出' ? _expenseCategories : _incomeCategories;
        try {
          final createdCategory = categories.firstWhere((c) => c.name == name);
          return createdCategory.id;
        } catch (e) {
          print('创建分类后仍未找到该分类: $name');
          return null;
        }
      } else {
        print('创建分类失败: $name');
        return null;
      }
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }
}
