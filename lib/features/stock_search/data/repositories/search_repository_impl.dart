import '../../../../core/network/api_result.dart';
import '../../../portfolio/data/services/alpha_vantage_service.dart';
import '../../domain/models/symbol_search_result.dart';
import '../../domain/repositories/search_repository.dart';

///  implementation of SearchRepository using Marketstack
class SearchRepositoryImpl implements SearchRepository {
  final MarketstackService _service;

  SearchRepositoryImpl(this._service);

  @override
  Future<ApiResult<List<SymbolSearchResult>>> searchSymbol(
      String keywords) async {
    final result = await _service.searchSymbol(keywords);

    switch (result) {
      case ApiSuccess(data: final matches):
        final results =
            matches.map((m) => SymbolSearchResult.fromJson(m)).toList();
        return ApiSuccess(results);
      case ApiError(message: final msg, statusCode: final code):
        return ApiError(msg, statusCode: code);
    }
  }
}
