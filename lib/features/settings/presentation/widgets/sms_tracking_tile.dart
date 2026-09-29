import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/sms/sms_listener_service.dart';
import '../../../../core/sms/sms_providers.dart';
import '../../../../core/utils/locale_provider.dart';

class SmsTrackingTile extends ConsumerWidget {
  const SmsTrackingTile({super.key});

  Future<void> _handleToggle(
    BuildContext context,
    WidgetRef ref,
    bool enable,
  ) async {
    if (enable) {
      final status = await Permission.sms.request();
      if (status.isGranted) {
        await ref.read(smsTrackingEnabledProvider.notifier).setEnabled(true);
        final expenseDao = ref.read(expenseDaoProvider);
        await SmsListenerService().startListening(expenseDao: expenseDao);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ref.read(trProvider('sms_tracking_active_snack'))),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ref.read(trProvider('sms_permission_needed'))),
              action: SnackBarAction(
                label: ref.read(trProvider('settings')),
                onPressed: () => openAppSettings(),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      await ref.read(smsTrackingEnabledProvider.notifier).setEnabled(false);
      SmsListenerService().stopListening();
    }
  }

  void _showInfoSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.sms_rounded,
                      color: Colors.teal,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      ref.watch(trProvider('auto_track_sms')),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildFeatureRow(
                icon: Icons.account_balance_wallet_rounded,
                color: Colors.amber.shade700,
                title: ref.watch(trProvider('sms_supported_banks')),
                subtitle: ref.watch(trProvider('sms_supported_banks_desc')),
              ),
              const SizedBox(height: 14),
              _buildFeatureRow(
                icon: Icons.shield_rounded,
                color: Colors.green,
                title: ref.watch(trProvider('sms_privacy_guarantee')),
                subtitle: ref.watch(trProvider('sms_privacy_note')),
              ),
              const SizedBox(height: 14),
              _buildFeatureRow(
                icon: Icons.touch_app_rounded,
                color: Colors.blue,
                title: ref.watch(trProvider('sms_1tap_confirm')),
                subtitle: ref.watch(trProvider('sms_1tap_confirm_desc')),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(ref.watch(trProvider('got_it'))),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnabled = ref.watch(smsTrackingEnabledProvider);

    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.teal.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.sms_rounded, color: Colors.teal, size: 24),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              ref.watch(trProvider('auto_track_sms')),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: Colors.grey.shade600,
            onPressed: () => _showInfoSheet(context, ref),
          ),
        ],
      ),
      subtitle: Text(
        isEnabled
            ? ref.watch(trProvider('sms_tracking_active_sub'))
            : ref.watch(trProvider('auto_track_sms_desc')),
      ),
      value: isEnabled,
      onChanged: (val) => _handleToggle(context, ref, val),
    );
  }
}
