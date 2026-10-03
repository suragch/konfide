# Guide: Adding and Managing Questions in Konfide

This guide explains how to add, edit, and organize question decks in Konfide.

## 1. Overview

Konfide separates questions into two categories:
* **Preset (Curated) Packs**: Bundled inside the app under `assets/decks/*.json`. These are read-only for players, but players can duplicate them to create custom variations.
* **Custom Packs**: Created, duplicated, or imported by users directly inside the app, stored in the local SQLite database.

All preset decks live in the `assets/decks/` directory:
```
konfide/
├── assets/
│   └── decks/
│       ├── getting_to_know_you.json
│       ├── friends_and_family.json
│       ├── couples_romance.json
│       ├── family_generations.json
│       ├── thought_provoking.json
│       └── deeply_personal.json
```

---

## 2. Adding or Editing Questions in an Existing Pack

### Step 1: Open the Deck File
Navigate to `assets/decks/` and open the pack you want to modify (e.g., `assets/decks/getting_to_know_you.json`).

### Step 2: Add or Edit Questions
Add new question strings to the `"questions"` array:
```json
{
  "id": "getting_to_know_you",
  "version": 2,
  "title": "Getting to Know You",
  ...
  "questions": [
    "What place on earth feels most like home to you, and what makes it feel that way?",
    "What's a small ritual or habit in your day that brings you unexpected peace?",
    "NEW QUESTION: If you could apprentice with any master artisan for a month, who would it be?"
  ]
}
```

### Step 3: Bump the Version Number
> [!IMPORTANT]
> Whenever you modify questions or metadata in an existing preset deck, **increment the `"version"` field by 1** (e.g. from `1` to `2`).
>
> The app compares this version number with the user's local SQLite database. When `asset.version > db.version`, the app automatically syncs the updates without resetting the user's favorites or notes.

---

## 3. Creating a Brand New Preset Pack

To add a completely new curated pack to the app:

### Step 1: Create a New JSON File
Create a new file in `assets/decks/` named `<your_deck_id>.json` (e.g. `assets/decks/career_and_dreams.json`).

### Step 2: Add the Deck JSON
Paste the following template and fill in your content:
```json
{
  "id": "career_and_dreams",
  "version": 1,
  "title": "Career & Aspirations",
  "description": "Meaningful questions about vocation, proud accomplishments, creative callings, and future dreams.",
  "icon": "lightbulb",
  "accentColor": "#0EA5E9",
  "questions": [
    "What was the first project or job where you felt a genuine sense of flow?",
    "If money were completely irrelevant, what work would you spend your days doing?",
    "What is a professional risk you took that you are proud of, regardless of the outcome?",
    "Who has been the most influential mentor or guide in your journey so far?"
  ]
}
```

### Step 3: Register the Asset in `PresetDeckService`
Open [`lib/core/services/preset_deck_service.dart`](file:///Users/suragch/Dev/FlutterProjects/konfide/lib/core/services/preset_deck_service.dart) and add the path to `presetAssetFiles`:

```dart
static const List<String> presetAssetFiles = [
  'assets/decks/getting_to_know_you.json',
  'assets/decks/friends_and_family.json',
  'assets/decks/couples_romance.json',
  'assets/decks/family_generations.json',
  'assets/decks/thought_provoking.json',
  'assets/decks/deeply_personal.json',
  'assets/decks/career_and_dreams.json', // <-- Add here
];
```

### Step 4: Run Tests
Run the test suite to verify your JSON is valid:
```bash
flutter test
```

When users update or launch the app, Konfide automatically detects the new deck ID and adds it to their catalog.

---

## 4. Deck JSON Schema & Field Reference

| Field         |   Type   | Required | Description                                       | Example                  |
| :------------ | :------: | :------: | :------------------------------------------------ | :----------------------- |
| `id`          | `String` |   Yes    | Unique identifier (lowercase, underscores).       | `"couples_romance"`      |
| `version`     |  `int`   |   Yes    | Monotonically increasing version counter.         | `1`, `2`, `3`            |
| `title`       | `String` |   Yes    | Display name of the pack.                         | `"Two Hearts & Romance"` |
| `description` | `String` |   Yes    | 1-2 sentence description of the pack's focus.     | `"Romantic intimacy..."` |
| `icon`        | `String` |   Yes    | Icon key mapped to a Material icon (see below).   | `"heart"`                |
| `accentColor` | `String` |   Yes    | 6-digit hex color code starting with `#`.         | `"#E11D48"`              |
| `questions`   | `Array`  |   Yes    | List of question strings (or structured objects). | `["Question 1?", ...]`   |

### Supported Icon Keys
Use any of the following icon keywords in the `"icon"` field:

| Icon Key      | Rendered Icon                 | Common Use Case                            |
| :------------ | :---------------------------- | :----------------------------------------- |
| `"sparkles"`  | `Icons.auto_awesome`          | Icebreakers, curiosity, creative questions |
| `"people"`    | `Icons.people_outline`        | Friends, camaraderie, social memories      |
| `"heart"`     | `Icons.favorite_outline`      | Couples, romance, vulnerability            |
| `"home"`      | `Icons.home_outlined`         | Family, heritage, childhood roots          |
| `"mind"`      | `Icons.psychology_outlined`   | Philosophy, deep thoughts, mind-benders    |
| `"fire"`      | `Icons.local_fire_department` | Honest reflections, real talk, courage     |
| `"lightbulb"` | `Icons.lightbulb_outline`     | Ideas, career, innovation, problem-solving |
| `"explore"`   | `Icons.explore_outlined`      | Travel, adventure, life journeys           |
| `"chat"`      | `Icons.chat_bubble_outline`   | General discussion (fallback default)      |

### Question Formats: Simple vs. Structured
You can format the `"questions"` array in two ways:

#### Option A: Simple Strings (Recommended for most packs)
```json
"questions": [
  "What was your favorite vacation memory?",
  "What is something you're grateful for today?"
]
```
The app will automatically assign stable IDs formatted as `${deck_id}_${index + 1}` (e.g. `getting_to_know_you_1`).

#### Option B: Structured Objects with Explicit IDs
```json
"questions": [
  {
    "id": "gtk_home_place",
    "text": "What place on earth feels most like home to you?"
  },
  {
    "id": "gtk_morning_habit",
    "text": "What's a small ritual in your day that brings you peace?"
  }
]
```
Explicit IDs are useful if you plan to reorder questions frequently and want to guarantee that user favorites and notes stay permanently anchored to that specific question.

---

## 5. How Future Updates Reach Users (Sync Engine)

When an existing user updates their app through an app store release, their local database already has data from the previous version. Here is how the startup sync engine protects their experience:

1. **Auto-Discovery of New Packs**:
   - The app inspects all files in `PresetDeckService.presetAssetFiles`.
   - If an asset ID does not exist in SQLite, it inserts the new deck and all questions automatically.

2. **Smart Question Upsert on Version Bump**:
   - If `asset.version > db.version`:
     - Updates the deck title, description, icon, and accent color.
     - For existing questions (matching ID): Updates the text in place. **Favorites and personal reflection notes remain linked to that question ID.**
     - For new questions: Appends them to the deck.
     - For retired questions: Safely deletes them from the database.
     - Updates the stored `version` to match the asset.

3. **User Isolation**:
   - Decks duplicated or created by the user have `is_preset = 0` and unique UUIDs (`custom_...`).
   - Sync operations **never touch or alter custom or duplicated decks**.

4. **Restoring Factory Presets**:
   - If a user ever wants to revert their standard packs to factory defaults, they can tap **Restore Standard Packs** in the **Settings** screen.

---

## 6. Creating Packs In-App and Exporting to Assets

You can also draft and test question packs right inside the Konfide app before adding them to code:

1. Launch Konfide on your phone or computer.
2. Tap the **+** (New Pack) button under **Your Custom Packs**.
3. Fill in the title, description, choose a color, and type in your questions.
4. Tap the three dots (`⋮`) on your custom pack and choose **Export Pack (.json)**.
5. Save the file or copy the JSON to your clipboard.
6. Paste the exported `.json` file into `assets/decks/<pack_id>.json`.
7. Add the file to `PresetDeckService.presetAssetFiles` in `lib/core/services/preset_deck_service.dart`.

Your custom pack is now an official preset pack for all users!

---

## 7. Verification & Testing

After modifying or adding asset files, run these commands in the terminal:

```bash
# 1. Run the test suite
flutter test

# 2. Check code quality
flutter analyze
```

Konfide includes automated unit tests that verify:
* All preset JSON files are valid JSON.
* Every pack contains non-empty metadata and valid colors/icons.
* The total question catalog maintains high quality and coverage.
