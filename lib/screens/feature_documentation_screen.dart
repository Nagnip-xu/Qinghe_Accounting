import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FeatureDocumentationScreen extends StatefulWidget {
  final String featureId;

  const FeatureDocumentationScreen({super.key, required this.featureId});

  @override
  State<FeatureDocumentationScreen> createState() =>
      _FeatureDocumentationScreenState();
}

class _FeatureDocumentationScreenState
    extends State<FeatureDocumentationScreen> {
  late String _title;
  late List<DocumentationSection> _sections;

  @override
  void initState() {
    super.initState();
    _loadDocumentation();
  }

  void _loadDocumentation() {
    switch (widget.featureId) {
      case 'category_budget':
        _title = '分类预算功能说明';
        _sections = _getCategoryBudgetSections();
        break;
      case 'monthly_budget':
        _title = '月度预算功能说明';
        _sections = _getMonthlyBudgetSections();
        break;
      case 'transaction_entry':
        _title = '记账功能使用指南';
        _sections = _getTransactionEntrySections();
        break;
      case 'statistics_analysis':
        _title = '统计分析功能说明';
        _sections = _getStatisticsAnalysisSections();
        break;
      case 'bill_recurring':
        _title = '周期账单设置指南';
        _sections = _getBillRecurringSections();
        break;
      case 'cloud_sync':
        _title = '云同步功能说明';
        _sections = _getCloudSyncSections();
        break;
      default:
        _title = '功能说明';
        _sections = [
          DocumentationSection(
            title: '功能未找到',
            content: '抱歉，未找到该功能的文档说明。',
            icon: Icons.help_outline,
          ),
        ];
    }
  }

  List<DocumentationSection> _getCategoryBudgetSections() {
    return [
      DocumentationSection(
        title: '什么是分类预算？',
        content:
            '分类预算功能允许您为不同支出类别（如餐饮、交通、购物等）设定单独的预算金额，'
            '帮助您更精细地控制各类消费，合理分配资金，避免某一类别超支。',
        icon: Icons.category,
      ),
      DocumentationSection(
        title: '如何创建分类预算',
        content:
            '1. 进入"预算管理"页面\n'
            '2. 在"分类预算"部分，点击"添加"按钮\n'
            '3. 在弹出的对话框中，选择一个消费类别\n'
            '4. 输入该类别的预算金额\n'
            '5. 点击"确定"保存分类预算',
        icon: Icons.add_circle_outline,
      ),
      DocumentationSection(
        title: '如何编辑或删除分类预算',
        content:
            '1. 在"预算管理"页面，点击需要修改的分类预算卡片\n'
            '2. 在弹出的对话框中，您可以修改预算金额\n'
            '3. 点击"保存"更新预算信息\n'
            '4. 如需删除该预算，点击对话框底部的"删除"按钮',
        icon: Icons.edit,
      ),
      DocumentationSection(
        title: '预算使用进度说明',
        content:
            '- 分类预算卡片显示该类别的预算使用进度\n'
            '- 进度条颜色表示预算使用状态：\n'
            '  • 绿色：使用率低于80%\n'
            '  • 橙色：使用率介于80%-100%\n'
            '  • 红色：已超出预算\n'
            '- 每个预算卡片显示：总预算、已使用金额、剩余金额及使用百分比',
        icon: Icons.show_chart,
      ),
      DocumentationSection(
        title: '预算周期',
        content:
            '分类预算默认按月度计算，每月1日自动重置。您设置的预算金额将应用于当前月份，'
            '次月将保持相同的预算设置，但使用进度会重新计算。',
        icon: Icons.date_range,
      ),
      DocumentationSection(
        title: '预算分析与优化',
        content:
            '- 定期查看分类预算使用情况，分析消费模式\n'
            '- 对频繁超支的类别，考虑增加预算或减少相关开支\n'
            '- 对长期剩余较多的类别，可适当减少预算，将资金分配到更需要的地方\n'
            '- 结合统计分析页面的图表，更全面了解您的消费习惯',
        icon: Icons.analytics,
      ),
      DocumentationSection(
        title: '与总预算的关系',
        content:
            '分类预算与月度总预算相互独立。月度总预算反映您当月计划总开支，'
            '而分类预算则细化到各个消费类别。两者共同帮助您实现更精确的财务规划与控制。',
        icon: Icons.account_balance_wallet,
      ),
      DocumentationSection(
        title: '常见问题解答',
        content:
            'Q: 能否将未使用的预算结转到下月？\n'
            'A: 目前系统暂不支持预算结转功能，每月预算独立计算。\n\n'
            'Q: 预算提醒功能如何设置？\n'
            'A: 在"账单提醒"功能中，您可以设置预算用量提醒，当某类别预算使用超过阈值时收到通知。\n\n'
            'Q: 如何查看历史月份的预算完成情况？\n'
            'A: 在预算管理页面顶部，可以切换查看不同月份的预算使用情况。',
        icon: Icons.help_outline,
      ),
    ];
  }

  List<DocumentationSection> _getMonthlyBudgetSections() {
    return [
      DocumentationSection(
        title: '什么是月度总预算？',
        content:
            '月度总预算是您对整个月计划花费的总金额限制，帮助您控制总体支出，避免超支。'
            '设置合理的月度总预算是良好财务规划的第一步。',
        icon: Icons.account_balance_wallet,
      ),
      DocumentationSection(
        title: '如何设置月度总预算',
        content:
            '1. 进入"预算管理"页面\n'
            '2. 在上方的总预算卡片中，点击"编辑"按钮\n'
            '3. 在弹出的对话框中，输入您计划的月度预算金额\n'
            '4. 点击"保存"按钮确认设置',
        icon: Icons.edit,
      ),
      DocumentationSection(
        title: '预算使用进度说明',
        content:
            '- 月度总预算卡片显示当月预算使用进度\n'
            '- 进度条颜色表示预算使用状态：\n'
            '  • 蓝色：使用率低于80%\n'
            '  • 橙色：使用率介于80%-100%\n'
            '  • 红色：已超出预算\n'
            '- 卡片显示：总预算、已使用金额、剩余金额及使用进度百分比',
        icon: Icons.show_chart,
      ),
      DocumentationSection(
        title: '与分类预算的关系',
        content:
            '月度总预算与分类预算是相互独立的功能。总预算关注的是您当月的总体支出情况，'
            '而分类预算则帮助您控制具体消费类别的支出。二者配合使用，能让您的财务管理更加精细和系统化。',
        icon: Icons.compare_arrows,
      ),
      DocumentationSection(
        title: '预算调整建议',
        content:
            '- 新用户建议从实际支出记录开始，了解自己的消费模式后再设置预算\n'
            '- 设置预算时应考虑实际收入水平，通常建议预算不超过月收入的80%\n'
            '- 定期审视预算使用情况，适当调整不合理的预算设置\n'
            '- 特殊月份(如节假日、旅行)可适当调高预算',
        icon: Icons.lightbulb_outline,
      ),
      DocumentationSection(
        title: '常见问题解答',
        content:
            'Q: 月度预算会自动重置吗？\n'
            'A: 是的，每个月初系统会自动使用上月设置的预算金额作为新月份的预算。\n\n'
            'Q: 能否设置不同月份的预算金额？\n'
            'A: 目前系统会沿用上月的预算设置，您可以在每月初根据需要手动修改。\n\n'
            'Q: 预算超支后会有提醒吗？\n'
            'A: 如果您开启了预算提醒功能，当预算使用超过80%或100%时，系统会发送通知提醒。',
        icon: Icons.help_outline,
      ),
    ];
  }

  List<DocumentationSection> _getTransactionEntrySections() {
    return [
      DocumentationSection(
        title: '快速记账',
        content:
            '青禾记账支持多种快捷记账方式：\n\n'
            '1. 主页面"+"按钮：点击首页右下角的加号按钮，直接进入记账界面\n'
            '2. 手势记账：在主界面向上滑动，快速唤起记账页面\n'
            '3. 语音记账：点击记账界面的麦克风图标，说出"买菜花了30元"等语句\n'
            '4. 扫描记账：支持扫描发票自动识别金额、类别和日期',
        icon: Icons.flash_on,
      ),
      DocumentationSection(
        title: '账单分类',
        content:
            '青禾记账提供多级分类系统：\n\n'
            '1. 收入/支出：记账时首先选择交易类型\n'
            '2. 主分类：如餐饮、交通、购物等大类\n'
            '3. 子分类：每个主分类下有更详细的子分类\n'
            '4. 自定义分类：可在"设置-分类管理"中添加、编辑或删除分类\n\n'
            '合理使用分类能让您的财务数据更有条理，便于后期分析。',
        icon: Icons.category,
      ),
      DocumentationSection(
        title: '添加详细信息',
        content:
            '记账时可添加以下详细信息：\n\n'
            '1. 金额：必填项，支持小数点和快速计算\n'
            '2. 日期和时间：默认为当前，可修改为过去或未来日期\n'
            '3. 账户：选择资金来源或去向的账户\n'
            '4. 备注：记录交易的额外信息\n'
            '5. 图片：最多可添加3张图片（如发票、收据）\n'
            '6. 位置：可选择添加消费地点\n'
            '7. 标签：为交易添加自定义标签，便于筛选',
        icon: Icons.edit_note,
      ),
      DocumentationSection(
        title: '账单编辑与删除',
        content:
            '如何管理已创建的账单：\n\n'
            '1. 编辑账单：在账单列表中点击具体账单，进入详情后点击编辑图标\n'
            '2. 删除账单：在账单详情页面点击右上角菜单，选择"删除"\n'
            '3. 批量操作：在账单列表页长按任意账单，进入多选模式，可批量删除\n'
            '4. 恢复删除：最近删除的账单可在"设置-回收站"中恢复',
        icon: Icons.edit,
      ),
      DocumentationSection(
        title: '账单搜索与筛选',
        content:
            '青禾记账提供强大的账单查找功能：\n\n'
            '1. 搜索：点击账单页顶部搜索框，可按关键词、金额范围搜索\n'
            '2. 时间筛选：可按日、周、月、年、自定义时间段筛选\n'
            '3. 类别筛选：选择特定收支类别查看相关账单\n'
            '4. 账户筛选：查看特定账户的收支明细\n'
            '5. 标签筛选：通过自定义标签快速找到相关账单',
        icon: Icons.search,
      ),
      DocumentationSection(
        title: '多币种记账',
        content:
            '如果您有跨境消费需求，可以使用多币种记账功能：\n\n'
            '1. 启用方式：在"设置-通用设置"中开启"多币种支持"\n'
            '2. 添加币种：在"设置-币种管理"中添加常用币种\n'
            '3. 记账时选择：记账时可选择不同币种\n'
            '4. 汇率转换：系统会根据当日汇率自动换算成本币\n'
            '5. 汇率设置：可以使用自动更新汇率或手动设置',
        icon: Icons.currency_exchange,
      ),
      DocumentationSection(
        title: '问题与技巧',
        content:
            'Q: 如何快速输入重复性质的账单？\n'
            'A: 可以使用复制功能或设置周期账单。在账单详情页，点击"更多"-"复制"创建相似账单。\n\n'
            'Q: 如何处理多人同时付款的情况？\n'
            'A: 可以使用AA记账功能，在记账时勾选"AA收款"，设置总金额和您支付的部分。\n\n'
            'Q: 记账数据会自动备份吗？\n'
            'A: 是的，应用默认每周自动备份。您也可以在"设置-数据备份"手动备份或调整备份周期。',
        icon: Icons.help_outline,
      ),
    ];
  }

  List<DocumentationSection> _getStatisticsAnalysisSections() {
    return [
      DocumentationSection(
        title: '统计概览',
        content:
            '青禾记账提供全面的财务统计功能，帮助您清晰了解自己的收支情况：\n\n'
            '1. 收支总览：展示选定时间段内的总收入、总支出和结余\n'
            '2. 趋势分析：通过折线图直观展示收支变化趋势\n'
            '3. 类别分布：使用饼图展示不同类别的支出占比\n'
            '4. 预算完成度：各分类预算的使用进度和剩余额度',
        icon: Icons.bar_chart,
      ),
      DocumentationSection(
        title: '图表类型与使用',
        content:
            '青禾记账提供多种图表供您分析财务数据：\n\n'
            '1. 饼图：展示支出在各类别间的分布比例\n'
            '2. 柱状图：比较不同时间段或类别的收支金额\n'
            '3. 折线图：展示一段时间内收支的变化趋势\n'
            '4. 环比图：对比本月与上月、本年与去年的收支情况\n\n'
            '点击图表可查看更详细信息，长按图表可保存为图片。',
        icon: Icons.pie_chart,
      ),
      DocumentationSection(
        title: '自定义分析维度',
        content:
            '除了预设的分析维度外，您还可以自定义分析视角：\n\n'
            '1. 时间维度：按日、周、月、季度、年查看统计数据\n'
            '2. 类别维度：选择特定类别或自定义类别组合进行分析\n'
            '3. 账户维度：分析不同账户的收支情况和余额变化\n'
            '4. 标签维度：根据自定义标签分析特定消费行为\n'
            '5. 商家维度：分析在特定商家的消费频率和金额',
        icon: Icons.view_module,
      ),
      DocumentationSection(
        title: '数据导出',
        content:
            '您可以导出统计数据用于进一步分析或备份：\n\n'
            '1. 导出格式：支持Excel、CSV、PDF格式\n'
            '2. 导出范围：可选择导出图表、原始数据或分析报告\n'
            '3. 导出方式：\n'
            '   • 在统计页面点击右上角"更多"-"导出"\n'
            '   • 选择所需的时间范围和数据类型\n'
            '   • 选择导出格式后点击"导出"按钮\n'
            '4. 导出文件可通过邮件、云盘等方式分享',
        icon: Icons.download,
      ),
      DocumentationSection(
        title: '消费洞察',
        content:
            '青禾记账基于您的消费数据提供个性化的财务洞察：\n\n'
            '1. 消费习惯分析：识别您的高频消费场景和时间\n'
            '2. 异常支出提醒：标记出与平时消费模式不同的大额支出\n'
            '3. 节省建议：基于历史数据，推荐可能的节省空间\n'
            '4. 财务健康评分：综合评估您的收支、储蓄和债务情况\n\n'
            '消费洞察功能需要积累足够的记账数据才能提供准确建议。',
        icon: Icons.lightbulb,
      ),
      DocumentationSection(
        title: '常见问题',
        content:
            'Q: 为什么某些数据在不同图表中显示的金额有差异？\n'
            'A: 不同图表可能采用不同的统计口径，如收付实现制vs权责发生制，可在设置中统一统计口径。\n\n'
            'Q: 如何自定义统计报表？\n'
            'A: 在统计页面点击右上角"自定义报表"，选择所需的图表类型、数据维度和显示方式。\n\n'
            'Q: 能否设置定期接收财务分析报告？\n'
            'A: 可以。在"设置-通知管理"中开启"周期报告"功能，可选择每周或每月接收统计概要。',
        icon: Icons.help_outline,
      ),
    ];
  }

  List<DocumentationSection> _getBillRecurringSections() {
    return [
      DocumentationSection(
        title: '什么是周期账单',
        content:
            '周期账单是指按固定时间间隔重复发生的收支，如：\n\n'
            '• 每月的房租、物业费\n'
            '• 固定发薪日的工资收入\n'
            '• 每季度的会员费\n'
            '• 每年的保险费\n\n'
            '设置周期账单后，系统会在对应日期自动记录这些交易，减轻您的记账负担，避免遗漏重要账单。',
        icon: Icons.repeat,
      ),
      DocumentationSection(
        title: '创建周期账单',
        content:
            '创建周期账单的方法：\n\n'
            '1. 方法一：记账时设置\n'
            '   • 在普通记账界面填写账单信息\n'
            '   • 勾选底部"设为周期账单"\n'
            '   • 设置重复周期和结束条件\n\n'
            '2. 方法二：通过周期账单管理\n'
            '   • 进入"我的-周期账单"\n'
            '   • 点击右上角"+"按钮\n'
            '   • 填写账单信息并设置周期',
        icon: Icons.add_circle_outline,
      ),
      DocumentationSection(
        title: '周期设置选项',
        content:
            '周期账单支持多种重复模式：\n\n'
            '1. 按天重复：每隔X天重复一次\n'
            '2. 按周重复：每周的特定星期几（可多选）\n'
            '3. 按月重复：\n'
            '   • 每月X日（如每月15日）\n'
            '   • 每月第X个星期几（如每月第一个星期一）\n'
            '   • 每月最后一天\n'
            '4. 按年重复：每年的特定日期\n'
            '5. 自定义周期：设置特定的重复间隔',
        icon: Icons.date_range,
      ),
      DocumentationSection(
        title: '周期账单管理',
        content:
            '管理已创建的周期账单：\n\n'
            '1. 查看：在"我的-周期账单"页面可查看所有已设置的周期账单\n'
            '2. 编辑：点击特定周期账单，可修改金额、分类、周期等信息\n'
            '3. 暂停：可临时暂停某个周期账单的自动记录\n'
            '4. 删除：长按周期账单或在详情页选择删除\n'
            '5. 过滤：可按类型、金额范围等筛选周期账单',
        icon: Icons.settings,
      ),
      DocumentationSection(
        title: '提醒设置',
        content:
            '周期账单支持多种提醒方式：\n\n'
            '1. 自动记账：到期自动记录，无需手动确认\n'
            '2. 提醒确认：到期提醒您确认后再记录\n'
            '3. 提前提醒：可设置提前1天、3天或自定义天数提醒\n'
            '4. 提醒方式：应用内通知、系统通知\n\n'
            '提醒设置在创建周期账单时可配置，也可在账单详情中修改。',
        icon: Icons.notifications,
      ),
      DocumentationSection(
        title: '调整与特例',
        content:
            '灵活处理周期账单的特殊情况：\n\n'
            '1. 一次性调整：对特定一次的周期账单进行金额或日期调整\n'
            '2. 跳过某次：临时跳过某一次账单而不影响后续周期\n'
            '3. 永久修改：从当前开始调整所有未来的账单\n'
            '4. 分期处理：对大额周期账单设置分期记录\n'
            '5. 提前结束：设置周期账单的结束日期或结束次数',
        icon: Icons.tune,
      ),
      DocumentationSection(
        title: '统计与分析',
        content:
            '周期账单的统计分析功能：\n\n'
            '1. 周期账单概览：查看未来一段时间的周期账单总额\n'
            '2. 月度预测：基于周期账单预测未来月份的收支情况\n'
            '3. 类别分布：分析周期账单在各个类别的分布\n'
            '4. 趋势分析：了解周期账单金额随时间的变化趋势\n'
            '5. 优化建议：发现可能的成本节约机会',
        icon: Icons.analytics,
      ),
    ];
  }

  List<DocumentationSection> _getCloudSyncSections() {
    return [
      DocumentationSection(
        title: '云同步功能介绍',
        content:
            '青禾记账的云同步功能可以：\n\n'
            '1. 多设备数据同步：在手机、平板等多个设备间同步账单数据\n'
            '2. 数据备份：将账单数据安全备份到云端，防止设备丢失导致数据丢失\n'
            '3. 历史版本：支持恢复之前的数据版本\n'
            '4. 账户共享：家庭成员间共享账本（需开启家庭共享功能）',
        icon: Icons.cloud_sync,
      ),
      DocumentationSection(
        title: '开启云同步',
        content:
            '如何启用云同步功能：\n\n'
            '1. 注册/登录账户：必须创建青禾记账账户才能使用云同步\n'
            '2. 开启同步：\n'
            '   • 进入"设置-云同步设置"\n'
            '   • 开启"自动同步"开关\n'
            '   • 选择需要同步的数据类型\n'
            '3. 首次同步：系统会自动合并本地数据和云端数据',
        icon: Icons.toggle_on,
      ),
      DocumentationSection(
        title: '同步设置',
        content:
            '云同步的详细设置选项：\n\n'
            '1. 同步频率：\n'
            '   • 实时同步：数据变更立即上传\n'
            '   • 定时同步：每天、每周定时同步\n'
            '   • 手动同步：仅在手动触发时同步\n'
            '2. 同步范围：\n'
            '   • 账单数据：收支记录\n'
            '   • 预算设置：预算配置信息\n'
            '   • 分类设置：自定义分类\n'
            '   • 应用设置：主题、显示偏好等',
        icon: Icons.settings_applications,
      ),
      DocumentationSection(
        title: '数据安全',
        content:
            '青禾记账在云同步过程中采取多重安全措施：\n\n'
            '1. 传输加密：使用TLS加密所有数据传输\n'
            '2. 存储加密：云端存储的数据采用AES-256加密\n'
            '3. 密码保护：可设置独立的同步密码\n'
            '4. 双重验证：支持开启双因素认证增强账户安全\n'
            '5. 定期安全审计：系统定期检查数据访问情况',
        icon: Icons.security,
      ),
      DocumentationSection(
        title: '云同步问题排查',
        content:
            '当云同步出现问题时，可尝试以下解决方法：\n\n'
            '1. 同步失败：\n'
            '   • 检查网络连接\n'
            '   • 确认账户登录状态\n'
            '   • 尝试手动触发同步\n'
            '   • 重启应用后再试\n'
            '2. 数据冲突：\n'
            '   • 查看冲突详情\n'
            '   • 选择保留本地版本或云端版本\n'
            '   • 手动合并数据\n'
            '3. 同步过慢：\n'
            '   • 使用WiFi网络\n'
            '   • 减少同步数据范围\n'
            '   • 增加同步间隔',
        icon: Icons.build,
      ),
      DocumentationSection(
        title: '数据恢复',
        content:
            '如何从云端恢复数据：\n\n'
            '1. 数据版本恢复：\n'
            '   • 进入"设置-云同步-同步历史"\n'
            '   • 选择要恢复的历史版本\n'
            '   • 选择"恢复"或"合并"操作\n'
            '2. 新设备恢复：\n'
            '   • 在新设备上安装应用并登录账户\n'
            '   • 系统会提示是否恢复云端数据\n'
            '   • 选择"恢复"并等待完成\n'
            '3. 选择性恢复：可选择只恢复部分数据类型',
        icon: Icons.restore,
      ),
      DocumentationSection(
        title: '云存储空间',
        content:
            '关于云存储空间的使用：\n\n'
            '1. 免费额度：每个账户有200MB免费云存储空间\n'
            '2. 空间管理：\n'
            '   • 在"设置-云同步-存储空间"查看使用情况\n'
            '   • 可选择清理旧版本数据释放空间\n'
            '   • 可压缩图片附件减少占用\n'
            '3. 存储升级：支持购买额外存储空间\n'
            '4. 数据分级：可设置不同重要程度数据的保留策略',
        icon: Icons.cloud_queue,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor:
            isDarkMode ? AppColors.darkBackground : AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _title,
          style: TextStyle(
            color:
                isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _sections.length,
        itemBuilder: (context, index) {
          return _buildSectionCard(_sections[index], isDarkMode);
        },
      ),
    );
  }

  Widget _buildSectionCard(DocumentationSection section, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        iconColor: AppColors.primary,
        collapsedIconColor: isDarkMode ? Colors.white70 : Colors.black54,
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 4.0,
        ),
        title: Row(
          children: [
            Icon(section.icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                section.title,
                style: TextStyle(
                  color:
                      isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
            child: Text(
              section.content,
              style: TextStyle(
                color:
                    isDarkMode
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DocumentationSection {
  final String title;
  final String content;
  final IconData icon;

  DocumentationSection({
    required this.title,
    required this.content,
    required this.icon,
  });
}
