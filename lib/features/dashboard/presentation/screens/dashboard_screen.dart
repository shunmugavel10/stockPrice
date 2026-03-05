import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/esg_helpers.dart';
import '../../../../core/utils/platform_adaptive.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/animated_counter.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_screen.dart';
import '../../../../shared/widgets/esg_badge.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../portfolio/domain/models/portfolio_summary.dart';
import '../../../portfolio/presentation/providers/portfolio_providers.dart';
import '../providers/theme_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(portfolioSummaryProvider);
    final hPad = context.horizontalPadding;

    return Scaffold(
      // Dashboard screen appbar 
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.eco_rounded, color: AppColors.primary, size: 28),
            const SizedBox(width: 8),
            Text(
              'GreenInvest',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        // IconButton to switch dark to light theme.
        actions: [
          IconButton(
            icon: Icon(
              isCupertino
                  ? (context.isDarkMode
                      ? CupertinoIcons.sun_max_fill
                      : CupertinoIcons.moon_fill)
                  : (context.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded),
            ),
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
        ],
      ),

      body: summaryAsync.when(
        // shimmer effect used while data loading
        loading: () => const ShimmerDashboard(),
        error: (err, _) => ErrorScreen(
          message: err.toString(),
          onRetry: () => ref.invalidate(portfolioSummaryProvider),
        ),
        data: (summary) {
          // if empty data screen displays this content
          if (summary.holdings.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.trending_up_rounded,
              title: 'No Holdings Yet',
              subtitle:
                  'Add stocks to your portfolio to see your green investment dashboard.',
              actionLabel: 'Add Stock',
              onAction: () => GoRouter.of(context).go('/search'),
            );
          }

          final content = ResponsiveContent(
            
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryHeader(context, summary, hPad),
                const SizedBox(height: 8),
                _buildStatCards(context, summary, hPad),
                const SizedBox(height: 16),
                // Tablet: charts side by side
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
                              _buildSectionTitle(context, 'Stock Allocation'),
                              _buildPieChart(context, summary),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle(context, 'CO₂ Impact'),
                              _buildCO2BarChart(context, summary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  _buildSectionTitle(context, 'Stock Allocation'),
                  _buildPieChart(context, summary),
                  const SizedBox(height: 16),
                  _buildSectionTitle(context, 'CO₂ Impact by Stock'),
                  _buildCO2BarChart(context, summary),
                ],
                const SizedBox(height: 16),
                _buildSectionTitle(context, 'Holdings'),
                _buildHoldingsList(context, summary),
              ],
            ),
          );

          return AdaptiveRefreshControl(
            onRefresh: () async {
              ref.invalidate(portfolioSummaryProvider);
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: content,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(
      BuildContext context, PortfolioSummary summary, double hPad) {
    return GlassmorphismCard(
      margin: EdgeInsets.fromLTRB(hPad, 8, hPad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Portfolio Value',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.isDarkMode
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              )),
          const SizedBox(height: 4),
          AnimatedCounter(
            value: summary.totalValue,
            formatter: (v) => v.toCurrency(),
            style: context.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                summary.totalProfitLoss >= 0
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 16,
                color: summary.totalProfitLoss >= 0
                    ? AppColors.success
                    : AppColors.error,
              ),
              const SizedBox(width: 4),
              Text(
                '${summary.totalProfitLoss >= 0 ? '+' : ''}${summary.totalProfitLoss.toCurrency()} (${summary.totalProfitLossPercent.toStringAsFixed(1)}%)',
                style: context.textTheme.bodySmall?.copyWith(
                  color: summary.totalProfitLoss >= 0
                      ? AppColors.success
                      : AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(
      BuildContext context, PortfolioSummary summary, double hPad) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Row(
        children: [
          Expanded(
            child: _StatMiniCard(
              icon: Icons.eco_rounded,
              label: 'Green Score',
              value: summary.greenScore.toStringAsFixed(0),
              suffix: '/100',
              color: EsgHelpers.scoreColor(summary.greenScore),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatMiniCard(
              icon: Icons.cloud_outlined,
              label: 'Total CO₂',
              value: summary.totalCO2.toStringAsFixed(1),
              suffix: ' t/yr',
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: context.horizontalPadding + 4, vertical: 4),
      child: Text(
        title,
        style: context.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildPieChart(BuildContext context, PortfolioSummary summary) {
    return GlassmorphismCard(
      child: SizedBox(
        height: context.chartHeight,
        child: Row(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: context.isTablet ? 44 : 36,
                  sections: summary.holdings.asMap().entries.map((entry) {
                    final i = entry.key;
                    final h = entry.value;
                    final pct = summary.totalValue > 0
                        ? (h.totalValue / summary.totalValue * 100)
                        : 0.0;
                    return PieChartSectionData(
                      color: AppColors.chartPalette[
                          i % AppColors.chartPalette.length],
                      value: h.totalValue,
                      title: '${pct.toStringAsFixed(0)}%',
                      radius: context.isTablet ? 60 : 50,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: summary.holdings.asMap().entries.map((entry) {
                  final i = entry.key;
                  final h = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.chartPalette[
                                i % AppColors.chartPalette.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            h.holding.symbol,
                            style: context.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCO2BarChart(BuildContext context, PortfolioSummary summary) {
    final maxCO2 = summary.holdings.fold<double>(
        0, (prev, h) => h.esg.co2Emission > prev ? h.esg.co2Emission : prev);

    return GlassmorphismCard(
      child: SizedBox(
        height: context.chartHeight - 20,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxCO2 * 1.2,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final h = summary.holdings[groupIndex];
                  return BarTooltipItem(
                    '${h.holding.symbol}\n${h.esg.co2Emission.toStringAsFixed(1)} t',
                    const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < summary.holdings.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          summary.holdings[index].holding.symbol,
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: summary.holdings.asMap().entries.map((entry) {
              final i = entry.key;
              final h = entry.value;
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: h.esg.co2Emission,
                    color: EsgHelpers.scoreColor(
                        100 - h.esg.co2Emission.clamp(0, 100)),
                    width: context.isTablet ? 28 : 20,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6)),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Holdings list — grid on tablet, list on mobile
  Widget _buildHoldingsList(BuildContext context, PortfolioSummary summary) {
    if (context.isTablet || context.isDesktop) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
        child: ResponsiveGrid(
          columns: context.gridColumns,
          children:
              summary.holdings.map((h) => _buildHoldingTile(context, h)).toList(),
        ),
      );
    }
    return Column(
      children:
          summary.holdings.map((h) => _buildHoldingTile(context, h)).toList(),
    );
  }

  Widget _buildHoldingTile(BuildContext context, EnrichedHolding h) {
    final isProfit = h.profitLoss >= 0;
    return GestureDetector(
      onTap: () => context.push('/stock-detail', extra: {
        'symbol': h.holding.symbol,
        'name': h.holding.name,
      }),
      child: GlassmorphismCard(
      child: Row(
        children: [
          // Symbol circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                h.holding.symbol.substring(
                    0, h.holding.symbol.length > 2 ? 2 : h.holding.symbol.length),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        h.holding.symbol,
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    EsgBadge(rating: h.esg.sustainabilityRating),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${h.holding.quantity.toStringAsFixed(0)} shares · ${h.quote.price.toCurrency()}/share',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.isDarkMode
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Value
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                h.totalValue.toCurrency(),
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isProfit
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 12,
                    color: isProfit ? AppColors.success : AppColors.error,
                  ),
                  Text(
                    '${isProfit ? '+' : ''}${h.profitLossPercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isProfit ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
              // CO2 indicator
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_outlined,
                      size: 11,
                      color: context.isDarkMode
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                  const SizedBox(width: 2),
                  Text(
                    '${h.esg.co2Emission.toStringAsFixed(1)}t',
                    style: TextStyle(
                      fontSize: 10,
                      color: context.isDarkMode
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String suffix;
  final Color color;

  const _StatMiniCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.suffix,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphismCard(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.isDarkMode
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                suffix,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.isDarkMode
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
