import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../portfolio/data/services/alpha_vantage_service.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../domain/models/symbol_search_result.dart';
import '../../domain/repositories/search_repository.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepositoryImpl(MarketstackService(DioClient.instance));
});

/// Holds the current search query
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Fetches search results from Marketstack tickers endpoint
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

const _pageSize = 10;

@immutable
class PaginatedTickersState {
  final List<SymbolSearchResult> tickers;
  final bool isLoading;
  final bool hasMore;
  final int offset;
  final String? error;

  const PaginatedTickersState({
    this.tickers = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.offset = 0,
    this.error,
  });

  PaginatedTickersState copyWith({
    List<SymbolSearchResult>? tickers,
    bool? isLoading,
    bool? hasMore,
    int? offset,
    String? error,
  }) {
    return PaginatedTickersState(
      tickers: tickers ?? this.tickers,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      error: error,
    );
  }
}

class PaginatedTickersNotifier extends StateNotifier<PaginatedTickersState> {
  final MarketstackService _service;

  PaginatedTickersNotifier(this._service) : super(const PaginatedTickersState());

  Future<void> fetchInitial() async {
    if (state.isLoading) return;
    state = const PaginatedTickersState(isLoading: true);

    final result = await _service.fetchTickers(offset: 0, limit: _pageSize);

    switch (result) {
      case ApiSuccess(data: final items):
        final parsed = items.map((m) => SymbolSearchResult.fromJson(m)).toList();
        state = PaginatedTickersState(
          tickers: parsed,
          offset: parsed.length,
          hasMore: parsed.length >= _pageSize,
        );
      case ApiError(message: final msg):
        state = PaginatedTickersState(error: msg);
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, error: null);

    final result = await _service.fetchTickers(
      offset: state.offset,
      limit: _pageSize,
    );

    switch (result) {
      case ApiSuccess(data: final items):
        final parsed = items.map((m) => SymbolSearchResult.fromJson(m)).toList();
        state = state.copyWith(
          tickers: [...state.tickers, ...parsed],
          offset: state.offset + parsed.length,
          hasMore: parsed.length >= _pageSize,
          isLoading: false,
        );
      case ApiError(message: final msg):
        state = state.copyWith(isLoading: false, error: msg);
    }
  }
}

final paginatedTickersProvider =
    StateNotifierProvider<PaginatedTickersNotifier, PaginatedTickersState>((ref) {
  final service = MarketstackService(DioClient.instance);
  return PaginatedTickersNotifier(service);
});
