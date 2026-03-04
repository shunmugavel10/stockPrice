import 'package:hive/hive.dart';

part 'stock_holding.g.dart';

/// Represents a stock holding in the user's portfolio, persisted via Hive
@HiveType(typeId: 0)
class StockHolding extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String symbol;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final double quantity;

  @HiveField(4)
  final double averageBuyPrice;

  @HiveField(5)
  final DateTime addedAt;

  StockHolding({
    required this.id,
    required this.symbol,
    required this.name,
    required this.quantity,
    required this.averageBuyPrice,
    required this.addedAt,
  });

  StockHolding copyWith({
    String? id,
    String? symbol,
    String? name,
    double? quantity,
    double? averageBuyPrice,
    DateTime? addedAt,
  }) {
    return StockHolding(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      averageBuyPrice: averageBuyPrice ?? this.averageBuyPrice,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
