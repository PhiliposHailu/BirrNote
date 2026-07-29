import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/locale_provider.dart';

class LanguageTile extends ConsumerWidget {
  const LanguageTile({super.key});

  final Map<String, String> _languages = const {
    'en': 'English',
    'am': 'አማርኛ (Amharic)',
    'om': 'Afaan Oromoo',
    'ti': 'ትግርኛ (Tigrinya)',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(localeProvider);
    final languageTitle = ref.watch(trProvider('language'));

    return ListTile(
      leading: const Icon(Icons.language_outlined, size: 28),
      title: Text(languageTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(_languages[currentLanguage] ?? 'English'),
      trailing: DropdownButton<String>(
        value: currentLanguage,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down),
        items: _languages.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
        onChanged: (String? newLanguage) {
          if (newLanguage != null) {
            ref.read(localeProvider.notifier).setLocale(newLanguage);
          }
        },
      ),
    );
  }
}