import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class CloudSyncService {
  
  GoogleSignInAccount? _currentAccount;

  Future<void> init() async {
    await GoogleSignIn.instance.initialize();
  }

  Future<GoogleSignInAccount?> signIn() async {
    try {
      await init();
      final account = await GoogleSignIn.instance.authenticate();
      _currentAccount = account;
      if (account == null) return null;

      await account.authorizationClient
          .authorizeScopes([drive.DriveApi.driveAppdataScope]);

      return account;
    } catch (e) {
      print("Google Auth Error: $e");
      return null;
    }
  }

  Future<bool> backupDatabase() async {
  try {
    await init();

    var account = _currentAccount;
    account ??= await GoogleSignIn.instance.attemptLightweightAuthentication();
    _currentAccount = account;

    if (account == null) {
      account = await signIn();
      if (account == null) return false;
    }

    const scopes = [drive.DriveApi.driveAppdataScope];
    final authorization = await account.authorizationClient.authorizeScopes(scopes);
    final httpClient = authorization.authClient(scopes: scopes);

    final driveApi = drive.DriveApi(httpClient);

    final dbFolder = await getApplicationDocumentsDirectory();
    final localFile = File(p.join(dbFolder.path, 'birr_note_db.sqlite'));

    if (!localFile.existsSync()) return false;

    final fileList = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name = 'birr_note_db.sqlite'",
    );

    final media = drive.Media(localFile.openRead(), localFile.lengthSync());

    if (fileList.files != null && fileList.files!.isNotEmpty) {
      final existingFileId = fileList.files!.first.id!;
      await driveApi.files.update(drive.File(), existingFileId, uploadMedia: media);
    } else {
      final driveFile = drive.File()
        ..name = 'birr_note_db.sqlite'
        ..parents = ['appDataFolder'];
      await driveApi.files.create(driveFile, uploadMedia: media);
    }

    return true;
  } catch (e) {
    print("Backup Error: $e");
    return false;
  }
}

  Future<void> signOut() async {
    await GoogleSignIn.instance.disconnect();
    _currentAccount = null;
  }
}

final cloudSyncProvider = Provider<CloudSyncService>((ref) {
  return CloudSyncService();
});