import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/money/currency.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/core/widgets/icon_registry.dart';
import 'package:floos/core/widgets/money_text.dart';
import 'package:floos/core/widgets/sheets.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:floos/data/db/seed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sheet listing accounts with balances; returns the chosen id.
Future<String?> pickAccount(BuildContext context, {String? excludeId, String? selectedId, String? title}) =>
    showAppSheet<String>(
      context,
      builder: (_) => _AccountPicker(excludeId: excludeId, selectedId: selectedId, title: title),
    );

class _AccountPicker extends ConsumerWidget {
  const _AccountPicker({this.excludeId, this.selectedId, this.title});

  final String? excludeId;
  final String? selectedId;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = (ref.watch(accountsWithBalanceProvider).value ?? const [])
        .where((a) => !a.account.archived && a.account.id != excludeId)
        .toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetTitle(title ?? context.l10n.txChooseAccount),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.x2),
            children: [
              for (final a in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.sm),
                  child: AppCard(
                    borderColor: a.account.id == selectedId ? context.colors.primary : null,
                    onTap: () => Navigator.pop(context, a.account.id),
                    child: Row(
                      children: [
                        IconTile.keyed(a.account.icon, a.account.color),
                        const SizedBox(width: AppSpace.md),
                        Expanded(child: Text(a.account.name, style: context.text.bodyM)),
                        MoneyText(a.balance, a.currency, style: context.text.bodyS),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Searchable category sheet with subcategories; returns the chosen id.
Future<String?> pickCategory(BuildContext context, {required String kind, String? selectedId, bool parentsOnly = false}) =>
    showAppSheet<String>(
      context,
      expand: true,
      builder: (_) => _CategoryPicker(kind: kind, selectedId: selectedId, parentsOnly: parentsOnly),
    );

class _CategoryPicker extends ConsumerStatefulWidget {
  const _CategoryPicker({required this.kind, this.selectedId, this.parentsOnly = false});

  final String kind;
  final String? selectedId;
  final bool parentsOnly;

  @override
  ConsumerState<_CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends ConsumerState<_CategoryPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final all = (ref.watch(categoriesStreamProvider).value ?? const <CategoryRow>[])
        .where((c) => c.kind == widget.kind && !c.archived && c.systemKey != SystemCategory.adjustment)
        .toList();
    final q = _q.trim().toLowerCase();
    final parents = all.where((c) => c.parentId == null).toList();
    final rows = <(CategoryRow, bool)>[];
    for (final p in parents) {
      final kids = widget.parentsOnly ? <CategoryRow>[] : all.where((c) => c.parentId == p.id).toList();
      final pm = q.isEmpty || p.name.toLowerCase().contains(q);
      final km = kids.where((k) => q.isEmpty || k.name.toLowerCase().contains(q) || pm).toList();
      if (pm || km.isNotEmpty) rows.add((p, false));
      for (final k in km) {
        rows.add((k, true));
      }
    }
    return Column(
      children: [
        SheetTitle(context.l10n.txChooseCategory),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          child: TextField(
            autofocus: false,
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              hintText: context.l10n.txSearchCategories,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.x2),
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final (c, child) = rows[i];
              final selected = c.id == widget.selectedId;
              return Padding(
                padding: EdgeInsetsDirectional.only(start: child ? AppSpace.x3 : 0),
                child: ListTile(
                  minTileHeight: AppSizes.rowHeight,
                  contentPadding: EdgeInsets.zero,
                  leading: IconTile.keyed(c.icon, c.color, small: child),
                  title: Text(c.name, style: child ? context.text.bodyS.copyWith(color: context.colors.textPrimary) : context.text.bodyM),
                  trailing: selected ? Icon(Icons.check_rounded, color: context.colors.primary) : null,
                  onTap: () => Navigator.pop(context, c.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Searchable currency list with common ones pinned (APP_PROMPT §6.1).
Future<String?> pickCurrency(BuildContext context, {String? selected}) => showAppSheet<String>(
  context,
  expand: true,
  builder: (_) => CurrencyList(selected: selected, onPick: (c) => Navigator.pop(context, c)),
);

class CurrencyList extends StatefulWidget {
  const CurrencyList({required this.onPick, super.key, this.selected, this.shrinkWrap = false});

  final String? selected;
  final ValueChanged<String> onPick;
  final bool shrinkWrap;

  @override
  State<CurrencyList> createState() => _CurrencyListState();
}

class _CurrencyListState extends State<CurrencyList> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final list = Currencies.ordered(query: _q);
    final view = ListView.builder(
      shrinkWrap: widget.shrinkWrap,
      physics: widget.shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final c = list[i];
        final selected = c.code == widget.selected;
        return ListTile(
          minTileHeight: AppSizes.rowHeight,
          contentPadding: EdgeInsets.zero,
          leading: SizedBox(
            width: AppSizes.iconTile + AppSpace.md,
            child: Text(c.code, style: context.text.bodyM),
          ),
          title: Text(c.name, style: context.text.bodyS.copyWith(color: context.colors.textPrimary)),
          trailing: selected ? Icon(Icons.check_rounded, color: context.colors.primary) : Text(c.symbol, style: context.text.caption),
          onTap: () => widget.onPick(c.code),
        );
      },
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.sm),
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(hintText: context.l10n.search, prefixIcon: const Icon(Icons.search_rounded)),
          ),
        ),
        if (widget.shrinkWrap) view else Expanded(child: view),
      ],
    );
  }
}

/// Icon grid (~120 Phosphor icons).
Future<String?> pickIcon(BuildContext context, {String? selected, String? color}) => showAppSheet<String>(
  context,
  expand: true,
  builder: (ctx) => Column(
    children: [
      SheetTitle(ctx.l10n.icon),
      Expanded(
        child: GridView.count(
          crossAxisCount: 6,
          padding: const EdgeInsets.all(AppSpace.lg),
          mainAxisSpacing: AppSpace.sm,
          crossAxisSpacing: AppSpace.sm,
          children: [
            for (final k in IconRegistry.keys)
              Semantics(
                button: true,
                selected: k == selected,
                label: k,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () => Navigator.pop(ctx, k),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: k == selected ? Border.all(color: ctx.colors.primary, width: AppSizes.selectedBorder) : null,
                    ),
                    alignment: Alignment.center,
                    child: IconTile.keyed(k, color ?? 'purple'),
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  ),
);

/// CategoryColor swatches row.
class ColorSwatches extends StatelessWidget {
  const ColorSwatches({required this.selected, required this.onChanged, super.key});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpace.sm,
    runSpacing: AppSpace.sm,
    children: [
      for (final c in CategoryColor.values)
        Semantics(
          button: true,
          selected: c.name == selected,
          label: c.name,
          child: InkResponse(
            onTap: () => onChanged(c.name),
            child: Container(
              width: AppSizes.minTouch,
              height: AppSizes.minTouch,
              decoration: BoxDecoration(
                color: c.strong,
                shape: BoxShape.circle,
                border: Border.all(
                  color: c.name == selected ? context.colors.textPrimary : context.colors.surface,
                  width: 3,
                ),
              ),
              child: c.name == selected ? Icon(Icons.check_rounded, color: context.colors.onDark) : null,
            ),
          ),
        ),
    ],
  );
}
