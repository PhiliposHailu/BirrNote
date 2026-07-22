import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

final GlobalKey budgetHeaderKey = GlobalKey();
final GlobalKey expenseListKey = GlobalKey();
final GlobalKey chatInputKey = GlobalKey();

class OnboardingTour {
  static List<TargetFocus> _createTargets(BuildContext context) {
    // A. THE SOLID CONTAINER HELPER: Ensures 100% crisp readability with high contrast!
    Widget buildContentCard(String title, String description) {
      return Card(
        elevation: 8,
        color: Colors.white, // Solid white background!
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return [
      // TARGET A: THE BUDGET HEADER
      TargetFocus(
        identify: "TargetBudgetHeader",
        keyTarget: budgetHeaderKey,
        // FIXED: Changed Circle to RRect (Rounded Rectangle) to fit your card!
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return buildContentCard(
                "Today's Spending Power 📊",
                "This card displays exactly how much you can spend today. It automatically rolls over your savings or overspends every week!",
              );
            },
          ),
        ],
      ),

      // TARGET B: THE TRANSACTION LIST
      TargetFocus(
        identify: "TargetExpenseList",
        keyTarget: expenseListKey,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return buildContentCard(
                "Your Daily Log 📝",
                "This is your daily spending feed. If you make a mistake, tap the red trash can icon to delete any item safely with an Undo option.",
              );
            },
          ),
        ],
      ),

      // TARGET C: THE CHAT INPUT BAR
      TargetFocus(
        identify: "TargetChatInput",
        keyTarget: chatInputKey,
        // FIXED: Changed to RRect
        shape: ShapeLightFocus.RRect,
        radius: 24, // Fits your rounded text bar!
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return buildContentCard(
                "Effortless Tracking 💬",
                "Type your transactions naturally here (e.g. 'taxi 50' or 'macchiato 40') and Gemini AI will instantly categorize it, or tap the '+' icon to log it manually!",
              );
            },
          ),
        ],
      ),
    ];
  }

  // 3. LAUNCH THE TOUR
  static void show(BuildContext context) {
    TutorialCoachMark(
      targets: _createTargets(context),
      colorShadow:
          Colors.black, // Darken screen using solid black for maximum contrast!
      opacityShadow: 0.8,
      textSkip: "SKIP",
      // FIXED: Styled the skip button to be bright amber so it never gets lost!
      textStyleSkip: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.amber,
        fontSize: 15,
      ),
      alignSkip: Alignment.topRight,
      paddingFocus:
          4, // FIXED: Shrunk padding from 10 to 4 so it tightly hugs your cards!
    ).show(context: context);
  }
}
