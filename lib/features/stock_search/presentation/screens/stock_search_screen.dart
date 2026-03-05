import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/platform_adaptive.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_screen.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/buy_stock_sheet.dart';
import '../../domain/models/symbol_search_result.dart';
import '../providers/search_providers.dart';

class StockSearchScreen extends ConsumerStatefulWidget {
  const StockSearchScreen({super.key});

  @override
  ConsumerState<StockSearchScreen> createState() => _StockSearchScreenState();
}

class _StockSearchScreenState extends ConsumerState<StockSearchScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _initialFetched = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(paginatedTickersProvider.notifier).fetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);
    final tickersState = ref.watch(paginatedTickersProvider);
    final hPad = context.horizontalPadding;

    // Trigger initial fetch once
    if (!_initialFetched && tickersState.tickers.isEmpty && !tickersState.isLoading && tickersState.error == null) {
      _initialFetched = true;
      Future.microtask(() => ref.read(paginatedTickersProvider.notifier).fetchInitial());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Stock',
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ResponsiveContent(
        child: Column(
          children: [
            // Search bar — adaptive for iOS/Android
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 12),
              child: AdaptiveTextField(
                controller: _searchController,
                placeholder: 'Search stocks (e.g., AAPL, TSLA)...',
                prefix: Icon(
                  isCupertino ? CupertinoIcons.search : Icons.search_rounded,
                  color: AppColors.lightTextSecondary,
                ),
                suffix: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                          setState(() {});
                        },
                        child: Icon(
                          isCupertino
                              ? CupertinoIcons.clear_circled_solid
                              : Icons.clear_rounded,
                          size: 20,
                          color: AppColors.lightTextSecondary,
                        ),
                      )
                    : null,
                textCapitalization: TextCapitalization.characters,
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                  setState(() {});
                },
              ),
            ),
            // Results
            Expanded(
              child: searchResults.when(
                loading: () => ListView.builder(
                  itemCount: 5,
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  itemBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: ShimmerLoading(height: 64),
                  ),
                ),
                error: (err, _) => ErrorScreen(
                  message: err.toString(),
                  onRetry: () => ref.invalidate(searchResultsProvider),
                ),
                data: (results) {
                  if (_searchController.text.isEmpty) {
                    return _buildLiveTickers(context, hPad, tickersState);
                  }

                  if (results.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.search_off_rounded,
                      title: 'No Results',
                      subtitle:
                          'No stocks found for your search. Try a different symbol.',
                    );
                  }

                  // Tablet: grid layout for results
                  if (context.isTablet || context.isDesktop) {
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: context.gridColumns,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 3.0,
                      ),
                      itemCount: results.length,
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      itemBuilder: (context, index) {
                        final result = results[index];
                        return _buildResultCard(context, result);
                      },
                    );
                  }

                  return ListView.builder(
                    itemCount: results.length,
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    itemBuilder: (context, index) {
                      final result = results[index];
                      return _buildResultCard(context, result);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Category Helpers 

  static String _exchangeCategory(String exchange) {
    final upper = exchange.toUpperCase();
    if (upper == 'NASDAQ' || upper == 'XNAS') return 'NASDAQ';
    if (upper == 'NYSE' || upper == 'XNYS' || upper == 'XASE') return 'NYSE';
    if (upper == 'XLON' || upper == 'LSE') return 'London';
    if (upper == 'XJPX' || upper == 'XTKS') return 'Tokyo';
    if (upper == 'XHKG') return 'Hong Kong';
    if (upper == 'XSHG' || upper == 'XSHE') return 'China';
    if (upper == 'XBOM' || upper == 'XNSE') return 'India';
    if (upper == 'XFRA' || upper == 'XETR') return 'Europe';
    if (upper == 'XASX') return 'Australia';
    if (upper == 'XTSE' || upper == 'XTSX') return 'Canada';
    if (upper.isEmpty) return 'Other';
    return upper;
  }

  static Color _categoryColor(String category) {
    switch (category) {
      case 'NASDAQ':
        return AppColors.info;
      case 'NYSE':
        return AppColors.primary;
      case 'London':
        return const Color(0xFF6C5CE7);
      case 'Tokyo':
        return const Color(0xFFE17055);
      case 'Hong Kong':
        return const Color(0xFFD63031);
      case 'China':
        return const Color(0xFFE84393);
      case 'India':
        return AppColors.esgExcellent;
      case 'Europe':
        return const Color(0xFF0984E3);
      case 'Australia':
        return AppColors.warning;
      case 'Canada':
        return const Color(0xFFFF7675);
      default:
        return AppColors.esgAverage;
    }
  }

  static IconData _categoryIcon(String category) {
    switch (category) {
      case 'NASDAQ':
        return Icons.memory_rounded;
      case 'NYSE':
        return Icons.account_balance_rounded;
      case 'London':
        return Icons.location_city_rounded;
      case 'Tokyo':
        return Icons.temple_buddhist_rounded;
      case 'India':
        return Icons.currency_rupee_rounded;
      default:
        return Icons.public_rounded;
    }
  }

  /// Builds a flat list of widgets from categorized tickers, inserting
  /// category headers before each new group. Preserves insertion order.
  List<Widget> _buildCategorizedItems(
      BuildContext context, List<SymbolSearchResult> tickers) {
    final List<Widget> items = [];
    String? lastCategory;

    for (var i = 0; i < tickers.length; i++) {
      final ticker = tickers[i];
      final category = _exchangeCategory(ticker.exchange);

      if (category != lastCategory) {
        if (lastCategory != null) {
          items.add(const SizedBox(height: 10));
        }
        items.add(_buildCategoryLabel(context, category));
        items.add(const SizedBox(height: 6));
        lastCategory = category;
      }

      items.add(_buildTickerTile(context, ticker, category));
    }

    return items;
  }

  Widget _buildCategoryLabel(BuildContext context, String category) {
    final color = _categoryColor(category);
    final icon = _categoryIcon(category);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            category,
            style: context.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Live Paginated Tickers

  Widget _buildLiveTickers(
      BuildContext context, double hPad, PaginatedTickersState tickersState) {
    // Initial loading state
    if (tickersState.tickers.isEmpty && tickersState.isLoading) {
      return ListView.builder(
        itemCount: 10,
        padding: EdgeInsets.symmetric(horizontal: hPad),
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: ShimmerLoading(height: 64),
        ),
      );
    }

    // Error state with retry
    if (tickersState.tickers.isEmpty && tickersState.error != null) {
      return ErrorScreen(
        message: tickersState.error!,
        onRetry: () =>
            ref.read(paginatedTickersProvider.notifier).fetchInitial(),
      );
    }

    // Empty fallback
    if (tickersState.tickers.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.public_rounded,
        title: 'No Stocks Available',
        subtitle: 'Unable to load stock listings right now.',
      );
    }

    // Build categorized items from the flat ticker list
    final categorizedItems =
        _buildCategorizedItems(context, tickersState.tickers);

    // Total: header + categorized items + bottom indicator
    final hasBottom = tickersState.isLoading || tickersState.hasMore || tickersState.error != null;
    final totalCount = 1 + categorizedItems.length + (hasBottom ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: hPad),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        // Header
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Browse Stocks',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Live data from Marketstack · Tap any stock to add it',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.isDarkMode
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        }

        // Categorized items (offset by 1 for header)
        final itemIndex = index - 1;
        if (itemIndex < categorizedItems.length) {
          return categorizedItems[itemIndex];
        }

        // Bottom loading indicator
        if (tickersState.isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (tickersState.error != null) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Column(
                children: [
                  Text(
                    'Failed to load more',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => ref
                        .read(paginatedTickersProvider.notifier)
                        .fetchNextPage(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // No more data
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text(
              'You\'ve reached the end',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.isDarkMode
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTickerTile(
      BuildContext context, SymbolSearchResult ticker, String category) {
    final symbol = ticker.symbol;
    final name = ticker.name.isNotEmpty ? ticker.name : symbol;
    final color = _categoryColor(category);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: color.withValues(alpha: 0.1),
          child: Text(
            symbol.substring(0, symbol.length > 2 ? 2 : symbol.length),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: color,
            ),
          ),
        ),
        title: Text(
          symbol,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                category,
                style: context.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showAddDialog(context, symbol, name),
              child: Icon(
                isCupertino
                    ? CupertinoIcons.add_circled
                    : Icons.add_circle_outline_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ],
        ),
        onTap: () => context.push('/stock-detail', extra: {
          'symbol': symbol,
          'name': name,
        }),
      ),
    );
  }

  // ─── Search Results ────────────────────────────────────────────

  Widget _buildResultCard(BuildContext context, SymbolSearchResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            result.symbol.substring(
                0, result.symbol.length > 2 ? 2 : result.symbol.length),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: AppColors.primary,
            ),
          ),
        ),
        title: Text(
          result.symbol,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          result.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              result.region,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.isDarkMode
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showAddDialog(
                context,
                result.symbol,
                result.name,
              ),
              child: Icon(
                isCupertino
                    ? CupertinoIcons.add_circled
                    : Icons.add_circle_outline_rounded,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        onTap: () => context.push('/stock-detail', extra: {
          'symbol': result.symbol,
          'name': result.name,
        }),
      ),
    );
  }

  void _showAddDialog(BuildContext context, String symbol, String name) {
    showBuyStockSheet(
      context,
      ref: ref,
      symbol: symbol,
      name: name,
    );
  }
}
