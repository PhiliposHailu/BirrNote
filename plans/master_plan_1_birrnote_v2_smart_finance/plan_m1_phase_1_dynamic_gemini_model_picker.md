# Phase 1 Plan — Dynamic Gemini Model Picker

> **Master Plan:** [Master Plan 1 — BirrNote v2.0: Smart Finance Engine](file:///home/philipos/Desktop/Dev/birr_note/plans/master_plan_1_birrnote_v2_smart_finance/master_plan_1_birrnote_v2_smart_finance.md)  
> **Status:** Completed — Audited & Verified  
> **Target Package:** `birr_note`  
> **Scope:** Dynamic runtime discovery, offline caching, and user selection of Gemini models for note parsing and advisor chat  

---

## 1. Executive Summary & Problem Statement

Currently, BirrNote hardcodes the model identifier `'gemini-3.1-flash-lite'` across two critical call sites in [`ai_service.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/core/network/ai_service.dart#L22):
1. `parseNoteToExpenses()` (Natural language expense parser)
2. `askAdvisor()` (Financial advisor chat stream)

When Google deprecates, renames, or introduces newer and faster models (such as `gemini-3.8-flash`), the application risks silent failures or degraded intelligence. 

**Phase 1 Solution:**
- Query Google's Generative Language REST API (`GET /v1beta/models?key=KEY`) upon key entry or refresh.
- Filter for models supporting `generateContent`.
- Cache the retrieved list in `SharedPreferences` for seamless offline resilience.
- Provide a clean, zero-clutter model picker in the settings interface with `gemini-3.8-flash` as default.
- Inject the active model dynamically into `AiService`.

---

## 2. UI/UX & HCI Principles Alignment

Per the platform's [Zero-Clutter Standard](file:///home/philipos/Desktop/Dev/.agents/rules/ui-ux-design-principles.md):
- **Cognitive Load Reduction & Progressive Disclosure:** 
  - If no API key is saved, the model picker remains hidden to avoid distracting users during initial setup.
  - Once a key is validated, the active model is clearly displayed with an intuitive dropdown to switch models.
- **Recognition Over Recall:**
  - Display clean, human-readable model names (e.g. `Gemini 3.8 Flash`, `Gemini 2.5 Flash`) rather than raw API endpoint strings (`models/gemini-3.8-flash`).
  - Active model is highlighted with a distinct badge.
- **Trust & Transparency:**
  - Clearly indicate connection status: "Online" (live models refreshed) vs. "Offline" (using cached models).
  - API keys are strictly read from secure storage and never exposed in error messages or logs.
- **Mobile Ergonomics & Fitts's Law:**
  - All interactive elements (dropdown trigger, refresh button, option items) maintain a minimum hit area of **44x44px**.
  - Dropdown fits comfortably within the modal bottom sheet thumb zone.

---

## 3. Architecture & File Matrix

```
lib/
├── core/
│   ├── network/
│   │   ├── ai_service.dart          # [MODIFY] Accept modelName, remove hardcoded strings
│   │   ├── api_key_provider.dart    # [MODIFY] Trigger model refresh on key save / reset on delete
│   │   └── model_provider.dart      # [CREATE] Model data model, REST client, cache, Riverpod providers
│   └── utils/
│       └── app_translations.dart    # [MODIFY] Add 4-language keys for model picker
└── features/
    └── settings/
        └── presentation/
            ├── settings_screen.dart # [MODIFY] Show active model in Gemini tile subtitle
            └── widgets/
                └── gemini_key_sheet.dart # [MODIFY] Embed model dropdown & refresh action
```

### Exact Files to Modify / Create

| Action | Absolute File Path | Description |
|---|---|---|
| **MODIFY** | [`pubspec.yaml`](file:///home/philipos/Desktop/Dev/birr_note/pubspec.yaml) | Add `http: ^1.4.0` dependency |
| **CREATE** | [`lib/core/network/model_provider.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/core/network/model_provider.dart) | Data model `GeminiModelInfo`, REST fetcher, SharedPreferences caching, Riverpod providers |
| **MODIFY** | [`lib/core/network/ai_service.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/core/network/ai_service.dart) | Inject `modelName` parameter; replace hardcoded model strings |
| **MODIFY** | [`lib/core/network/api_key_provider.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/core/network/api_key_provider.dart) | Trigger model fetch on `saveKey()` |
| **MODIFY** | [`lib/core/utils/app_translations.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/core/utils/app_translations.dart) | Add translation strings across English (`en`), Amharic (`am`), Afaan Oromoo (`om`), Tigrinya (`ti`) |
| **MODIFY** | [`lib/features/settings/presentation/widgets/gemini_key_sheet.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/settings/presentation/widgets/gemini_key_sheet.dart) | Add model selection dropdown and refresh action |
| **MODIFY** | [`lib/features/settings/presentation/settings_screen.dart`](file:///home/philipos/Desktop/Dev/birr_note/lib/features/settings/presentation/settings_screen.dart) | Display active model in Gemini tile subtitle |

---

## 4. Technical Schemas & Data Contracts

### 4.1 Data Model: `GeminiModelInfo`
```dart
class GeminiModelInfo {
  final String id;          // e.g. "gemini-3.8-flash" (stripped of 'models/' prefix)
  final String displayName; // e.g. "Gemini 3.8 Flash"

  const GeminiModelInfo({
    required this.id,
    required this.displayName,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
  };

  factory GeminiModelInfo.fromJson(Map<String, dynamic> json) => GeminiModelInfo(
    id: json['id'] as String,
    displayName: json['displayName'] as String,
  );
}
```

### 4.2 Built-in Hardcoded Fallbacks (Zero Network Dependency)
If the device has never been online or the REST call fails:
```dart
const List<GeminiModelInfo> kDefaultGeminiModels = [
  GeminiModelInfo(id: 'gemini-3.8-flash', displayName: 'Gemini 3.8 Flash'),
  GeminiModelInfo(id: 'gemini-2.5-flash', displayName: 'Gemini 2.5 Flash'),
  GeminiModelInfo(id: 'gemini-1.5-flash', displayName: 'Gemini 1.5 Flash'),
  GeminiModelInfo(id: 'gemini-3.1-flash-lite', displayName: 'Gemini 3.1 Flash Lite'),
];
```

### 4.3 Google Models REST API Contract
- **Endpoint:** `GET https://generativelanguage.googleapis.com/v1beta/models?key={apiKey}`
- **Header:** `Content-Type: application/json`
- **Filtering Logic:**
  ```dart
  final List<dynamic> rawModels = body['models'] ?? [];
  final filtered = rawModels.where((m) {
    final methods = List<String>.from(m['supportedGenerationMethods'] ?? []);
    return methods.contains('generateContent');
  }).map((m) {
    final rawName = m['name'] as String; // e.g. "models/gemini-3.8-flash"
    final cleanId = rawName.startsWith('models/') ? rawName.substring(7) : rawName;
    final displayName = m['displayName'] as String? ?? cleanId;
    return GeminiModelInfo(id: cleanId, displayName: displayName);
  }).toList();
  ```

### 4.4 SharedPreferences Keys
- `'cached_gemini_models'`: JSON array of serialized `GeminiModelInfo`
- `'selected_gemini_model'`: String model ID (Default: `'gemini-3.8-flash'`)

### 4.5 Riverpod State Architecture
```dart
// 1. Manages list of available models (loaded from cache, updated via network)
class AvailableModelsNotifier extends StateNotifier<AsyncValue<List<GeminiModelInfo>>> { ... }
final availableModelsProvider = StateNotifierProvider<AvailableModelsNotifier, AsyncValue<List<GeminiModelInfo>>>(...);

// 2. Manages selected model ID
class SelectedModelNotifier extends StateNotifier<String> { ... }
final selectedModelProvider = StateNotifierProvider<SelectedModelNotifier, String>(...);

// 3. Updated AiService Provider
final aiServiceProvider = Provider<AiService>((ref) {
  final apiKey = ref.watch(apiKeyProvider);
  final modelName = ref.watch(selectedModelProvider);
  return AiService(apiKey, modelName: modelName);
});
```

---

## 5. Security, Invariants & Error Handling

1. **Zero Credential Leaks:**
   - The `apiKey` is never persisted in `SharedPreferences`. It remains exclusively in `FlutterSecureStorage`.
   - The models REST request logs zero sensitive authorization tokens or parameters.
2. **Offline-First Resilience:**
   - If offline or API fails, the app uses cached models in `SharedPreferences`.
   - If cache is empty, the app falls back to `kDefaultGeminiModels`.
3. **Invalid Model Graceful Recovery:**
   - If the user had previously selected a model that is no longer returned in the available list, the system falls back to `gemini-3.8-flash` or the first available model rather than throwing an exception.
4. **Idempotent Selection:**
   - Updating the selected model only writes to disk and triggers rebuilds when the value actually changes.

---

## 6. Manageable Implementation Chunks

### Chunk 1: Dependencies & Network Layer
- Add `http: ^1.4.0` to `pubspec.yaml` and run `flutter pub get`.
- Implement `lib/core/network/model_provider.dart` with:
  - `GeminiModelInfo` class with JSON serialization.
  - `kDefaultGeminiModels` fallback constant.
  - `fetchModelsFromApi(String apiKey)` helper with timeout and error trapping.
  - `AvailableModelsNotifier` & `availableModelsProvider`.
  - `SelectedModelNotifier` & `selectedModelProvider`.

### Chunk 2: AiService Parameterization & Key Integration
- Refactor `AiService` in `lib/core/network/ai_service.dart`:
  - Add `final String modelName;` to `AiService`.
  - Update constructor: `AiService(this.apiKey, {this.modelName = 'gemini-3.8-flash'});`.
  - Replace `'gemini-3.1-flash-lite'` with `modelName` in `parseNoteToExpenses()` and `askAdvisor()`.
  - Update `aiServiceProvider` to read both `apiKeyProvider` and `selectedModelProvider`.
- Update `ApiKeyNotifier.saveKey()` to trigger `ref.read(availableModelsProvider.notifier).refresh(key)`.

### Chunk 3: UI Integration (Modal Sheet & Settings)
- Update `lib/features/settings/presentation/widgets/gemini_key_sheet.dart`:
  - When `hasKey` is true, display a dedicated "AI Model" card.
  - Dropdown showing model display names with clean subtitles.
  - Refresh icon button with inline loading indicator.
  - Ensure minimum 44x44px touch targets.
- Update `lib/features/settings/presentation/settings_screen.dart`:
  - Show the current active model in the subtitle of the Gemini API Key tile (e.g. `Key Active • Gemini 3.8 Flash`).

### Chunk 4: Multi-Language Localization
- Update `lib/core/utils/app_translations.dart` with keys:
  - `ai_model`: `AI Model` / `የኤአይ ሞዴል` / `Moodeela AI` / `ናይ AI ሞዴል`
  - `select_model`: `Select Model` / `ሞዴል ይምረጡ` / `Moodeela Filadhu` / `ሞዴል ምረጹ`
  - `refresh_models`: `Refresh Models` / `ሞዴሎችን ያድሱ` / `Moodeelota Haaromsi` / `ሞዴላት ሓድሽ`
  - `models_refreshed`: `Models updated` / `ሞዴሎች ተዘምነዋል` / `Moodeelonni haaromfamaniiru` / `ሞዴላት ተሓዲሶም`
  - `offline_models`: `Offline (Using cached models)` / `ከመስመር ውጭ (የተቀመጡ ሞዴሎች)` / `Toora Alaa` / `ካብ መስመር ወጻኢ`

### Chunk 5: Verification & End-to-End Testing
- Validate code formatting and linting: `flutter analyze`.
- Test model discovery with valid API key.
- Test model selection persistence across app reloads.
- Test offline fallback by toggling airplane mode.
- Verify note parsing and chat advisor use the selected model.

---

## 7. Review & Hold Gate

Per the [Specs-First Development Protocol](file:///home/philipos/Desktop/Dev/.agents/rules/specs-first.md), this document is held for explicit user review and approval. **No production code will be modified until explicit user confirmation is given.**
