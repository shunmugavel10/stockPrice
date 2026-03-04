import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/platform_adaptive.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final hPad = context.horizontalPadding;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: ResponsiveContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile section
              _buildSectionTitle(context, 'Profile'),
              _buildProfileCard(context),
              const SizedBox(height: 8),
              // Tablet: appearance and about side by side
              if (context.isTablet || context.isDesktop)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(context, 'Appearance'),
                            _buildThemeCard(context, ref, themeMode),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(context, 'About'),
                            _buildAboutCard(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                _buildSectionTitle(context, 'Appearance'),
                _buildThemeCard(context, ref, themeMode),
                const SizedBox(height: 16),
                _buildSectionTitle(context, 'About'),
                _buildAboutCard(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final secondaryColor = context.isDarkMode
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return GlassmorphismCard(
      child: Column(
        children: [
          // Avatar + Name + Email header
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'AJ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alex Johnson',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'alex.johnson@greeninvest.com',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: secondaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          // Detail rows
          _ProfileRow(
            icon: isCupertino
                ? CupertinoIcons.phone_fill
                : Icons.phone_rounded,
            label: 'Phone',
            value: '+1 (555) 987-6543',
          ),
          const SizedBox(height: 12),
          _ProfileRow(
            icon: isCupertino
                ? CupertinoIcons.calendar
                : Icons.cake_rounded,
            label: 'Date of Birth',
            value: 'March 15, 1992',
          ),
          const Divider(height: 24),
          _ProfileRow(
            icon: isCupertino
                ? CupertinoIcons.building_2_fill
                : Icons.account_balance_rounded,
            label: 'Bank',
            value: 'Chase Bank',
          ),
          const SizedBox(height: 12),
          _ProfileRow(
            icon: isCupertino
                ? CupertinoIcons.creditcard_fill
                : Icons.credit_card_rounded,
            label: 'Account',
            value: '**** **** **** 4829',
          ),
          const SizedBox(height: 12),
          _ProfileRow(
            icon: isCupertino
                ? CupertinoIcons.arrow_right_arrow_left
                : Icons.swap_horiz_rounded,
            label: 'Routing',
            value: '021000021',
          ),
          const SizedBox(height: 12),
          _ProfileRow(
            icon: isCupertino
                ? CupertinoIcons.doc_text_fill
                : Icons.badge_rounded,
            label: 'PAN',
            value: 'ABCPJ1234K',
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(
      BuildContext context, WidgetRef ref, ThemeMode themeMode) {
    return GlassmorphismCard(
      child: Column(
        children: [
          _ThemeOption(
            title: 'System Default',
            icon: isCupertino
                ? CupertinoIcons.brightness
                : Icons.brightness_auto_rounded,
            isSelected: themeMode == ThemeMode.system,
            onTap: () => ref
                .read(themeModeProvider.notifier)
                .setThemeMode(ThemeMode.system),
          ),
          const Divider(height: 1),
          _ThemeOption(
            title: 'Light Mode',
            icon: isCupertino
                ? CupertinoIcons.sun_max_fill
                : Icons.light_mode_rounded,
            isSelected: themeMode == ThemeMode.light,
            onTap: () => ref
                .read(themeModeProvider.notifier)
                .setThemeMode(ThemeMode.light),
          ),
          const Divider(height: 1),
          _ThemeOption(
            title: 'Dark Mode',
            icon: isCupertino
                ? CupertinoIcons.moon_fill
                : Icons.dark_mode_rounded,
            isSelected: themeMode == ThemeMode.dark,
            onTap: () => ref
                .read(themeModeProvider.notifier)
                .setThemeMode(ThemeMode.dark),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return GlassmorphismCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco_rounded, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      AppConstants.appTagline,
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Track your investments while monitoring the environmental impact. '
            'GreenInvest helps you build a sustainable portfolio by displaying '
            'ESG scores and CO₂ emissions for your holdings.',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.isDarkMode
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Version 1.0.0',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.isDarkMode
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title,
        style: context.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final secondaryColor = context.isDarkMode
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Row(
      children: [
        Icon(icon, size: 18, color: secondaryColor),
        const SizedBox(width: 12),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: secondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? AppColors.primary : null),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primary : null,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                isCupertino
                    ? CupertinoIcons.checkmark_alt
                    : Icons.check_rounded,
                size: 20,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}
