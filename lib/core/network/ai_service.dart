import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'api_key_provider.dart';

class AiService {
  final String? apiKey;

  AiService(this.apiKey);

  // returns a List of Maps!
  Future<List<Map<String, dynamic>>?> parseNoteToExpenses(String note) async {
    if (apiKey == null || apiKey!.isEmpty) return null;

    final model = GenerativeModel(
      model: 'gemini-3.1-flash-lite',
      apiKey: apiKey!,
      systemInstruction: Content.system('''
        You are the financial parser for BirrNote. Extract a JSON list of expenses.
        
        RULES:
        1. CATEGORY: Strictly use ONLY one of: [Food, Transport, Shopping, Utilities, Entertainment, Health, Transfer, General].
        2. NAME: Set 'extractedNote' to a short, clean name (e.g., "Coffee", "Gas").
        3. PRICING & GROUPING:
           - Distinct prices: "Gas 200, Food 100" -> Return 2 objects.
           - Group total: "Groceries 500 for milk and eggs" -> Return 1 object (Amount: 500, Name: "Groceries").
           - Partial prices: "Shirt, pants, and coffee 50" -> Return 3 objects. Coffee gets 50.0. Shirt and pants get 0.0.
           - Missing price: Always use 0.0.
        4. NOISE: If text contains no expenses (e.g., "Hello", "What's up"), return [].
        5. CURRENCY: Assume Ethiopian Birr (ETB).
      '''),
      
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: Schema.array(
          items: Schema.object(
            properties: {
              'extractedNote': Schema.string(
                description: 'A short, clean name for this specific expense.',
              ),
              'amount': Schema.number(description: 'The total cost.'),
              'category': Schema.string(
                description: 'A 1-2 word broad category.',
              ),
              'quantity': Schema.integer(
                description: 'Number of items. Default to 1.',
              ),
            },
            requiredProperties: [
              'extractedNote',
              'amount',
              'category',
              'quantity',
            ],
          ),
        ),
      ),
    );

    try {
      final response = await model.generateContent([Content.text(note)]);

      if (response.text != null) {
        // Decode the JSON array
        final List<dynamic> decodedList = jsonDecode(response.text!);
        // Cast it safely to a List of Maps
        return decodedList.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('AI Parsing Error: $e');
      return null;
    }
    return null;
  }

  // The Financial Advisor Chat Method
  Future<String> askAdvisor(
    String userQuestion,
    String financialContext,
  ) async {
    if (apiKey == null || apiKey!.isEmpty) {
      return "Please add your Gemini API Key in Settings first ;)";
    }

    // 1. We initialize a conversational model
    final model = GenerativeModel(
      model: 'gemini-3.1-flash-lite',
      apiKey: apiKey!,
      systemInstruction: Content.system('''
        You are a friendly, professional financial advisor for the BirrNote app.
        The user is asking you for financial advice. 
        
        Here is the user's current spending summary:
        $financialContext
        
        RULES:
        1. Base your advice STRICTLY on the spending summary provided above.
        2. Keep your answers concise, practical, and conversational.
        3. Do not use markdown formatting like **bold** or *italics* too heavily, keep it clean for a mobile screen.
        4. If they ask something unrelated to finance, politely steer them back to their budget.
      '''),
    );

    try {
      final response = await model.generateContent([
        Content.text(userQuestion),
      ]);
      return response.text ?? "I'm sorry, I couldn't process that right now.";
    } catch (e) {
      print('Advisor AI Error: $e');
      return "Looks like you're offline or there was an error connecting to the AI.";
    }
  }
}

final aiServiceProvider = Provider<AiService>((ref) {
  final apiKey = ref.watch(apiKeyProvider);
  return AiService(apiKey);
});
