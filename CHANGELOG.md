# Changelog

## [2.0.0] - 2026-10-10

### Added
- **Architecture Overhaul**: Migrated to a modular feature-first architecture powered by SQLite (`sqflite`).
- **Preset Decks System**: Bundled curated question decks as version-controlled JSON assets (`assets/decks/`) with automatic SQLite database seeding and update sync:
  - *Getting to Know You*
  - *Friends*
  - *Couples & Romance*
  - *Family & Generations*
  - *Thought Provoking*
  - *Deeply Personal*
  - *Christian Faith*
- **Tactile Card Interface**: Interactive swipeable card stack featuring fluid gesture physics, rotation animations, and haptic feedback.
- **Custom Decks**: Create, edit, and delete custom question decks directly inside the app.
- **Import & Export**: Share custom decks and backup collections via JSON export and import.
- **Card Sharing**: Share conversation starter cards as formatted text or card images.
- **Favorites**: Bookmark questions across decks for quick access.
- **Companion Tracking**: Associate conversation progress with specific people/companions.
- **Daily Question**: Randomized daily question displayed on the main screen to prompt everyday conversations.
- **Offline Typography**: Bundled *Newsreader* and *Plus Jakarta Sans* fonts locally for reliable offline rendering.
- **Settings Screen**: Added configuration for haptic feedback, theme preferences, and data management.
- **Test Suite**: Comprehensive unit and widget tests covering database operations, services, models, and UI components.

### Changed
- Migrated Android build scripts from Groovy (`build.gradle`) to Kotlin DSL (`build.gradle.kts`).
- Replaced hardcoded static question lists with dynamic database storage and asset synchronizer.
- Modernized theme, colors, and responsive layouts.

### Removed
- Removed legacy unused desktop platform folders (`linux/`, `windows/`).
- Removed static `questions.dart` data file in favor of SQLite database and JSON preset decks.

## [1.0.0] - 2024-08-14

### Added
- Initial release of the Konfide conversation starter app for Android.
- Carousel slider card view for browsing conversation questions.
- Built-in categories of questions to spark face-to-face conversations.
- Clean and minimal UI supporting light and dark themes.
