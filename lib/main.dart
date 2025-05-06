import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'constants/theme.dart';
import 'providers/account_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/category_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'providers/user_provider.dart';
import 'providers/financial_goal_provider.dart';
import 'providers/reminder_provider.dart';
import 'screens/home_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/account_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/budget_screen.dart';
import 'widgets/bottom_navigation.dart';
import 'services/database_service.dart';
import 'database/database_helper.dart';
import 'services/notification_service.dart';

// 定义全局导航键，用于在Provider中访问context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 确保Flutter引擎初始化

  // 初始化数据库
  await DatabaseHelper.instance.initDatabase();

  // 初始化数据库服务
  final dbService = DatabaseService();
  await dbService.database;

  // 初始化通知服务和恢复提醒，添加try-catch处理可能的异常
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.restoreReminders();
  } catch (e) {
    print('通知服务初始化失败：$e');
    // 捕获异常但继续运行应用
  }

  // 运行应用
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => FinancialGoalProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: languageProvider.getText('appTitle'),
            theme: AppTheme.createLightTheme(themeProvider.themeColor),
            darkTheme: AppTheme.createDarkTheme(themeProvider.themeColor),
            themeMode: themeProvider.themeMode,
            locale: languageProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('zh'), Locale('en')],
            home: const MainScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // 定义应用的主要页面
  final List<Widget> _pages = const [
    HomeScreen(), // 首页 - 索引0
    StatisticsScreen(), // 统计 - 索引1
    // 添加按钮没有对应页面（它会打开一个新页面）
    AccountScreen(), // 账户 - 索引2 (导航索引3)
    ProfileScreen(), // 我的 - 索引3 (导航索引4)
  ];

  @override
  void initState() {
    super.initState();
    // 初始化数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );
      final budgetProvider = Provider.of<BudgetProvider>(
        context,
        listen: false,
      );
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      accountProvider.initAccounts();
      transactionProvider.initData();
      categoryProvider.initCategories();
      budgetProvider.initBudgets();
      userProvider.initialize();

      // 添加一个延迟操作，确保所有数据都已加载完成后再次同步所有数据
      Future.delayed(const Duration(seconds: 2), () {
        syncAllData(context);
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      // 页面索引转换为导航栏索引
      _currentIndex = index >= 2 ? index + 1 : index;
    });
  }

  void _onTabTapped(int index) {
    // 如果是添加按钮（索引2），启动添加交易页面
    if (index == 2) {
      // 不改变当前选中的导航项
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
      );
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    // 导航栏索引转换为页面索引
    int pageIndex = index > 2 ? index - 1 : index;

    // 切换到对应页面
    _pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // 打开预算管理页面
  void _openBudgetScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const BudgetScreen()));
  }

  // 全数据同步函数，用于确保所有数据一致性
  void syncAllData(BuildContext context) async {
    try {
      final accountProvider = Provider.of<AccountProvider>(
        context,
        listen: false,
      );
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );

      print('开始全面同步数据...');
      // 先强制同步账户余额
      await accountProvider.accountService.syncAccountBalances();
      // 再刷新账户提供者中的数据
      await accountProvider.syncData();
      // 刷新交易数据
      await transactionProvider.initData();

      print('所有数据同步完成！');
    } catch (e) {
      print('同步数据时出错: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(), // 禁用滑动翻页，只通过底部导航切换
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
