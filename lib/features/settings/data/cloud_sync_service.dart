import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive; 

class CloudSyncService {
  
  // 1. Initialize (No scopes allowed here anymore!)
  Future<void> init() async {
    await GoogleSignIn.instance.initialize();
  }

  // 2. The Login & Permission Function
  Future<GoogleSignInAccount?> signIn() async {
    try {
      await init();
      
      // Step A: Authenticate (Pop up the Google Account picker)
      final account = await GoogleSignIn.instance.authenticate();
      
      if (account == null) {
        return null; // User cancelled the login
      }

      // Step B: Authorize (Ask for the hidden Drive AppData permission)
      final authClient = account.authorizationClient;
      if (authClient != null) {
        await authClient.authorizeScopes([drive.DriveApi.driveAppdataScope]);
      }

      return account;
    } catch (e) {
      print("Google Auth Error: $e");
      return null;
    }
  }

  // 3. The Logout Function
  Future<void> signOut() async {
    await GoogleSignIn.instance.disconnect();
  }
}

// Wrap it in Riverpod
final cloudSyncProvider = Provider<CloudSyncService>((ref) {
  return CloudSyncService();
});