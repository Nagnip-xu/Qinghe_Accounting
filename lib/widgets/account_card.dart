import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/account.dart';
import '../utils/formatter.dart';

class AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback? onTap;

  const AccountCard({super.key, required this.account, this.onTap});

  @override
  Widget build(BuildContext context) {
    // 获取账户图标
    IconData accountIcon = FontAwesomeIcons.wallet;
    Color accountIconColor = Theme.of(context).primaryColor;

    // 解析颜色字符串
    if (account.color != null && account.color!.isNotEmpty) {
      try {
        accountIconColor = Color(int.parse(account.color!));
      } catch (e) {
        // 保持默认颜色
      }
    }

    // 解析图标字符串
    switch (account.icon) {
      case 'wallet':
        accountIcon = FontAwesomeIcons.wallet;
        break;
      case 'credit-card':
        accountIcon = FontAwesomeIcons.creditCard;
        break;
      case 'cc-visa':
        accountIcon = FontAwesomeIcons.ccVisa;
        break;
      case 'mobile-screen':
        accountIcon = FontAwesomeIcons.mobileScreen;
        break;
      case 'money-bill-trend-up':
        accountIcon = FontAwesomeIcons.moneyBillTrendUp;
        break;
      default:
        accountIcon = FontAwesomeIcons.landmark;
        break;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // 账户图标
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accountIconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: FaIcon(accountIcon, color: accountIconColor, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              // 账户信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          account.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (account.isDebt)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6.0,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: const Text(
                                '负债',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      account.type,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // 余额
              Text(
                CurrencyFormatter.format(account.balance),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color:
                      account.balance < 0
                          ? Colors.red
                          : Theme.of(context).primaryColor,
                ),
              ),
              // 更多按钮
              const SizedBox(width: 8),
              const Icon(Icons.more_horiz, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
