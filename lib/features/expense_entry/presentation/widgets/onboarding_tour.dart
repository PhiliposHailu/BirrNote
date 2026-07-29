import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/locale_provider.dart';

final GlobalKey budgetHeaderKey = GlobalKey();
final GlobalKey expenseListKey = GlobalKey();
final GlobalKey chatInputKey = GlobalKey();

class OnboardingTour {
  static List<TargetFocus> _createTargets(BuildContext context, WidgetRef ref) {
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
                ref.watch(trProvider('budget_tour_title')),
                ref.watch(trProvider('budget_tour_desc')),
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
                ref.watch(trProvider('log_tour_title')),
                ref.watch(trProvider('log_tour_desc')),
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
                ref.watch(trProvider('chat_tour_title')),
                ref.watch(trProvider('chat_tour_desc')),
              );
            },
          ),
        ],
      ),
    ];
  }

  // 3. LAUNCH THE TOUR
  static void show(BuildContext context, WidgetRef ref) {
    TutorialCoachMark(
      targets: _createTargets(context, ref),
      colorShadow:
          Colors.black, // Darken screen using solid black for maximum contrast!
      opacityShadow: 0.8,
      textSkip: ref.watch(trProvider('skip')),
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
