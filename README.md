# 清和记账 (Qinghe Accounting)

一款现代化、功能丰富的个人财务管理应用，基于Flutter框架开发，提供直观易用的记账体验和全面的财务分析功能。

## 项目概述

清和记账是一款专为个人财务管理设计的移动应用，提供简洁高效的记账功能，帮助用户轻松追踪日常收支、管理预算、分析消费习惯，实现更好的财务规划。应用采用Flutter框架开发，支持Android和iOS平台，提供现代化UI设计和流畅的用户体验。

## 功能特点

### 核心功能

- **记账管理**：轻松记录日常收入、支出和转账交易
- **多账户管理**：支持管理多种类型账户（现金、银行卡、信用卡等）
- **预算规划**：设置月度总预算和分类预算，实时跟踪预算使用情况
- **数据统计**：通过图表直观展示收支趋势和消费分类占比
- **分类管理**：自定义收支分类，灵活组织财务数据

### 其他功能

- **多语言支持**：支持中文和英文界面
- **深色/浅色主题**：根据系统设置或个人偏好切换主题
- **数据备份与恢复**：保护用户数据安全
- **财务目标**：设置并追踪个人财务目标
- **账单提醒**：设置定期账单提醒，避免逾期付款

## 技术栈

- **开发框架**：Flutter
- **编程语言**：Dart
- **状态管理**：Provider
- **本地存储**：SQLite (sqflite)
- **图表库**：fl_chart
- **国际化**：flutter_localizations
- **UI组件**：Material Design & Cupertino
- **图标库**：font_awesome_flutter
- **日期处理**：intl

## 界面预览

应用包含以下主要界面：

1. **首页**：展示资产概览和最近交易记录
2. **统计分析**：提供图表和数据分析功能
3. **添加记账**：快速记录新的交易
4. **预算管理**：设置和跟踪预算使用情况
5. **账户管理**：管理不同类型的账户
6. **个人设置**：用户个人信息和应用设置

### 应用截图

<div align="center">
  <div>
    <img src="website/images/shouye.jpg" alt="首页" width="200"/>
    <img src="website/images/tongji.jpg" alt="统计分析" width="200"/>
    <img src="website/images/tianjia.jpg" alt="添加记账" width="200"/>
  </div>
  <div>
    <img src="website/images/yusuan.jpg" alt="预算管理" width="200"/>
    <img src="website/images/zhanghu.jpg" alt="账户管理" width="200"/>
  </div>
</div>

## 项目结构

```
lib/
  ├── constants/        # 常量定义（颜色、主题、图标等）
  ├── database/         # 数据库相关代码
  ├── l10n/            # 国际化资源
  ├── models/          # 数据模型
  ├── providers/       # 状态管理
  ├── screens/         # 界面
  ├── services/        # 服务层（数据处理、业务逻辑）
  ├── utils/           # 工具类
  ├── widgets/         # 可复用组件
  └── main.dart        # 应用入口
```

## 安装与使用

### 环境要求

- Flutter SDK 3.0.0 或更高版本
- Dart SDK 2.17.0 或更高版本
- Android Studio / VS Code

### 安装步骤

1. 克隆项目仓库
   ```
   git clone https://github.com/yourusername/qinghe_accounting.git
   cd qinghe_accounting
   ```

2. 安装依赖
   ```
   flutter pub get
   ```

3. 运行应用
   ```
   flutter run
   ```

## 开发与贡献

欢迎贡献代码、报告问题或提出改进建议。请遵循以下步骤：

1. Fork 项目仓库
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 联系方式

如有任何问题或建议，请通过以下方式联系我们：

- 电子邮件：[1626814667@qq.com] 