import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/cloud_sync_service.dart';

class CloudSyncTile extends ConsumerWidget {
  const CloudSyncTile({super.key});

  void _showSyncSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (context) => const _CloudSyncSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(cloudSyncProvider);
    final isLoggedIn = authService.currentUser != null;

    return ListTile(
      leading: const Icon(Icons.cloud_sync_outlined, size: 28),
      title: const Text('Google Drive Sync', style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        isLoggedIn 
            ? 'Logged in as ${authService.currentUser!.email}' 
            : 'Backup or restore your data securely',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showSyncSheet(context, ref),
    );
  }
}

// ----------------------------------------------------------------------
// PRIVATE WIDGET: The sliding sheet containing the sync operations
// ----------------------------------------------------------------------
class _CloudSyncSheet extends ConsumerStatefulWidget {
  const _CloudSyncSheet();

  @override
  ConsumerState<_CloudSyncSheet> createState() => _CloudSyncSheetState();
}

class _CloudSyncSheetState extends ConsumerState<_CloudSyncSheet> {
  GoogleSignInAccount? _user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Read the current login status when the sheet opens
    _user = ref.read(cloudSyncProvider).currentUser;
  }

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);
    final account = await ref.read(cloudSyncProvider).signIn();
    setState(() {
      _user = account;
      _isLoading = false;
    });
  }

  Future<void> _handleSignOut() async {
    await ref.read(cloudSyncProvider).signOut();
    setState(() {
      _user = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = _user != null;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Google Drive Cloud Sync',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Backup or restore your BirrNote database. All backups are stored privately in your hidden Google Drive App Data folder.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (!isLoggedIn)
              // --- STATE A: LOGGED OUT (Show Sign In) ---
              FilledButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
                onPressed: _handleSignIn,
              )
            else ...[
              // --- STATE B: LOGGED IN (Show Backup & Restore) ---
              Text(
                'Connected Account: ${_user!.email}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  // BACKUP BUTTON
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Backup'),
                      onPressed: () async {
                        Navigator.pop(context); // Close sheet
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Starting cloud backup...')),
                        );
                        final success = await ref.read(cloudSyncProvider).backupDatabase();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Backup Successful! 🚀' : 'Backup failed.'),
                              backgroundColor: success ? Colors.green : Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // RESTORE BUTTON
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.cloud_download),
                      label: const Text('Restore'),
                      onPressed: () async {
                        Navigator.pop(context); // Close sheet
                        final success = await ref.read(cloudSyncProvider).restoreDatabase();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Restore Successful! Restart app. 🎉' : 'Restore failed.'),
                              backgroundColor: success ? Colors.green : Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _handleSignOut,
                child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}