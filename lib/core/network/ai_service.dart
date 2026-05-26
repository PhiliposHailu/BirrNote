import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'api_key_provider.dart';

class AiService {
  final String? apiKey;

  AiService(this.apiKey);

  Future<Map<String, dynamic>?> parseNoteToExpense(String note) async {
    if (apiKey == null || apiKey!.isEmpty) return null;

    // 1. Initialize the Model (Gemini Flash is incredibly fast and cheap)
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey!,
      // 2. THE ZOD EQUIVALENT: We force the AI to return exactly this JSON structure.
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: Schema.object(
          properties: {
            'amount': Schema.number(description: 'The total cost or price mentioned. If none, return 0.0.'),
            'category': Schema.string(description: 'A 1-2 word category (e.g., Food, Transport, Utilities, Entertainment, Groceries, Drink).'),
            'quantity': Schema.integer(description: 'The number of items bought. Default to 1 unless the user explicitly mentions a different quantity.'),
          },
          requiredProperties: ['amount', 'category', 'quantity'],
        ),
      ),
    );

    try {
      // 3. Send the note to the AI
      final prompt = 'Extract the financial details from this note: "$note"';
      final response = await model.generateContent([Content.text(prompt)]);

      // 4. Parse the guaranteed JSON response
      if (response.text != null) {
        return jsonDecode(response.text!) as Map<String, dynamic>;
      }
    } catch (e) {
      print('AI Parsing Error: $e');
      return null; // If offline or fails, we return null so the note stays "pending"
    }
    return null;
  }
}

// A provider that automatically updates if the user changes their API key in Settings
final aiServiceProvider = Provider<AiService>((ref) {
  final apiKey = ref.watch(apiKeyProvider);
  return AiService(apiKey);
});