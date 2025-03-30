// lib/services/gemini_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class GeminiService {
  static final GeminiService instance = GeminiService._init();
  GeminiService._init();

  Future<String> getPurchaseAdvice({
    required String itemName,
    required double cost,
    required double remainingBudget,
    required double desireRating,
  }) async {
    try {
      // Build the prompt for Gemini
      final prompt =
          "The user wants to buy $itemName, for \$${cost.toStringAsFixed(2)}, "
          "and they have \$${remainingBudget.toStringAsFixed(2)} remaining in their budget, "
          "and their desire rating for this item is ${desireRating.toStringAsFixed(1)}/10. "
          "Evaluate if this is a good purchase. First give a rating from 1-10 where 1 means 'terrible purchase' and 10 means 'excellent purchase'. "
          "Then briefly explain your reasoning in 1-2 sentences. "
          "Format your response exactly like this: 'Rating: X/10\n\nExplanation: Your explanation here' "
          "Make sure to include the newlines exactly as shown, with Rating and Explanation on separate lines.";

      // Call Gemini API using the package
      final response = await Gemini.instance.prompt(
        parts: [Part.text(prompt)],
      );

      // Return the text output
      if (response != null &&
          response.output != null &&
          response.output!.isNotEmpty) {
        return response.output!;
      } else {
        debugPrint('Empty response from Gemini');
        return 'Unable to analyze this purchase at the moment. Please try again later.';
      }
    } catch (e) {
      debugPrint('Error with Gemini API: $e');
      return 'Error analyzing this purchase. Please check your API key and internet connection.';
    }
  }
}
