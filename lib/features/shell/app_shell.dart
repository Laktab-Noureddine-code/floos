import 'package:floos/core/widgets/nav.dart';
import 'package:floos/features/transaction_form/transaction_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom-nav scaffold around the four tabs; the centre FAB opens the
/// transaction sheet (design.md §2).
class AppShell extends StatelessWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBody: true,
    body: shell,
    bottomNavigationBar: AppBottomNav(
      index: shell.currentIndex,
      onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
      onFab: () => openTransactionForm(context),
    ),
  );
}
