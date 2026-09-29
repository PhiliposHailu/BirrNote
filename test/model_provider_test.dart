import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:birr_note/core/network/model_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GeminiModelInfo', () {
    test('serializes to and from JSON correctly', () {
      const model = GeminiModelInfo(
        id: 'gemini-3.8-flash',
        displayName: 'Gemini 3.8 Flash',
      );

      final json = model.toJson();
      expect(json['id'], 'gemini-3.8-flash');
      expect(json['displayName'], 'Gemini 3.8 Flash');

      final reconstructed = GeminiModelInfo.fromJson(json);
      expect(reconstructed.id, model.id);
      expect(reconstructed.displayName, model.displayName);
      expect(reconstructed, equals(model));
    });

    test('default models list contains gemini-3.8-flash as primary', () {
      expect(kDefaultGeminiModels.isNotEmpty, isTrue);
      expect(kDefaultGeminiModels.first.id, 'gemini-3.8-flash');
      expect(kDefaultModelId, 'gemini-3.8-flash');
    });
  });

  group('SelectedModelNotifier', () {
    test('defaults to gemini-3.8-flash and updates state', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = SelectedModelNotifier();

      expect(notifier.state, 'gemini-3.8-flash');

      await notifier.setModel('gemini-2.5-flash');
      expect(notifier.state, 'gemini-2.5-flash');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_gemini_model'), 'gemini-2.5-flash');
    });

    test('loads saved model from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'selected_gemini_model': 'gemini-1.5-flash',
      });

      final notifier = SelectedModelNotifier();
      // Allow async _load to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(notifier.state, 'gemini-1.5-flash');
    });
  });

  group('AvailableModelsNotifier', () {
    test('falls back to default models when no cache exists', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = AvailableModelsNotifier();

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(notifier.state.valueOrNull, isNotNull);
      expect(notifier.state.valueOrNull, equals(kDefaultGeminiModels));
    });

    test('loads cached models from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'cached_gemini_models':
            '[{"id":"custom-gemini-model","displayName":"Custom Model"}]',
      });

      final notifier = AvailableModelsNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.valueOrNull, isNotNull);
      expect(notifier.state.valueOrNull?.length, 1);
      expect(notifier.state.valueOrNull?.first.id, 'custom-gemini-model');
    });
  });
}
