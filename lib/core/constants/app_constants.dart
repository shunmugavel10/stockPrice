class AppConstants {
  AppConstants._();

  static const String appName = 'GreenInvest';
  static const String appTagline = 'Sustainable Stock Portfolio Tracker';

  // Marketstack API
  static const String marketstackBaseUrl = 'http://api.marketstack.com/v1';
  static const String marketstackApiKey = '483e55cd1c5ed6435d1a7453b92cb5b9';

  // Hive Box Names
  static const String portfolioBox = 'portfolio_box';
  static const String settingsBox = 'settings_box';

  // Settings Keys
  static const String themeModeKey = 'theme_mode';

  // ESG Rating Scale
  static const List<String> esgRatings = [
    'AAA', 'AA', 'A', 'BBB', 'BB', 'B', 'CCC',
  ];

  // Rate Limit & Caching
  static const int cacheDurationSeconds = 60;
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 15);
}
