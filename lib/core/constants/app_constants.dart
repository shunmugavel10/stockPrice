/// Application-wide constants for GreenInvest
class AppConstants {
  AppConstants._();

  static const String appName = 'GreenInvest';
  static const String appTagline = 'Sustainable Stock Portfolio Tracker';

  // API
  static const String globalQuoteFunction = 'GLOBAL_QUOTE';
  static const String symbolSearchFunction = 'SYMBOL_SEARCH';

  // Hive Box Names
  static const String portfolioBox = 'portfolio_box';
  static const String settingsBox = 'settings_box';

  // Settings Keys
  static const String themeModeKey = 'theme_mode';

  // ESG Rating Scale
  static const List<String> esgRatings = [
    'AAA', 'AA', 'A', 'BBB', 'BB', 'B', 'CCC',
  ];

  // Rate Limit
  static const int apiCallIntervalMs = 12500; // Alpha Vantage free: 5 calls/min
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 15);
}
