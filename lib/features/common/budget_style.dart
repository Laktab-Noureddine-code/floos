import 'package:floos/core/theme/app_theme.dart';
import 'package:floos/domain/services/budget_service.dart';
import 'package:flutter/widgets.dart';

/// Ring/bar colour by budget level: < 70 % green, 70–100 % orange, > 100 % red.
Color budgetColor(BuildContext context, BudgetLevel level) => switch (level) {
  BudgetLevel.ok => CategoryColor.green.strong,
  BudgetLevel.warning => context.colors.warning,
  BudgetLevel.over => context.colors.danger,
};
