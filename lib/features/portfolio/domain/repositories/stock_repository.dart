import '../../../../core/network/api_result.dart';
import '../models/stock_quote.dart';

/// Abstract repository for stock price operations
abstract class StockRepository {
  Future<ApiResult<StockQuote>> getQuote(String symbol);
}
