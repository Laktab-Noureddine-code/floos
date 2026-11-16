import 'package:floos/app/providers.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/core/widgets/app_card.dart';
import 'package:floos/core/widgets/states.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Categories tree with Expenses / Income tabs and reorder.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.categories),
          bottom: TabBar(tabs: [Tab(text: l.kindExpense), Tab(text: l.kindIncome)]),
          actions: [
            IconButton(
              tooltip: l.categoryMerge,
              icon: const Icon(Icons.merge_rounded),
              onPressed: () => context.push('/categories/merge'),
            ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (ctx) => FloatingActionButton(
            tooltip: l.categoryNew,
            onPressed: () => ctx.push('/categories/new?kind=${DefaultTabController.of(ctx).index == 0 ? 'expense' : 'income'}'),
            child: const Icon(Icons.add_rounded),
          ),
        ),
        body: AsyncValueView<List<CategoryRow>>(
          value: ref.watch(categoriesStreamProvider),
          data: (all) => TabBarView(children: [_Tree(all: all, kind: 'expense'), _Tree(all: all, kind: 'income')]),
        ),
      ),
    );
  }
}

class _Tree extends ConsumerWidget {
  const _Tree({required this.all, required this.kind});

  final List<CategoryRow> all;
  final String kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final parents = all.where((c) => c.kind == kind && c.parentId == null && c.systemKey == null).toList();
    if (parents.isEmpty) return Center(child: Text(l.categoryEmpty));
    Widget row(CategoryRow c, {bool child = false}) => Padding(
      padding: EdgeInsets.only(left: child ? AppSpace.x3 : 0, bottom: AppSpace.sm),
      child: AppCard(
        onTap: () => context.push('/categories/${c.id}/edit'),
        child: Row(
          children: [
            IconTile.keyed(c.icon, c.color, small: child),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(
                c.name,
                style: context.text.bodyM.copyWith(color: c.archived ? context.colors.textTertiary : null),
              ),
            ),
            if (c.archived) Text(l.archive, style: context.text.caption),
          ],
        ),
      ),
    );
    return ReorderableListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSizes.scrollBottomPadding),
      onReorder: (o, n) async {
        final ids = parents.map((c) => c.id).toList();
        final id = ids.removeAt(o);
        ids.insert(n > o ? n - 1 : n, id);
        await ref.read(categoriesRepoProvider).reorder(ids);
      },
      children: [
        for (final p in parents)
          Column(
            key: ValueKey(p.id),
            children: [
              row(p),
              for (final c in all.where((c) => c.parentId == p.id)) row(c, child: true),
            ],
          ),
      ],
    );
  }
}
