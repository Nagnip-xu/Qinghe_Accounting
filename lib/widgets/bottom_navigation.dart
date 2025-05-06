import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../constants/colors.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDarkMode ? AppColors.darkCard : Colors.white,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor:
            isDarkMode ? AppColors.darkTextSecondary : Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: const FaIcon(FontAwesomeIcons.house, size: 20),
            label: l10n.home,
          ),
          BottomNavigationBarItem(
            icon: const FaIcon(FontAwesomeIcons.chartColumn, size: 20),
            label: l10n.statistics,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 40),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: const FaIcon(FontAwesomeIcons.wallet, size: 20),
            label: l10n.account,
          ),
          BottomNavigationBarItem(
            icon: const FaIcon(FontAwesomeIcons.user, size: 20),
            label: l10n.profile,
          ),
        ],
      ),
    );
  }
}
