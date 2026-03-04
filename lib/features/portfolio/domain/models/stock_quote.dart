/// Parsed Alpha Vantage GLOBAL_QUOTE response
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

  factory StockQuote.fromJson(Map<String, dynamic> json) {
    final quote = json['Global Quote'] as Map<String, dynamic>? ?? {};
    return StockQuote(
      symbol: quote['01. symbol'] ?? '',
      open: double.tryParse(quote['02. open'] ?? '') ?? 0.0,
      high: double.tryParse(quote['03. high'] ?? '') ?? 0.0,
      low: double.tryParse(quote['04. low'] ?? '') ?? 0.0,
      price: double.tryParse(quote['05. price'] ?? '') ?? 0.0,
      volume: int.tryParse(quote['06. volume'] ?? '') ?? 0,
      latestTradingDay: quote['07. latest trading day'] ?? '',
      previousClose: double.tryParse(quote['08. previous close'] ?? '') ?? 0.0,
      change: double.tryParse(quote['09. change'] ?? '') ?? 0.0,
      changePercent: quote['10. change percent'] ?? '0%',
    );
  }

  bool get isEmpty => symbol.isEmpty;
}
