import '../../../../core/network/api_result.dart';
import '../models/symbol_search_result.dart';

/// repository for symbol search operations
abstract class SearchRepository {
  Future<ApiResult<List<SymbolSearchResult>>> searchSymbol(String keywords);
}
