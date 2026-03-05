import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/esg_helpers.dart';
import '../../../../core/utils/platform_adaptive.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/esg_badge.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../../domain/models/stock_holding.dart';
import '../providers/portfolio_providers.dart';

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<StockHolding> holdings) {
    setState(() {
      if (_selectedIds.length == holdings.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(holdings.map((h) => h.id));
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final count = _selectedIds.length;
    final result = await showAdaptiveConfirmDialog<bool>(
      context: context,
      title: 'Remove Selected',
      content: 'Remove $count selected stock${count > 1 ? 's' : ''} from your portfolio?',
      cancelLabel: 'Cancel',
      confirmLabel: 'Remove',
      isDestructive: true,
    );

    if (result == true && mounted) {
      for (final id in _selectedIds.toList()) {
        ref.read(holdingsProvider.notifier).removeHolding(id);
      }
      setState(() {
        _selectionMode = false;
        _selectedIds.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final holdings = ref.watch(holdingsProvider);
    final hPad = context.horizontalPadding;

    // Exit selection mode if holdings become empty
    if (holdings.isEmpty && _selectionMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectionMode = false;
            _selectedIds.clear();
          });
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: _selectionMode
            ? Text(
                '${_selectedIds.length} selected',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              )
            : Text(
                'My Portfolio',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
        leading: _selectionMode
            ? IconButton(
                icon: Icon(isCupertino
                    ? CupertinoIcons.xmark
                    : Icons.close_rounded),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (_selectionMode) ...[
            // Select all / deselect all
            IconButton(
              icon: Icon(
                _selectedIds.length == holdings.length
                    ? (isCupertino
                        ? CupertinoIcons.checkmark_square_fill
                        : Icons.select_all_rounded)
                    : (isCupertino
                        ? CupertinoIcons.square
                        : Icons.deselect_rounded),
              ),
              tooltip: _selectedIds.length == holdings.length
                  ? 'Deselect all'
                  : 'Select all',
              onPressed: () => _selectAll(holdings),
            ),
            // Delete selected
            IconButton(
              icon: Icon(
                isCupertino ? CupertinoIcons.trash_fill : Icons.delete_rounded,
                color: _selectedIds.isNotEmpty ? AppColors.error : null,
              ),
              tooltip: 'Delete selected',
              onPressed: _selectedIds.isNotEmpty ? _deleteSelected : null,
            ),
          ] else if (holdings.isNotEmpty)
            IconButton(
              icon: Icon(isCupertino
                  ? CupertinoIcons.trash
                  : Icons.delete_sweep_outlined),
              tooltip: 'Select to delete',
              onPressed: _toggleSelectionMode,
            ),
        ],
      ),
      body: holdings.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Portfolio Empty',
              subtitle: 'Tap the search tab to add stocks to your portfolio.',
            )
          : AdaptiveRefreshControl(
              onRefresh: () async {
                ref.invalidate(portfolioSummaryProvider);
              },
              child: ResponsiveContent(
                child: _buildHoldingsContent(context, ref, holdings, hPad),
              ),
            ),
    );
  }

  Widget _buildHoldingsContent(BuildContext context, WidgetRef ref,
      List<StockHolding> holdings, double hPad) {
    // Tablet/desktop: 2-column grid
    if (context.isTablet || context.isDesktop) {
      return Padding(
        padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 100),
        child: ResponsiveGrid(
          columns: context.gridColumns,
          children: holdings
              .map((holding) => _buildSelectableCard(context, ref, holding))
              .toList(),
        ),
      );
    }

    // Mobile: single column list
    return Padding(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: holdings
            .map((holding) => _selectionMode
                ? _buildSelectableCard(context, ref, holding)
                : _buildDismissibleCard(context, ref, holding))
            .toList(),
      ),
    );
  }

  Widget _buildSelectableCard(
      BuildContext context, WidgetRef ref, StockHolding holding) {
    return GestureDetector(
      onTap: _selectionMode ? () => _toggleSelection(holding.id) : null,
      onLongPress: !_selectionMode
          ? () {
              _toggleSelectionMode();
              _toggleSelection(holding.id);
            }
          : null,
      child: _buildHoldingCard(context, ref, holding),
    );
  }

  Widget _buildDismissibleCard(
      BuildContext context, WidgetRef ref, StockHolding holding) {
    return GestureDetector(
      onTap: () => context.push('/stock-detail', extra: {
        'symbol': holding.symbol,
        'name': holding.name,
      }),
      onLongPress: () {
        _toggleSelectionMode();
        _toggleSelection(holding.id);
      },
      child: Dismissible(
        key: ValueKey(holding.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            isCupertino ? CupertinoIcons.delete : Icons.delete_rounded,
            color: AppColors.error,
          ),
        ),
        confirmDismiss: (_) => _confirmDelete(context),
        onDismissed: (_) {
          ref.read(holdingsProvider.notifier).removeHolding(holding.id);
        },
        child: _buildHoldingCard(context, ref, holding),
      ),
    );
  }

  Widget _buildHoldingCard(
      BuildContext context, WidgetRef ref, StockHolding holding) {
    final esgAsync = ref.watch(esgDataProvider(holding.symbol));
    final quoteAsync = ref.watch(stockQuoteProvider(holding.symbol));
    final isSelected = _selectionMode && _selectedIds.contains(holding.id);

    return GlassmorphismCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Checkbox — only visible in selection mode
              if (_selectionMode) ...[
                GestureDetector(
                  onTap: () => _toggleSelection(holding.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : (context.isDarkMode
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded,
                            size: 16, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              // Symbol avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    holding.symbol.substring(
                        0,
                        holding.symbol.length > 2
                            ? 2
                            : holding.symbol.length),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            holding.symbol,
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        esgAsync.when(
                          data: (esg) =>
                              EsgBadge(rating: esg.sustainabilityRating),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    Text(
                      holding.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  quoteAsync.when(
                    data: (quote) => Text(
                      (holding.quantity * quote.price).toCurrency(),
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    loading: () => Text(
                      (holding.quantity * holding.averageBuyPrice).toCurrency(),
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    error: (_, __) => Text(
                      (holding.quantity * holding.averageBuyPrice).toCurrency(),
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${holding.quantity.toStringAsFixed(0)} shares',
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
          // ESG alternatives suggestion
          esgAsync.when(
            data: (esg) {
              if (!EsgHelpers.needsAlternative(esg.esgScore)) {
                return const SizedBox.shrink();
              }
              final alternatives =
                  EsgHelpers.suggestAlternatives(holding.symbol);
              return Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCupertino
                          ? CupertinoIcons.lightbulb
                          : Icons.lightbulb_outline_rounded,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ESG < 50. Consider: ${alternatives.join(", ")}',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showAdaptiveConfirmDialog<bool>(
      context: context,
      title: 'Remove Holding',
      content: 'Are you sure you want to remove this stock?',
      cancelLabel: 'Cancel',
      confirmLabel: 'Remove',
      isDestructive: true,
    );
  }
}
