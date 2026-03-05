class SymbolSearchResult {
  final String symbol;
  final String name;
  final String type;
  final String region;
  final String currency;
  final String exchange;

  const SymbolSearchResult({
    required this.symbol,
    required this.name,
    required this.type,
    required this.region,
    required this.currency,
    this.exchange = '',
  });

  /// Parse Marketstack response entry
  factory SymbolSearchResult.fromJson(Map<String, dynamic> json) {
    final exchange = json['stock_exchange'] as Map<String, dynamic>? ?? {};
    return SymbolSearchResult(
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'Common Stock',
      region: exchange['country'] ?? exchange['acronym'] ?? '',
      currency: exchange['currency']?['code'] ?? '',
      exchange: exchange['acronym'] ?? '',
    );
  }
}
