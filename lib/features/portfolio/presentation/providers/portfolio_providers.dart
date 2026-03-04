import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/repositories/portfolio_local_repository_impl.dart';
import '../../data/repositories/stock_repository_impl.dart';
import '../../data/services/alpha_vantage_service.dart';
import '../../data/services/mock_esg_service.dart';
import '../../domain/models/esg_data.dart';
import '../../domain/models/portfolio_summary.dart';
import '../../domain/models/stock_holding.dart';
import '../../domain/models/stock_quote.dart';
import '../../domain/repositories/esg_repository.dart';
import '../../domain/repositories/portfolio_local_repository.dart';
import '../../domain/repositories/stock_repository.dart';

// ─── Service Providers ───────────────────────────────────────────

final alphaVantageServiceProvider = Provider<AlphaVantageService>((ref) {
  return AlphaVantageService(DioClient.instance);
});

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  return StockRepositoryImpl(ref.read(alphaVantageServiceProvider));
});

final esgRepositoryProvider = Provider<EsgRepository>((ref) {
  return MockEsgService();
});

final portfolioBoxProvider = Provider<Box<StockHolding>>((ref) {
  throw UnimplementedError('Must be overridden in main.dart');
});

final portfolioLocalRepositoryProvider = Provider<PortfolioLocalRepository>((ref) {
  return PortfolioLocalRepositoryImpl(ref.read(portfolioBoxProvider));
});

// ─── Portfolio State ─────────────────────────────────────────────

/// Holds the list of portfolio holdings from Hive
final holdingsProvider =
    StateNotifierProvider<HoldingsNotifier, List<StockHolding>>((ref) {
  final localRepo = ref.read(portfolioLocalRepositoryProvider);
  return HoldingsNotifier(localRepo);
});

class HoldingsNotifier extends StateNotifier<List<StockHolding>> {
  final PortfolioLocalRepository _localRepo;

  HoldingsNotifier(this._localRepo) : super(_localRepo.getAll());

  Future<void> addHolding({
    required String symbol,
    required String name,
    required double quantity,
    required double buyPrice,
  }) async {
    final holding = StockHolding(
      id: const Uuid().v4(),
      symbol: symbol.toUpperCase(),
      name: name,
      quantity: quantity,
      averageBuyPrice: buyPrice,
      addedAt: DateTime.now(),
    );
    await _localRepo.add(holding);
    state = _localRepo.getAll();
  }

  Future<void> removeHolding(String id) async {
    await _localRepo.remove(id);
    state = _localRepo.getAll();
  }

  Future<void> updateHolding(StockHolding holding) async {
    await _localRepo.update(holding);
    state = _localRepo.getAll();
  }

  void refresh() {
    state = _localRepo.getAll();
  }
}

// ─── Quote Providers ─────────────────────────────────────────────

/// Fetches a real-time quote for a single symbol
final stockQuoteProvider =
    FutureProvider.family<StockQuote, String>((ref, symbol) async {
  final repo = ref.read(stockRepositoryProvider);
  final result = await repo.getQuote(symbol);
  switch (result) {
    case ApiSuccess(data: final quote):
      return quote;
    case ApiError(message: final msg):
      throw Exception(msg);
  }
});

/// Fetches ESG data for a single symbol
final esgDataProvider =
    FutureProvider.family<EsgData, String>((ref, symbol) async {
  final repo = ref.read(esgRepositoryProvider);
  return repo.getEsgData(symbol);
});

/// Fetches historical CO2 data for a symbol
final historicalCO2Provider =
    FutureProvider.family<List<double>, String>((ref, symbol) async {
  final repo = ref.read(esgRepositoryProvider);
  return repo.getHistoricalCO2(symbol);
});

// ─── Dashboard / Portfolio Summary ───────────────────────────────

/// Enriched portfolio summary combining holdings, quotes, and ESG data
final portfolioSummaryProvider = FutureProvider<PortfolioSummary>((ref) async {
  final holdings = ref.watch(holdingsProvider);

  if (holdings.isEmpty) return PortfolioSummary.empty;

  final stockRepo = ref.read(stockRepositoryProvider);
  final esgRepo = ref.read(esgRepositoryProvider);

  final enriched = <EnrichedHolding>[];

  for (final holding in holdings) {
    try {
      final quoteResult = await stockRepo.getQuote(holding.symbol);
      final esg = await esgRepo.getEsgData(holding.symbol);

      StockQuote quote;
      switch (quoteResult) {
        case ApiSuccess(data: final q):
          quote = q;
        case ApiError():
          // Use a fallback quote with buy price as current price
          quote = StockQuote(
            symbol: holding.symbol,
            open: holding.averageBuyPrice,
            high: holding.averageBuyPrice,
            low: holding.averageBuyPrice,
            price: holding.averageBuyPrice,
            volume: 0,
            latestTradingDay: '',
            previousClose: holding.averageBuyPrice,
            change: 0,
            changePercent: '0%',
          );
      }

      enriched.add(EnrichedHolding(
        holding: holding,
        quote: quote,
        esg: esg,
      ));

      // Rate limit delay between API calls
      await Future.delayed(const Duration(milliseconds: 1200));
    } catch (_) {
      // Skip holdings that fail to load
    }
  }

  return PortfolioSummary.fromHoldings(enriched);
});
