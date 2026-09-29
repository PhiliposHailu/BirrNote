import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GeminiModelInfo {
  final String id;
  final String displayName;

  const GeminiModelInfo({required this.id, required this.displayName});

  Map<String, dynamic> toJson() => {'id': id, 'displayName': displayName};

  factory GeminiModelInfo.fromJson(Map<String, dynamic> json) =>
      GeminiModelInfo(
        id: json['id'] as String,
        displayName: json['displayName'] as String? ?? json['id'] as String,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeminiModelInfo &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const List<GeminiModelInfo> kDefaultGeminiModels = [
  GeminiModelInfo(id: 'gemini-3.8-flash', displayName: 'Gemini 3.8 Flash'),
  GeminiModelInfo(id: 'gemini-2.5-flash', displayName: 'Gemini 2.5 Flash'),
  GeminiModelInfo(id: 'gemini-1.5-flash', displayName: 'Gemini 1.5 Flash'),
  GeminiModelInfo(
    id: 'gemini-3.1-flash-lite',
    displayName: 'Gemini 3.1 Flash Lite',
  ),
];

const String kDefaultModelId = 'gemini-3.8-flash';
const String _cachedModelsKey = 'cached_gemini_models';
const String _selectedModelKey = 'selected_gemini_model';

extension AsyncValueExtension<T> on AsyncValue<T> {
  T? get valueOrNull {
    final self = this;
    return self is AsyncData<T> ? self.value : null;
  }
}

class AvailableModelsNotifier
    extends StateNotifier<AsyncValue<List<GeminiModelInfo>>> {
  AvailableModelsNotifier() : super(const AsyncValue.loading()) {
    _loadFromCacheAndSync();
  }

  Future<void> _loadFromCacheAndSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cachedModelsKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List<dynamic> list = jsonDecode(cachedJson);
        final models = list
            .map(
              (item) => GeminiModelInfo.fromJson(item as Map<String, dynamic>),
            )
            .toList();
        if (models.isNotEmpty) {
          state = AsyncValue.data(models);
          return;
        }
      }
    } catch (_) {
      // In case of corrupted cache, fall back to defaults
    }
    state = const AsyncValue.data(kDefaultGeminiModels);
  }

  Future<void> refresh(String? apiKey) async {
    if (apiKey == null || apiKey.trim().isEmpty) {
      return;
    }

    state = const AsyncValue.loading();

    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=${apiKey.trim()}',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> rawModels = data['models'] ?? [];

        final models = rawModels
            .where((m) {
              final methods = List<String>.from(
                m['supportedGenerationMethods'] ?? [],
              );
              return methods.contains('generateContent');
            })
            .map((m) {
              final rawName = m['name'] as String? ?? '';
              final cleanId = rawName.startsWith('models/')
                  ? rawName.substring(7)
                  : rawName;
              final displayName = (m['displayName'] as String?)?.trim();
              return GeminiModelInfo(
                id: cleanId,
                displayName: (displayName != null && displayName.isNotEmpty)
                    ? displayName
                    : cleanId,
              );
            })
            .where((m) => m.id.isNotEmpty)
            .toList();

        if (models.isNotEmpty) {
          // Sort alphabetically by display name
          models.sort((a, b) => a.displayName.compareTo(b.displayName));

          final prefs = await SharedPreferences.getInstance();
          final encoded = jsonEncode(models.map((e) => e.toJson()).toList());
          await prefs.setString(_cachedModelsKey, encoded);

          state = AsyncValue.data(models);
          return;
        }
      }

      await _fallbackToCachedOrDefault();
    } catch (_) {
      await _fallbackToCachedOrDefault();
    }
  }

  Future<void> _fallbackToCachedOrDefault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cachedModelsKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List<dynamic> list = jsonDecode(cachedJson);
        final models = list
            .map(
              (item) => GeminiModelInfo.fromJson(item as Map<String, dynamic>),
            )
            .toList();
        if (models.isNotEmpty) {
          state = AsyncValue.data(models);
          return;
        }
      }
    } catch (_) {}
    state = const AsyncValue.data(kDefaultGeminiModels);
  }
}

final availableModelsProvider =
    StateNotifierProvider<
      AvailableModelsNotifier,
      AsyncValue<List<GeminiModelInfo>>
    >((ref) {
      return AvailableModelsNotifier();
    });

class SelectedModelNotifier extends StateNotifier<String> {
  SelectedModelNotifier() : super(kDefaultModelId) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_selectedModelKey) ?? kDefaultModelId;
  }

  Future<void> setModel(String modelId) async {
    final cleanId = modelId.trim();
    if (cleanId.isEmpty || cleanId == state) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedModelKey, cleanId);
    state = cleanId;
  }
}

final selectedModelProvider =
    StateNotifierProvider<SelectedModelNotifier, String>((ref) {
      return SelectedModelNotifier();
    });
