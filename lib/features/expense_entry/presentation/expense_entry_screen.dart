import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/expense_list.dart';
import 'widgets/chat_input_bar.dart';
import '../../settings/presentation/settings_screen.dart';
import '../data/expense_providers.dart';

// ----------------------------------------------------------------------
// CLASS 1: The Widget itself. Notice it extends ConsumerStatefulWidget!
// ----------------------------------------------------------------------
class ExpenseEntryScreen extends ConsumerStatefulWidget {
  const ExpenseEntryScreen({super.key});

  @override
  ConsumerState<ExpenseEntryScreen> createState() => _ExpenseEntryScreenState();
}

// ----------------------------------------------------------------------
// CLASS 2: The State class. This holds your variables, listeners, and build method.
// ----------------------------------------------------------------------
class _ExpenseEntryScreenState extends ConsumerState<ExpenseEntryScreen> {
  late final StreamSubscription<List<ConnectivityResult>>
  _connectivitySubscription;

  @override
  void initState() {
    super.initState();

    // 1. Check once when the app opens
    Future.microtask(() => ref.read(expenseLogicProvider).syncPendingNotes());

    // 2. Listen for network changes while the app is open
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      // If the device connects to Mobile Data or WiFi...
      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi)) {
        Future.delayed(const Duration(seconds: 2), () {
          ref.read(expenseLogicProvider).syncPendingNotes();
        });
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Expanded(child: ExpenseList()),
        ChatInputBar(),
      ],
    );
  }
}
