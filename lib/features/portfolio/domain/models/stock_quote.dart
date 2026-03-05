/// Parsed stock quote — supports Marketstack EOD response
class StockQuote {
  final String symbol;
  final double open;
  final double high;
  final double low;
  final double price;
  final int volume;
  final String latestTradingDay;
  final double previousClose;
  final double change;
  final String changePercent;

  const StockQuote({
    required this.symbol,
    required this.open,
    required this.high,
    required this.low,
    required this.price,
    required this.volume,
    required this.latestTradingDay,
    required this.previousClose,
    required this.change,
    required this.changePercent,
  });

  /// Parse a single Marketstack EOD data entry
  factory StockQuote.fromMarketstack(Map<String, dynamic> eod) {
    final close = (eod['close'] as num?)?.toDouble() ?? 0.0;
    final open = (eod['open'] as num?)?.toDouble() ?? 0.0;
    final high = (eod['high'] as num?)?.toDouble() ?? 0.0;
    final low = (eod['low'] as num?)?.toDouble() ?? 0.0;
    final volume = (eod['volume'] as num?)?.toInt() ?? 0;
    final symbol = (eod['symbol'] as String?) ?? '';
    final date = (eod['date'] as String?) ?? '';
    final tradingDay = date.length >= 10 ? date.substring(0, 10) : date;

    final change = close - open;
    final changePercent =
        open != 0 ? '${(change / open * 100).toStringAsFixed(2)}%' : '0%';

    return StockQuote(
      symbol: symbol,
      open: open,
      high: high,
      low: low,
      price: close,
      volume: volume,
      latestTradingDay: tradingDay,
      previousClose: open,
      change: change,
      changePercent: changePercent,
    );
  }

  bool get isEmpty => symbol.isEmpty;
}
