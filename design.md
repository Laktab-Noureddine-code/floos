# Personal Finance Tracker — Design Spec (design.md)

> Reference: 3-screen finance UI (Home · Report · My Plan) in a soft lavender / white style.
> Target: Flutter, offline, local SQLite (Drift).
> All colors were **sampled from the reference image**; sizes are measured against a **375 × 812 pt** frame.

---

## 0. Audit of the reference design

### What works (keep it)
| Area | Why it's good |
|---|---|
| **Visual hierarchy** | One big number per screen (balance, total expenses, goal amount), so you read each screen in about one second. |
| **Soft color system** | A single brand purple, plus one pastel tint and one strong color for each category. The colors look consistent and are easy to extend. |
| **Card-based layout** | White cards with 20 pt radius on a #F5F5F5 background make clean sections that are easy to build as reusable widgets. |
| **Center FAB** | The "+" is always one thumb-tap away, which matches the "quick add in under 5 seconds" rule. |
| **Decimal de-emphasis** | `$87,457` bold and `.85` at 50% opacity is an elegant way to make large numbers readable. |
| **Comparison chips** | `+12% vs last month` gives a cheap insight that gets a lot of use. |
| **Goal warning banner** | Shows the goal status ("behind schedule") inline instead of hiding it. |

### Issues found in the reference (fix in your version)
| # | Issue | Severity | Fix |
|---|---|---|---|
| 1 | Goal card shows **"$8,750.00 Out of $1,750.00"**, so the saved amount is bigger than the target, while the bar is only ~15% full and says "$750 Left". The data is contradictory. | High | Format the card as `saved / target`, with progress `saved/target` and left `target − saved`, all computed from the same source. |
| 2 | The **"Budgets"** section contains *Save for a Car / Education / Vacation*, which are savings **goals**, not spending **limits**. | High | Use the Budgets section for **category limits** (spent / limit). Keep savings in Goals. (See §4.3.) |
| 3 | Typo **"Gropceries"**. | Low | "Groceries". |
| 4 | **"$2,95,776"** uses the Indian digit grouping, while everything else uses Western grouping. | Medium | Use one `NumberFormat` from the user's locale everywhere. |
| 5 | **"Cash, EUR"** shows **$** amounts. | Medium | The account currency must drive the symbol. |
| 6 | Header says **November 2025**, but the transactions are dated **12 January 2026**. | Medium | The list must follow the selected period. |
| 7 | **"+$784 than last week"** has broken grammar. | Low | "+$784 vs last week". |
| 8 | The donut has an **unlabelled grey hatched slice**. | Medium | Label it "Other" or "Unbudgeted", or remove it. |
| 9 | "Your insight is ready · **Get Pro**" is an upsell that doesn't fit a personal offline app. | Low | Reuse the pill as a **local insight banner** (e.g. "Food is 25% above last month"). |
| 10 | **The FAB covers content** ("Health Savin…", the Cafes row). | Medium | Add bottom padding to scroll views: `navBarHeight + 40`. |
| 11 | **Low contrast**: grey labels (#9A9A9A on white) and 10–11 pt captions fall below WCAG AA. | Medium | Use #6E6E73 or darker for secondary text, with a minimum size of 12 pt. |
| 12 | The **icon-only** pin / history buttons have no labels. | Low | Add `Semantics` / tooltips. |
| 13 | Expense rows mix the sign inside the number with `$` after it (`-354.25$`). | Low | Use one format: `−$354.25` (with a real minus sign, U+2212). |

### Adaptations for your feature list
| Your feature | Where it goes |
|---|---|
| Transactions, quick add | Home list + FAB → bottom sheet (§4.4) |
| Accounts / wallets | "Your Money → Details" opens the Accounts screen |
| Limits (budgets) | Plan → **Budgets** section: rings show **% spent** and go green → orange → red |
| Objectifs (goals) | Plan → **Goals** section (same card as the reference, with the data fixed) |
| Reports | Report tab: Expenses / Income toggle, donut ↔ bar switch |
| Backup / export, PIN, currency, month start day | Settings tab |

---

## 1. Design tokens

### 1.1 Colors

#### Brand
| Token | Hex | Use |
|---|---|---|
| `primary` | `#9C6CF6` | Brand purple, active toggles, chips, donut "Other" |
| `primaryLight` | `#B08AFF` | FAB gradient start, highlights |
| `primaryDark` | `#7C4DE0` | Pressed states, gradient end |
| `primaryTint` | `#F4EEFF` | Chip background ("For the Period"), selected states |
| `headerGradient` | `#A278FE → #A47EF5 → #9271DA` (top → bottom, slight diagonal) | Home header |

#### Neutrals
| Token | Hex | Use |
|---|---|---|
| `background` | `#F5F5F5` | Scaffold background |
| `surface` | `#FFFFFF` | Cards, bottom nav, sheets |
| `surfaceMuted` | `#EFEFEF` | Segmented control track, inactive pills |
| `border` | `#EDEDED` | 1 pt card outline (very subtle) |
| `textPrimary` | `#111111` | Titles, amounts |
| `textSecondary` | `#6E6E73` | Labels (darker than the reference, for AA) |
| `textTertiary` | `#A1A1A6` | Inactive nav labels, hints |
| `inverse` | `#141311` | Black insight pill, dark CTA button |
| `onDark` | `#FFFFFF` | Text on purple or black |

#### Semantic
| Token | Hex | Use |
|---|---|---|
| `expense` | `#F0384D` | Negative amounts |
| `income` | `#22A55B` | Positive amounts |
| `successTint` | `#E7FFEA` | `+12%` chip background (text `#22A55B`) |
| `danger` | `#FD7150` | Goal-behind banner, over-limit |
| `dangerTint` | `#FFF0EB` | Goal progress track |
| `warning` | `#FE9F1C` | Budget 70–100% |

#### Category palette (strong + tint pairs)
| Name | Strong | Tint | Example |
|---|---|---|---|
| Purple | `#9C6CF6` | `#F7F1FB` | Education, Shopping |
| Blue | `#229FFC` | `#E7F5FE` | Groceries, Vacation, Income icon |
| Green | `#38C775` | `#E7F4EB` | Health, Salary |
| Orange | `#FE7503` | `#FFF1E5` | Clothing & Shoes |
| Coral | `#F27255` | `#FFF0E9` | Car, Transport |
| Pink/Red | `#F0384D` | `#FFEAEF` | Expense icon, Bills |
| Slate | `#5B6B82` | `#F1F4F9` | Cafes, Misc |
| Grey (Other) | `#D9D9D9` hatched | `#EBEBEB` | "Other" slice |

> Rule: an icon tile always uses **tint as the background + strong as the glyph**. A ring or bar always uses **strong as the fill + tint as the track**.

### 1.2 Typography
Font: **Inter** (`google_fonts`) for the closest match. Use `FontFeature.tabularFigures()` on every number so digits don't jump around.

| Token | Size / Line | Weight | Use |
|---|---|---|---|
| `displayL` | 40 / 48 | 700 | Home balance (decimals: same size, 50% opacity) |
| `displayM` | 28 / 34 | 700 | Donut center total, goal amount |
| `titleL` | 18 / 24 | 600 | Screen title ("Report", "My Plan") |
| `titleM` | 16 / 22 | 600 | Section headers ("Transactions", "Goals") |
| `amountM` | 20 / 26 | 700 | Income / Expense card values |
| `bodyM` | 15 / 20 | 600 | List item title, list amount |
| `bodyS` | 13 / 18 | 400 | Subtitles ("31% of total") |
| `caption` | 12 / 16 | 500 | Chips, nav labels, "View All", dates |
| `micro` | 11 / 14 | 600 | Donut tooltip ("31%"), ring % |

Letter spacing: −0.5 for display styles, −0.2 for titles, 0 for everything else.

### 1.3 Spacing (4-pt grid)
`xs 4 · sm 8 · md 12 · lg 16 · xl 20 · 2xl 24 · 3xl 32`
- Screen horizontal padding: **16**
- Gap between cards in a list: **12**
- Card inner padding: **16**
- Section header → content: **12**
- Section → section: **24**

### 1.4 Radius
| Token | Value | Use |
|---|---|---|
| `rSm` | 8 | Small chips, progress bars (full pill = height/2) |
| `rMd` | 12 | Icon tiles (40×40) |
| `rLg` | 20 | Cards, list tiles |
| `rXl` | 28 | Home header bottom / content sheet top, bottom sheets |
| `rFull` | 999 | Pills, FAB, avatar, segmented control |

### 1.5 Elevation / shadows
| Token | Value |
|---|---|
| `shadowCard` | `0 2 8 rgba(17,17,17,0.04)` (almost flat; the cards rely mostly on the white-on-grey contrast) |
| `shadowFloating` | `0 8 24 rgba(17,17,17,0.08)` (goal card, month dropdown, toggles) |
| `shadowFab` | `0 8 20 rgba(156,108,246,0.45)` (purple glow under the FAB) |
| `shadowNav` | `0 -4 16 rgba(17,17,17,0.04)` |

### 1.6 Iconography
- Style: **rounded, filled-duotone** glyphs at 20 pt inside 40 × 40 tiles (`rMd`).
- Packages: `phosphor_flutter` (Fill / Duotone) or `iconsax` are the closest match.
- Nav icons: 22 pt, filled when active and outlined when inactive.

### 1.7 Motion
| Interaction | Spec |
|---|---|
| Tab switch | Fade-through, 200 ms, `Curves.easeOut` |
| Donut load | Sweep in from 0° with a 60 ms stagger per segment, 600 ms `easeOutCubic` |
| Progress bars / rings | Animate width / sweep from 0 on first build, 500 ms |
| Segment toggle | Sliding thumb, 220 ms `easeInOut` |
| FAB press | Scale to 0.92, then a bottom sheet slides up (300 ms) |
| Balance change | `AnimatedSwitcher` / counting tween, 400 ms |

---

## 2. Layout and navigation

```
┌─────────────────────────────┐
│ Screen content (scrollable) │  ← bottom padding = 96 + safe area
│                             │
├─────────────────────────────┤
│  Home  Report  (FAB)  Plan  Settings │  ← nav 72 pt + safe area
└─────────────────────────────┘
```

### Bottom navigation
- Height: **72** + safe area. White, with `shadowNav` and a top radius of `rXl`.
- 4 items with an empty center slot: **Home · Report · [FAB] · Plan · Settings**.
- Item: icon 22 pt, 4 pt gap, label `caption`.
  - Active: icon `textPrimary` filled, label `textPrimary` w600.
  - Inactive: icon and label `textTertiary`.
- Flutter: `Scaffold(bottomNavigationBar: CustomNav, floatingActionButton: GradientFab, floatingActionButtonLocation: centerDocked)`, or a `Stack` for full control.

### FAB
- 56 × 56 circle, **raised 20 pt above the nav top edge** (half outside the nav).
- Fill: `LinearGradient(topLeft #B08AFF → bottomRight #9C6CF6)`.
- Ring: a 4 pt white border (separates the FAB from the content behind it).
- Glyph: `+` at 24 pt, white, stroke 2.5.
- Shadow: `shadowFab`.
- Action: opens the **Add Transaction** bottom sheet.

---

## 3. Shared components

### 3.1 `AppCard`
White, `rLg`, padding 16, `shadowCard`, optional 1 pt `border`.

### 3.2 `IconTile`
40 × 40, `rMd`, background = category tint, 20 pt glyph = category strong.
Variant `small` 32 × 32 (`rSm`), used for the account badge.

### 3.3 `MonthPicker` pill
- Height 36, horizontal padding 14, `rFull`.
- On white screens: white background + `shadowFloating`, text `caption` w500 `textPrimary`, chevron-down 16 pt.
- On the purple header: background `rgba(255,255,255,0.18)`, white text.
- Opens a month/year sheet. It also respects the **custom month start day** from Settings.

### 3.4 `CircleIconButton`
40 × 40, white (or white 18% on purple), `rFull`. Notification variant: a 8 pt red dot (`#F0384D`) with a 2 pt white border at the top right.

### 3.5 `SegmentedToggle` (Expenses | Income)
- Track: `surfaceMuted`, height 44, `rFull`, padding 4.
- Thumb: white, `rFull`, `shadowFloating`.
- Label: `bodyS` w600. Active text is `textPrimary`; inactive is `textSecondary`.

### 3.6 `ChartTypeToggle` (bar | donut)
A small white pill (height 32) with two 28 × 28 icon buttons. The active one is a filled `primary` circle with a white icon.

### 3.7 `TrendChip`
Height 22, padding 6 × 8, `rFull`. Up (spending ↑ is bad) uses `dangerTint` + `danger`. Down uses `successTint` + `income`.
Text format: `+12%` / `−6%`, plus "vs last month" next to it in `caption textSecondary`.
> Note: in the reference, a spending *increase* is shown in green, which is backwards. For **expenses**, an increase = red. For **income**, an increase = green.

### 3.8 `LinearProgress`
Height 8, `rFull`, track = tint, fill = strong. Animate it.
Variant **`hatched`** (goal card): the fill is solid, and the remaining area *near the fill* (≈ 25% of the width) is painted with diagonal stripes 2 pt wide, 4 pt apart, in the strong color at 40% opacity. The rest is a plain tint track. There is a 14 pt white knob with a 3 pt strong-colored border at the fill end.
Use a `CustomPainter`.

### 3.9 `RingProgress`
44 × 44, stroke 4, `StrokeCap.round`, start angle −90°. Track = tint, fill = strong. Center label `micro` w700 in the strong color. Inner circle fill = tint at 60%.

### 3.10 `SectionHeader`
Row: title (`titleM`) + optional trailing "View All" (`caption textSecondary`) or icon buttons. Height 24.

### 3.11 `InsightPill`
Height 48, `inverse` background, `rFull`, padding 16.
Leading ✨ icon (white 18 pt) + text `bodyS` w600 white + trailing "See" + chevron (white 70%).
Content comes from a local insights engine (see §6).

### 3.12 `TransactionTile`
```
[IconTile]  Title (bodyM)                     −$354.25 (bodyM w700, expense/income color)
            ↳ [badge] Account · Category (caption textSecondary)    $4,245.21 (caption, running balance)
```
- `AppCard` padding 16, gap 12 between tiles.
- Swipe left reveals **Delete** (danger) and **Edit** (primary).
- Tapping it opens the edit sheet.

### 3.13 `DateGroupHeader`
`Monday, 12 January 2026` in `caption textSecondary` on the left; `Total  −$295.76` on the right (`caption` + `bodyS w700`).

---

## 4. Screens

### 4.1 Home

**Header (purple)**
- Height ≈ **300** including the status bar. `headerGradient` with a subtle diagonal light sheen (an optional `RadialGradient` white at 10% in the top-left).
- Row (top 56): **Avatar** 44 pt (circle, 2 pt white border, small badge at the bottom right) · **MonthPicker** (centered) · **Notification button**.
- "Current Balance": `bodyS` white 80%, centered, 24 pt below the row.
- Balance: `displayL` white. The decimals `.85` are white at 50%.
- Delta pill: `+$784 vs last week`, `caption` white, background white 18%, `rFull`, height 26.

**Content sheet**
- A white container overlapping the header by **24 pt**, with a top radius `rXl`, holding all of the content below. (The reference uses `background #F5F5F5` inside; either works. Grey with white cards looks closer to the reference.)

**"Your Money" section**
- Header: "Your Money" + ⓘ, with a trailing pill button "Details ›" (height 28, `surfaceMuted`) → Accounts screen.
- 2 cards side by side (gap 12, each `Expanded`), height ≈ 104:
  - `IconTile` (Income: blue tint + 💰 / Expenses: pink tint + 👛)
  - Label `bodyS textSecondary` + ⓘ
  - Value `amountM`
- Tapping a card opens Report pre-filtered to that type.

**Insight pill**: `InsightPill`, full width, 16 pt margin above and below.

**Transactions section**
- Header: "Transactions" + icon buttons (📌 pinned, 🕘 history) + a "For the Period" chip (`primaryTint`, text `primary`, `caption` w600). The chip opens a period filter.
- Grouped by day: `DateGroupHeader` + `TransactionTile`s.
- Shows the last ~10 items, then "See all" → full list with search and filters.

**Empty state**: an illustration of an empty wallet, "No transactions yet", and a primary button "Add your first expense".

### 4.2 Report

- App bar: back arrow, "Report" `titleL`, `MonthPicker` (white) on the right.
- `SegmentedToggle` **Expenses | Income** (16 pt margin).
- Row: "Expenses Report" `titleM` + `ChartTypeToggle`.

**Donut chart**
- Diameter **220**, stroke **44**, **4° gaps** between segments, segments with **rounded corners** (radius 8).
- Order: largest slice first, clockwise from −90°. "Other" (grey hatched) goes last.
- Center: "Total Expenses" `bodyS textSecondary` + amount `displayM` (decimals at 50% opacity).
- Tapping a segment raises it with a 6 pt outward offset and shows a black tooltip pill (`inverse`, `micro` white, "31%") at the segment's outer edge.
- Implementation: a `CustomPainter` (fl_chart's `PieChart` can't make rounded segment ends; it's fine if you accept square ends).

**Bar variant**: the last 6 months as vertical bars with a 12 pt width and top radius 6. The current month is `primary`, the others `primaryTint`.

**Category list**
- Header row: "All Expenses" `bodyS textSecondary` · "Total **$42,124.67**".
- Each item is an `AppCard`:
```
[IconTile]  Groceries (bodyM)                 $8,750.00 (bodyM w700)
            31% of total (bodyS secondary)    [TrendChip +12%] vs last month
[==========LinearProgress (category color)==========]
```
- Bar fill = share of the total. Tap → category detail (transactions + 6-month trend).

### 4.3 My Plan (Goals + Budgets)

- App bar: back arrow, "My Plan" `titleL`; trailing: a black circle "+" button (40 pt, `inverse`) and an outlined "↗" button (open full plan / export).

**Goals**
- `SectionHeader` "Goals" · "View All". A horizontal `PageView` of goal cards, or just the featured goal.
- **Goal card** (`shadowFloating`, `rLg`):
  ```
  [IconTile coral]  House by the Sea (bodyM)        [⋮]
                    Due Jun 2027 (caption secondary)
  
  $1,000.00  of $1,750.00          ← displayM + bodyS secondary
  [=====●//////---------------]     ← hatched LinearProgress
  Your Progress (caption)             $750 left (caption w700)
  ```
- **Status banner** attached to the bottom of the card (bottom radius = card radius, height 36):
  - Behind: `danger` background, white ⓘ + "You're 30% behind schedule".
  - On track: `income` background, "On track: $125/month needed".
  - Done: `primary` background, "Goal reached 🎉".
- Status logic: `expected = target × elapsedDays / totalDays`; behind if `saved < expected × 0.9`.

**Budgets (limits)**, reworked from the reference
- `SectionHeader` "Budgets" · "View All".
- Each item is an `AppCard`, height 72:
  ```
  [IconTile]  Food (bodyM)                              (RingProgress 72%)
              $1,440 of $2,000 · $18/day left (bodyS)
  ```
- Ring color by % spent: **< 70% → green**, **70–100% → warning orange**, **> 100% → danger red** (and the ring shows "112%").
- Tap → budget detail (edit limit, period, rollover toggle, alerts at 80% / 100%).

### 4.4 Add Transaction (bottom sheet, opened from the FAB)
Not in the reference. This design matches its style:
- Modal sheet, top radius `rXl`, drag handle 36 × 4 `surfaceMuted`.
- `SegmentedToggle`: **Expense | Income | Transfer**.
- Big amount field, centered, `displayL`, with a currency prefix; the numeric keypad autofocuses.
- A horizontal scroll of category chips (`IconTile` + label under it, 64 pt wide). The selected one gets a 2 pt `primary` border.
- Rows (each 52 pt, with a divider): 📅 Date (default today) · 💳 Account · 📝 Note · 🔁 Repeat.
- Primary button: full width, height 52, `rFull`, `primary` gradient, "Save". It turns disabled grey until amount > 0.

### 4.5 Settings
Grouped `AppCard` lists (iOS-style rows, 52 pt each, chevron trailing):
- **General**: Currency · Month starts on · Language · Theme (Light / Dark / System)
- **Security**: App lock (PIN / biometrics) switch
- **Data**: Backup now · Restore from backup · Export CSV · Delete all data (danger text)
- **Categories & Accounts**: Manage categories · Manage accounts
- **About**: Version

---

## 5. Dark mode (optional but cheap with tokens)
| Light | Dark |
|---|---|
| `background #F5F5F5` | `#0E0E10` |
| `surface #FFFFFF` | `#1A1A1D` |
| `surfaceMuted #EFEFEF` | `#26262A` |
| `textPrimary #111111` | `#F5F5F7` |
| `textSecondary #6E6E73` | `#A1A1A6` |
| Category tints | Strong color at **16% opacity** over the surface |
| `inverse` pill | `#FFFFFF` with dark text |

The header gradient stays purple; just reduce the brightness by ~10%.

---

## 6. Local insights (replaces "Get Pro")
Compute them on app open from SQLite, and show the most important one in the `InsightPill`:
1. Budget ≥ 80% → "Food is at 86% of its limit, $14/day left"
2. Category Δ ≥ 20% vs last month → "Cafes is up 34% vs last month"
3. Goal behind → "House by the Sea needs $210/month to stay on track"
4. Savings rate this month → "You saved 22% of your income 👏"

---

## 7. Flutter implementation

### 7.1 Packages
| Need | Package |
|---|---|
| DB | `drift`, `drift_flutter`, `sqlite3_flutter_libs` (or `sqlcipher_flutter_libs` for encryption) |
| State | `flutter_riverpod` |
| Font | `google_fonts` (Inter) |
| Icons | `phosphor_flutter` |
| Charts | `fl_chart` (bars) + a custom painter (donut, rings, hatched bar) |
| Formatting | `intl` |
| Notifications | `flutter_local_notifications` |
| Lock | `local_auth` |
| Backup | `file_picker`, `share_plus`, `path_provider` |

### 7.2 Folder structure
```
lib/
  core/theme/        app_colors.dart, app_text.dart, app_theme.dart, tokens.dart
  core/widgets/      app_card.dart, icon_tile.dart, segmented_toggle.dart,
                     trend_chip.dart, linear_progress.dart, ring_progress.dart,
                     donut_chart.dart, insight_pill.dart, month_picker.dart,
                     gradient_fab.dart, app_bottom_nav.dart
  data/              database.dart (Drift tables), daos/, repositories/
  features/home/  features/report/  features/plan/  features/settings/
  features/transaction_form/
```

### 7.3 Theme starter
```dart
class AppColors {
  static const primary = Color(0xFF9C6CF6);
  static const primaryLight = Color(0xFFB08AFF);
  static const primaryDark = Color(0xFF7C4DE0);
  static const primaryTint = Color(0xFFF4EEFF);
  static const background = Color(0xFFF5F5F5);
  static const surface = Colors.white;
  static const surfaceMuted = Color(0xFFEFEFEF);
  static const textPrimary = Color(0xFF111111);
  static const textSecondary = Color(0xFF6E6E73);
  static const textTertiary = Color(0xFFA1A1A6);
  static const inverse = Color(0xFF141311);
  static const expense = Color(0xFFF0384D);
  static const income = Color(0xFF22A55B);
  static const successTint = Color(0xFFE7FFEA);
  static const danger = Color(0xFFFD7150);
  static const dangerTint = Color(0xFFFFF0EB);
  static const warning = Color(0xFFFE9F1C);

  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFA278FE), Color(0xFFA47EF5), Color(0xFF9271DA)],
  );
  static const fabGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );
}

/// strong, tint
enum CategoryColor {
  purple(Color(0xFF9C6CF6), Color(0xFFF7F1FB)),
  blue(Color(0xFF229FFC), Color(0xFFE7F5FE)),
  green(Color(0xFF38C775), Color(0xFFE7F4EB)),
  orange(Color(0xFFFE7503), Color(0xFFFFF1E5)),
  coral(Color(0xFFF27255), Color(0xFFFFF0E9)),
  pink(Color(0xFFF0384D), Color(0xFFFFEAEF)),
  slate(Color(0xFF5B6B82), Color(0xFFF1F4F9));
  const CategoryColor(this.strong, this.tint);
  final Color strong, tint;
}

class AppRadius { static const sm = 8.0, md = 12.0, lg = 20.0, xl = 28.0; }
class AppSpace  { static const xs = 4.0, sm = 8.0, md = 12.0, lg = 16.0, xl = 20.0, x2 = 24.0, x3 = 32.0; }

ThemeData buildTheme() {
  final base = GoogleFonts.interTextTheme();
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, surface: AppColors.surface),
    textTheme: base.copyWith(
      displayLarge: base.displayLarge!.copyWith(fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: AppColors.textPrimary),
      titleLarge:   base.titleLarge!.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleMedium:  base.titleMedium!.copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      bodyMedium:   base.bodyMedium!.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      bodySmall:    base.bodySmall!.copyWith(fontSize: 13, color: AppColors.textSecondary),
      labelSmall:   base.labelSmall!.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
    ),
  );
}
```

### 7.4 Money display helper (decimals at 50% opacity)
```dart
Widget moneyText(int cents, {required String currency, required TextStyle style}) {
  final f = NumberFormat.currency(symbol: currency, decimalDigits: 2);
  final s = f.format(cents / 100);           // "$87,457.85"
  final i = s.lastIndexOf(RegExp(r'[.,]'));
  return Text.rich(TextSpan(children: [
    TextSpan(text: s.substring(0, i), style: style),
    TextSpan(text: s.substring(i), style: style.copyWith(color: style.color!.withOpacity(0.5))),
  ]), style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]));
}
```

### 7.5 Donut painter sketch
```dart
class DonutPainter extends CustomPainter {
  DonutPainter(this.values, this.colors, {this.stroke = 44, this.gapDeg = 4, this.progress = 1});
  final List<double> values; final List<Color> colors;
  final double stroke, gapDeg, progress;
  @override
  void paint(Canvas c, Size s) {
    final total = values.fold<double>(0, (a, b) => a + b);
    final rect = Rect.fromCircle(center: s.center(Offset.zero), radius: s.width / 2 - stroke / 2);
    var start = -pi / 2;
    final gap = gapDeg * pi / 180;
    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * pi * progress;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..color = colors[i];
      c.drawArc(rect, start + gap / 2, max(0, sweep - gap), false, p);
      start += sweep;
    }
  }
  @override
  bool shouldRepaint(covariant DonutPainter o) => o.progress != progress || o.values != values;
}
```
> For the rounded segment corners, build each segment as a `Path` (outer arc → inner arc) and apply corner radii, or draw it with `StrokeCap.round` and a slightly larger gap (≈ 10°).

---

## 8. Accessibility checklist
- [ ] Text contrast ≥ 4.5:1 (secondary text `#6E6E73` on white = 5.0:1 ✓)
- [ ] Minimum text size 12 pt; respect `MediaQuery.textScaler` up to 1.3× without overflow
- [ ] Touch targets ≥ 44 × 44
- [ ] Never rely on color alone: show a ring % label and the sign on amounts (−/+)
- [ ] `Semantics` labels on icon-only buttons, the FAB ("Add transaction"), chart segments ("Groceries, 31 percent, 8,750 dollars")
- [ ] Reduce motion: skip the chart sweep when `MediaQuery.disableAnimations` is set

---

## 9. Build order (UI)
1. Tokens + theme + `AppCard`, `IconTile`, `moneyText`
2. Bottom nav + gradient FAB + empty tab screens
3. Add Transaction sheet (wired to Drift)
4. Home (header, Your Money, transactions list)
5. Report (toggle, donut, category list)
6. Plan (goal card + hatched bar, budget rings)
7. Settings (backup / export / lock)
8. Insights, animations, dark mode
