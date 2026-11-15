import 'package:drift/drift.dart';
import 'package:floos/data/db/app_database.dart';
import 'package:uuid/uuid.dart';

/// Stable system category keys (not localized; names are).
abstract final class SystemCategory {
  static const otherExpense = 'other_expense';
  static const otherIncome = 'other_income';
  static const adjustment = 'adjustment';
}

class _SeedCat {
  const _SeedCat(this.key, this.icon, this.color, {this.system});
  final String key;
  final String icon;
  final String color;
  final String? system;
}

/// Seeded categories (APP_PROMPT §4.14) with icon + CategoryColor.
const _expense = [
  _SeedCat('food', 'shopping_cart', 'blue'),
  _SeedCat('restaurants', 'fork_knife', 'slate'),
  _SeedCat('transport', 'bus', 'coral'),
  _SeedCat('fuel', 'gas_pump', 'orange'),
  _SeedCat('rent', 'house', 'purple'),
  _SeedCat('bills', 'lightning', 'pink'),
  _SeedCat('phone', 'wifi_high', 'blue'),
  _SeedCat('health', 'heartbeat', 'green'),
  _SeedCat('education', 'graduation_cap', 'purple'),
  _SeedCat('shopping', 'shopping_bag', 'purple'),
  _SeedCat('clothing', 't_shirt', 'orange'),
  _SeedCat('entertainment', 'film_slate', 'pink'),
  _SeedCat('subscriptions', 'repeat', 'slate'),
  _SeedCat('travel', 'airplane', 'blue'),
  _SeedCat('gifts', 'gift', 'coral'),
  _SeedCat('family', 'baby', 'green'),
  _SeedCat('personal_care', 'sparkle', 'pink'),
  _SeedCat('sport', 'barbell', 'green'),
  _SeedCat('taxes', 'receipt', 'slate'),
  _SeedCat('other', 'dots_three_circle', 'grey', system: SystemCategory.otherExpense),
];

const _income = [
  _SeedCat('salary', 'money', 'green'),
  _SeedCat('freelance', 'briefcase', 'blue'),
  _SeedCat('business', 'storefront', 'purple'),
  _SeedCat('gifts_income', 'gift', 'coral'),
  _SeedCat('refunds', 'arrow_counter_clockwise', 'slate'),
  _SeedCat('investments', 'chart_line_up', 'orange'),
  _SeedCat('other_income', 'dots_three_circle', 'grey', system: SystemCategory.otherIncome),
];

/// Localized seed names. Seeded names become user data after creation.
const Map<String, Map<String, String>> seedNames = {
  'en': {
    'food': 'Food & Groceries', 'restaurants': 'Restaurants & Cafes', 'transport': 'Transport',
    'fuel': 'Fuel', 'rent': 'Rent / Housing', 'bills': 'Bills & Utilities',
    'phone': 'Phone & Internet', 'health': 'Health', 'education': 'Education',
    'shopping': 'Shopping', 'clothing': 'Clothing & Shoes', 'entertainment': 'Entertainment',
    'subscriptions': 'Subscriptions', 'travel': 'Travel', 'gifts': 'Gifts & Donations',
    'family': 'Family & Kids', 'personal_care': 'Personal Care', 'sport': 'Sport',
    'taxes': 'Taxes & Fees', 'other': 'Other', 'salary': 'Salary', 'freelance': 'Freelance',
    'business': 'Business', 'gifts_income': 'Gifts', 'refunds': 'Refunds',
    'investments': 'Investments', 'other_income': 'Other income',
    'adjustment': 'Balance adjustment',
  },
  'fr': {
    'food': 'Alimentation', 'restaurants': 'Restaurants & cafés', 'transport': 'Transport',
    'fuel': 'Carburant', 'rent': 'Loyer / Logement', 'bills': 'Factures & charges',
    'phone': 'Téléphone & Internet', 'health': 'Santé', 'education': 'Éducation',
    'shopping': 'Shopping', 'clothing': 'Vêtements & chaussures', 'entertainment': 'Loisirs',
    'subscriptions': 'Abonnements', 'travel': 'Voyages', 'gifts': 'Cadeaux & dons',
    'family': 'Famille & enfants', 'personal_care': 'Soins personnels', 'sport': 'Sport',
    'taxes': 'Impôts & frais', 'other': 'Autre', 'salary': 'Salaire', 'freelance': 'Freelance',
    'business': 'Activité', 'gifts_income': 'Cadeaux', 'refunds': 'Remboursements',
    'investments': 'Investissements', 'other_income': 'Autres revenus',
    'adjustment': 'Ajustement de solde',
  },
  'ar': {
    'food': 'طعام وبقالة', 'restaurants': 'مطاعم ومقاهي', 'transport': 'نقل',
    'fuel': 'وقود', 'rent': 'إيجار / سكن', 'bills': 'فواتير وخدمات',
    'phone': 'هاتف وإنترنت', 'health': 'صحة', 'education': 'تعليم',
    'shopping': 'تسوق', 'clothing': 'ملابس وأحذية', 'entertainment': 'ترفيه',
    'subscriptions': 'اشتراكات', 'travel': 'سفر', 'gifts': 'هدايا وتبرعات',
    'family': 'عائلة وأطفال', 'personal_care': 'عناية شخصية', 'sport': 'رياضة',
    'taxes': 'ضرائب ورسوم', 'other': 'أخرى', 'salary': 'راتب', 'freelance': 'عمل حر',
    'business': 'أعمال', 'gifts_income': 'هدايا', 'refunds': 'استردادات',
    'investments': 'استثمارات', 'other_income': 'دخل آخر',
    'adjustment': 'تعديل الرصيد',
  },
};

/// Seeds localized categories once (no-op if any category exists).
Future<void> seedCategories(AppDatabase db, String locale, int now) async {
  if (await db.categoriesDao.count() > 0) return;
  final lang = seedNames.containsKey(locale) ? locale : 'en';
  final names = seedNames[lang]!;
  const uuid = Uuid();
  await db.transaction(() async {
    var order = 0;
    Future<void> add(_SeedCat c, String kind) => db.categoriesDao.upsert(
      CategoriesCompanion.insert(
        id: uuid.v4(),
        createdAt: now,
        updatedAt: now,
        name: names[c.key]!,
        kind: kind,
        icon: c.icon,
        color: c.color,
        sortOrder: Value(order++),
        isSystem: Value(c.system != null),
        systemKey: Value(c.system),
      ),
    );
    for (final c in _expense) {
      await add(c, 'expense');
    }
    order = 0;
    for (final c in _income) {
      await add(c, 'income');
    }
    await add(
      const _SeedCat('adjustment', 'scales', 'slate', system: SystemCategory.adjustment),
      'income',
    );
  });
}
