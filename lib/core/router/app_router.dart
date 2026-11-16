import 'package:floos/app/providers.dart';
import 'package:floos/app/startup.dart';
import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/data/repositories/transactions_repository.dart';
import 'package:floos/features/accounts/account_detail_screen.dart';
import 'package:floos/features/accounts/account_form_screen.dart';
import 'package:floos/features/accounts/accounts_screen.dart';
import 'package:floos/features/backup/backup_screen.dart';
import 'package:floos/features/backup/csv_import_screen.dart';
import 'package:floos/features/budgets/budget_detail_screen.dart';
import 'package:floos/features/budgets/budget_form_screen.dart';
import 'package:floos/features/budgets/budgets_screen.dart';
import 'package:floos/features/categories/categories_screen.dart';
import 'package:floos/features/categories/category_form_screen.dart';
import 'package:floos/features/debts/debt_detail_screen.dart';
import 'package:floos/features/debts/debt_form_screen.dart';
import 'package:floos/features/debts/debts_screen.dart';
import 'package:floos/features/goals/goal_detail_screen.dart';
import 'package:floos/features/goals/goal_form_screen.dart';
import 'package:floos/features/goals/goals_screen.dart';
import 'package:floos/features/home/home_screen.dart';
import 'package:floos/features/lock/lock_controller.dart';
import 'package:floos/features/lock/lock_screen.dart';
import 'package:floos/features/notifications/notifications_screens.dart';
import 'package:floos/features/onboarding/onboarding_screen.dart';
import 'package:floos/features/plan/plan_screen.dart';
import 'package:floos/features/rates/rates_screen.dart';
import 'package:floos/features/recurring/recurring_screens.dart';
import 'package:floos/features/report/category_detail_screen.dart';
import 'package:floos/features/report/insights_screen.dart';
import 'package:floos/features/report/report_screen.dart';
import 'package:floos/features/settings/about_screen.dart';
import 'package:floos/features/settings/general_screen.dart';
import 'package:floos/features/settings/security_screen.dart';
import 'package:floos/features/settings/settings_screen.dart';
import 'package:floos/features/shell/app_shell.dart';
import 'package:floos/features/tags/tags_screen.dart';
import 'package:floos/features/transaction_form/transaction_form_sheet.dart';
import 'package:floos/features/transaction_form/tx_form_controller.dart';
import 'package:floos/features/transactions/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Lets the notification gateway navigate from outside the widget tree.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  void bump(Object? _, Object? __) => refresh.value++;
  ref
    ..listen(prefsProvider.select((p) => p.onboardingDone), bump)
    ..listen(lockedProvider, bump)
    ..onDispose(refresh.dispose);

  String? redirect(BuildContext context, GoRouterState state) {
    if (state.uri.host == 'add' || state.uri.scheme == 'floos') {
      return '/add${state.uri.hasQuery ? '?${state.uri.query}' : ''}';
    }
    final path = state.uri.path;
    final onboarded = ref.read(prefsProvider).onboardingDone;
    if (!onboarded) return path == '/onboarding' ? null : '/onboarding';
    if (path == '/onboarding') return '/home';
    final locked = ref.read(lockedProvider);
    if (locked) return path == '/lock' ? null : '/lock';
    if (path == '/lock') return '/home';
    if (path == '/') return '/home';
    return null;
  }

  Widget account(GoRouterState s) => AccountDetailScreen(accountId: s.pathParameters['id']!);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: redirect,
    errorBuilder: (context, state) => Scaffold(appBar: AppBar(), body: Center(child: Text(context.l10n.errorGeneric))),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const _HomeWithRefresh())]),
          StatefulShellBranch(
            routes: [GoRoute(path: '/report', builder: (_, s) => ReportScreen(type: s.uri.queryParameters['type']))],
          ),
          StatefulShellBranch(routes: [GoRoute(path: '/plan', builder: (_, _) => const PlanScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen())]),
        ],
      ),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/lock', builder: (_, _) => const LockScreen()),
      GoRoute(
        path: '/add',
        builder: (_, s) => _AddEntry(type: s.uri.queryParameters['type']),
      ),
      GoRoute(
        path: '/transactions',
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, s) {
          final q = s.uri.queryParameters;
          final id = q['id'];
          return TransactionsScreen(
            initial: TxFilter(
              startMs: int.tryParse(q['start'] ?? ''),
              endExclusiveMs: int.tryParse(q['end'] ?? ''),
              ids: id == null ? null : {id},
              includePending: id != null,
            ),
          );
        },
      ),
      GoRoute(path: '/insights', builder: (_, _) => const InsightsScreen()),
      GoRoute(path: '/notifications', builder: (_, _) => const NotificationCenterScreen()),
      GoRoute(path: '/accounts', builder: (_, _) => const AccountsScreen(), routes: [
        GoRoute(path: 'new', builder: (_, _) => const AccountFormScreen()),
        GoRoute(path: ':id', builder: (_, s) => account(s), routes: [
          GoRoute(path: 'edit', builder: (_, s) => AccountFormScreen(accountId: s.pathParameters['id'])),
        ]),
      ]),
      GoRoute(path: '/categories', builder: (_, _) => const CategoriesScreen(), routes: [
        GoRoute(path: 'new', builder: (_, s) => CategoryFormScreen(kind: s.uri.queryParameters['kind'] ?? 'expense')),
        GoRoute(path: 'merge', builder: (_, _) => const CategoryMergeScreen()),
        GoRoute(path: ':id/edit', builder: (_, s) => CategoryFormScreen(categoryId: s.pathParameters['id'])),
      ]),
      GoRoute(path: '/tags', builder: (_, _) => const TagsScreen()),
      GoRoute(path: '/rates', builder: (_, _) => const RatesScreen()),
      GoRoute(path: '/report/category/:id', builder: (_, s) => CategoryDetailScreen(categoryId: s.pathParameters['id']!)),
      GoRoute(path: '/goals', builder: (_, _) => const GoalsScreen(), routes: [
        GoRoute(path: 'new', builder: (_, _) => const GoalFormScreen()),
        GoRoute(path: ':id', builder: (_, s) => GoalDetailScreen(goalId: s.pathParameters['id']!), routes: [
          GoRoute(path: 'edit', builder: (_, s) => GoalFormScreen(goalId: s.pathParameters['id'])),
        ]),
      ]),
      GoRoute(path: '/budgets', builder: (_, _) => const BudgetsScreen(), routes: [
        GoRoute(path: 'new', builder: (_, _) => const BudgetFormScreen()),
        GoRoute(path: ':id', builder: (_, s) => BudgetDetailScreen(budgetId: s.pathParameters['id']!), routes: [
          GoRoute(path: 'edit', builder: (_, s) => BudgetFormScreen(budgetId: s.pathParameters['id'])),
        ]),
      ]),
      GoRoute(path: '/recurring', builder: (_, _) => const RecurringScreen(), routes: [
        GoRoute(path: 'new', builder: (_, _) => const RecurringFormScreen()),
        GoRoute(path: ':id/edit', builder: (_, s) => RecurringFormScreen(ruleId: s.pathParameters['id'])),
      ]),
      GoRoute(path: '/debts', builder: (_, _) => const DebtsScreen(), routes: [
        GoRoute(path: 'new', builder: (_, _) => const DebtFormScreen()),
        GoRoute(path: ':id', builder: (_, s) => DebtDetailScreen(debtId: s.pathParameters['id']!), routes: [
          GoRoute(path: 'edit', builder: (_, s) => DebtFormScreen(debtId: s.pathParameters['id'])),
        ]),
      ]),
      GoRoute(path: '/settings/general', builder: (_, _) => const GeneralSettingsScreen()),
      GoRoute(path: '/settings/currency', redirect: (_, _) => '/settings/general'),
      GoRoute(path: '/settings/notifications', builder: (_, _) => const NotificationSettingsScreen()),
      GoRoute(path: '/settings/security', builder: (_, _) => const SecuritySettingsScreen()),
      GoRoute(path: '/settings/backup', builder: (_, _) => const BackupScreen()),
      GoRoute(path: '/settings/about', builder: (_, _) => const AboutScreen()),
      GoRoute(path: '/settings/diagnostics', builder: (_, _) => const DiagnosticsScreen()),
      GoRoute(path: '/backup/import-csv', builder: (_, _) => const CsvImportScreen()),
    ],
  );
});

class _HomeWithRefresh extends ConsumerWidget {
  const _HomeWithRefresh();

  @override
  Widget build(BuildContext context, WidgetRef ref) => HomeScreen(onRefresh: () => runStartupTasks(ProviderScope.containerOf(context)));
}

/// `/add?type=` and `floos://add`: opens Home then the transaction sheet.
class _AddEntry extends StatefulWidget {
  const _AddEntry({this.type});

  final String? type;

  @override
  State<_AddEntry> createState() => _AddEntryState();
}

class _AddEntryState extends State<_AddEntry> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final router = GoRouter.of(context);
      router.go('/home');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        await openTransactionForm(ctx, args: TxFormArgs(type: widget.type));
      }
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.shrink());
}
