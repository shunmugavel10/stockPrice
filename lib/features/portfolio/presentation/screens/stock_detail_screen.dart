import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/esg_helpers.dart';
import '../../../../core/utils/platform_adaptive.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../../../../shared/widgets/esg_badge.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/error_screen.dart';
import '../../domain/models/stock_quote.dart';
import '../../../../shared/widgets/buy_stock_sheet.dart';
import '../providers/portfolio_providers.dart';

class StockDetailScreen extends ConsumerStatefulWidget {
  final String symbol;
  final String name;

  const StockDetailScreen({
    super.key,
    required this.symbol,
    required this.name,
  });

  @override
  ConsumerState<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends ConsumerState<StockDetailScreen> {
  int _selectedPeriodIndex = 2; // Default: 1M

  static const _periods = [
    {'label': '1W', 'days': 7},
    {'label': '2W', 'days': 14},
    {'label': '1M', 'days': 30},
    {'label': '3M', 'days': 90},
    {'label': '6M', 'days': 180},
    {'label': '1Y', 'days': 365},
  ];

  String get _providerKey =>
      '${widget.symbol}_${_periods[_selectedPeriodIndex]['days']}';

  @override
  Widget build(BuildContext context) {
    final quoteAsync = ref.watch(stockQuoteProvider(widget.symbol));
    final esgAsync = ref.watch(esgDataProvider(widget.symbol));
    final co2HistoryAsync = ref.watch(historicalCO2Provider(widget.symbol));
    final historyAsync = ref.watch(historicalPricesProvider(_providerKey));
    final hPad = context.horizontalPadding;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.symbol,
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      bottomNavigationBar: _buildBuyBar(context, quoteAsync),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: ResponsiveContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live price header
              _buildStockHeader(context, quoteAsync),

              // Price chart
              _buildPriceChartSection(context, historyAsync, quoteAsync),

              const SizedBox(height: 8),

              // Market stats
              quoteAsync.when(
                data: (quote) => _buildMarketStats(context, quote),
                loading: () => Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: const ShimmerLoading(height: 80),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 8),

              // ESG Overview
              _buildSectionTitle(context, 'Sustainability Overview', hPad),
              esgAsync.when(
                data: (esg) => _buildEsgCard(context, esg),
                loading: () => Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: const ShimmerLoading(height: 160),
                ),
                error: (err, _) => ErrorScreen(
                  message: err.toString(),
                  onRetry: () =>
                      ref.invalidate(esgDataProvider(widget.symbol)),
                ),
              ),

              const SizedBox(height: 16),

              // CO₂ Trend
              _buildSectionTitle(
                  context, 'CO₂ Emissions Trend (12 months)', hPad),
              co2HistoryAsync.when(
                data: (data) => _buildCO2TrendChart(context, data),
                loading: () => Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: const ShimmerLoading(height: 220),
                ),
                error: (err, _) => ErrorScreen(
                  message: err.toString(),
                  onRetry: () =>
                      ref.invalidate(historicalCO2Provider(widget.symbol)),
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
                      _buildAlternatives(context, widget.symbol),
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

  // Sticky buy bar at the bottom (Groww/Zerodha style)
  Widget _buildBuyBar(BuildContext context, AsyncValue<StockQuote> quoteAsync) {
    final currentPrice = quoteAsync.valueOrNull?.price;

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? const Color(0xFF1A1A2E)
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (currentPrice != null) ...[
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Price',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.isDarkMode
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  currentPrice.toCurrency(),
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const Spacer(),
          ] else
            const Spacer(),
          SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => showBuyStockSheet(
                context,
                ref: ref,
                symbol: widget.symbol,
                name: widget.name,
                currentPrice: currentPrice,
              ),
              icon: Icon(
                isCupertino
                    ? CupertinoIcons.cart_badge_plus
                    : Icons.shopping_cart_rounded,
                size: 20,
              ),
              label: const Text(
                'Buy Stock',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Price chart section with period tabs
  Widget _buildPriceChartSection(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> historyAsync,
    AsyncValue<StockQuote> quoteAsync,
  ) {
    return Column(
      children: [
        // Period selector tabs (Groww style)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: List.generate(_periods.length, (index) {
              final isSelected = _selectedPeriodIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPeriodIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (context.isDarkMode
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary)
                              .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _periods[index]['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (context.isDarkMode
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        // Chart area
        historyAsync.when(
          data: (data) {
            if (data.isEmpty) {
              return SizedBox(
                height: 250,
                child: Center(
                  child: Text(
                    'No price data for this period',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.isDarkMode
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              );
            }
            return _buildInteractivePriceChart(context, data);
          },
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const ShimmerLoading(height: 250),
                const SizedBox(height: 8),
              ],
            ),
          ),
          error: (err, _) => SizedBox(
            height: 250,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.signal_wifi_off_rounded,
                      size: 32,
                      color: context.isDarkMode
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                  const SizedBox(height: 8),
                  Text('Unable to load price data',
                      style: context.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(historicalPricesProvider(_providerKey)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Groww/Zerodha-style interactive line chart
  Widget _buildInteractivePriceChart(
      BuildContext context, List<Map<String, dynamic>> data) {
    final prices = data.map((e) => (e['close'] as num?)?.toDouble() ?? 0.0).toList();
    final dates = data.map((e) => (e['date'] as String?) ?? '').toList();

    if (prices.isEmpty) return const SizedBox.shrink();

    final maxY = prices.reduce((a, b) => a > b ? a : b);
    final minY = prices.reduce((a, b) => a < b ? a : b);
    final range = maxY - minY;
    final paddedMin = minY - range * 0.05;
    final paddedMax = maxY + range * 0.05;

    final firstPrice = prices.first;
    final lastPrice = prices.last;
    final priceChange = lastPrice - firstPrice;
    final isPositive = priceChange >= 0;
    final chartColor = isPositive ? AppColors.success : AppColors.error;

    final spots = prices
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassmorphismCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period change summary
            Row(
              children: [
                Text(
                  '${_periods[_selectedPeriodIndex]['label']} Change',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.isDarkMode
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: chartColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${isPositive ? '+' : ''}${priceChange.toStringAsFixed(2)} (${firstPrice != 0 ? '${(priceChange / firstPrice * 100).toStringAsFixed(2)}%' : '0%'})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: chartColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // The chart
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: paddedMin,
                  maxY: paddedMax,
                  clipData: const FlClipData.all(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: range > 0 ? range / 4 : 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: (context.isDarkMode
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary)
                          .withValues(alpha: 0.1),
                      strokeWidth: 0.5,
                      dashArray: [4, 4],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 52,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max || value == meta.min) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              '\$${value.toStringAsFixed(value >= 100 ? 0 : 2)}',
                              style: TextStyle(
                                fontSize: 9,
                                color: context.isDarkMode
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: prices.length > 10
                            ? (prices.length / 5).roundToDouble()
                            : 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= dates.length) {
                            return const SizedBox.shrink();
                          }
                          final dateStr = dates[idx];
                          if (dateStr.length < 10) {
                            return const SizedBox.shrink();
                          }
                          final dt = DateTime.tryParse(dateStr);
                          if (dt == null) return const SizedBox.shrink();
                          final label = DateFormat('d MMM').format(dt);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 9,
                                color: context.isDarkMode
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    getTouchedSpotIndicator: (barData, spotIndexes) {
                      return spotIndexes.map((idx) {
                        return TouchedSpotIndicatorData(
                          FlLine(
                            color: chartColor.withValues(alpha: 0.5),
                            strokeWidth: 1,
                            dashArray: [4, 4],
                          ),
                          FlDotData(
                            show: true,
                            getDotPainter: (spot, p, bar, i) =>
                                FlDotCirclePainter(
                              radius: 5,
                              color: chartColor,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            ),
                          ),
                        );
                      }).toList();
                    },
                    touchTooltipData: LineTouchTooltipData(
                      tooltipRoundedRadius: 10,
                      tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      getTooltipItems: (spots) => spots.map((spot) {
                        final idx = spot.x.toInt();
                        String dateLabel = '';
                        if (idx >= 0 && idx < dates.length) {
                          final dt = DateTime.tryParse(dates[idx]);
                          if (dt != null) {
                            dateLabel = DateFormat('d MMM yyyy').format(dt);
                          }
                        }
                        return LineTooltipItem(
                          '\$${spot.y.toStringAsFixed(2)}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: dateLabel,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w400,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.2,
                      color: chartColor,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            chartColor.withValues(alpha: 0.20),
                            chartColor.withValues(alpha: 0.02),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 300),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Market stats row (Open, High, Low, Volume)
  Widget _buildMarketStats(BuildContext context, StockQuote quote) {
    return GlassmorphismCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Market Stats',
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                    label: 'Open',
                    value: quote.open.toCurrency(),
                    icon: Icons.lock_open_rounded),
              ),
              Expanded(
                child: _StatItem(
                    label: 'High',
                    value: quote.high.toCurrency(),
                    icon: Icons.arrow_upward_rounded,
                    color: AppColors.success),
              ),
              Expanded(
                child: _StatItem(
                    label: 'Low',
                    value: quote.low.toCurrency(),
                    icon: Icons.arrow_downward_rounded,
                    color: AppColors.error),
              ),
              Expanded(
                child: _StatItem(
                    label: 'Volume',
                    value: _formatVolume(quote.volume),
                    icon: Icons.bar_chart_rounded),
              ),
            ],
          ),
          if (quote.latestTradingDay.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 14,
                    color: context.isDarkMode
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
                const SizedBox(width: 4),
                Text(
                  'Last traded: ${quote.latestTradingDay}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.isDarkMode
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _formatVolume(int volume) {
    if (volume >= 1000000000) return '${(volume / 1000000000).toStringAsFixed(1)}B';
    if (volume >= 1000000) return '${(volume / 1000000).toStringAsFixed(1)}M';
    if (volume >= 1000) return '${(volume / 1000).toStringAsFixed(1)}K';
    return volume.toString();
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

  Widget _buildStockHeader(BuildContext context, AsyncValue<StockQuote> quoteAsync) {
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
                    widget.symbol.substring(
                        0, widget.symbol.length > 2 ? 2 : widget.symbol.length),
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
                      widget.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      widget.symbol,
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
            data: (quote) {
              final isUp = quote.change >= 0;
              final changeColor = isUp ? AppColors.success : AppColors.error;
              return Row(
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
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: changeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUp
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 16,
                          color: changeColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${isUp ? '+' : ''}${quote.change.toStringAsFixed(2)} (${quote.changePercent})',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: changeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const ShimmerLoading(height: 36, width: 150),
            error: (_, __) => Text(
              'Price unavailable',
              style: context.textTheme.bodySmall?.copyWith(
                color: AppColors.error,
              ),
            ),
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ??
        (context.isDarkMode
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary);
    return Column(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: context.isDarkMode
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 2),
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
