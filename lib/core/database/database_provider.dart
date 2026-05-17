import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';

// THE WHY: We create a global "Provider" for our database. 
// Now, anywhere in our app, we can just ask Riverpod for 'databaseProvider'
// and it will give us access to save or read expenses without creating multiple DB connections.
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});