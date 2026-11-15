import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('fr')];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'Floos'**
  String get appName;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @undo.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get undo;

  /// No description provided for @done.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get done;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get skip;

  /// No description provided for @seeAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout voir'**
  String get seeAll;

  /// No description provided for @viewAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get viewAll;

  /// No description provided for @details.
  ///
  /// In fr, this message translates to:
  /// **'Détails'**
  String get details;

  /// No description provided for @add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// No description provided for @none.
  ///
  /// In fr, this message translates to:
  /// **'Aucun'**
  String get none;

  /// No description provided for @today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get yesterday;

  /// No description provided for @tomorrow.
  ///
  /// In fr, this message translates to:
  /// **'Demain'**
  String get tomorrow;

  /// No description provided for @ok.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @archive.
  ///
  /// In fr, this message translates to:
  /// **'Archiver'**
  String get archive;

  /// No description provided for @unarchive.
  ///
  /// In fr, this message translates to:
  /// **'Désarchiver'**
  String get unarchive;

  /// No description provided for @duplicate.
  ///
  /// In fr, this message translates to:
  /// **'Dupliquer'**
  String get duplicate;

  /// No description provided for @apply.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get apply;

  /// No description provided for @reset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get reset;

  /// No description provided for @clear.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get clear;

  /// No description provided for @optional.
  ///
  /// In fr, this message translates to:
  /// **'Facultatif'**
  String get optional;

  /// No description provided for @more.
  ///
  /// In fr, this message translates to:
  /// **'Plus'**
  String get more;

  /// No description provided for @name.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get name;

  /// No description provided for @note.
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @date.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In fr, this message translates to:
  /// **'Heure'**
  String get time;

  /// No description provided for @amount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get amount;

  /// No description provided for @account.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get account;

  /// No description provided for @category.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get category;

  /// No description provided for @categories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get categories;

  /// No description provided for @accounts.
  ///
  /// In fr, this message translates to:
  /// **'Comptes'**
  String get accounts;

  /// No description provided for @tags.
  ///
  /// In fr, this message translates to:
  /// **'Étiquettes'**
  String get tags;

  /// No description provided for @payee.
  ///
  /// In fr, this message translates to:
  /// **'Bénéficiaire'**
  String get payee;

  /// No description provided for @currency.
  ///
  /// In fr, this message translates to:
  /// **'Devise'**
  String get currency;

  /// No description provided for @icon.
  ///
  /// In fr, this message translates to:
  /// **'Icône'**
  String get icon;

  /// No description provided for @color.
  ///
  /// In fr, this message translates to:
  /// **'Couleur'**
  String get color;

  /// No description provided for @type.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @total.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get loading;

  /// No description provided for @selectAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout sélectionner'**
  String get selectAll;

  /// No description provided for @change.
  ///
  /// In fr, this message translates to:
  /// **'Changer'**
  String get change;

  /// No description provided for @share.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get share;

  /// No description provided for @export.
  ///
  /// In fr, this message translates to:
  /// **'Exporter'**
  String get export;

  /// No description provided for @import.
  ///
  /// In fr, this message translates to:
  /// **'Importer'**
  String get import;

  /// No description provided for @continueLabel.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueLabel;

  /// No description provided for @settle.
  ///
  /// In fr, this message translates to:
  /// **'Solder'**
  String get settle;

  /// No description provided for @pause.
  ///
  /// In fr, this message translates to:
  /// **'Mettre en pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get resume;

  /// No description provided for @open.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir'**
  String get open;

  /// No description provided for @copy.
  ///
  /// In fr, this message translates to:
  /// **'Copier'**
  String get copy;

  /// No description provided for @noDate.
  ///
  /// In fr, this message translates to:
  /// **'Aucune date'**
  String get noDate;

  /// No description provided for @noTime.
  ///
  /// In fr, this message translates to:
  /// **'Aucune heure'**
  String get noTime;

  /// No description provided for @yes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get no;

  /// No description provided for @from.
  ///
  /// In fr, this message translates to:
  /// **'De'**
  String get from;

  /// No description provided for @to.
  ///
  /// In fr, this message translates to:
  /// **'Vers'**
  String get to;

  /// No description provided for @start.
  ///
  /// In fr, this message translates to:
  /// **'Début'**
  String get start;

  /// No description provided for @end.
  ///
  /// In fr, this message translates to:
  /// **'Fin'**
  String get end;

  /// No description provided for @custom.
  ///
  /// In fr, this message translates to:
  /// **'Personnalisé'**
  String get custom;

  /// No description provided for @navHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// No description provided for @navReport.
  ///
  /// In fr, this message translates to:
  /// **'Rapport'**
  String get navReport;

  /// No description provided for @navPlan.
  ///
  /// In fr, this message translates to:
  /// **'Plan'**
  String get navPlan;

  /// No description provided for @navSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get navSettings;

  /// No description provided for @fabAddTransaction.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une transaction'**
  String get fabAddTransaction;

  /// No description provided for @typeExpense.
  ///
  /// In fr, this message translates to:
  /// **'Dépense'**
  String get typeExpense;

  /// No description provided for @typeIncome.
  ///
  /// In fr, this message translates to:
  /// **'Revenu'**
  String get typeIncome;

  /// No description provided for @typeTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Virement'**
  String get typeTransfer;

  /// No description provided for @expenses.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses'**
  String get expenses;

  /// No description provided for @incomes.
  ///
  /// In fr, this message translates to:
  /// **'Revenus'**
  String get incomes;

  /// No description provided for @transfers.
  ///
  /// In fr, this message translates to:
  /// **'Virements'**
  String get transfers;

  /// No description provided for @saved.
  ///
  /// In fr, this message translates to:
  /// **'Enregistré'**
  String get saved;

  /// No description provided for @deleted.
  ///
  /// In fr, this message translates to:
  /// **'Supprimé'**
  String get deleted;

  /// No description provided for @deletedCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 élément supprimé} other{{count} éléments supprimés}}'**
  String deletedCount(int count);

  /// No description provided for @transactionsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune transaction} =1{1 transaction} other{{count} transactions}}'**
  String transactionsCount(int count);

  /// No description provided for @daysCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 jour} =1{1 jour} other{{count} jours}}'**
  String daysCount(int count);

  /// No description provided for @selectedCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 sélectionnée} other{{count} sélectionnées}}'**
  String selectedCount(int count);

  /// No description provided for @errorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue.'**
  String get errorGeneric;

  /// No description provided for @errorWithRetry.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les données.'**
  String get errorWithRetry;

  /// No description provided for @errAmountEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un montant.'**
  String get errAmountEmpty;

  /// No description provided for @errAmountNegative.
  ///
  /// In fr, this message translates to:
  /// **'Le montant doit être positif.'**
  String get errAmountNegative;

  /// No description provided for @errAmountInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Montant invalide.'**
  String get errAmountInvalid;

  /// No description provided for @errAmountTooManyDecimals.
  ///
  /// In fr, this message translates to:
  /// **'Maximum {digits} décimales pour cette devise.'**
  String errAmountTooManyDecimals(int digits);

  /// No description provided for @errAmountTooLarge.
  ///
  /// In fr, this message translates to:
  /// **'Montant trop élevé.'**
  String get errAmountTooLarge;

  /// No description provided for @errDivisionZero.
  ///
  /// In fr, this message translates to:
  /// **'Division par zéro impossible.'**
  String get errDivisionZero;

  /// No description provided for @errAmountZero.
  ///
  /// In fr, this message translates to:
  /// **'Le montant doit être supérieur à 0.'**
  String get errAmountZero;

  /// No description provided for @errAccountNameLength.
  ///
  /// In fr, this message translates to:
  /// **'Le nom doit contenir de 1 à 40 caractères.'**
  String get errAccountNameLength;

  /// No description provided for @errAccountTypeInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Type de compte invalide.'**
  String get errAccountTypeInvalid;

  /// No description provided for @errCurrencyInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Devise inconnue.'**
  String get errCurrencyInvalid;

  /// No description provided for @errAccountNameTaken.
  ///
  /// In fr, this message translates to:
  /// **'Un compte actif porte déjà ce nom.'**
  String get errAccountNameTaken;

  /// No description provided for @errAccountNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Compte introuvable.'**
  String get errAccountNotFound;

  /// No description provided for @errAccountHasTransactions.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte contient des transactions.'**
  String get errAccountHasTransactions;

  /// No description provided for @errCategoryNameLength.
  ///
  /// In fr, this message translates to:
  /// **'Le nom doit contenir de 1 à 30 caractères.'**
  String get errCategoryNameLength;

  /// No description provided for @errCategoryParentSelf.
  ///
  /// In fr, this message translates to:
  /// **'Une catégorie ne peut pas être son propre parent.'**
  String get errCategoryParentSelf;

  /// No description provided for @errCategoryNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie introuvable.'**
  String get errCategoryNotFound;

  /// No description provided for @errCategoryMaxDepth.
  ///
  /// In fr, this message translates to:
  /// **'Un seul niveau de sous-catégorie est autorisé.'**
  String get errCategoryMaxDepth;

  /// No description provided for @errCategoryKindMismatch.
  ///
  /// In fr, this message translates to:
  /// **'La catégorie ne correspond pas au type.'**
  String get errCategoryKindMismatch;

  /// No description provided for @errCategoryHasChildren.
  ///
  /// In fr, this message translates to:
  /// **'Cette catégorie a des sous-catégories.'**
  String get errCategoryHasChildren;

  /// No description provided for @errCategorySystem.
  ///
  /// In fr, this message translates to:
  /// **'Les catégories système ne peuvent pas être supprimées.'**
  String get errCategorySystem;

  /// No description provided for @errCategoryInUse.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie utilisée : choisissez une catégorie de remplacement.'**
  String get errCategoryInUse;

  /// No description provided for @errCategoryMergeSame.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez deux catégories différentes.'**
  String get errCategoryMergeSame;

  /// No description provided for @errTagNameLength.
  ///
  /// In fr, this message translates to:
  /// **'Le nom doit contenir de 1 à 30 caractères.'**
  String get errTagNameLength;

  /// No description provided for @errTagNameTaken.
  ///
  /// In fr, this message translates to:
  /// **'Cette étiquette existe déjà.'**
  String get errTagNameTaken;

  /// No description provided for @errRateSameCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez deux devises différentes.'**
  String get errRateSameCurrency;

  /// No description provided for @errRateInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Taux invalide.'**
  String get errRateInvalid;

  /// No description provided for @errRateMissing.
  ///
  /// In fr, this message translates to:
  /// **'Aucun taux {from} → {to}. Ajoutez-en un.'**
  String errRateMissing(String from, String to);

  /// No description provided for @errAccountRequired.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un compte.'**
  String get errAccountRequired;

  /// No description provided for @errPayeeTooLong.
  ///
  /// In fr, this message translates to:
  /// **'60 caractères maximum.'**
  String get errPayeeTooLong;

  /// No description provided for @errNoteTooLong.
  ///
  /// In fr, this message translates to:
  /// **'500 caractères maximum.'**
  String get errNoteTooLong;

  /// No description provided for @errTimeInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Heure invalide.'**
  String get errTimeInvalid;

  /// No description provided for @errToAccountRequired.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez le compte de destination.'**
  String get errToAccountRequired;

  /// No description provided for @errSameAccount.
  ///
  /// In fr, this message translates to:
  /// **'Les comptes doivent être différents.'**
  String get errSameAccount;

  /// No description provided for @errToAmountRequired.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le montant reçu.'**
  String get errToAmountRequired;

  /// No description provided for @errCategoryRequired.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une catégorie.'**
  String get errCategoryRequired;

  /// No description provided for @errNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Élément introuvable.'**
  String get errNotFound;

  /// No description provided for @errCustomRange.
  ///
  /// In fr, this message translates to:
  /// **'La date de fin doit suivre la date de début.'**
  String get errCustomRange;

  /// No description provided for @errBudgetExists.
  ///
  /// In fr, this message translates to:
  /// **'Un budget actif existe déjà pour cette catégorie et cette période.'**
  String get errBudgetExists;

  /// No description provided for @errGoalNameLength.
  ///
  /// In fr, this message translates to:
  /// **'Le nom doit contenir de 1 à 40 caractères.'**
  String get errGoalNameLength;

  /// No description provided for @errDeadlineBeforeStart.
  ///
  /// In fr, this message translates to:
  /// **'L\'échéance doit être après la date de début.'**
  String get errDeadlineBeforeStart;

  /// No description provided for @errLinkedAccountRequired.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez le compte d\'épargne lié.'**
  String get errLinkedAccountRequired;

  /// No description provided for @errTransferCurrencyMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les deux comptes doivent avoir la même devise.'**
  String get errTransferCurrencyMismatch;

  /// No description provided for @errIntervalInvalid.
  ///
  /// In fr, this message translates to:
  /// **'L\'intervalle doit être au moins 1.'**
  String get errIntervalInvalid;

  /// No description provided for @errMonthDayInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Jour du mois invalide.'**
  String get errMonthDayInvalid;

  /// No description provided for @errEndBeforeStart.
  ///
  /// In fr, this message translates to:
  /// **'La fin doit suivre le début.'**
  String get errEndBeforeStart;

  /// No description provided for @errRemindInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Rappel entre 0 et 7 jours.'**
  String get errRemindInvalid;

  /// No description provided for @errRuleEnded.
  ///
  /// In fr, this message translates to:
  /// **'Cette récurrence est terminée.'**
  String get errRuleEnded;

  /// No description provided for @errPersonNameLength.
  ///
  /// In fr, this message translates to:
  /// **'Le nom doit contenir de 1 à 40 caractères.'**
  String get errPersonNameLength;

  /// No description provided for @errDueBeforeStart.
  ///
  /// In fr, this message translates to:
  /// **'L\'échéance doit suivre la date de début.'**
  String get errDueBeforeStart;

  /// No description provided for @errStorage.
  ///
  /// In fr, this message translates to:
  /// **'Erreur d\'enregistrement. Vos données n\'ont pas été modifiées.'**
  String get errStorage;

  /// No description provided for @errAttachmentFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ajouter cette image.'**
  String get errAttachmentFailed;

  /// No description provided for @errBackupInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Ce fichier n\'est pas une sauvegarde Floos valide.'**
  String get errBackupInvalid;

  /// No description provided for @errBackupChecksum.
  ///
  /// In fr, this message translates to:
  /// **'La sauvegarde est corrompue (somme de contrôle invalide).'**
  String get errBackupChecksum;

  /// No description provided for @errBackupNewerSchema.
  ///
  /// In fr, this message translates to:
  /// **'Cette sauvegarde vient d\'une version plus récente de l\'application. Mettez à jour Floos.'**
  String get errBackupNewerSchema;

  /// No description provided for @errBackupWrongPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe incorrect.'**
  String get errBackupWrongPassword;

  /// No description provided for @errBackupFailed.
  ///
  /// In fr, this message translates to:
  /// **'La sauvegarde a échoué.'**
  String get errBackupFailed;

  /// No description provided for @errCsvEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Le fichier est vide.'**
  String get errCsvEmpty;

  /// No description provided for @errCsvMapping.
  ///
  /// In fr, this message translates to:
  /// **'Associez au moins les colonnes date et montant.'**
  String get errCsvMapping;

  /// No description provided for @errPinMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les codes ne correspondent pas.'**
  String get errPinMismatch;

  /// No description provided for @errPinInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Le code doit contenir 4 à 6 chiffres.'**
  String get errPinInvalid;

  /// No description provided for @errPermissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'Autorisation refusée.'**
  String get errPermissionDenied;

  /// No description provided for @errBaseCurrencyRates.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez d\'abord un taux vers {currency} pour : {codes}.'**
  String errBaseCurrencyRates(String currency, String codes);

  /// No description provided for @a11yMinus.
  ///
  /// In fr, this message translates to:
  /// **'moins'**
  String get a11yMinus;

  /// No description provided for @a11yHiddenAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant masqué'**
  String get a11yHiddenAmount;

  /// No description provided for @a11yProgress.
  ///
  /// In fr, this message translates to:
  /// **'{percent} pour cent'**
  String a11yProgress(int percent);

  /// No description provided for @a11yNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get a11yNotifications;

  /// No description provided for @a11yUnread.
  ///
  /// In fr, this message translates to:
  /// **'Notifications non lues'**
  String get a11yUnread;

  /// No description provided for @a11yToggleAmounts.
  ///
  /// In fr, this message translates to:
  /// **'Afficher ou masquer les montants'**
  String get a11yToggleAmounts;

  /// No description provided for @a11yProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get a11yProfile;

  /// No description provided for @a11yPinned.
  ///
  /// In fr, this message translates to:
  /// **'Épinglées en premier'**
  String get a11yPinned;

  /// No description provided for @a11yHistory.
  ///
  /// In fr, this message translates to:
  /// **'Récemment modifiées'**
  String get a11yHistory;

  /// No description provided for @a11yBarChart.
  ///
  /// In fr, this message translates to:
  /// **'Graphique en barres'**
  String get a11yBarChart;

  /// No description provided for @a11yDonutChart.
  ///
  /// In fr, this message translates to:
  /// **'Graphique en anneau'**
  String get a11yDonutChart;

  /// No description provided for @a11yChartSegment.
  ///
  /// In fr, this message translates to:
  /// **'{name}, {percent} pour cent, {amount}'**
  String a11yChartSegment(String name, int percent, String amount);

  /// No description provided for @a11yMoreActions.
  ///
  /// In fr, this message translates to:
  /// **'Plus d\'actions'**
  String get a11yMoreActions;

  /// No description provided for @a11yPrevious.
  ///
  /// In fr, this message translates to:
  /// **'Période précédente'**
  String get a11yPrevious;

  /// No description provided for @a11yNext.
  ///
  /// In fr, this message translates to:
  /// **'Période suivante'**
  String get a11yNext;

  /// No description provided for @a11yBackspace.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get a11yBackspace;

  /// No description provided for @a11yDragToReorder.
  ///
  /// In fr, this message translates to:
  /// **'Faire glisser pour réordonner'**
  String get a11yDragToReorder;

  /// No description provided for @a11ySwipeHint.
  ///
  /// In fr, this message translates to:
  /// **'Glisser pour supprimer ou modifier'**
  String get a11ySwipeHint;

  /// No description provided for @a11ySelected.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionné'**
  String get a11ySelected;

  /// No description provided for @a11yViewAsTable.
  ///
  /// In fr, this message translates to:
  /// **'Voir en tableau'**
  String get a11yViewAsTable;

  /// No description provided for @a11yViewAsChart.
  ///
  /// In fr, this message translates to:
  /// **'Voir en graphique'**
  String get a11yViewAsChart;

  /// No description provided for @a11yChartSummary.
  ///
  /// In fr, this message translates to:
  /// **'{title} : total {total}, {count} éléments'**
  String a11yChartSummary(String title, String total, int count);

  /// No description provided for @vsLastPeriod.
  ///
  /// In fr, this message translates to:
  /// **'vs période préc.'**
  String get vsLastPeriod;

  /// No description provided for @vsLastMonth.
  ///
  /// In fr, this message translates to:
  /// **'vs mois dernier'**
  String get vsLastMonth;

  /// No description provided for @badgeScheduled.
  ///
  /// In fr, this message translates to:
  /// **'Planifiée'**
  String get badgeScheduled;

  /// No description provided for @badgePending.
  ///
  /// In fr, this message translates to:
  /// **'À confirmer'**
  String get badgePending;

  /// No description provided for @insightSee.
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get insightSee;

  /// No description provided for @channelBudget.
  ///
  /// In fr, this message translates to:
  /// **'Alertes de budget'**
  String get channelBudget;

  /// No description provided for @channelBills.
  ///
  /// In fr, this message translates to:
  /// **'Rappels de factures'**
  String get channelBills;

  /// No description provided for @channelPending.
  ///
  /// In fr, this message translates to:
  /// **'Récurrences à confirmer'**
  String get channelPending;

  /// No description provided for @channelGoals.
  ///
  /// In fr, this message translates to:
  /// **'Objectifs'**
  String get channelGoals;

  /// No description provided for @channelDebts.
  ///
  /// In fr, this message translates to:
  /// **'Dettes'**
  String get channelDebts;

  /// No description provided for @channelDaily.
  ///
  /// In fr, this message translates to:
  /// **'Rappel quotidien'**
  String get channelDaily;

  /// No description provided for @channelBackup.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde'**
  String get channelBackup;

  /// No description provided for @notifBudgetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Budget {name}'**
  String notifBudgetTitle(String name);

  /// No description provided for @notifBudgetBody.
  ///
  /// In fr, this message translates to:
  /// **'{name} : {percent} % de {limit} utilisés'**
  String notifBudgetBody(String name, int percent, String limit);

  /// No description provided for @notifBudgetBodyHidden.
  ///
  /// In fr, this message translates to:
  /// **'{name} : {percent} % du budget utilisé'**
  String notifBudgetBodyHidden(String name, int percent);

  /// No description provided for @notifBillTitle.
  ///
  /// In fr, this message translates to:
  /// **'Facture à venir'**
  String get notifBillTitle;

  /// No description provided for @notifBillBody.
  ///
  /// In fr, this message translates to:
  /// **'{name} {amount} à payer le {date}'**
  String notifBillBody(String name, String amount, String date);

  /// No description provided for @notifBillBodyHidden.
  ///
  /// In fr, this message translates to:
  /// **'{name} à payer le {date}'**
  String notifBillBodyHidden(String name, String date);

  /// No description provided for @notifPendingTitle.
  ///
  /// In fr, this message translates to:
  /// **'À confirmer'**
  String get notifPendingTitle;

  /// No description provided for @notifPendingBody.
  ///
  /// In fr, this message translates to:
  /// **'{name} est prêt à être confirmé'**
  String notifPendingBody(String name);

  /// No description provided for @notifSummaryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Récurrences ajoutées'**
  String get notifSummaryTitle;

  /// No description provided for @notifSummaryBody.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 opération récurrente a été ajoutée} other{{count} opérations récurrentes ont été ajoutées}}'**
  String notifSummaryBody(int count);

  /// No description provided for @notifGoalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Objectif'**
  String get notifGoalTitle;

  /// No description provided for @notifGoalBody.
  ///
  /// In fr, this message translates to:
  /// **'🎉 {percent} % de {name}'**
  String notifGoalBody(int percent, String name);

  /// No description provided for @notifGoalDoneBody.
  ///
  /// In fr, this message translates to:
  /// **'🎉 Objectif atteint : {name}'**
  String notifGoalDoneBody(String name);

  /// No description provided for @notifDebtTitle.
  ///
  /// In fr, this message translates to:
  /// **'Échéance de dette'**
  String get notifDebtTitle;

  /// No description provided for @notifDebtOweTomorrow.
  ///
  /// In fr, this message translates to:
  /// **'Vous devez {amount} à {name} demain'**
  String notifDebtOweTomorrow(String amount, String name);

  /// No description provided for @notifDebtOweToday.
  ///
  /// In fr, this message translates to:
  /// **'Vous devez {amount} à {name} aujourd\'hui'**
  String notifDebtOweToday(String amount, String name);

  /// No description provided for @notifDebtOwedTomorrow.
  ///
  /// In fr, this message translates to:
  /// **'{name} vous doit {amount} demain'**
  String notifDebtOwedTomorrow(String amount, String name);

  /// No description provided for @notifDebtOwedToday.
  ///
  /// In fr, this message translates to:
  /// **'{name} vous doit {amount} aujourd\'hui'**
  String notifDebtOwedToday(String amount, String name);

  /// No description provided for @notifDebtHiddenTomorrow.
  ///
  /// In fr, this message translates to:
  /// **'Échéance avec {name} demain'**
  String notifDebtHiddenTomorrow(String name);

  /// No description provided for @notifDebtHiddenToday.
  ///
  /// In fr, this message translates to:
  /// **'Échéance avec {name} aujourd\'hui'**
  String notifDebtHiddenToday(String name);

  /// No description provided for @notifDailyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Floos'**
  String get notifDailyTitle;

  /// No description provided for @notifDailyBody.
  ///
  /// In fr, this message translates to:
  /// **'Saisir les dépenses du jour ?'**
  String get notifDailyBody;

  /// No description provided for @notifBackupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde'**
  String get notifBackupTitle;

  /// No description provided for @notifBackupBody.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegardez vos données'**
  String get notifBackupBody;

  /// No description provided for @notifTestTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notification de test'**
  String get notifTestTitle;

  /// No description provided for @notifTestBody.
  ///
  /// In fr, this message translates to:
  /// **'Les notifications fonctionnent.'**
  String get notifTestBody;

  /// No description provided for @widgetSpent.
  ///
  /// In fr, this message translates to:
  /// **'Dépensé ce mois'**
  String get widgetSpent;

  /// No description provided for @widgetIncome.
  ///
  /// In fr, this message translates to:
  /// **'Revenus'**
  String get widgetIncome;

  /// No description provided for @widgetBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde'**
  String get widgetBalance;

  /// No description provided for @budgetOverall.
  ///
  /// In fr, this message translates to:
  /// **'Global'**
  String get budgetOverall;

  /// No description provided for @txNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle transaction'**
  String get txNew;

  /// No description provided for @txEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la transaction'**
  String get txEdit;

  /// No description provided for @txSaveAndAdd.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer et ajouter'**
  String get txSaveAndAdd;

  /// No description provided for @txAllCategories.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get txAllCategories;

  /// No description provided for @txNewCategory.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle'**
  String get txNewCategory;

  /// No description provided for @txChooseCategory.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une catégorie'**
  String get txChooseCategory;

  /// No description provided for @txChooseAccount.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un compte'**
  String get txChooseAccount;

  /// No description provided for @txFromAccount.
  ///
  /// In fr, this message translates to:
  /// **'Depuis'**
  String get txFromAccount;

  /// No description provided for @txToAccount.
  ///
  /// In fr, this message translates to:
  /// **'Vers'**
  String get txToAccount;

  /// No description provided for @txToAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant reçu'**
  String get txToAmount;

  /// No description provided for @txRateLine.
  ///
  /// In fr, this message translates to:
  /// **'Taux : 1 {from} = {rate} {to}'**
  String txRateLine(String from, String rate, String to);

  /// No description provided for @txRateMissingHint.
  ///
  /// In fr, this message translates to:
  /// **'Aucun taux {from} → {to} : saisissez le taux du jour.'**
  String txRateMissingHint(String from, String to);

  /// No description provided for @txRateField.
  ///
  /// In fr, this message translates to:
  /// **'1 {from} = ? {to}'**
  String txRateField(String from, String to);

  /// No description provided for @txPayeeHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Marjane, Uber…'**
  String get txPayeeHint;

  /// No description provided for @txNoteHint.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une note'**
  String get txNoteHint;

  /// No description provided for @txTags.
  ///
  /// In fr, this message translates to:
  /// **'Étiquettes'**
  String get txTags;

  /// No description provided for @txAddTag.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une étiquette'**
  String get txAddTag;

  /// No description provided for @txNewTagHint.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle étiquette'**
  String get txNewTagHint;

  /// No description provided for @txAttachments.
  ///
  /// In fr, this message translates to:
  /// **'Justificatifs'**
  String get txAttachments;

  /// No description provided for @txAddPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get txAddPhoto;

  /// No description provided for @txCamera.
  ///
  /// In fr, this message translates to:
  /// **'Appareil photo'**
  String get txCamera;

  /// No description provided for @txGallery.
  ///
  /// In fr, this message translates to:
  /// **'Galerie'**
  String get txGallery;

  /// No description provided for @txRepeat.
  ///
  /// In fr, this message translates to:
  /// **'Répéter'**
  String get txRepeat;

  /// No description provided for @txRepeatNone.
  ///
  /// In fr, this message translates to:
  /// **'Jamais'**
  String get txRepeatNone;

  /// No description provided for @txAdvanced.
  ///
  /// In fr, this message translates to:
  /// **'Options avancées'**
  String get txAdvanced;

  /// No description provided for @txLinkDebt.
  ///
  /// In fr, this message translates to:
  /// **'Lier à une dette'**
  String get txLinkDebt;

  /// No description provided for @txContributeGoal.
  ///
  /// In fr, this message translates to:
  /// **'Contribuer à un objectif'**
  String get txContributeGoal;

  /// No description provided for @txExcludeReports.
  ///
  /// In fr, this message translates to:
  /// **'Exclure des rapports'**
  String get txExcludeReports;

  /// No description provided for @txExcludeReportsHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. remboursements'**
  String get txExcludeReportsHint;

  /// No description provided for @txPinned.
  ///
  /// In fr, this message translates to:
  /// **'Épinglée'**
  String get txPinned;

  /// No description provided for @txAddTime.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une heure'**
  String get txAddTime;

  /// No description provided for @txCalendar.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier'**
  String get txCalendar;

  /// No description provided for @txDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette transaction ?'**
  String get txDeleteConfirm;

  /// No description provided for @txRecurringScopeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Transaction récurrente'**
  String get txRecurringScopeTitle;

  /// No description provided for @txRecurringScopeMessage.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer les modifications à :'**
  String get txRecurringScopeMessage;

  /// No description provided for @txScopeOnlyThis.
  ///
  /// In fr, this message translates to:
  /// **'Celle-ci uniquement'**
  String get txScopeOnlyThis;

  /// No description provided for @txScopeFuture.
  ///
  /// In fr, this message translates to:
  /// **'Celle-ci et les suivantes'**
  String get txScopeFuture;

  /// No description provided for @txDuplicated.
  ///
  /// In fr, this message translates to:
  /// **'Copie créée — vérifiez puis enregistrez'**
  String get txDuplicated;

  /// No description provided for @txAmountPreview.
  ///
  /// In fr, this message translates to:
  /// **'= {amount}'**
  String txAmountPreview(String amount);

  /// No description provided for @txSearchCategories.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une catégorie'**
  String get txSearchCategories;

  /// No description provided for @txCreateCategoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle catégorie'**
  String get txCreateCategoryTitle;

  /// No description provided for @txParentCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie parente'**
  String get txParentCategory;

  /// No description provided for @txNoParent.
  ///
  /// In fr, this message translates to:
  /// **'Aucune (principale)'**
  String get txNoParent;

  /// No description provided for @txKeypadHint.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un montant'**
  String get txKeypadHint;

  /// No description provided for @txNoAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créez d\'abord un compte.'**
  String get txNoAccount;

  /// No description provided for @txCreateAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get txCreateAccount;

  /// No description provided for @freqDaily.
  ///
  /// In fr, this message translates to:
  /// **'Quotidienne'**
  String get freqDaily;

  /// No description provided for @freqWeekly.
  ///
  /// In fr, this message translates to:
  /// **'Hebdomadaire'**
  String get freqWeekly;

  /// No description provided for @freqMonthly.
  ///
  /// In fr, this message translates to:
  /// **'Mensuelle'**
  String get freqMonthly;

  /// No description provided for @freqYearly.
  ///
  /// In fr, this message translates to:
  /// **'Annuelle'**
  String get freqYearly;

  /// No description provided for @recEvery.
  ///
  /// In fr, this message translates to:
  /// **'Tous les'**
  String get recEvery;

  /// No description provided for @recInterval.
  ///
  /// In fr, this message translates to:
  /// **'Intervalle'**
  String get recInterval;

  /// No description provided for @recEveryDay.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{Chaque jour} other{Tous les {n} jours}}'**
  String recEveryDay(int n);

  /// No description provided for @recEveryWeek.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{Chaque semaine le {weekday}} other{Toutes les {n} semaines le {weekday}}}'**
  String recEveryWeek(int n, String weekday);

  /// No description provided for @recEveryMonth.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{Chaque mois le {day}} other{Tous les {n} mois le {day}}}'**
  String recEveryMonth(int n, int day);

  /// No description provided for @recEveryYear.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{Chaque année le {date}} other{Tous les {n} ans le {date}}}'**
  String recEveryYear(int n, String date);

  /// No description provided for @recWeekday.
  ///
  /// In fr, this message translates to:
  /// **'Jour de la semaine'**
  String get recWeekday;

  /// No description provided for @recMonthDay.
  ///
  /// In fr, this message translates to:
  /// **'Jour du mois'**
  String get recMonthDay;

  /// No description provided for @recMonthDayHint.
  ///
  /// In fr, this message translates to:
  /// **'Les mois plus courts utilisent leur dernier jour.'**
  String get recMonthDayHint;

  /// No description provided for @recEnds.
  ///
  /// In fr, this message translates to:
  /// **'Fin'**
  String get recEnds;

  /// No description provided for @recEndsNever.
  ///
  /// In fr, this message translates to:
  /// **'Jamais'**
  String get recEndsNever;

  /// No description provided for @recEndsOn.
  ///
  /// In fr, this message translates to:
  /// **'Le'**
  String get recEndsOn;

  /// No description provided for @recEndsAfter.
  ///
  /// In fr, this message translates to:
  /// **'Après'**
  String get recEndsAfter;

  /// No description provided for @recOccurrences.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 fois} other{{n} fois}}'**
  String recOccurrences(int n);

  /// No description provided for @recMode.
  ///
  /// In fr, this message translates to:
  /// **'Création'**
  String get recMode;

  /// No description provided for @recModeAuto.
  ///
  /// In fr, this message translates to:
  /// **'Automatique'**
  String get recModeAuto;

  /// No description provided for @recModeConfirm.
  ///
  /// In fr, this message translates to:
  /// **'À confirmer'**
  String get recModeConfirm;

  /// No description provided for @recModeAutoHint.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutée automatiquement à la date prévue.'**
  String get recModeAutoHint;

  /// No description provided for @recModeConfirmHint.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutée en attente de votre confirmation.'**
  String get recModeConfirmHint;

  /// No description provided for @recReminder.
  ///
  /// In fr, this message translates to:
  /// **'Rappel de facture'**
  String get recReminder;

  /// No description provided for @recReminderOff.
  ///
  /// In fr, this message translates to:
  /// **'Aucun'**
  String get recReminderOff;

  /// No description provided for @recReminderDays.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Le jour même} =1{1 jour avant} other{{n} jours avant}}'**
  String recReminderDays(int n);

  /// No description provided for @recReminderTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure du rappel'**
  String get recReminderTime;

  /// No description provided for @recStart.
  ///
  /// In fr, this message translates to:
  /// **'Début'**
  String get recStart;

  /// No description provided for @recName.
  ///
  /// In fr, this message translates to:
  /// **'Nom (facultatif)'**
  String get recName;

  /// No description provided for @recTitle.
  ///
  /// In fr, this message translates to:
  /// **'Répétition'**
  String get recTitle;

  /// No description provided for @recRemove.
  ///
  /// In fr, this message translates to:
  /// **'Ne pas répéter'**
  String get recRemove;

  /// No description provided for @homeCurrentBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde actuel'**
  String get homeCurrentBalance;

  /// No description provided for @homeDeltaVs.
  ///
  /// In fr, this message translates to:
  /// **'{amount} vs période préc.'**
  String homeDeltaVs(String amount);

  /// No description provided for @homeYourMoney.
  ///
  /// In fr, this message translates to:
  /// **'Votre argent'**
  String get homeYourMoney;

  /// No description provided for @homeYourMoneyInfo.
  ///
  /// In fr, this message translates to:
  /// **'Revenus et dépenses de la période sélectionnée, convertis dans votre devise principale.'**
  String get homeYourMoneyInfo;

  /// No description provided for @homeIncome.
  ///
  /// In fr, this message translates to:
  /// **'Revenus'**
  String get homeIncome;

  /// No description provided for @homeExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses'**
  String get homeExpenses;

  /// No description provided for @homeTransactions.
  ///
  /// In fr, this message translates to:
  /// **'Transactions'**
  String get homeTransactions;

  /// No description provided for @homeForPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Pour la période'**
  String get homeForPeriod;

  /// No description provided for @homeNeedsConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'À confirmer'**
  String get homeNeedsConfirmation;

  /// No description provided for @homeConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get homeConfirm;

  /// No description provided for @homeSkip.
  ///
  /// In fr, this message translates to:
  /// **'Ignorer'**
  String get homeSkip;

  /// No description provided for @homeEditRule.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la règle'**
  String get homeEditRule;

  /// No description provided for @homeBudgets.
  ///
  /// In fr, this message translates to:
  /// **'Budgets'**
  String get homeBudgets;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune transaction pour le moment'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyAction.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter votre première dépense'**
  String get homeEmptyAction;

  /// No description provided for @homeEmptyPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Aucune transaction sur cette période.'**
  String get homeEmptyPeriod;

  /// No description provided for @homeCoachMark.
  ///
  /// In fr, this message translates to:
  /// **'Touchez + pour ajouter une dépense en quelques secondes.'**
  String get homeCoachMark;

  /// No description provided for @homeConfirmAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant confirmé'**
  String get homeConfirmAmount;

  /// No description provided for @homeMissingRates.
  ///
  /// In fr, this message translates to:
  /// **'Taux manquant pour : {codes}'**
  String homeMissingRates(String codes);

  /// No description provided for @homeInfoIncomeExpense.
  ///
  /// In fr, this message translates to:
  /// **'Les virements ne sont jamais comptés comme revenus ou dépenses.'**
  String get homeInfoIncomeExpense;

  /// No description provided for @insightBudgetOver.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez dépassé votre budget {name} de {amount}.'**
  String insightBudgetOver(String name, String amount);

  /// No description provided for @insightBudgetWarning.
  ///
  /// In fr, this message translates to:
  /// **'{name} est à {percent} % de sa limite, {perDay}/jour restants.'**
  String insightBudgetWarning(String name, int percent, String perDay);

  /// No description provided for @insightGoalBehind.
  ///
  /// In fr, this message translates to:
  /// **'{name} nécessite {amount}/mois pour rester dans les temps.'**
  String insightGoalBehind(String name, String amount);

  /// No description provided for @insightBill.
  ///
  /// In fr, this message translates to:
  /// **'{name} ({amount}) {when}.'**
  String insightBill(String name, String amount, String when);

  /// No description provided for @insightBillWhen.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =0{à payer aujourd\'hui} =1{à payer demain} other{à payer dans {days} jours}}'**
  String insightBillWhen(int days);

  /// No description provided for @insightCategoryUp.
  ///
  /// In fr, this message translates to:
  /// **'{name} est en hausse de {percent} % par rapport au mois dernier.'**
  String insightCategoryUp(String name, int percent);

  /// No description provided for @insightUnusual.
  ///
  /// In fr, this message translates to:
  /// **'Dépense inhabituelle en {name} : {amount}.'**
  String insightUnusual(String name, String amount);

  /// No description provided for @insightSavings.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez épargné {percent} % de vos revenus jusqu\'ici 👏'**
  String insightSavings(int percent);

  /// No description provided for @insightNoLogs.
  ///
  /// In fr, this message translates to:
  /// **'N\'oubliez pas de saisir vos dépenses.'**
  String get insightNoLogs;

  /// No description provided for @insightBackup.
  ///
  /// In fr, this message translates to:
  /// **'Aucune sauvegarde depuis 30 jours : sauvegardez vos données.'**
  String get insightBackup;

  /// No description provided for @insightDismiss.
  ///
  /// In fr, this message translates to:
  /// **'Masquer pour cette période'**
  String get insightDismiss;

  /// No description provided for @insightDismissed.
  ///
  /// In fr, this message translates to:
  /// **'Conseil masqué'**
  String get insightDismissed;

  /// No description provided for @insightsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conseils'**
  String get insightsTitle;

  /// No description provided for @insightsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun conseil pour l\'instant. Continuez à saisir vos opérations.'**
  String get insightsEmpty;

  /// No description provided for @periodWeek.
  ///
  /// In fr, this message translates to:
  /// **'Semaine'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois'**
  String get periodMonth;

  /// No description provided for @periodYear.
  ///
  /// In fr, this message translates to:
  /// **'Année'**
  String get periodYear;

  /// No description provided for @periodCustom.
  ///
  /// In fr, this message translates to:
  /// **'Personnalisée'**
  String get periodCustom;

  /// No description provided for @periodPickTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisir la période'**
  String get periodPickTitle;

  /// No description provided for @periodThis.
  ///
  /// In fr, this message translates to:
  /// **'Cette période'**
  String get periodThis;

  /// No description provided for @periodLast.
  ///
  /// In fr, this message translates to:
  /// **'Période précédente'**
  String get periodLast;

  /// No description provided for @periodLast3Months.
  ///
  /// In fr, this message translates to:
  /// **'3 derniers mois'**
  String get periodLast3Months;

  /// No description provided for @periodThisYear.
  ///
  /// In fr, this message translates to:
  /// **'Cette année'**
  String get periodThisYear;

  /// No description provided for @periodAllTime.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get periodAllTime;

  /// No description provided for @periodCustomRange.
  ///
  /// In fr, this message translates to:
  /// **'Plage personnalisée'**
  String get periodCustomRange;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
