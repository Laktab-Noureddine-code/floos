// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Floos';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get confirm => 'Confirmer';

  @override
  String get close => 'Fermer';

  @override
  String get back => 'Retour';

  @override
  String get retry => 'Réessayer';

  @override
  String get undo => 'Annuler';

  @override
  String get done => 'Terminé';

  @override
  String get next => 'Suivant';

  @override
  String get skip => 'Passer';

  @override
  String get seeAll => 'Tout voir';

  @override
  String get viewAll => 'Voir tout';

  @override
  String get details => 'Détails';

  @override
  String get add => 'Ajouter';

  @override
  String get search => 'Rechercher';

  @override
  String get none => 'Aucun';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String get tomorrow => 'Demain';

  @override
  String get ok => 'OK';

  @override
  String get archive => 'Archiver';

  @override
  String get unarchive => 'Désarchiver';

  @override
  String get duplicate => 'Dupliquer';

  @override
  String get apply => 'Appliquer';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get clear => 'Effacer';

  @override
  String get optional => 'Facultatif';

  @override
  String get more => 'Plus';

  @override
  String get name => 'Nom';

  @override
  String get note => 'Note';

  @override
  String get date => 'Date';

  @override
  String get time => 'Heure';

  @override
  String get amount => 'Montant';

  @override
  String get account => 'Compte';

  @override
  String get category => 'Catégorie';

  @override
  String get categories => 'Catégories';

  @override
  String get accounts => 'Comptes';

  @override
  String get tags => 'Étiquettes';

  @override
  String get payee => 'Bénéficiaire';

  @override
  String get currency => 'Devise';

  @override
  String get icon => 'Icône';

  @override
  String get color => 'Couleur';

  @override
  String get type => 'Type';

  @override
  String get total => 'Total';

  @override
  String get loading => 'Chargement…';

  @override
  String get selectAll => 'Tout sélectionner';

  @override
  String get change => 'Changer';

  @override
  String get share => 'Partager';

  @override
  String get export => 'Exporter';

  @override
  String get import => 'Importer';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get settle => 'Solder';

  @override
  String get pause => 'Mettre en pause';

  @override
  String get resume => 'Reprendre';

  @override
  String get open => 'Ouvrir';

  @override
  String get copy => 'Copier';

  @override
  String get noDate => 'Aucune date';

  @override
  String get noTime => 'Aucune heure';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get from => 'De';

  @override
  String get to => 'Vers';

  @override
  String get start => 'Début';

  @override
  String get end => 'Fin';

  @override
  String get custom => 'Personnalisé';

  @override
  String get navHome => 'Accueil';

  @override
  String get navReport => 'Rapport';

  @override
  String get navPlan => 'Plan';

  @override
  String get navSettings => 'Réglages';

  @override
  String get fabAddTransaction => 'Ajouter une transaction';

  @override
  String get typeExpense => 'Dépense';

  @override
  String get typeIncome => 'Revenu';

  @override
  String get typeTransfer => 'Virement';

  @override
  String get expenses => 'Dépenses';

  @override
  String get incomes => 'Revenus';

  @override
  String get transfers => 'Virements';

  @override
  String get saved => 'Enregistré';

  @override
  String get deleted => 'Supprimé';

  @override
  String deletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments supprimés',
      one: '1 élément supprimé',
    );
    return '$_temp0';
  }

  @override
  String transactionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
      zero: 'Aucune transaction',
    );
    return '$_temp0';
  }

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
      zero: '0 jour',
    );
    return '$_temp0';
  }

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sélectionnées',
      one: '1 sélectionnée',
    );
    return '$_temp0';
  }

  @override
  String get errorGeneric => 'Une erreur est survenue.';

  @override
  String get errorWithRetry => 'Impossible de charger les données.';

  @override
  String get errAmountEmpty => 'Saisissez un montant.';

  @override
  String get errAmountNegative => 'Le montant doit être positif.';

  @override
  String get errAmountInvalid => 'Montant invalide.';

  @override
  String errAmountTooManyDecimals(int digits) {
    return 'Maximum $digits décimales pour cette devise.';
  }

  @override
  String get errAmountTooLarge => 'Montant trop élevé.';

  @override
  String get errDivisionZero => 'Division par zéro impossible.';

  @override
  String get errAmountZero => 'Le montant doit être supérieur à 0.';

  @override
  String get errAccountNameLength =>
      'Le nom doit contenir de 1 à 40 caractères.';

  @override
  String get errAccountTypeInvalid => 'Type de compte invalide.';

  @override
  String get errCurrencyInvalid => 'Devise inconnue.';

  @override
  String get errAccountNameTaken => 'Un compte actif porte déjà ce nom.';

  @override
  String get errAccountNotFound => 'Compte introuvable.';

  @override
  String get errAccountHasTransactions =>
      'Ce compte contient des transactions.';

  @override
  String get errCategoryNameLength =>
      'Le nom doit contenir de 1 à 30 caractères.';

  @override
  String get errCategoryParentSelf =>
      'Une catégorie ne peut pas être son propre parent.';

  @override
  String get errCategoryNotFound => 'Catégorie introuvable.';

  @override
  String get errCategoryMaxDepth =>
      'Un seul niveau de sous-catégorie est autorisé.';

  @override
  String get errCategoryKindMismatch =>
      'La catégorie ne correspond pas au type.';

  @override
  String get errCategoryHasChildren => 'Cette catégorie a des sous-catégories.';

  @override
  String get errCategorySystem =>
      'Les catégories système ne peuvent pas être supprimées.';

  @override
  String get errCategoryInUse =>
      'Catégorie utilisée : choisissez une catégorie de remplacement.';

  @override
  String get errCategoryMergeSame => 'Choisissez deux catégories différentes.';

  @override
  String get errTagNameLength => 'Le nom doit contenir de 1 à 30 caractères.';

  @override
  String get errTagNameTaken => 'Cette étiquette existe déjà.';

  @override
  String get errRateSameCurrency => 'Choisissez deux devises différentes.';

  @override
  String get errRateInvalid => 'Taux invalide.';

  @override
  String errRateMissing(String from, String to) {
    return 'Aucun taux $from → $to. Ajoutez-en un.';
  }

  @override
  String get errAccountRequired => 'Choisissez un compte.';

  @override
  String get errPayeeTooLong => '60 caractères maximum.';

  @override
  String get errNoteTooLong => '500 caractères maximum.';

  @override
  String get errTimeInvalid => 'Heure invalide.';

  @override
  String get errToAccountRequired => 'Choisissez le compte de destination.';

  @override
  String get errSameAccount => 'Les comptes doivent être différents.';

  @override
  String get errToAmountRequired => 'Saisissez le montant reçu.';

  @override
  String get errCategoryRequired => 'Choisissez une catégorie.';

  @override
  String get errNotFound => 'Élément introuvable.';

  @override
  String get errCustomRange => 'La date de fin doit suivre la date de début.';

  @override
  String get errBudgetExists =>
      'Un budget actif existe déjà pour cette catégorie et cette période.';

  @override
  String get errGoalNameLength => 'Le nom doit contenir de 1 à 40 caractères.';

  @override
  String get errDeadlineBeforeStart =>
      'L\'échéance doit être après la date de début.';

  @override
  String get errLinkedAccountRequired => 'Choisissez le compte d\'épargne lié.';

  @override
  String get errTransferCurrencyMismatch =>
      'Les deux comptes doivent avoir la même devise.';

  @override
  String get errIntervalInvalid => 'L\'intervalle doit être au moins 1.';

  @override
  String get errMonthDayInvalid => 'Jour du mois invalide.';

  @override
  String get errEndBeforeStart => 'La fin doit suivre le début.';

  @override
  String get errRemindInvalid => 'Rappel entre 0 et 7 jours.';

  @override
  String get errRuleEnded => 'Cette récurrence est terminée.';

  @override
  String get errPersonNameLength =>
      'Le nom doit contenir de 1 à 40 caractères.';

  @override
  String get errDueBeforeStart => 'L\'échéance doit suivre la date de début.';

  @override
  String get errStorage =>
      'Erreur d\'enregistrement. Vos données n\'ont pas été modifiées.';

  @override
  String get errAttachmentFailed => 'Impossible d\'ajouter cette image.';

  @override
  String get errBackupInvalid =>
      'Ce fichier n\'est pas une sauvegarde Floos valide.';

  @override
  String get errBackupChecksum =>
      'La sauvegarde est corrompue (somme de contrôle invalide).';

  @override
  String get errBackupNewerSchema =>
      'Cette sauvegarde vient d\'une version plus récente de l\'application. Mettez à jour Floos.';

  @override
  String get errBackupWrongPassword => 'Mot de passe incorrect.';

  @override
  String get errBackupFailed => 'La sauvegarde a échoué.';

  @override
  String get errCsvEmpty => 'Le fichier est vide.';

  @override
  String get errCsvMapping => 'Associez au moins les colonnes date et montant.';

  @override
  String get errPinMismatch => 'Les codes ne correspondent pas.';

  @override
  String get errPinInvalid => 'Le code doit contenir 4 à 6 chiffres.';

  @override
  String get errPermissionDenied => 'Autorisation refusée.';

  @override
  String errBaseCurrencyRates(String currency, String codes) {
    return 'Ajoutez d\'abord un taux vers $currency pour : $codes.';
  }

  @override
  String get a11yMinus => 'moins';

  @override
  String get a11yHiddenAmount => 'Montant masqué';

  @override
  String a11yProgress(int percent) {
    return '$percent pour cent';
  }

  @override
  String get a11yNotifications => 'Notifications';

  @override
  String get a11yUnread => 'Notifications non lues';

  @override
  String get a11yToggleAmounts => 'Afficher ou masquer les montants';

  @override
  String get a11yProfile => 'Profil';

  @override
  String get a11yPinned => 'Épinglées en premier';

  @override
  String get a11yHistory => 'Récemment modifiées';

  @override
  String get a11yBarChart => 'Graphique en barres';

  @override
  String get a11yDonutChart => 'Graphique en anneau';

  @override
  String a11yChartSegment(String name, int percent, String amount) {
    return '$name, $percent pour cent, $amount';
  }

  @override
  String get a11yMoreActions => 'Plus d\'actions';

  @override
  String get a11yPrevious => 'Période précédente';

  @override
  String get a11yNext => 'Période suivante';

  @override
  String get a11yBackspace => 'Effacer';

  @override
  String get a11yDragToReorder => 'Faire glisser pour réordonner';

  @override
  String get a11ySwipeHint => 'Glisser pour supprimer ou modifier';

  @override
  String get a11ySelected => 'Sélectionné';

  @override
  String get a11yViewAsTable => 'Voir en tableau';

  @override
  String get a11yViewAsChart => 'Voir en graphique';

  @override
  String a11yChartSummary(String title, String total, int count) {
    return '$title : total $total, $count éléments';
  }

  @override
  String get vsLastPeriod => 'vs période préc.';

  @override
  String get vsLastMonth => 'vs mois dernier';

  @override
  String get badgeScheduled => 'Planifiée';

  @override
  String get badgePending => 'À confirmer';

  @override
  String get insightSee => 'Voir';

  @override
  String get channelBudget => 'Alertes de budget';

  @override
  String get channelBills => 'Rappels de factures';

  @override
  String get channelPending => 'Récurrences à confirmer';

  @override
  String get channelGoals => 'Objectifs';

  @override
  String get channelDebts => 'Dettes';

  @override
  String get channelDaily => 'Rappel quotidien';

  @override
  String get channelBackup => 'Sauvegarde';

  @override
  String notifBudgetTitle(String name) {
    return 'Budget $name';
  }

  @override
  String notifBudgetBody(String name, int percent, String limit) {
    return '$name : $percent % de $limit utilisés';
  }

  @override
  String notifBudgetBodyHidden(String name, int percent) {
    return '$name : $percent % du budget utilisé';
  }

  @override
  String get notifBillTitle => 'Facture à venir';

  @override
  String notifBillBody(String name, String amount, String date) {
    return '$name $amount à payer le $date';
  }

  @override
  String notifBillBodyHidden(String name, String date) {
    return '$name à payer le $date';
  }

  @override
  String get notifPendingTitle => 'À confirmer';

  @override
  String notifPendingBody(String name) {
    return '$name est prêt à être confirmé';
  }

  @override
  String get notifSummaryTitle => 'Récurrences ajoutées';

  @override
  String notifSummaryBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opérations récurrentes ont été ajoutées',
      one: '1 opération récurrente a été ajoutée',
    );
    return '$_temp0';
  }

  @override
  String get notifGoalTitle => 'Objectif';

  @override
  String notifGoalBody(int percent, String name) {
    return '🎉 $percent % de $name';
  }

  @override
  String notifGoalDoneBody(String name) {
    return '🎉 Objectif atteint : $name';
  }

  @override
  String get notifDebtTitle => 'Échéance de dette';

  @override
  String notifDebtOweTomorrow(String amount, String name) {
    return 'Vous devez $amount à $name demain';
  }

  @override
  String notifDebtOweToday(String amount, String name) {
    return 'Vous devez $amount à $name aujourd\'hui';
  }

  @override
  String notifDebtOwedTomorrow(String amount, String name) {
    return '$name vous doit $amount demain';
  }

  @override
  String notifDebtOwedToday(String amount, String name) {
    return '$name vous doit $amount aujourd\'hui';
  }

  @override
  String notifDebtHiddenTomorrow(String name) {
    return 'Échéance avec $name demain';
  }

  @override
  String notifDebtHiddenToday(String name) {
    return 'Échéance avec $name aujourd\'hui';
  }

  @override
  String get notifDailyTitle => 'Floos';

  @override
  String get notifDailyBody => 'Saisir les dépenses du jour ?';

  @override
  String get notifBackupTitle => 'Sauvegarde';

  @override
  String get notifBackupBody => 'Sauvegardez vos données';

  @override
  String get notifTestTitle => 'Notification de test';

  @override
  String get notifTestBody => 'Les notifications fonctionnent.';

  @override
  String get widgetSpent => 'Dépensé ce mois';

  @override
  String get widgetIncome => 'Revenus';

  @override
  String get widgetBalance => 'Solde';

  @override
  String get budgetOverall => 'Global';

  @override
  String get txNew => 'Nouvelle transaction';

  @override
  String get txEdit => 'Modifier la transaction';

  @override
  String get txSaveAndAdd => 'Enregistrer et ajouter';

  @override
  String get txAllCategories => 'Toutes';

  @override
  String get txNewCategory => 'Nouvelle';

  @override
  String get txChooseCategory => 'Choisir une catégorie';

  @override
  String get txChooseAccount => 'Choisir un compte';

  @override
  String get txFromAccount => 'Depuis';

  @override
  String get txToAccount => 'Vers';

  @override
  String get txToAmount => 'Montant reçu';

  @override
  String txRateLine(String from, String rate, String to) {
    return 'Taux : 1 $from = $rate $to';
  }

  @override
  String txRateMissingHint(String from, String to) {
    return 'Aucun taux $from → $to : saisissez le taux du jour.';
  }

  @override
  String txRateField(String from, String to) {
    return '1 $from = ? $to';
  }

  @override
  String get txPayeeHint => 'Ex. Marjane, Uber…';

  @override
  String get txNoteHint => 'Ajouter une note';

  @override
  String get txTags => 'Étiquettes';

  @override
  String get txAddTag => 'Ajouter une étiquette';

  @override
  String get txNewTagHint => 'Nouvelle étiquette';

  @override
  String get txAttachments => 'Justificatifs';

  @override
  String get txAddPhoto => 'Ajouter une photo';

  @override
  String get txCamera => 'Appareil photo';

  @override
  String get txGallery => 'Galerie';

  @override
  String get txRepeat => 'Répéter';

  @override
  String get txRepeatNone => 'Jamais';

  @override
  String get txAdvanced => 'Options avancées';

  @override
  String get txLinkDebt => 'Lier à une dette';

  @override
  String get txContributeGoal => 'Contribuer à un objectif';

  @override
  String get txExcludeReports => 'Exclure des rapports';

  @override
  String get txExcludeReportsHint => 'Ex. remboursements';

  @override
  String get txPinned => 'Épinglée';

  @override
  String get txAddTime => 'Ajouter une heure';

  @override
  String get txCalendar => 'Calendrier';

  @override
  String get txDeleteConfirm => 'Supprimer cette transaction ?';

  @override
  String get txRecurringScopeTitle => 'Transaction récurrente';

  @override
  String get txRecurringScopeMessage => 'Appliquer les modifications à :';

  @override
  String get txScopeOnlyThis => 'Celle-ci uniquement';

  @override
  String get txScopeFuture => 'Celle-ci et les suivantes';

  @override
  String get txDuplicated => 'Copie créée — vérifiez puis enregistrez';

  @override
  String txAmountPreview(String amount) {
    return '= $amount';
  }

  @override
  String get txSearchCategories => 'Rechercher une catégorie';

  @override
  String get txCreateCategoryTitle => 'Nouvelle catégorie';

  @override
  String get txParentCategory => 'Catégorie parente';

  @override
  String get txNoParent => 'Aucune (principale)';

  @override
  String get txKeypadHint => 'Saisissez un montant';

  @override
  String get txNoAccount => 'Créez d\'abord un compte.';

  @override
  String get txCreateAccount => 'Créer un compte';

  @override
  String get freqDaily => 'Quotidienne';

  @override
  String get freqWeekly => 'Hebdomadaire';

  @override
  String get freqMonthly => 'Mensuelle';

  @override
  String get freqYearly => 'Annuelle';

  @override
  String get recEvery => 'Tous les';

  @override
  String get recInterval => 'Intervalle';

  @override
  String recEveryDay(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Tous les $n jours',
      one: 'Chaque jour',
    );
    return '$_temp0';
  }

  @override
  String recEveryWeek(int n, String weekday) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Toutes les $n semaines le $weekday',
      one: 'Chaque semaine le $weekday',
    );
    return '$_temp0';
  }

  @override
  String recEveryMonth(int n, int day) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Tous les $n mois le $day',
      one: 'Chaque mois le $day',
    );
    return '$_temp0';
  }

  @override
  String recEveryYear(int n, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Tous les $n ans le $date',
      one: 'Chaque année le $date',
    );
    return '$_temp0';
  }

  @override
  String get recWeekday => 'Jour de la semaine';

  @override
  String get recMonthDay => 'Jour du mois';

  @override
  String get recMonthDayHint =>
      'Les mois plus courts utilisent leur dernier jour.';

  @override
  String get recEnds => 'Fin';

  @override
  String get recEndsNever => 'Jamais';

  @override
  String get recEndsOn => 'Le';

  @override
  String get recEndsAfter => 'Après';

  @override
  String recOccurrences(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n fois',
      one: '1 fois',
    );
    return '$_temp0';
  }

  @override
  String get recMode => 'Création';

  @override
  String get recModeAuto => 'Automatique';

  @override
  String get recModeConfirm => 'À confirmer';

  @override
  String get recModeAutoHint => 'Ajoutée automatiquement à la date prévue.';

  @override
  String get recModeConfirmHint => 'Ajoutée en attente de votre confirmation.';

  @override
  String get recReminder => 'Rappel de facture';

  @override
  String get recReminderOff => 'Aucun';

  @override
  String recReminderDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n jours avant',
      one: '1 jour avant',
      zero: 'Le jour même',
    );
    return '$_temp0';
  }

  @override
  String get recReminderTime => 'Heure du rappel';

  @override
  String get recStart => 'Début';

  @override
  String get recName => 'Nom (facultatif)';

  @override
  String get recTitle => 'Répétition';

  @override
  String get recRemove => 'Ne pas répéter';

  @override
  String get homeCurrentBalance => 'Solde actuel';

  @override
  String homeDeltaVs(String amount) {
    return '$amount vs période préc.';
  }

  @override
  String get homeYourMoney => 'Votre argent';

  @override
  String get homeYourMoneyInfo =>
      'Revenus et dépenses de la période sélectionnée, convertis dans votre devise principale.';

  @override
  String get homeIncome => 'Revenus';

  @override
  String get homeExpenses => 'Dépenses';

  @override
  String get homeTransactions => 'Transactions';

  @override
  String get homeForPeriod => 'Pour la période';

  @override
  String get homeNeedsConfirmation => 'À confirmer';

  @override
  String get homeConfirm => 'Confirmer';

  @override
  String get homeSkip => 'Ignorer';

  @override
  String get homeEditRule => 'Modifier la règle';

  @override
  String get homeBudgets => 'Budgets';

  @override
  String get homeEmptyTitle => 'Aucune transaction pour le moment';

  @override
  String get homeEmptyAction => 'Ajouter votre première dépense';

  @override
  String get homeEmptyPeriod => 'Aucune transaction sur cette période.';

  @override
  String get homeCoachMark =>
      'Touchez + pour ajouter une dépense en quelques secondes.';

  @override
  String get homeConfirmAmount => 'Montant confirmé';

  @override
  String homeMissingRates(String codes) {
    return 'Taux manquant pour : $codes';
  }

  @override
  String get homeInfoIncomeExpense =>
      'Les virements ne sont jamais comptés comme revenus ou dépenses.';

  @override
  String insightBudgetOver(String name, String amount) {
    return 'Vous avez dépassé votre budget $name de $amount.';
  }

  @override
  String insightBudgetWarning(String name, int percent, String perDay) {
    return '$name est à $percent % de sa limite, $perDay/jour restants.';
  }

  @override
  String insightGoalBehind(String name, String amount) {
    return '$name nécessite $amount/mois pour rester dans les temps.';
  }

  @override
  String insightBill(String name, String amount, String when) {
    return '$name ($amount) $when.';
  }

  @override
  String insightBillWhen(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'à payer dans $days jours',
      one: 'à payer demain',
      zero: 'à payer aujourd\'hui',
    );
    return '$_temp0';
  }

  @override
  String insightCategoryUp(String name, int percent) {
    return '$name est en hausse de $percent % par rapport au mois dernier.';
  }

  @override
  String insightUnusual(String name, String amount) {
    return 'Dépense inhabituelle en $name : $amount.';
  }

  @override
  String insightSavings(int percent) {
    return 'Vous avez épargné $percent % de vos revenus jusqu\'ici 👏';
  }

  @override
  String get insightNoLogs => 'N\'oubliez pas de saisir vos dépenses.';

  @override
  String get insightBackup =>
      'Aucune sauvegarde depuis 30 jours : sauvegardez vos données.';

  @override
  String get insightDismiss => 'Masquer pour cette période';

  @override
  String get insightDismissed => 'Conseil masqué';

  @override
  String get insightsTitle => 'Conseils';

  @override
  String get insightsEmpty =>
      'Aucun conseil pour l\'instant. Continuez à saisir vos opérations.';

  @override
  String get periodWeek => 'Semaine';

  @override
  String get periodMonth => 'Mois';

  @override
  String get periodYear => 'Année';

  @override
  String get periodCustom => 'Personnalisée';

  @override
  String get periodPickTitle => 'Choisir la période';

  @override
  String get periodThis => 'Cette période';

  @override
  String get periodLast => 'Période précédente';

  @override
  String get periodLast3Months => '3 derniers mois';

  @override
  String get periodThisYear => 'Cette année';

  @override
  String get periodAllTime => 'Tout';

  @override
  String get periodCustomRange => 'Plage personnalisée';

  @override
  String get txListTitle => 'Transactions';

  @override
  String get txSearchHint => 'Rechercher (bénéficiaire, note, =45, >100)';

  @override
  String get filterTitle => 'Filtres';

  @override
  String get filterDateRange => 'Période';

  @override
  String get filterTypes => 'Types';

  @override
  String get filterAccounts => 'Comptes';

  @override
  String get filterCategories => 'Catégories';

  @override
  String get filterTags => 'Étiquettes';

  @override
  String get filterAmountMin => 'Montant min.';

  @override
  String get filterAmountMax => 'Montant max.';

  @override
  String get filterHasAttachment => 'Avec justificatif';

  @override
  String get filterPendingOnly => 'À confirmer uniquement';

  @override
  String get filterClearAll => 'Tout effacer';

  @override
  String filterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filtres',
      one: '1 filtre',
    );
    return '$_temp0';
  }

  @override
  String get footerIn => 'Entrées';

  @override
  String get footerOut => 'Sorties';

  @override
  String get footerNet => 'Net';

  @override
  String get bulkDelete => 'Supprimer';

  @override
  String get bulkCategory => 'Changer la catégorie';

  @override
  String get bulkAccount => 'Changer le compte';

  @override
  String get bulkTag => 'Ajouter une étiquette';

  @override
  String get bulkExport => 'Exporter en CSV';

  @override
  String get bulkDone => 'Modifications appliquées';

  @override
  String get searchNoResults =>
      'Aucun résultat. Essayez d\'autres mots ou retirez des filtres.';

  @override
  String get csvSeparator => 'Séparateur';

  @override
  String get csvComma => 'Virgule (,)';

  @override
  String get csvSemicolon => 'Point-virgule (;)';

  @override
  String get csvExported => 'Fichier CSV prêt';

  @override
  String get chooseTag => 'Choisir une étiquette';

  @override
  String get obWelcomeTitle => 'Bienvenue sur Floos';

  @override
  String get obWelcomeBody =>
      'Suivez vos dépenses, budgets et objectifs. Tout reste sur votre téléphone, hors ligne.';

  @override
  String get obStart => 'Commencer';

  @override
  String get obCurrencyTitle => 'Votre devise';

  @override
  String get obCurrencyBody =>
      'Choisissez la devise principale et le jour de début de mois.';

  @override
  String get obMonthStart => 'Le mois commence le';

  @override
  String get obAccountTitle => 'Votre premier compte';

  @override
  String get obAccountBody =>
      'Ajoutez un compte (espèces, banque…) avec son solde actuel.';

  @override
  String get obAccountName => 'Nom du compte';

  @override
  String get obAccountDefault => 'Espèces';

  @override
  String get obInitialBalance => 'Solde actuel';

  @override
  String get obSecurityTitle => 'Sécurisez Floos';

  @override
  String get obSecurityBody =>
      'Protégez l\'accès avec un code PIN. Vous pourrez le changer plus tard.';

  @override
  String get obSetPin => 'Définir un code PIN';

  @override
  String get obSkipPin => 'Plus tard';

  @override
  String get obFinish => 'Terminer';

  @override
  String obStep(int n, int total) {
    return 'Étape $n sur $total';
  }

  @override
  String get pinEnter => 'Saisissez votre code PIN';

  @override
  String get pinCreate => 'Créez un code PIN (4 à 6 chiffres)';

  @override
  String get pinConfirm => 'Confirmez le code PIN';

  @override
  String get pinCurrent => 'Code PIN actuel';

  @override
  String get pinWrong => 'Code PIN incorrect';

  @override
  String pinLocked(int s) {
    return 'Trop d\'essais. Réessayez dans $s s.';
  }

  @override
  String get pinForgot => 'Code PIN oublié ?';

  @override
  String get pinUseBiometrics => 'Utiliser la biométrie';

  @override
  String get pinBiometricReason => 'Déverrouiller Floos';

  @override
  String get pinForgotTitle => 'Réinitialiser l\'accès';

  @override
  String get pinForgotBody =>
      'Vous pouvez vous authentifier par biométrie, ou effacer toutes les données de l\'application.';

  @override
  String get pinWipeAll => 'Effacer toutes les données';

  @override
  String get pinWipeConfirm1 =>
      'Toutes vos données seront définitivement supprimées. Continuer ?';

  @override
  String get pinWipeConfirm2 =>
      'Dernière confirmation : cette action est irréversible.';

  @override
  String get pinChanged => 'Code PIN modifié';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsProfile => 'Profil';

  @override
  String get settingsDisplayName => 'Votre prénom';

  @override
  String get settingsGeneral => 'Général';

  @override
  String get settingsBaseCurrency => 'Devise principale';

  @override
  String get settingsMonthStart => 'Début du mois';

  @override
  String get settingsWeekStart => 'Début de la semaine';

  @override
  String get weekMonday => 'Lundi';

  @override
  String get weekSaturday => 'Samedi';

  @override
  String get weekSunday => 'Dimanche';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get settingsHideAmounts => 'Masquer les montants au démarrage';

  @override
  String get settingsManage => 'Gérer';

  @override
  String get settingsRates => 'Taux de change';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsSecurity => 'Sécurité';

  @override
  String get settingsBackup => 'Sauvegarde et données';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get securityLock => 'Verrouillage par code PIN';

  @override
  String get securityChangePin => 'Changer le code PIN';

  @override
  String get securityBiometrics => 'Déverrouillage biométrique';

  @override
  String get securityTimeout => 'Verrouiller après';

  @override
  String get timeoutImmediate => 'Immédiatement';

  @override
  String get timeout30 => '30 secondes';

  @override
  String get timeout60 => '1 minute';

  @override
  String get timeout300 => '5 minutes';

  @override
  String get securitySecureFlag =>
      'Masquer l\'aperçu dans les applications récentes';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutPrivacy => 'Confidentialité';

  @override
  String get aboutPrivacyBody =>
      'Floos fonctionne entièrement hors ligne. Aucune donnée ne quitte votre appareil, sauf sauvegardes que vous partagez vous-même.';

  @override
  String get aboutLicenses => 'Licences open source';

  @override
  String get aboutDiagnostics => 'Diagnostics';

  @override
  String get diagEmpty => 'Aucune erreur enregistrée';

  @override
  String get diagExport => 'Exporter le journal';

  @override
  String get diagClear => 'Effacer le journal';

  @override
  String baseCurrencyBlocked(String codes) {
    return 'Taux manquants pour $codes. Ajoutez-les avant de changer de devise.';
  }

  @override
  String get errorLoading => 'Une erreur est survenue';

  @override
  String get splashLoading => 'Chargement…';

  @override
  String get accountNew => 'Nouveau compte';

  @override
  String get accountEdit => 'Modifier le compte';

  @override
  String get accountTypeCash => 'Espèces';

  @override
  String get accountTypeBank => 'Banque';

  @override
  String get accountTypeCard => 'Carte';

  @override
  String get accountTypeSavings => 'Épargne';

  @override
  String get accountTypeEwallet => 'Portefeuille électronique';

  @override
  String get accountTypeOther => 'Autre';

  @override
  String get accountInitialBalance => 'Solde initial';

  @override
  String get accountIncludeTotal => 'Inclure dans le total';

  @override
  String get accountArchivedSection => 'Archivés';

  @override
  String get accountReconcile => 'Rapprocher le solde';

  @override
  String get accountReconcileBody =>
      'Saisissez le solde réel. Un ajustement sera créé pour la différence.';

  @override
  String get accountRealBalance => 'Solde réel';

  @override
  String get accountReconciled => 'Solde rapproché';

  @override
  String get accountBalanceHistory => 'Solde sur 6 mois';

  @override
  String get accountDeleteTitle => 'Supprimer le compte';

  @override
  String accountDeleteBody(int n) {
    return 'Ce compte contient $n opérations. Que faire ?';
  }

  @override
  String get accountMoveTo => 'Déplacer les opérations vers…';

  @override
  String get accountDeleteAll => 'Supprimer aussi les opérations';

  @override
  String get accountTotalBalance => 'Solde total';

  @override
  String get accountsEmpty => 'Aucun compte';

  @override
  String get accountTransactions => 'Opérations';

  @override
  String get reorderHint => 'Maintenez et faites glisser pour réordonner';

  @override
  String get categoryNew => 'Nouvelle catégorie';

  @override
  String get categoryEdit => 'Modifier la catégorie';

  @override
  String get categoryParent => 'Catégorie parente';

  @override
  String get categoryMerge => 'Fusionner';

  @override
  String get categoryMergeInto => 'Fusionner dans…';

  @override
  String get categoryDeleteTitle => 'Supprimer la catégorie';

  @override
  String categoryDeleteReassign(int n) {
    return '$n opérations utilisent cette catégorie. Choisissez une catégorie de remplacement.';
  }

  @override
  String get categoryPickReplacement => 'Choisir un remplacement';

  @override
  String categoryArchivedBudgets(int n) {
    return '$n budget(s) archivé(s)';
  }

  @override
  String get categoryEmpty => 'Aucune catégorie';

  @override
  String get tagsEmpty => 'Aucune étiquette';

  @override
  String get tagNew => 'Nouvelle étiquette';

  @override
  String tagUsage(int n) {
    return '$n utilisations';
  }

  @override
  String get ratesTitle => 'Taux de change';

  @override
  String get ratesEmpty =>
      'Aucun taux. Ajoutez-en un pour convertir les devises.';

  @override
  String get rateAdd => 'Ajouter un taux';

  @override
  String get rateValue => 'Taux';

  @override
  String get rateFrom => 'De';

  @override
  String get rateTo => 'Vers';

  @override
  String get rateHistory => 'Historique';

  @override
  String rateLine(String from, String rate, String to) {
    return '1 $from = $rate $to';
  }

  @override
  String get kindExpense => 'Dépenses';

  @override
  String get kindIncome => 'Revenus';

  @override
  String get reportTitle => 'Rapport';

  @override
  String get reportExpensesTotal => 'Total des dépenses';

  @override
  String get reportIncomeTotal => 'Total des revenus';

  @override
  String get reportNoData => 'Aucune donnée pour cette période';

  @override
  String get reportUncategorized => 'Sans catégorie';

  @override
  String get reportCashFlow => 'Flux de trésorerie';

  @override
  String get reportCashFlowNet => 'Net';

  @override
  String get reportStats => 'Statistiques';

  @override
  String get reportSavingsRate => 'Taux d\'épargne';

  @override
  String get reportAvgPerDay => 'Moyenne par jour';

  @override
  String get reportTxCount => 'Opérations';

  @override
  String get reportBiggest => 'Plus grosse dépense';

  @override
  String get reportMostFrequent => 'Catégorie la plus fréquente';

  @override
  String get reportTopPayee => 'Bénéficiaire principal';

  @override
  String get reportByTag => 'Par étiquette';

  @override
  String get reportByAccount => 'Par compte';

  @override
  String get reportExportCsv => 'Exporter en CSV';

  @override
  String get reportExportPdf => 'Exporter en PDF';

  @override
  String get reportShowDonut => 'Anneau';

  @override
  String get reportShowBars => 'Barres';

  @override
  String get categoryDetailSubcategories => 'Sous-catégories';

  @override
  String get categoryDetailTrend => 'Évolution sur 6 périodes';

  @override
  String get categoryDetailTx => 'Opérations de la période';

  @override
  String get insightsAll => 'Toutes les alertes';

  @override
  String get planTitle => 'Mon plan';

  @override
  String get planAddTitle => 'Ajouter';

  @override
  String get planNewBudget => 'Nouveau budget';

  @override
  String get planNewGoal => 'Nouvel objectif';

  @override
  String get planNewRecurring => 'Nouvelle opération récurrente';

  @override
  String get planNewDebt => 'Nouvelle dette ou prêt';

  @override
  String get planGoals => 'Objectifs';

  @override
  String get planBudgets => 'Budgets';

  @override
  String get planRecurring => 'Récurrentes et factures';

  @override
  String get planDebts => 'Dettes et prêts';

  @override
  String get budgetsEmpty =>
      'Aucun budget. Fixez une limite pour mieux maîtriser vos dépenses.';

  @override
  String get budgetEdit => 'Modifier le budget';

  @override
  String get budgetName => 'Nom (facultatif)';

  @override
  String get budgetAllCategories => 'Toutes les dépenses';

  @override
  String get budgetCategory => 'Catégorie';

  @override
  String get budgetIncludeSub => 'Inclure les sous-catégories';

  @override
  String get budgetPeriodLabel => 'Période';

  @override
  String get budgetRollover => 'Reporter le reste';

  @override
  String get budgetThresholds => 'Alertes à 80 % et 100 %';

  @override
  String get budgetSpent => 'Dépensé';

  @override
  String get budgetLeft => 'Reste';

  @override
  String get budgetOverBy => 'Dépassement';

  @override
  String budgetPerDay(String amount) {
    return '$amount / jour';
  }

  @override
  String budgetProjected(String amount) {
    return 'Projection : $amount';
  }

  @override
  String budgetDaysLeft(int n) {
    return '$n jours restants';
  }

  @override
  String get budgetHistory => 'Historique';

  @override
  String budgetRolloverIn(String amount) {
    return 'Report : $amount';
  }

  @override
  String get budgetTransactions => 'Opérations du budget';

  @override
  String get budgetDeleteConfirm => 'Supprimer ce budget ?';

  @override
  String get goalsEmpty =>
      'Aucun objectif. Créez-en un pour épargner avec un but.';

  @override
  String get goalNew => 'Nouvel objectif';

  @override
  String get goalEdit => 'Modifier l\'objectif';

  @override
  String get goalTarget => 'Montant cible';

  @override
  String get goalDeadline => 'Échéance';

  @override
  String get goalStart => 'Début';

  @override
  String get goalTracking => 'Suivi';

  @override
  String get goalTrackManual => 'Manuel';

  @override
  String get goalTrackLinked => 'Lié à un compte';

  @override
  String get goalLinkedAccount => 'Compte lié';

  @override
  String get goalSaved => 'Épargné';

  @override
  String get goalRemaining => 'Reste';

  @override
  String get goalContribute => 'Verser';

  @override
  String get goalWithdraw => 'Retirer';

  @override
  String get goalAmountField => 'Montant';

  @override
  String get goalFromAccount => 'Depuis le compte';

  @override
  String get goalOnTrack => 'Dans les temps';

  @override
  String goalBehind(int n) {
    return 'En retard de $n %';
  }

  @override
  String get goalCompletedLabel => 'Atteint';

  @override
  String get goalNoDeadline => 'Sans échéance';

  @override
  String goalNeeded(String amount) {
    return '$amount par mois nécessaires';
  }

  @override
  String goalEstimated(String date) {
    return 'Estimation : $date';
  }

  @override
  String get goalCelebrate => 'Objectif atteint ! Bravo 🎉';

  @override
  String get goalMarkComplete => 'Marquer comme atteint';

  @override
  String get goalReactivate => 'Réactiver';

  @override
  String get goalContributions => 'Versements';

  @override
  String get goalDeleteConfirm => 'Supprimer cet objectif et ses versements ?';

  @override
  String get recurringEmpty =>
      'Aucune opération récurrente. Ajoutez vos factures et abonnements.';

  @override
  String get recurringNew => 'Nouvelle récurrence';

  @override
  String get recurringEdit => 'Modifier la récurrence';

  @override
  String recurringNext(String date) {
    return 'Prochaine : $date';
  }

  @override
  String get recurringPaused => 'En pause';

  @override
  String get recurringSkipNext => 'Passer la prochaine';

  @override
  String get recurringDeleteTitle => 'Supprimer la récurrence';

  @override
  String get recurringKeepPast => 'Garder les opérations passées';

  @override
  String get recurringDeletePast => 'Supprimer aussi les opérations passées';

  @override
  String get recurringActive => 'Active';

  @override
  String get debtsEmpty => 'Aucune dette ni prêt.';

  @override
  String get debtNew => 'Nouvelle dette';

  @override
  String get debtEdit => 'Modifier la dette';

  @override
  String get debtIOwe => 'Je dois';

  @override
  String get debtOwedToMe => 'On me doit';

  @override
  String get debtPerson => 'Personne';

  @override
  String get debtAmountField => 'Montant';

  @override
  String get debtDue => 'Échéance';

  @override
  String get debtPaid => 'Payé';

  @override
  String get debtRemaining => 'Reste';

  @override
  String get debtAddPayment => 'Ajouter un paiement';

  @override
  String get debtSettle => 'Marquer comme soldé';

  @override
  String get debtReopen => 'Rouvrir';

  @override
  String get debtOverdue => 'En retard';

  @override
  String get debtSettled => 'Soldé';

  @override
  String get debtRecordOnly => 'Enregistrer sans toucher aux comptes';

  @override
  String get debtPayments => 'Paiements';

  @override
  String get debtStart => 'Date';

  @override
  String get debtDeleteConfirm => 'Supprimer cette dette ?';

  @override
  String get debtOpenTab => 'En cours';

  @override
  String get debtSettledTab => 'Soldées';

  @override
  String get notifCenterTitle => 'Notifications';

  @override
  String get notifCenterEmpty => 'Aucune notification';

  @override
  String get notifMarkAllRead => 'Tout marquer comme lu';

  @override
  String get notifClear => 'Effacer l\'historique';

  @override
  String get notifSettingsMaster => 'Activer les notifications';

  @override
  String get notifSettingsBudget => 'Alertes de budget';

  @override
  String get notifSettingsBills => 'Factures et récurrentes';

  @override
  String get notifSettingsGoals => 'Objectifs';

  @override
  String get notifSettingsDebts => 'Dettes et prêts';

  @override
  String get notifSettingsDaily => 'Rappel quotidien';

  @override
  String get notifSettingsDailyTime => 'Heure du rappel';

  @override
  String get notifSettingsBackup => 'Rappels de sauvegarde';

  @override
  String get notifPermissionDenied =>
      'Les notifications sont désactivées pour Floos dans les réglages du système.';

  @override
  String get notifRequestPermission => 'Autoriser les notifications';

  @override
  String get notifSendTest => 'Envoyer une notification test';

  @override
  String get backupNow => 'Sauvegarder maintenant';

  @override
  String get backupPassword => 'Mot de passe (facultatif)';

  @override
  String get backupPasswordHint =>
      'Laissez vide pour une sauvegarde non chiffrée';

  @override
  String get backupCreated => 'Sauvegarde créée';

  @override
  String get backupShare => 'Partager la sauvegarde';

  @override
  String get backupAuto => 'Sauvegarde automatique';

  @override
  String get backupAutoOff => 'Désactivée';

  @override
  String get backupAutoDaily => 'Quotidienne';

  @override
  String get backupAutoWeekly => 'Hebdomadaire';

  @override
  String get backupAutoMonthly => 'Mensuelle';

  @override
  String get backupKeep => 'Sauvegardes conservées';

  @override
  String backupLast(String date) {
    return 'Dernière sauvegarde : $date';
  }

  @override
  String get backupNever => 'Aucune sauvegarde pour l\'instant';

  @override
  String get backupRestore => 'Restaurer une sauvegarde';

  @override
  String backupRestorePreview(String date, int n) {
    return 'Sauvegarde du $date · $n opérations';
  }

  @override
  String get backupRestoreWarning =>
      'La restauration remplace toutes les données actuelles. Une sauvegarde de sécurité sera créée avant.';

  @override
  String get backupRestoreDone => 'Restauration terminée';

  @override
  String get backupEncrypted =>
      'Cette sauvegarde est chiffrée. Saisissez le mot de passe.';

  @override
  String get dataExportCsv => 'Exporter les opérations (CSV)';

  @override
  String get dataImportCsv => 'Importer un fichier CSV';

  @override
  String get dataDeleteAll => 'Supprimer toutes les données';

  @override
  String get dataDeleteAllBody =>
      'Toutes vos données seront définitivement supprimées. Tapez SUPPRIMER pour confirmer.';

  @override
  String get dataDeleteWord => 'SUPPRIMER';

  @override
  String get dataDeleted => 'Données supprimées';

  @override
  String get csvStepFile => 'Fichier';

  @override
  String get csvStepMapping => 'Colonnes';

  @override
  String get csvStepReview => 'Vérification';

  @override
  String get csvStepImport => 'Import';

  @override
  String get csvPickFile => 'Choisir un fichier CSV';

  @override
  String get csvDateFormat => 'Format de date';

  @override
  String get csvDecimalComma => 'Virgule décimale';

  @override
  String get csvNotMapped => '— Non importé —';

  @override
  String csvRows(int n, int e, int d) {
    return '$n lignes valides, $e erreurs, $d doublons';
  }

  @override
  String get csvImportDuplicates => 'Importer aussi les doublons';

  @override
  String get csvUnknownAccounts => 'Comptes inconnus (créés automatiquement)';

  @override
  String get csvUnknownCategories =>
      'Catégories inconnues (créées automatiquement)';

  @override
  String get csvDoImport => 'Importer';

  @override
  String csvReport(int n, int s, int e) {
    return '$n importées, $s ignorées, $e erreurs';
  }

  @override
  String get csvFallbackAccount => 'Compte par défaut';

  @override
  String get csvFieldDate => 'Date';

  @override
  String get csvFieldTime => 'Heure';

  @override
  String get csvFieldType => 'Type';

  @override
  String get csvFieldAmount => 'Montant';

  @override
  String get csvFieldCurrency => 'Devise';

  @override
  String get csvFieldAccount => 'Compte';

  @override
  String get csvFieldToAccount => 'Vers le compte';

  @override
  String get csvFieldToAmount => 'Montant reçu';

  @override
  String get csvFieldCategory => 'Catégorie';

  @override
  String get csvFieldParentCategory => 'Catégorie parente';

  @override
  String get csvFieldPayee => 'Bénéficiaire';

  @override
  String get csvFieldNote => 'Note';

  @override
  String get csvFieldTags => 'Étiquettes';

  @override
  String get csvFieldId => 'Identifiant';
}
