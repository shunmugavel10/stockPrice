import 'esg_data.dart';
import 'stock_holding.dart';
import 'stock_quote.dart';

/// Enriched holding combining stock, quote, and ESG data
class EnrichedHolding {
  final StockHolding holding;
  final StockQuote quote;
  final EsgData esg;

  const EnrichedHolding({
    required this.holding,
    required this.quote,
    required this.esg,
  });

  double get totalValue => holding.quantity * quote.price;
  double get totalCost => holding.quantity * holding.averageBuyPrice;
  double get profitLoss => totalValue - totalCost;
  double get profitLossPercent =>
      totalCost > 0 ? (profitLoss / totalCost) * 100 : 0;
}

/// Aggregated portfolio statistics
class PortfolioSummary {
  final double totalValue;
  final double totalCost;
  final double totalCO2;
  final double greenScore;
  final List<EnrichedHolding> holdings;

  const PortfolioSummary({
    required this.totalValue,
    required this.totalCost,
    required this.totalCO2,
    required this.greenScore,
    required this.holdings,
  });

  double get totalProfitLoss => totalValue - totalCost;
  double get totalProfitLossPercent =>
      totalCost > 0 ? (totalProfitLoss / totalCost) * 100 : 0;

  static const PortfolioSummary empty = PortfolioSummary(
    totalValue: 0,
    totalCost: 0,
    totalCO2: 0,
    greenScore: 0,
    holdings: [],
  );

  /// Calculates weighted ESG score
  static PortfolioSummary fromHoldings(List<EnrichedHolding> holdings) {
    if (holdings.isEmpty) return empty;

    double totalValue = 0;
    double totalCost = 0;
    double totalCO2 = 0;
    double weightedEsgSum = 0;

    for (final h in holdings) {
      final value = h.totalValue;
      totalValue += value;
      totalCost += h.totalCost;
      totalCO2 += h.esg.co2Emission;
      weightedEsgSum += value * h.esg.esgScore;
    }

    final greenScore = totalValue > 0 ? weightedEsgSum / totalValue : 0.0;

    return PortfolioSummary(
      totalValue: totalValue,
      totalCost: totalCost,
      totalCO2: totalCO2,
      greenScore: greenScore,
      holdings: holdings,
    );
  }
}
