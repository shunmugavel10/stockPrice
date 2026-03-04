import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/stock_holding.dart';
import '../../domain/repositories/portfolio_local_repository.dart';

/// Hive-based implementation of local portfolio persistence
class PortfolioLocalRepositoryImpl implements PortfolioLocalRepository {
  final Box<StockHolding> _box;

  PortfolioLocalRepositoryImpl(this._box);

  /// Opens the Hive box — call this during app initialization
  static Future<Box<StockHolding>> openBox() async {
    return Hive.openBox<StockHolding>(AppConstants.portfolioBox);
  }

  @override
  List<StockHolding> getAll() {
    return _box.values.toList();
  }

  @override
  Future<void> add(StockHolding holding) async {
    await _box.put(holding.id, holding);
  }

  @override
  Future<void> update(StockHolding holding) async {
    await _box.put(holding.id, holding);
  }

  @override
  Future<void> remove(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }
}
