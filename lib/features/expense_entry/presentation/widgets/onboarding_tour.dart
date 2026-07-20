import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

// 1. THE SHARED GLOBAL KEYS (Accessible anywhere in the project)
final GlobalKey budgetHeaderKey = GlobalKey();
final GlobalKey expenseListKey = GlobalKey();
final GlobalKey chatInputKey = GlobalKey();

class OnboardingTour {
  // 2. CONSTRUCT THE VISUAL HIGHLIGHT TARGETS
  static List<TargetFocus> _createTargets(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return [
      // Target A: The Budget Header Card
      TargetFocus(
        identify: "TargetBudgetHeader",
        keyTarget: budgetHeaderKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's Spending Power 📊",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "This card displays exactly how much you can spend today. It automatically rolls over your savings or overspends every week!",
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      
      // Target B: The Expense List
      TargetFocus(
        identify: "TargetExpenseList",
        keyTarget: expenseListKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Your Daily Log 📝",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "This is your daily spending feed. If you make a mistake, tap the red trash can icon to delete any item safely with an Undo option.",
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                  ),
                ],
              );
            },
          ),
        ],
      ),

      // Target C: The Chat Input Bar
      TargetFocus(
        identify: "TargetChatInput",
        keyTarget: chatInputKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Effortless Tracking 💬",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Type your transactions naturally here (e.g. 'taxi 50' or 'macchiato 40') and Gemini AI will instantly categorize it, or tap the '+' icon to log it manually!",
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ];
  }

  // 3. LAUNCH THE TOUR
  static void show(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    TutorialCoachMark(
      targets: _createTargets(context),
      colorShadow: colorScheme.primary, // Dims screen using primary blue-leather theme color!
      opacityShadow: 0.85,
      textSkip: "SKIP",
      textStyleSkip: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
      alignSkip: Alignment.topRight,
      paddingFocus: 10,
    ).show(context: context);
  }
}