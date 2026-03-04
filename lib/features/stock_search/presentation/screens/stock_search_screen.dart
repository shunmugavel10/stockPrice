import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/platform_adaptive.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_screen.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../portfolio/presentation/providers/portfolio_providers.dart';
import '../../domain/models/symbol_search_result.dart';
import '../providers/search_providers.dart';

class StockSearchScreen extends ConsumerStatefulWidget {
  const StockSearchScreen({super.key});

  @override
  ConsumerState<StockSearchScreen> createState() => _StockSearchScreenState();
}

class _StockSearchScreenState extends ConsumerState<StockSearchScreen> {
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);
    final hPad = context.horizontalPadding;

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
                placeholder: 'Search symbol (e.g., AAPL, TSLA)...',
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
                    return const EmptyStateWidget(
                      icon: Icons.search_rounded,
                      title: 'Search Stocks',
                      subtitle:
                          'Enter a stock symbol or company name to search.',
                    );
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
            Icon(
              isCupertino
                  ? CupertinoIcons.add_circled
                  : Icons.add_circle_outline_rounded,
              color: AppColors.primary,
            ),
          ],
        ),
        onTap: () => _showAddDialog(
          context,
          result.symbol,
          result.name,
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, String symbol, String name) {
    _quantityController.clear();
    _priceController.clear();

    showAdaptiveBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    symbol.substring(0, symbol.length > 2 ? 2 : symbol.length),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(symbol,
                          style: context.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(name,
                          style: context.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AdaptiveTextField(
              controller: _quantityController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              labelText: 'Quantity (shares)',
              prefix: Icon(
                isCupertino ? CupertinoIcons.number : Icons.numbers_rounded,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            AdaptiveTextField(
              controller: _priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              labelText: 'Buy Price (\$)',
              prefix: Icon(
                isCupertino
                    ? CupertinoIcons.money_dollar
                    : Icons.attach_money_rounded,
                size: 20,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: AdaptiveButton(
                onPressed: () => _addStock(context, symbol, name),
                child: const Text('Add to Portfolio'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _addStock(BuildContext context, String symbol, String name) {
    final quantity = double.tryParse(_quantityController.text);
    final price = double.tryParse(_priceController.text);

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity.')),
      );
      return;
    }
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid buy price.')),
      );
      return;
    }

    ref.read(holdingsProvider.notifier).addHolding(
          symbol: symbol,
          name: name,
          quantity: quantity,
          buyPrice: price,
        );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$symbol added to portfolio!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
