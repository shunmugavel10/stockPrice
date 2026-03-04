/// ESG (Environmental, Social, Governance) data for a stock
class EsgData {
  final String symbol;
  final double esgScore;
  final double co2Emission;
  final String sustainabilityRating;

  const EsgData({
    required this.symbol,
    required this.esgScore,
    required this.co2Emission,
    required this.sustainabilityRating,
  });

  factory EsgData.fromJson(Map<String, dynamic> json) {
    return EsgData(
      symbol: json['symbol'] as String? ?? '',
      esgScore: (json['esgScore'] as num?)?.toDouble() ?? 0.0,
      co2Emission: (json['co2Emission'] as num?)?.toDouble() ?? 0.0,
      sustainabilityRating: json['sustainabilityRating'] as String? ?? 'N/A',
    );
  }

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'esgScore': esgScore,
        'co2Emission': co2Emission,
        'sustainabilityRating': sustainabilityRating,
      };

  static const EsgData empty = EsgData(
    symbol: '',
    esgScore: 0,
    co2Emission: 0,
    sustainabilityRating: 'N/A',
  );
}
