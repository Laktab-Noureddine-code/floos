import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:floos/data/repositories/categories_repository.dart';
import 'package:floos/features/common/form_fields.dart';
import 'package:floos/features/common/pickers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Create / edit a category (also delete with reassignment, archive).
class CategoryFormScreen extends ConsumerStatefulWidget {
  const CategoryFormScreen({super.key, this.categoryId, this.kind = 'expense'});

  final String? categoryId;
  final String kind;

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _name = TextEditingController();
  late String _kind = widget.kind;
  String _icon = 'tag';
  String _color = 'purple';
  String? _parentId;
  CategoryRow? _existing;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.categoryId == null) {
      _loaded = true;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    final c = await ref.read(categoriesRepoProvider).byId(widget.categoryId!);
    if (c == null || !mounted) return;
    setState(() {
      _existing = c;
      _name.text = c.name;
      _kind = c.kind;
      _icon = c.icon;
      _color = c.color;
      _parentId = c.parentId;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final r = await ref
        .read(categoriesRepoProvider)
        .save(CategoryDraft(id: widget.categoryId, name: _name.text.trim(), kind: _kind, icon: _icon, color: _color, parentId: _parentId));
    if (!mounted) return;
    if (r.isErr) return showFailure(context, r.failureOrNull);
    context.pop();
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final repo = ref.read(categoriesRepoProvider);
    final id = widget.categoryId!;
    final n = await repo.usageCount(id);
    String? replacement;
    if (!mounted) return;
    if (n > 0) {
      replacement = await pickCategory(context, kind: _kind);
      if (replacement == null || !mounted) return;
    } else if (!await confirmDialog(context, title: l.categoryDeleteTitle, message: _name.text, danger: true, confirmLabel: l.delete)) {
      return;
    }
    final r = await repo.delete(id, replacementId: replacement);
    if (!mounted) return;
    if (r.isErr) return showFailure(context, r.failureOrNull);
    final archived = r.valueOrNull?.archivedBudgets ?? 0;
    if (archived > 0) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.categoryArchivedBudgets(archived))));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (!_loaded) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    final cats = ref.watch(categoriesMapProvider);
    final isEdit = widget.categoryId != null;
    final parentName = _parentId == null ? l.txNoParent : cats[_parentId]?.name ?? l.txNoParent;
    final hasChildren = cats.values.any((c) => c.parentId == widget.categoryId);
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l.categoryEdit : l.categoryNew),
        actions: [
          if (isEdit)
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'delete') await _delete();
                if (v == 'archive') {
                  await ref.read(categoriesRepoProvider).setArchived(widget.categoryId!, archived: !(_existing?.archived ?? false));
                  if (mounted) context.pop();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'archive', child: Text(_existing?.archived ?? false ? l.unarchive : l.archive)),
                PopupMenuItem(value: 'delete', child: Text(l.delete)),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.screen),
        children: [
          TextField(controller: _name, maxLength: 40, decoration: InputDecoration(labelText: l.name)),
          if (!isEdit) ...[
            const SizedBox(height: AppSpace.sm),
            SegmentedButton<String>(
              segments: [ButtonSegment(value: 'expense', label: Text(l.kindExpense)), ButtonSegment(value: 'income', label: Text(l.kindIncome))],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() {
                _kind = s.first;
                _parentId = null;
              }),
            ),
          ],
          const SizedBox(height: AppSpace.md),
          if (!hasChildren)
            AppCard(
              onTap: () async {
                final id = await pickCategory(context, kind: _kind, parentsOnly: true);
                if (id != null && id != widget.categoryId) setState(() => _parentId = id);
              },
              child: Row(
                children: [
                  Expanded(child: Text('${l.categoryParent} · $parentName', style: context.text.bodyM)),
                  if (_parentId != null) IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(() => _parentId = null)),
                ],
              ),
            ),
          const SizedBox(height: AppSpace.lg),
          IconColorField(icon: _icon, color: _color, onIcon: (v) => setState(() => _icon = v), onColor: (v) => setState(() => _color = v)),
          const SizedBox(height: AppSpace.x2),
          PrimaryButton(label: l.save, onPressed: _save),
        ],
      ),
    );
  }
}

/// Merge one category into another.
class CategoryMergeScreen extends ConsumerStatefulWidget {
  const CategoryMergeScreen({super.key});

  @override
  ConsumerState<CategoryMergeScreen> createState() => _CategoryMergeScreenState();
}

class _CategoryMergeScreenState extends ConsumerState<CategoryMergeScreen> {
  String _kind = 'expense';
  String? _source;
  String? _target;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cats = ref.watch(categoriesMapProvider);
    Widget picker(String label, String? id, ValueChanged<String> on) => AppCard(
      onTap: () async {
        final v = await pickCategory(context, kind: _kind);
        if (v != null) on(v);
      },
      child: Row(children: [Expanded(child: Text('$label · ${id == null ? l.none : cats[id]?.name ?? ''}', style: context.text.bodyM))]),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.categoryMerge)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.screen),
        children: [
          SegmentedButton<String>(
            segments: [ButtonSegment(value: 'expense', label: Text(l.kindExpense)), ButtonSegment(value: 'income', label: Text(l.kindIncome))],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() {
              _kind = s.first;
              _source = null;
              _target = null;
            }),
          ),
          const SizedBox(height: AppSpace.md),
          picker(l.from, _source, (v) => setState(() => _source = v)),
          const SizedBox(height: AppSpace.sm),
          picker(l.categoryMergeInto, _target, (v) => setState(() => _target = v)),
          const SizedBox(height: AppSpace.x2),
          PrimaryButton(
            label: l.categoryMerge,
            onPressed: _source == null || _target == null
                ? null
                : () async {
                    final r = await ref.read(categoriesRepoProvider).merge(_source!, _target!);
                    if (!context.mounted) return;
                    if (r.isErr) return showFailure(context, r.failureOrNull);
                    context.pop();
                  },
          ),
        ],
      ),
    );
  }
}
