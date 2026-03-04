# GreenInvest – Sustainable Stock Portfolio Tracker

A production-ready Flutter mobile app that tracks stock investments and monitors the carbon footprint & ESG score of invested companies.

## Tech Stack

- **Architecture**: Clean Architecture (Presentation → Domain → Data) + MVVM
- **State Management**: Riverpod
- **Navigation**: GoRouter with bottom nav shell
- **Networking**: Dio + Alpha Vantage API
- **Local Storage**: Hive
- **Charts**: fl_chart (Pie + Bar)
- **Theme**: Light/Dark with glassmorphism cards
- **ESG**: Mock service (swappable for OpenESG/ClimateWatch/ESG Enterprise)

## Setup

```bash
# 1. Install dependencies
flutter pub get

# 2. Run the app
flutter run
```

The `.env` file is already included with the Alpha Vantage API key.

## Project Structure

```
lib/
├── core/
│   ├── constants/     # Colors, app constants
│   ├── navigation/    # GoRouter config, shell scaffold
│   ├── network/       # Dio client, API result wrapper
│   ├── theme/         # Light/dark ThemeData + extensions
│   └── utils/         # Extensions, ESG helpers
├── features/
│   ├── dashboard/
│   │   └── presentation/
│   │       ├── providers/   # Theme provider
│   │       └── screens/     # Dashboard, Settings
│   ├── portfolio/
│   │   ├── data/
│   │   │   ├── repositories/  # Hive + API impls
│   │   │   └── services/      # Alpha Vantage, Mock ESG
│   │   ├── domain/
│   │   │   ├── models/        # StockHolding, StockQuote, EsgData, PortfolioSummary
│   │   │   └── repositories/  # Abstract repos
│   │   └── presentation/
│   │       ├── providers/     # Riverpod providers
│   │       └── screens/       # Portfolio screen
│   └── stock_search/
│       ├── data/repositories/
│       ├── domain/
│       │   ├── models/
│       │   └── repositories/
│       └── presentation/
│           ├── providers/
│           └── screens/
├── shared/widgets/    # Shimmer, empty state, error, glassmorphism card, ESG badge
└── main.dart
```

## Key Features

- **Add Stock**: Search symbols via Alpha Vantage, enter quantity & buy price, persist in Hive
- **Real-time Prices**: GLOBAL_QUOTE API with rate-limit handling & retry logic
- **ESG + CO₂ Data**: Mock service with deterministic data per symbol
- **Dashboard**: Portfolio value, Green Score, CO₂ impact, pie/bar charts, holdings list
- **Green Score**: Weighted ESG formula `Σ(stockValue × esgScore) / totalPortfolioValue`
- **Eco Suggestions**: Suggests alternatives when ESG < 50
- **Dark/Light Mode**: System default + manual toggle, persisted in Hive
- **Pull-to-Refresh**: On dashboard and portfolio screens
- **Error Handling**: Rate limit, network failure, invalid symbol, empty portfolio
