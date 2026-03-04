/// Represents a single result from Alpha Vantage SYMBOL_SEARCH
class SymbolSearchResult {
  final String symbol;
  final String name;
  final String type;
  final String region;
  final String currency;

  const SymbolSearchResult({
    required this.symbol,
    required this.name,
    required this.type,
    required this.region,
    required this.currency,
  });

  factory SymbolSearchResult.fromJson(Map<String, dynamic> json) {
    return SymbolSearchResult(
      symbol: json['1. symbol'] ?? '',
      name: json['2. name'] ?? '',
      type: json['3. type'] ?? '',
      region: json['4. region'] ?? '',
      currency: json['8. currency'] ?? '',
    );
  }
}
