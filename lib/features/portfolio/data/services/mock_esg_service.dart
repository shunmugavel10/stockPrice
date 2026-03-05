import 'dart:math';
import '../../domain/models/esg_data.dart';
import '../../domain/repositories/esg_repository.dart';

/// Mock ESG service that simulates ESG data.
class MockEsgService implements EsgRepository {
  // mock data per symbol for consistency
  static final Map<String, EsgData> _mockData = {
    'AAPL': const EsgData(symbol: 'AAPL', esgScore: 78, co2Emission: 22.1, sustainabilityRating: 'AA'),
    'MSFT': const EsgData(symbol: 'MSFT', esgScore: 85, co2Emission: 11.3, sustainabilityRating: 'AAA'),
    'GOOGL': const EsgData(symbol: 'GOOGL', esgScore: 72, co2Emission: 18.5, sustainabilityRating: 'AA'),
    'AMZN': const EsgData(symbol: 'AMZN', esgScore: 55, co2Emission: 44.8, sustainabilityRating: 'BBB'),
    'TSLA': const EsgData(symbol: 'TSLA', esgScore: 82, co2Emission: 8.2, sustainabilityRating: 'AAA'),
    'META': const EsgData(symbol: 'META', esgScore: 60, co2Emission: 25.0, sustainabilityRating: 'A'),
    'NVDA': const EsgData(symbol: 'NVDA', esgScore: 68, co2Emission: 15.7, sustainabilityRating: 'A'),
    'XOM': const EsgData(symbol: 'XOM', esgScore: 28, co2Emission: 120.5, sustainabilityRating: 'CCC'),
    'CVX': const EsgData(symbol: 'CVX', esgScore: 32, co2Emission: 98.3, sustainabilityRating: 'B'),
    'JPM': const EsgData(symbol: 'JPM', esgScore: 62, co2Emission: 30.2, sustainabilityRating: 'A'),
    'NEE': const EsgData(symbol: 'NEE', esgScore: 92, co2Emission: 3.1, sustainabilityRating: 'AAA'),
    'ENPH': const EsgData(symbol: 'ENPH', esgScore: 90, co2Emission: 2.5, sustainabilityRating: 'AAA'),
  };

  @override
  Future<EsgData> getEsgData(String symbol) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    final upper = symbol.toUpperCase();
    if (_mockData.containsKey(upper)) {
      return _mockData[upper]!;
    }

    final seed = upper.codeUnits.fold<int>(0, (a, b) => a + b);
    final rng = Random(seed);
    final score = 20 + rng.nextDouble() * 80;
    final co2 = 5 + rng.nextDouble() * 100;
    final ratingIndex = (score / 15).floor().clamp(0, 6);
    const ratings = ['CCC', 'B', 'BB', 'BBB', 'A', 'AA', 'AAA'];

    return EsgData(
      symbol: upper,
      esgScore: double.parse(score.toStringAsFixed(1)),
      co2Emission: double.parse(co2.toStringAsFixed(1)),
      sustainabilityRating: ratings[ratingIndex],
    );
  }

  @override
  Future<List<double>> getHistoricalCO2(String symbol, {int months = 12}) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final esg = await getEsgData(symbol);
    final base = esg.co2Emission;
    final rng = Random(symbol.hashCode);

    return List.generate(months, (i) {
      final variation = (rng.nextDouble() - 0.5) * base * 0.3;
      return double.parse((base + variation).toStringAsFixed(1));
    });
  }
}
