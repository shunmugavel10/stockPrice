import '../../../../core/network/api_result.dart';
import '../../domain/models/stock_quote.dart';
import '../../domain/repositories/stock_repository.dart';
import '../services/alpha_vantage_service.dart';

/// Concrete implementation of StockRepository using Alpha Vantage
class StockRepositoryImpl implements StockRepository {
  final AlphaVantageService _service;

  StockRepositoryImpl(this._service);

  @override
  Future<ApiResult<StockQuote>> getQuote(String symbol) {
    return _service.getGlobalQuote(symbol);
  }
}
