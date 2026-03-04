import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../portfolio/data/services/alpha_vantage_service.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../domain/models/symbol_search_result.dart';
import '../../domain/repositories/search_repository.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepositoryImpl(AlphaVantageService(DioClient.instance));
});

/// Holds the current search query
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Fetches search results from Alpha Vantage SYMBOL_SEARCH
final searchResultsProvider =
    FutureProvider<List<SymbolSearchResult>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().length < 2) return [];

  final repo = ref.read(searchRepositoryProvider);
  final result = await repo.searchSymbol(query.trim());

  switch (result) {
    case ApiSuccess(data: final results):
      return results;
    case ApiError(message: final msg):
      throw Exception(msg);
  }
});
