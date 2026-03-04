import '../models/stock_holding.dart';

/// Abstract repository for local portfolio persistence
abstract class PortfolioLocalRepository {
  List<StockHolding> getAll();
  Future<void> add(StockHolding holding);
  Future<void> update(StockHolding holding);
  Future<void> remove(String id);
  Future<void> clear();
}
