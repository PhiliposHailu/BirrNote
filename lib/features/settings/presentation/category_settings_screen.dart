import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/category_providers.dart';

class CategorySettingsScreen extends ConsumerStatefulWidget {
  const CategorySettingsScreen({super.key});

  @override
  ConsumerState<CategorySettingsScreen> createState() => _CategorySettingsScreenState();
}

class _CategorySettingsScreenState extends ConsumerState<CategorySettingsScreen> {
  final _categoryController = TextEditingController();

  void _handleAdd() {
    final name = _categoryController.text;
    if (name.isNotEmpty) {
      ref.read(categoryManagerProvider).add(name);
      _categoryController.clear();
      FocusScope.of(context).unfocus(); // Close keyboard
    }
  }

  // NEW: Clean helper dialog (Keeps our file size short and modular!)
  Future<bool?> _showConfirmDeleteDialog(BuildContext context, String category) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "$category"?'),
        content: const Text(
          'Past expenses under this category will not be deleted, but you won\'t be able to select it for future ones.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesStream = ref.watch(categoryNamesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. ADD NEW CATEGORY INPUT
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'New Category Name',
                      hintText: 'e.g., Gym, Pets...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _handleAdd(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(icon: const Icon(Icons.add), onPressed: _handleAdd),
              ],
            ),
            const SizedBox(height: 24),

            // 2. THE LIVE REORDERABLE LIST OF ACTIVE CATEGORIES
            Expanded(
              child: categoriesStream.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
                data: (categories) {
                  return ReorderableListView.builder(
                    itemCount: categories.length,
                    onReorder: (oldIndex, newIndex) {
                      if (oldIndex < newIndex) newIndex -= 1;
                      final list = List<String>.from(categories);
                      final item = list.removeAt(oldIndex);
                      list.insert(newIndex, item);
                      ref.read(categoryManagerProvider).reorder(list);
                    },
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isOthers = category == 'Others';

                      return ListTile(
                        key: ValueKey(category), 
                        leading: const Icon(Icons.drag_indicator), 
                        title: Text(category),
                        trailing: isOthers
                            ? const Tooltip(
                                message: 'Default fallback category',
                                child: Icon(Icons.lock_outline, color: Colors.grey),
                              )
                            : IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () async {
                                  // FIXED: Show the confirm dialog before deleting!
                                  final confirm = await _showConfirmDeleteDialog(context, category);
                                  if (confirm == true) {
                                    ref.read(categoryManagerProvider).delete(category);
                                  }
                                },
                              ),
                      );
                    },
                  );
                },
              ),
            ),

            // 3. THE EMERGENCY RESET BUTTON
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.restore),
                label: const Text('Reset to Default Categories'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Reset Categories?'),
                      content: const Text(
                        'This will delete all custom categories and restore the default 5. Past expenses will not be deleted. Continue?'
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await ref.read(categoryManagerProvider).reset();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}