import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/esg_helpers.dart';
import '../../../../core/utils/platform_adaptive.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../../../../shared/widgets/esg_badge.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/error_screen.dart';
import '../providers/portfolio_providers.dart';

class StockDetailScreen extends ConsumerWidget {
  final String symbol;
  final String name;

  const StockDetailScreen({
    super.key,
    required this.symbol,
    required this.name,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteAsync = ref.watch(stockQuoteProvider(symbol));
    final esgAsync = ref.watch(esgDataProvider(symbol));
    final co2HistoryAsync = ref.watch(historicalCO2Provider(symbol));
    final hPad = context.horizontalPadding;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          symbol,
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 100),
        child: ResponsiveContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stock header
              _buildStockHeader(context, ref, quoteAsync),

              const SizedBox(height: 8),

              // ESG Overview Card
              _buildSectionTitle(context, 'Sustainability Overview', hPad),
              esgAsync.when(
                data: (esg) => _buildEsgCard(context, esg),
                loading: () => Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: const ShimmerLoading(height: 160),
                ),
                error: (err, _) => ErrorScreen(
                  message: err.toString(),
                  onRetry: () => ref.invalidate(esgDataProvider(symbol)),
                ),
              ),

              const SizedBox(height: 16),

              // Historical CO₂ Emissions Chart
              _buildSectionTitle(context, 'CO₂ Emissions Trend (12 months)', hPad),
              co2HistoryAsync.when(
                data: (data) => _buildCO2TrendChart(context, data),
                loading: () => Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: const ShimmerLoading(height: 220),
                ),
                error: (err, _) => ErrorScreen(
                  message: err.toString(),
                  onRetry: () => ref.invalidate(historicalCO2Provider(symbol)),
                ),
              ),

              const SizedBox(height: 16),

              // Eco-friendly alternatives
              esgAsync.when(
                data: (esg) {
                  if (!EsgHelpers.needsAlternative(esg.esgScore)) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                          context, 'Eco-Friendly Alternatives', hPad),
                      _buildAlternatives(context, symbol),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
      BuildContext context, String title, double hPad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad + 4, 4, hPad + 4, 6),
      child: Text(
        title,
        style: context.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStockHeader(
      BuildContext context, WidgetRef ref, AsyncValue quoteAsync) {
    return GlassmorphismCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    symbol.substring(
                        0, symbol.length > 2 ? 2 : symbol.length),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
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
                      symbol,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.isDarkMode
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          quoteAsync.when(
            data: (quote) => Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  quote.price.toCurrency(),
                  style: context.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (quote.change >= 0
                            ? AppColors.success
                            : AppColors.error)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        quote.change >= 0
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 14,
                        color: quote.change >= 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${quote.change >= 0 ? '+' : ''}${quote.change.toStringAsFixed(2)} (${quote.changePercent})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: quote.change >= 0
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            loading: () => const ShimmerLoading(height: 36, width: 150),
            error: (_, __) => Text(
              'Price unavailable',
              style: context.textTheme.bodySmall?.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
          quoteAsync.when(
            data: (quote) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  _QuoteChip(
                      label: 'Open', value: quote.open.toCurrency()),
                  const SizedBox(width: 12),
                  _QuoteChip(
                      label: 'High', value: quote.high.toCurrency()),
                  const SizedBox(width: 12),
                  _QuoteChip(label: 'Low', value: quote.low.toCurrency()),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEsgCard(BuildContext context, dynamic esg) {
    final scoreColor = EsgHelpers.scoreColor(esg.esgScore);
    final scoreLabel = EsgHelpers.scoreLabel(esg.esgScore);

    return GlassmorphismCard(
      child: Column(
        children: [
          Row(
            children: [
              // ESG Score Circle
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: esg.esgScore / 100,
                        strokeWidth: 8,
                        backgroundColor: scoreColor.withValues(alpha: 0.15),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(scoreColor),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          esg.esgScore.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: scoreColor,
                          ),
                        ),
                        Text(
                          '/100',
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
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'ESG Rating: ',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.isDarkMode
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        EsgBadge(rating: esg.sustainabilityRating),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      scoreLabel,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scoreColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.cloud_outlined,
                            size: 16, color: AppColors.warning),
                        const SizedBox(width: 6),
                        Text(
                          '${esg.co2Emission.toStringAsFixed(1)} tonnes CO₂/year',
                          style: context.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

  Widget _buildCO2TrendChart(BuildContext context, List<double> data) {
    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No historical data available.'),
      );
    }

    final maxY = data.reduce((a, b) => a > b ? a : b) * 1.2;
    final minY = data.reduce((a, b) => a < b ? a : b) * 0.8;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return GlassmorphismCard(
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            minY: minY,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (maxY - minY) / 4,
              getDrawingHorizontalLine: (value) => FlLine(
                color: (context.isDarkMode
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary)
                    .withValues(alpha: 0.15),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 10,
                        color: context.isDarkMode
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx >= 0 && idx < months.length && idx % 2 == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          months[idx],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: context.isDarkMode
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => spots.map((spot) {
                  final monthIdx = spot.x.toInt();
                  final monthLabel =
                      monthIdx >= 0 && monthIdx < months.length
                          ? months[monthIdx]
                          : '';
                  return LineTooltipItem(
                    '$monthLabel\n${spot.y.toStringAsFixed(1)} t',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: data
                    .asMap()
                    .entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value))
                    .toList(),
                isCurved: true,
                curveSmoothness: 0.3,
                color: AppColors.warning,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                    radius: 3,
                    color: AppColors.warning,
                    strokeWidth: 1.5,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.warning.withValues(alpha: 0.25),
                      AppColors.warning.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlternatives(BuildContext context, String symbol) {
    final alternatives = EsgHelpers.suggestAlternatives(symbol);

    return GlassmorphismCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCupertino
                    ? CupertinoIcons.lightbulb_fill
                    : Icons.lightbulb_rounded,
                size: 18,
                color: AppColors.esgExcellent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This stock has a low ESG score. Consider these greener alternatives:',
                  style: context.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: context.isDarkMode
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: alternatives.map((alt) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.esgExcellent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.esgExcellent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.eco_rounded,
                        size: 16, color: AppColors.esgExcellent),
                    const SizedBox(width: 6),
                    Text(
                      alt,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.esgExcellent,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _QuoteChip extends StatelessWidget {
  final String label;
  final String value;

  const _QuoteChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: context.isDarkMode
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        Text(
          value,
          style: context.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
