import 'dart:io';

import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:floos/core/widgets/toggles.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:floos/data/db/seed.dart';
import 'package:floos/data/repositories/categories_repository.dart';
import 'package:floos/features/common/pickers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Inline red error text under a field.
class FieldError extends StatelessWidget {
  const FieldError(this.text, {super.key});

  final String? text;

  @override
  Widget build(BuildContext context) => text == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpace.xs, top: AppSpace.xs),
          child: Semantics(
            liveRegion: true,
            child: Text(text!, style: context.text.caption.copyWith(color: context.colors.expense)),
          ),
        );
}

/// 52 pt row with icon, label and value (design.md §4.4).
class FormRow extends StatelessWidget {
  const FormRow({required this.icon, required this.label, super.key, this.value, this.onTap, this.trailing, this.error});

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? error;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.rowHeight),
          child: Row(
            children: [
              Icon(icon, size: AppSizes.iconGlyph, color: error != null ? context.colors.expense : context.colors.textSecondary),
              const SizedBox(width: AppSpace.md),
              Text(label, style: context.text.bodyS.copyWith(color: context.colors.textPrimary)),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Text(
                  value ?? '',
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyM.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              ?trailing,
              if (trailing == null && onTap != null)
                Icon(Icons.chevron_right_rounded, color: context.colors.textTertiary),
            ],
          ),
        ),
      ),
      FieldError(error),
      const Divider(),
    ],
  );
}

/// Horizontal category chips: top 8 most used + "All" + inline create.
class CategoryStrip extends ConsumerStatefulWidget {
  const CategoryStrip({required this.kind, required this.selectedId, required this.onSelect, super.key});

  final String kind;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  ConsumerState<CategoryStrip> createState() => _CategoryStripState();
}

class _CategoryStripState extends ConsumerState<CategoryStrip> {
  List<String> _top = const [];
  String? _loadedKind;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  @override
  void didUpdateWidget(covariant CategoryStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) _load();
  }

  Future<void> _load() async {
    if (_loadedKind == widget.kind) return;
    _loadedKind = widget.kind;
    final ids = await ref.read(categoriesRepoProvider).mostUsed(widget.kind);
    if (mounted) setState(() => _top = ids);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final all = (ref.watch(categoriesStreamProvider).value ?? const <CategoryRow>[])
        .where((c) => c.kind == widget.kind && !c.archived && c.systemKey != SystemCategory.adjustment)
        .toList();
    final byId = {for (final c in all) c.id: c};
    final chosen = <CategoryRow>[
      for (final id in _top)
        if (byId[id] != null) byId[id]!,
    ];
    for (final c in all) {
      if (chosen.length >= 8) break;
      if (!chosen.contains(c) && c.parentId == null) chosen.add(c);
    }
    final selected = widget.selectedId == null ? null : byId[widget.selectedId];
    if (selected != null && !chosen.contains(selected)) chosen.insert(0, selected);
    return SizedBox(
      height: AppSizes.iconTile + AppSpace.x3 + AppSpace.md,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
        children: [
          for (final c in chosen)
            _Chip(
              label: c.name,
              tile: IconTile.keyed(c.icon, c.color),
              selected: c.id == widget.selectedId,
              onTap: () => widget.onSelect(c.id),
              onLongPress: () => _create(context),
            ),
          _Chip(
            label: l.txAllCategories,
            tile: const IconTile(icon: PhosphorIconsFill.squaresFour, color: CategoryColor.slate),
            selected: false,
            onTap: () async {
              final id = await pickCategory(context, kind: widget.kind, selectedId: widget.selectedId);
              if (id != null) widget.onSelect(id);
            },
            onLongPress: () => _create(context),
          ),
          _Chip(
            label: l.txNewCategory,
            tile: const IconTile(icon: PhosphorIconsBold.plus, color: CategoryColor.purple),
            selected: false,
            onTap: () => _create(context),
          ),
        ],
      ),
    );
  }

  Future<void> _create(BuildContext context) async {
    final id = await createCategoryInline(context, ref, kind: widget.kind);
    if (id != null) widget.onSelect(id);
  }
}

/// Small dialog to create a category inline (name + optional parent).
Future<String?> createCategoryInline(BuildContext context, WidgetRef ref, {required String kind}) async {
  final l = context.l10n;
  final name = TextEditingController();
  String? parentId;
  String? error;
  final parents = (ref.read(categoriesStreamProvider).value ?? const <CategoryRow>[])
      .where((c) => c.kind == kind && c.parentId == null && !c.archived && c.systemKey != SystemCategory.adjustment)
      .toList();
  final id = await showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(l.txCreateCategoryTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              maxLength: 30,
              decoration: InputDecoration(labelText: l.name, errorText: error),
            ),
            DropdownButtonFormField<String?>(
              initialValue: parentId,
              decoration: InputDecoration(labelText: l.txParentCategory),
              items: [
                DropdownMenuItem(child: Text(l.txNoParent)),
                for (final p in parents) DropdownMenuItem(value: p.id, child: Text(p.name)),
              ],
              onChanged: (v) => setState(() => parentId = v),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          TextButton(
            onPressed: () async {
              final parent = parentId == null ? null : parents.firstWhere((p) => p.id == parentId);
              final r = await ref.read(categoriesRepoProvider).save(
                CategoryDraft(
                  name: name.text,
                  kind: kind,
                  icon: parent?.icon ?? 'tag',
                  color: parent?.color ?? 'purple',
                  parentId: parentId,
                ),
              );
              if (!ctx.mounted) return;
              r.fold((id) => Navigator.pop(ctx, id), (f) => setState(() => error = failureMessage(l, f)));
            },
            child: Text(l.save),
          ),
        ],
      ),
    ),
  );
  name.dispose();
  return id;
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.tile, required this.selected, required this.onTap, this.onLongPress});

  final String label;
  final Widget tile;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    excludeSemantics: true,
    child: InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      onLongPress: onLongPress,
      child: SizedBox(
        width: AppSizes.categoryChipWidth + AppSpace.sm,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.selectedBorder),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md + AppSizes.selectedBorder),
                border: Border.all(
                  color: selected ? context.colors.primary : Colors.transparent,
                  width: AppSizes.selectedBorder,
                ),
              ),
              child: tile,
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.text.caption.copyWith(
                color: selected ? context.colors.primary : context.colors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Tag chips + "add" sheet with inline creation.
class TagsField extends ConsumerWidget {
  const TagsField({required this.selected, required this.onChanged, super.key});

  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final tags = ref.watch(tagsStreamProvider).value ?? const <TagRow>[];
    final byId = {for (final t in tags) t.id: t};
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Wrap(
        spacing: AppSpace.xs,
        runSpacing: AppSpace.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(PhosphorIconsRegular.tag, size: AppSizes.iconGlyph, color: context.colors.textSecondary),
          for (final id in selected)
            if (byId[id] != null)
              ChoicePill(
                label: '#${byId[id]!.name}',
                selected: true,
                onTap: null,
                onRemove: () => onChanged([...selected]..remove(id)),
              ),
          ChoicePill(
            label: '+ ${l.txAddTag}',
            selected: false,
            onTap: () async {
              final r = await showAppSheet<List<String>>(
                context,
                builder: (_) => _TagSheet(initial: selected),
              );
              if (r != null) onChanged(r);
            },
          ),
        ],
      ),
    );
  }
}

class _TagSheet extends ConsumerStatefulWidget {
  const _TagSheet({required this.initial});

  final List<String> initial;

  @override
  ConsumerState<_TagSheet> createState() => _TagSheetState();
}

class _TagSheetState extends ConsumerState<_TagSheet> {
  late final Set<String> _sel = {...widget.initial};
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final r = await ref.read(tagsRepoProvider).ensure(_ctrl.text);
    final id = r.valueOrNull;
    if (id != null) {
      setState(() => _sel.add(id));
      _ctrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tags = ref.watch(tagsStreamProvider).value ?? const <TagRow>[];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetTitle(l.txTags, trailing: TextButton(onPressed: () => Navigator.pop(context, _sel.toList()), child: Text(l.done))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          child: TextField(
            controller: _ctrl,
            maxLength: 30,
            onSubmitted: (_) => _add(),
            decoration: InputDecoration(
              hintText: l.txNewTagHint,
              suffixIcon: IconButton(tooltip: l.add, icon: const Icon(Icons.add_rounded), onPressed: _add),
            ),
          ),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(AppSpace.sm, 0, AppSpace.sm, AppSpace.x2),
            children: [
              for (final t in tags)
                CheckboxListTile(
                  value: _sel.contains(t.id),
                  title: Text('#${t.name}'),
                  onChanged: (v) => setState(() => v! ? _sel.add(t.id) : _sel.remove(t.id)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Thumbnails of existing and new attachments + add (camera/gallery).
class AttachmentsField extends ConsumerWidget {
  const AttachmentsField({
    required this.existing,
    required this.added,
    required this.removed,
    required this.onAdd,
    required this.onRemoveExisting,
    required this.onRemoveNew,
    super.key,
  });

  final List<AttachmentRow> existing;
  final List<String> added;
  final Set<String> removed;
  final ValueChanged<List<String>> onAdd;
  final ValueChanged<String> onRemoveExisting;
  final ValueChanged<String> onRemoveNew;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final store = ref.watch(attachmentStoreProvider);
    final files = [
      for (final a in existing)
        if (!removed.contains(a.id)) (store.fileFor(a.id), () => onRemoveExisting(a.id)),
      for (final p in added) (File(p), () => onRemoveNew(p)),
    ];
    return SizedBox(
      height: AppSizes.thumbnail + AppSpace.lg,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
        children: [
          for (final (f, remove) in files)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpace.sm),
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => showAttachmentPreview(context, f),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Image.file(f, width: AppSizes.thumbnail, height: AppSizes.thumbnail, fit: BoxFit.cover),
                    ),
                  ),
                  PositionedDirectional(
                    top: 0,
                    end: 0,
                    child: InkResponse(
                      onTap: remove,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: context.colors.inverse,
                        child: Icon(Icons.close_rounded, size: 12, color: context.colors.onInverse),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Semantics(
            button: true,
            label: l.txAddPhoto,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () => _pick(context),
              child: Container(
                width: AppSizes.thumbnail,
                height: AppSizes.thumbnail,
                decoration: BoxDecoration(
                  color: context.colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(PhosphorIconsRegular.camera, color: context.colors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final l = context.l10n;
    final source = await showAppSheet<ImageSource>(
      context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(PhosphorIconsRegular.camera),
              title: Text(l.txCamera),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(PhosphorIconsRegular.image),
              title: Text(l.txGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picker = ImagePicker();
    if (source == ImageSource.gallery) {
      final list = await picker.pickMultiImage();
      onAdd([for (final x in list) x.path]);
    } else {
      final x = await picker.pickImage(source: source);
      if (x != null) onAdd([x.path]);
    }
  }
}

/// Full-screen zoomable preview of an attachment.
Future<void> showAttachmentPreview(BuildContext context, File file) => showDialog<void>(
  context: context,
  builder: (ctx) => Dialog.fullscreen(
    backgroundColor: AppPalette.inverse,
    child: Stack(
      children: [
        Positioned.fill(child: InteractiveViewer(child: Image.file(file, fit: BoxFit.contain))),
        SafeArea(
          child: IconButton(
            tooltip: ctx.l10n.close,
            color: AppPalette.onDark,
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.close_rounded),
          ),
        ),
      ],
    ),
  ),
);
