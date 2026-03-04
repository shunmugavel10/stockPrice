import '../models/esg_data.dart';

/// Abstract repository for ESG data operations.
/// Designed to be swappable with OpenESG, ClimateWatch, or ESG Enterprise.
abstract class EsgRepository {
  Future<EsgData> getEsgData(String symbol);
  Future<List<double>> getHistoricalCO2(String symbol, {int months = 12});
}
