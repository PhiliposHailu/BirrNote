import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:birr_note/core/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Amortization DB & DAO', () {
    test('inserts and retrieves active amortization correctly', () async {
      // 1. Insert parent expense
      final expenseId = await db.expenseDao.insertExpense(
        ExpensesCompanion.insert(
          rawNote: 'Telecom 350',
          amount: const Value(350.0),
          category: const Value('Bills'),
          date: DateTime.now(),
        ),
      );

      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);
      final nextWeekMidnight = todayMidnight.add(const Duration(days: 7));

      // 2. Insert amortization
      await db.amortizationDao.insertAmortization(
        AmortizationsCompanion.insert(
          expenseId: expenseId,
          totalAmount: 350.0,
          durationDays: 7,
          dailyBurden: 50.0,
          startDate: todayMidnight,
          endDate: nextWeekMidnight,
        ),
      );

      // 3. Query active amortizations
      final active = await db.amortizationDao
          .watchActiveAmortizations(now)
          .first;
      expect(active.length, 1);
      expect(active.first.expenseId, expenseId);
      expect(active.first.totalAmount, 350.0);
      expect(active.first.durationDays, 7);
      expect(active.first.dailyBurden, 50.0);

      // 4. Query single amortization for expense
      final single = await db.amortizationDao.getAmortizationForExpense(
        expenseId,
      );
      expect(single, isNotNull);
      expect(single!.dailyBurden, 50.0);
    });

    test(
      'deleting parent expense automatically cleans up linked amortization',
      () async {
        final expenseId = await db.expenseDao.insertExpense(
          ExpensesCompanion.insert(
            rawNote: 'Monthly Internet',
            amount: const Value(700.0),
            category: const Value('Bills'),
            date: DateTime.now(),
          ),
        );

        final now = DateTime.now();
        final todayMidnight = DateTime(now.year, now.month, now.day);

        await db.amortizationDao.insertAmortization(
          AmortizationsCompanion.insert(
            expenseId: expenseId,
            totalAmount: 700.0,
            durationDays: 14,
            dailyBurden: 50.0,
            startDate: todayMidnight,
            endDate: todayMidnight.add(const Duration(days: 14)),
          ),
        );

        // Verify it exists
        expect(
          await db.amortizationDao.getAmortizationForExpense(expenseId),
          isNotNull,
        );

        // Delete the expense
        await db.expenseDao.deleteExpense(expenseId);

        // Verify amortization was cleaned up
        expect(
          await db.amortizationDao.getAmortizationForExpense(expenseId),
          isNull,
        );
      },
    );
  });

  group('Cycle-Overlap Amortization Formula', () {
    test('calculates correct elapsed burden within same cycle', () {
      final cycleStart = DateTime(2026, 9, 1);
      final cycleEnd = DateTime(2026, 9, 8); // 7-day weekly cycle
      final nowMidnight = DateTime(2026, 9, 3); // Day 3 of cycle (elapsed = 3)

      final amortStart = DateTime(2026, 9, 2);
      final amortEnd = DateTime(2026, 9, 9); // 7 days, 50 ETB/day
      const dailyBurden = 50.0;

      // Overlap:
      final windowStart = amortStart.isAfter(cycleStart)
          ? amortStart
          : cycleStart;
      final windowEnd = amortEnd.isBefore(cycleEnd) ? amortEnd : cycleEnd;

      final tomorrowMidnight = nowMidnight.add(const Duration(days: 1));
      final effectiveEnd = tomorrowMidnight.isBefore(windowEnd)
          ? tomorrowMidnight
          : windowEnd;
      final elapsedDays = effectiveEnd.difference(windowStart).inDays;

      // From Sept 2 up to end of Sept 3 = 2 days active (Sept 2, Sept 3)
      expect(elapsedDays, 2);
      final burden = elapsedDays * dailyBurden;
      expect(burden, 100.0);
    });

    test('calculates correct elapsed burden across cycle boundaries', () {
      final cycleStart = DateTime(2026, 9, 8);
      final cycleEnd = DateTime(2026, 9, 15);
      final nowMidnight = DateTime(2026, 9, 10); // Day 3 of cycle

      // Started in previous cycle on Sept 4, ends on Sept 11
      final amortStart = DateTime(2026, 9, 4);
      final amortEnd = DateTime(2026, 9, 11);
      const dailyBurden = 50.0;

      final windowStart = amortStart.isAfter(cycleStart)
          ? amortStart
          : cycleStart; // Sept 8
      final windowEnd = amortEnd.isBefore(cycleEnd)
          ? amortEnd
          : cycleEnd; // Sept 11

      final tomorrowMidnight = nowMidnight.add(const Duration(days: 1));
      final effectiveEnd = tomorrowMidnight.isBefore(windowEnd)
          ? tomorrowMidnight
          : windowEnd;
      final elapsedDays = effectiveEnd.difference(windowStart).inDays;

      // In this cycle, active on Sept 8, 9, 10 = 3 days
      expect(elapsedDays, 3);
      expect(elapsedDays * dailyBurden, 150.0);
    });
  });
}
