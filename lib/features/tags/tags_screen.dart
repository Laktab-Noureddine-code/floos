import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:floos/features/common/form_fields.dart';
import 'package:floos/features/common/pickers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tag management: rename, recolor, delete, usage counts.
class TagsScreen extends ConsumerWidget {
  const TagsScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, TagRow? tag) async {
    final l = context.l10n;
    final c = TextEditingController(text: tag?.name ?? '');
    var color = tag?.color ?? 'purple';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(tag == null ? l.tagNew : l.edit),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: c, autofocus: true, maxLength: 30, decoration: InputDecoration(labelText: l.name)),
              const SizedBox(height: AppSpace.md),
              ColorSwatches(selected: color, onChanged: (v) => set(() => color = v)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.save)),
          ],
        ),
      ),
    );
    final name = c.text.trim();
    c.dispose();
    if (ok != true || !context.mounted) return;
    final repo = ref.read(tagsRepoProvider);
    final r = tag == null ? await repo.ensure(name, color: color) : await repo.update(tag.id, name, color);
    if (context.mounted && r.isErr) showFailure(context, r.failureOrNull);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final tags = ref.watch(tagsStreamProvider).value ?? const <TagRow>[];
    final usage = ref.watch(_usageProvider).value ?? const <String, int>{};
    return Scaffold(
      appBar: AppBar(title: Text(l.tags)),
      floatingActionButton: FloatingActionButton(tooltip: l.tagNew, onPressed: () => _edit(context, ref, null), child: const Icon(Icons.add_rounded)),
      body: tags.isEmpty
          ? Center(child: Text(l.tagsEmpty))
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSizes.scrollBottomPadding),
              children: [
                for (final t in tags)
                  ListTile(
                    leading: Icon(Icons.tag_rounded, color: CategoryColor.byName(t.color).strong),
                    title: Text(t.name),
                    subtitle: Text(l.tagUsage(usage[t.id] ?? 0)),
                    onTap: () => _edit(context, ref, t),
                    trailing: IconButton(
                      tooltip: l.delete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () async {
                        if (await confirmDialog(context, title: l.delete, message: '#${t.name}', danger: true, confirmLabel: l.delete)) {
                          await ref.read(tagsRepoProvider).delete(t.id);
                        }
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}

final _usageProvider = StreamProvider<Map<String, int>>((ref) => ref.watch(tagsRepoProvider).watchUsage());
