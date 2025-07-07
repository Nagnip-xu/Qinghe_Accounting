import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart' as sql;
import '../constants/colors.dart';
import '../models/transaction.dart';
import '../providers/theme_provider.dart';
import '../services/database_service.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String categoryName;
  final Color categoryColor;
  final IconData categoryIcon;
  final String initialMonth; // 格式: YYYY-MM

  const CategoryDetailScreen({
    super.key,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIcon,
    required this.initialMonth,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  late String _currentMonth;
  bool _isLoading = true;
  double _totalAmount = 0.0;
  double _avgAmount = 0.0;
  int _transactionCount = 0;
  List<Transaction> _transactions = [];
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.initialMonth;
    _loadCategoryData();
  }

  // 加载分类数据
  Future<void> _loadCategoryData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 获取该分类在当前月份的所有交易
      await _fetchCategoryTransactions();

      // 计算总额、平均值等统计数据
      _calculateStatistics();
    } catch (e) {
      debugPrint('加载分类数据错误: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 获取分类交易
  Future<void> _fetchCategoryTransactions() async {
    final sql.Database db = await _databaseService.database;

    // 查询该分类的所有交易
    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT * FROM transactions
      WHERE categoryName = ? AND date LIKE '$_currentMonth-%'
      ORDER BY date DESC
    ''',
      [widget.categoryName],
    );

    // 解析交易数据
    _transactions = results.map((row) => Transaction.fromMap(row)).toList();
  }

  // 计算统计数据
  void _calculateStatistics() {
    if (_transactions.isEmpty) {
      _totalAmount = 0.0;
      _avgAmount = 0.0;
      _transactionCount = 0;
      return;
    }

    _transactionCount = _transactions.length;
    _totalAmount = _transactions.fold(0, (sum, item) => sum + item.amount);
    _avgAmount = _totalAmount / _transactionCount;
  }

  // 切换月份
  void _changeMonth(String newMonth) {
    setState(() {
      _currentMonth = newMonth;
    });
    _loadCategoryData();
  }

  // 构建上个月按钮
  void _gotoPreviousMonth() {
    // 解析当前年月
    int year = int.parse(_currentMonth.split('-')[0]);
    int month = int.parse(_currentMonth.split('-')[1]);

    // 计算上个月
    if (month == 1) {
      year--;
      month = 12;
    } else {
      month--;
    }

    // 格式化新月份
    String newMonth = '$year-${month.toString().padLeft(2, '0')}';
    _changeMonth(newMonth);
  }

  // 构建下个月按钮
  void _gotoNextMonth() {
    // 解析当前年月
    int year = int.parse(_currentMonth.split('-')[0]);
    int month = int.parse(_currentMonth.split('-')[1]);

    // 计算下个月
    if (month == 12) {
      year++;
      month = 1;
    } else {
      month++;
    }

    // 格式化新月份
    String newMonth = '$year-${month.toString().padLeft(2, '0')}';
    _changeMonth(newMonth);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeColor = themeProvider.themeColor;

    // 格式化展示月份
    final displayMonth = DateFormat.yMMMM(
      'zh_CN',
    ).format(DateTime.parse('$_currentMonth-01'));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.categoryColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.categoryIcon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              '${widget.categoryName}详情',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDarkMode ? Colors.white : Colors.black54,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 月份选择器
                      _buildMonthSelector(displayMonth, isDarkMode),
                      const SizedBox(height: 20),

                      // 统计卡片
                      _buildStatisticsCard(isDarkMode),
                      const SizedBox(height: 24),

                      // 交易列表标题
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 16,
                            color:
                                isDarkMode ? Colors.white70 : Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '交易记录',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 交易列表
                      _transactions.isEmpty
                          ? _buildEmptyState(isDarkMode)
                          : _buildTransactionList(isDarkMode),
                    ],
                  ),
                ),
              ),
    );
  }

  // 构建月份选择器
  Widget _buildMonthSelector(String displayMonth, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: isDarkMode ? Colors.white70 : Colors.black54,
              size: 20,
            ),
            onPressed: _gotoPreviousMonth,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              displayMonth,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: isDarkMode ? Colors.white70 : Colors.black54,
              size: 20,
            ),
            onPressed: _gotoNextMonth,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // 构建统计卡片
  Widget _buildStatisticsCard(bool isDarkMode) {
    final formatter = NumberFormat('#,##0.00', 'zh_CN');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: widget.categoryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            '${_currentMonth.split('-')[0]}年${_currentMonth.split('-')[1]}月统计',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // 总金额
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '总支出',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¥${formatter.format(_totalAmount)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: widget.categoryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 50,
                width: 1,
                color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '笔数',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_transactionCount',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 平均值
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '平均每笔',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¥${formatter.format(_avgAmount)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建空状态
  Widget _buildEmptyState(bool isDarkMode) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 48,
            color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无${widget.categoryName}类交易记录',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // 构建交易列表
  Widget _buildTransactionList(bool isDarkMode) {
    final formatter = NumberFormat('#,##0.00', 'zh_CN');

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _transactions.length,
      separatorBuilder:
          (context, index) => Divider(
            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            height: 1,
          ),
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        final dateStr = DateFormat('MM-dd HH:mm').format(transaction.date);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.categoryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.categoryIcon,
                color: widget.categoryColor,
                size: 24,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    transaction.note?.isNotEmpty == true
                        ? transaction.note!
                        : widget.categoryName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Text(
                  '¥${formatter.format(transaction.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.categoryColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            subtitle: Row(
              children: [
                Expanded(
                  child: Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ),
                // 支付方式
                if (transaction.accountName.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      transaction.accountName,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
