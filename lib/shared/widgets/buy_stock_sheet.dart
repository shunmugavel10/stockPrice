import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../core/utils/platform_adaptive.dart';
import '../../features/portfolio/presentation/providers/portfolio_providers.dart';

/// Reusable bottom sheet for buying / adding a stock to the portfolio.
void showBuyStockSheet(
  BuildContext context, {
  required WidgetRef ref,
  required String symbol,
  required String name,
  double? currentPrice,
}) {
  showAdaptiveBottomSheet(
    context: context,
    builder: (ctx) => _BuyStockSheetContent(
      symbol: symbol,
      name: name,
      currentPrice: currentPrice,
      ref: ref,
      parentContext: context,
    ),
  );
}

class _BuyStockSheetContent extends StatefulWidget {
  final String symbol;
  final String name;
  final double? currentPrice;
  final WidgetRef ref;
  final BuildContext parentContext;

  const _BuyStockSheetContent({
    required this.symbol,
    required this.name,
    required this.ref,
    required this.parentContext,
    this.currentPrice,
  });

  @override
  State<_BuyStockSheetContent> createState() => _BuyStockSheetContentState();
}

class _BuyStockSheetContentState extends State<_BuyStockSheetContent> {
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.currentPrice != null && widget.currentPrice! > 0) {
      _priceController.text = widget.currentPrice!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _buy() {
    final quantity = double.tryParse(_quantityController.text);
    final price = double.tryParse(_priceController.text);

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity.')),
      );
      return;
    }
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        const SnackBar(content: Text('Please enter a valid buy price.')),
      );
      return;
    }

    widget.ref.read(holdingsProvider.notifier).addHolding(
          symbol: widget.symbol,
          name: widget.name,
          quantity: quantity,
          buyPrice: price,
        );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(widget.parentContext).showSnackBar(
      SnackBar(
        content: Text('${widget.symbol} added to portfolio!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final symbol = widget.symbol;
    final name = widget.name;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
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
              onPressed: _buy,
              child: const Text('Buy Stock'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
