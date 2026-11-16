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

  /// No description provided for @txListTitle.
  ///
  /// In fr, this message translates to:
  /// **'Transactions'**
  String get txListTitle;

  /// No description provided for @txSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher (bénéficiaire, note, =45, >100)'**
  String get txSearchHint;

  /// No description provided for @filterTitle.
  ///
  /// In fr, this message translates to:
  /// **'Filtres'**
  String get filterTitle;

  /// No description provided for @filterDateRange.
  ///
  /// In fr, this message translates to:
  /// **'Période'**
  String get filterDateRange;

  /// No description provided for @filterTypes.
  ///
  /// In fr, this message translates to:
  /// **'Types'**
  String get filterTypes;

  /// No description provided for @filterAccounts.
  ///
  /// In fr, this message translates to:
  /// **'Comptes'**
  String get filterAccounts;

  /// No description provided for @filterCategories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get filterCategories;

  /// No description provided for @filterTags.
  ///
  /// In fr, this message translates to:
  /// **'Étiquettes'**
  String get filterTags;

  /// No description provided for @filterAmountMin.
  ///
  /// In fr, this message translates to:
  /// **'Montant min.'**
  String get filterAmountMin;

  /// No description provided for @filterAmountMax.
  ///
  /// In fr, this message translates to:
  /// **'Montant max.'**
  String get filterAmountMax;

  /// No description provided for @filterHasAttachment.
  ///
  /// In fr, this message translates to:
  /// **'Avec justificatif'**
  String get filterHasAttachment;

  /// No description provided for @filterPendingOnly.
  ///
  /// In fr, this message translates to:
  /// **'À confirmer uniquement'**
  String get filterPendingOnly;

  /// No description provided for @filterClearAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout effacer'**
  String get filterClearAll;

  /// No description provided for @filterCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 filtre} other{{count} filtres}}'**
  String filterCount(int count);

  /// No description provided for @footerIn.
  ///
  /// In fr, this message translates to:
  /// **'Entrées'**
  String get footerIn;

  /// No description provided for @footerOut.
  ///
  /// In fr, this message translates to:
  /// **'Sorties'**
  String get footerOut;

  /// No description provided for @footerNet.
  ///
  /// In fr, this message translates to:
  /// **'Net'**
  String get footerNet;

  /// No description provided for @bulkDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get bulkDelete;

  /// No description provided for @bulkCategory.
  ///
  /// In fr, this message translates to:
  /// **'Changer la catégorie'**
  String get bulkCategory;

  /// No description provided for @bulkAccount.
  ///
  /// In fr, this message translates to:
  /// **'Changer le compte'**
  String get bulkAccount;

  /// No description provided for @bulkTag.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une étiquette'**
  String get bulkTag;

  /// No description provided for @bulkExport.
  ///
  /// In fr, this message translates to:
  /// **'Exporter en CSV'**
  String get bulkExport;

  /// No description provided for @bulkDone.
  ///
  /// In fr, this message translates to:
  /// **'Modifications appliquées'**
  String get bulkDone;

  /// No description provided for @searchNoResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat. Essayez d\'autres mots ou retirez des filtres.'**
  String get searchNoResults;

  /// No description provided for @csvSeparator.
  ///
  /// In fr, this message translates to:
  /// **'Séparateur'**
  String get csvSeparator;

  /// No description provided for @csvComma.
  ///
  /// In fr, this message translates to:
  /// **'Virgule (,)'**
  String get csvComma;

  /// No description provided for @csvSemicolon.
  ///
  /// In fr, this message translates to:
  /// **'Point-virgule (;)'**
  String get csvSemicolon;

  /// No description provided for @csvExported.
  ///
  /// In fr, this message translates to:
  /// **'Fichier CSV prêt'**
  String get csvExported;

  /// No description provided for @chooseTag.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une étiquette'**
  String get chooseTag;

  /// No description provided for @obWelcomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur Floos'**
  String get obWelcomeTitle;

  /// No description provided for @obWelcomeBody.
  ///
  /// In fr, this message translates to:
  /// **'Suivez vos dépenses, budgets et objectifs. Tout reste sur votre téléphone, hors ligne.'**
  String get obWelcomeBody;

  /// No description provided for @obStart.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get obStart;

  /// No description provided for @obCurrencyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre devise'**
  String get obCurrencyTitle;

  /// No description provided for @obCurrencyBody.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez la devise principale et le jour de début de mois.'**
  String get obCurrencyBody;

  /// No description provided for @obMonthStart.
  ///
  /// In fr, this message translates to:
  /// **'Le mois commence le'**
  String get obMonthStart;

  /// No description provided for @obAccountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre premier compte'**
  String get obAccountTitle;

  /// No description provided for @obAccountBody.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez un compte (espèces, banque…) avec son solde actuel.'**
  String get obAccountBody;

  /// No description provided for @obAccountName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du compte'**
  String get obAccountName;

  /// No description provided for @obAccountDefault.
  ///
  /// In fr, this message translates to:
  /// **'Espèces'**
  String get obAccountDefault;

  /// No description provided for @obInitialBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde actuel'**
  String get obInitialBalance;

  /// No description provided for @obSecurityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sécurisez Floos'**
  String get obSecurityTitle;

  /// No description provided for @obSecurityBody.
  ///
  /// In fr, this message translates to:
  /// **'Protégez l\'accès avec un code PIN. Vous pourrez le changer plus tard.'**
  String get obSecurityBody;

  /// No description provided for @obSetPin.
  ///
  /// In fr, this message translates to:
  /// **'Définir un code PIN'**
  String get obSetPin;

  /// No description provided for @obSkipPin.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get obSkipPin;

  /// No description provided for @obFinish.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get obFinish;

  /// No description provided for @obStep.
  ///
  /// In fr, this message translates to:
  /// **'Étape {n} sur {total}'**
  String obStep(int n, int total);

  /// No description provided for @pinEnter.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez votre code PIN'**
  String get pinEnter;

  /// No description provided for @pinCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créez un code PIN (4 à 6 chiffres)'**
  String get pinCreate;

  /// No description provided for @pinConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez le code PIN'**
  String get pinConfirm;

  /// No description provided for @pinCurrent.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN actuel'**
  String get pinCurrent;

  /// No description provided for @pinWrong.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN incorrect'**
  String get pinWrong;

  /// No description provided for @pinLocked.
  ///
  /// In fr, this message translates to:
  /// **'Trop d\'essais. Réessayez dans {s} s.'**
  String pinLocked(int s);

  /// No description provided for @pinForgot.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN oublié ?'**
  String get pinForgot;

  /// No description provided for @pinUseBiometrics.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser la biométrie'**
  String get pinUseBiometrics;

  /// No description provided for @pinBiometricReason.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouiller Floos'**
  String get pinBiometricReason;

  /// No description provided for @pinForgotTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser l\'accès'**
  String get pinForgotTitle;

  /// No description provided for @pinForgotBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez vous authentifier par biométrie, ou effacer toutes les données de l\'application.'**
  String get pinForgotBody;

  /// No description provided for @pinWipeAll.
  ///
  /// In fr, this message translates to:
  /// **'Effacer toutes les données'**
  String get pinWipeAll;

  /// No description provided for @pinWipeConfirm1.
  ///
  /// In fr, this message translates to:
  /// **'Toutes vos données seront définitivement supprimées. Continuer ?'**
  String get pinWipeConfirm1;

  /// No description provided for @pinWipeConfirm2.
  ///
  /// In fr, this message translates to:
  /// **'Dernière confirmation : cette action est irréversible.'**
  String get pinWipeConfirm2;

  /// No description provided for @pinChanged.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN modifié'**
  String get pinChanged;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settingsTitle;

  /// No description provided for @settingsProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get settingsProfile;

  /// No description provided for @settingsDisplayName.
  ///
  /// In fr, this message translates to:
  /// **'Votre prénom'**
  String get settingsDisplayName;

  /// No description provided for @settingsGeneral.
  ///
  /// In fr, this message translates to:
  /// **'Général'**
  String get settingsGeneral;

  /// No description provided for @settingsBaseCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Devise principale'**
  String get settingsBaseCurrency;

  /// No description provided for @settingsMonthStart.
  ///
  /// In fr, this message translates to:
  /// **'Début du mois'**
  String get settingsMonthStart;

  /// No description provided for @settingsWeekStart.
  ///
  /// In fr, this message translates to:
  /// **'Début de la semaine'**
  String get settingsWeekStart;

  /// No description provided for @weekMonday.
  ///
  /// In fr, this message translates to:
  /// **'Lundi'**
  String get weekMonday;

  /// No description provided for @weekSaturday.
  ///
  /// In fr, this message translates to:
  /// **'Samedi'**
  String get weekSaturday;

  /// No description provided for @weekSunday.
  ///
  /// In fr, this message translates to:
  /// **'Dimanche'**
  String get weekSunday;

  /// No description provided for @settingsTheme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get themeDark;

  /// No description provided for @settingsHideAmounts.
  ///
  /// In fr, this message translates to:
  /// **'Masquer les montants au démarrage'**
  String get settingsHideAmounts;

  /// No description provided for @settingsManage.
  ///
  /// In fr, this message translates to:
  /// **'Gérer'**
  String get settingsManage;

  /// No description provided for @settingsRates.
  ///
  /// In fr, this message translates to:
  /// **'Taux de change'**
  String get settingsRates;

  /// No description provided for @settingsNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsSecurity.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get settingsSecurity;

  /// No description provided for @settingsBackup.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde et données'**
  String get settingsBackup;

  /// No description provided for @settingsAbout.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get settingsAbout;

  /// No description provided for @securityLock.
  ///
  /// In fr, this message translates to:
  /// **'Verrouillage par code PIN'**
  String get securityLock;

  /// No description provided for @securityChangePin.
  ///
  /// In fr, this message translates to:
  /// **'Changer le code PIN'**
  String get securityChangePin;

  /// No description provided for @securityBiometrics.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouillage biométrique'**
  String get securityBiometrics;

  /// No description provided for @securityTimeout.
  ///
  /// In fr, this message translates to:
  /// **'Verrouiller après'**
  String get securityTimeout;

  /// No description provided for @timeoutImmediate.
  ///
  /// In fr, this message translates to:
  /// **'Immédiatement'**
  String get timeoutImmediate;

  /// No description provided for @timeout30.
  ///
  /// In fr, this message translates to:
  /// **'30 secondes'**
  String get timeout30;

  /// No description provided for @timeout60.
  ///
  /// In fr, this message translates to:
  /// **'1 minute'**
  String get timeout60;

  /// No description provided for @timeout300.
  ///
  /// In fr, this message translates to:
  /// **'5 minutes'**
  String get timeout300;

  /// No description provided for @securitySecureFlag.
  ///
  /// In fr, this message translates to:
  /// **'Masquer l\'aperçu dans les applications récentes'**
  String get securitySecureFlag;

  /// No description provided for @aboutVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version'**
  String get aboutVersion;

  /// No description provided for @aboutPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité'**
  String get aboutPrivacy;

  /// No description provided for @aboutPrivacyBody.
  ///
  /// In fr, this message translates to:
  /// **'Floos fonctionne entièrement hors ligne. Aucune donnée ne quitte votre appareil, sauf sauvegardes que vous partagez vous-même.'**
  String get aboutPrivacyBody;

  /// No description provided for @aboutLicenses.
  ///
  /// In fr, this message translates to:
  /// **'Licences open source'**
  String get aboutLicenses;

  /// No description provided for @aboutDiagnostics.
  ///
  /// In fr, this message translates to:
  /// **'Diagnostics'**
  String get aboutDiagnostics;

  /// No description provided for @diagEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune erreur enregistrée'**
  String get diagEmpty;

  /// No description provided for @diagExport.
  ///
  /// In fr, this message translates to:
  /// **'Exporter le journal'**
  String get diagExport;

  /// No description provided for @diagClear.
  ///
  /// In fr, this message translates to:
  /// **'Effacer le journal'**
  String get diagClear;

  /// No description provided for @baseCurrencyBlocked.
  ///
  /// In fr, this message translates to:
  /// **'Taux manquants pour {codes}. Ajoutez-les avant de changer de devise.'**
  String baseCurrencyBlocked(String codes);

  /// No description provided for @errorLoading.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get errorLoading;

  /// No description provided for @splashLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get splashLoading;

  /// No description provided for @accountNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau compte'**
  String get accountNew;

  /// No description provided for @accountEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le compte'**
  String get accountEdit;

  /// No description provided for @accountTypeCash.
  ///
  /// In fr, this message translates to:
  /// **'Espèces'**
  String get accountTypeCash;

  /// No description provided for @accountTypeBank.
  ///
  /// In fr, this message translates to:
  /// **'Banque'**
  String get accountTypeBank;

  /// No description provided for @accountTypeCard.
  ///
  /// In fr, this message translates to:
  /// **'Carte'**
  String get accountTypeCard;

  /// No description provided for @accountTypeSavings.
  ///
  /// In fr, this message translates to:
  /// **'Épargne'**
  String get accountTypeSavings;

  /// No description provided for @accountTypeEwallet.
  ///
  /// In fr, this message translates to:
  /// **'Portefeuille électronique'**
  String get accountTypeEwallet;

  /// No description provided for @accountTypeOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get accountTypeOther;

  /// No description provided for @accountInitialBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde initial'**
  String get accountInitialBalance;

  /// No description provided for @accountIncludeTotal.
  ///
  /// In fr, this message translates to:
  /// **'Inclure dans le total'**
  String get accountIncludeTotal;

  /// No description provided for @accountArchivedSection.
  ///
  /// In fr, this message translates to:
  /// **'Archivés'**
  String get accountArchivedSection;

  /// No description provided for @accountReconcile.
  ///
  /// In fr, this message translates to:
  /// **'Rapprocher le solde'**
  String get accountReconcile;

  /// No description provided for @accountReconcileBody.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le solde réel. Un ajustement sera créé pour la différence.'**
  String get accountReconcileBody;

  /// No description provided for @accountRealBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde réel'**
  String get accountRealBalance;

  /// No description provided for @accountReconciled.
  ///
  /// In fr, this message translates to:
  /// **'Solde rapproché'**
  String get accountReconciled;

  /// No description provided for @accountBalanceHistory.
  ///
  /// In fr, this message translates to:
  /// **'Solde sur 6 mois'**
  String get accountBalanceHistory;

  /// No description provided for @accountDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le compte'**
  String get accountDeleteTitle;

  /// No description provided for @accountDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte contient {n} opérations. Que faire ?'**
  String accountDeleteBody(int n);

  /// No description provided for @accountMoveTo.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer les opérations vers…'**
  String get accountMoveTo;

  /// No description provided for @accountDeleteAll.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer aussi les opérations'**
  String get accountDeleteAll;

  /// No description provided for @accountTotalBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde total'**
  String get accountTotalBalance;

  /// No description provided for @accountsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte'**
  String get accountsEmpty;

  /// No description provided for @accountTransactions.
  ///
  /// In fr, this message translates to:
  /// **'Opérations'**
  String get accountTransactions;

  /// No description provided for @reorderHint.
  ///
  /// In fr, this message translates to:
  /// **'Maintenez et faites glisser pour réordonner'**
  String get reorderHint;

  /// No description provided for @categoryNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle catégorie'**
  String get categoryNew;

  /// No description provided for @categoryEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la catégorie'**
  String get categoryEdit;

  /// No description provided for @categoryParent.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie parente'**
  String get categoryParent;

  /// No description provided for @categoryMerge.
  ///
  /// In fr, this message translates to:
  /// **'Fusionner'**
  String get categoryMerge;

  /// No description provided for @categoryMergeInto.
  ///
  /// In fr, this message translates to:
  /// **'Fusionner dans…'**
  String get categoryMergeInto;

  /// No description provided for @categoryDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la catégorie'**
  String get categoryDeleteTitle;

  /// No description provided for @categoryDeleteReassign.
  ///
  /// In fr, this message translates to:
  /// **'{n} opérations utilisent cette catégorie. Choisissez une catégorie de remplacement.'**
  String categoryDeleteReassign(int n);

  /// No description provided for @categoryPickReplacement.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un remplacement'**
  String get categoryPickReplacement;

  /// No description provided for @categoryArchivedBudgets.
  ///
  /// In fr, this message translates to:
  /// **'{n} budget(s) archivé(s)'**
  String categoryArchivedBudgets(int n);

  /// No description provided for @categoryEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune catégorie'**
  String get categoryEmpty;

  /// No description provided for @tagsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune étiquette'**
  String get tagsEmpty;

  /// No description provided for @tagNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle étiquette'**
  String get tagNew;

  /// No description provided for @tagUsage.
  ///
  /// In fr, this message translates to:
  /// **'{n} utilisations'**
  String tagUsage(int n);

  /// No description provided for @ratesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Taux de change'**
  String get ratesTitle;

  /// No description provided for @ratesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun taux. Ajoutez-en un pour convertir les devises.'**
  String get ratesEmpty;

  /// No description provided for @rateAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un taux'**
  String get rateAdd;

  /// No description provided for @rateValue.
  ///
  /// In fr, this message translates to:
  /// **'Taux'**
  String get rateValue;

  /// No description provided for @rateFrom.
  ///
  /// In fr, this message translates to:
  /// **'De'**
  String get rateFrom;

  /// No description provided for @rateTo.
  ///
  /// In fr, this message translates to:
  /// **'Vers'**
  String get rateTo;

  /// No description provided for @rateHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get rateHistory;

  /// No description provided for @rateLine.
  ///
  /// In fr, this message translates to:
  /// **'1 {from} = {rate} {to}'**
  String rateLine(String from, String rate, String to);

  /// No description provided for @kindExpense.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses'**
  String get kindExpense;

  /// No description provided for @kindIncome.
  ///
  /// In fr, this message translates to:
  /// **'Revenus'**
  String get kindIncome;

  /// No description provided for @reportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rapport'**
  String get reportTitle;

  /// No description provided for @reportExpensesTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total des dépenses'**
  String get reportExpensesTotal;

  /// No description provided for @reportIncomeTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total des revenus'**
  String get reportIncomeTotal;

  /// No description provided for @reportNoData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée pour cette période'**
  String get reportNoData;

  /// No description provided for @reportUncategorized.
  ///
  /// In fr, this message translates to:
  /// **'Sans catégorie'**
  String get reportUncategorized;

  /// No description provided for @reportCashFlow.
  ///
  /// In fr, this message translates to:
  /// **'Flux de trésorerie'**
  String get reportCashFlow;

  /// No description provided for @reportCashFlowNet.
  ///
  /// In fr, this message translates to:
  /// **'Net'**
  String get reportCashFlowNet;

  /// No description provided for @reportStats.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get reportStats;

  /// No description provided for @reportSavingsRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux d\'épargne'**
  String get reportSavingsRate;

  /// No description provided for @reportAvgPerDay.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne par jour'**
  String get reportAvgPerDay;

  /// No description provided for @reportTxCount.
  ///
  /// In fr, this message translates to:
  /// **'Opérations'**
  String get reportTxCount;

  /// No description provided for @reportBiggest.
  ///
  /// In fr, this message translates to:
  /// **'Plus grosse dépense'**
  String get reportBiggest;

  /// No description provided for @reportMostFrequent.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie la plus fréquente'**
  String get reportMostFrequent;

  /// No description provided for @reportTopPayee.
  ///
  /// In fr, this message translates to:
  /// **'Bénéficiaire principal'**
  String get reportTopPayee;

  /// No description provided for @reportByTag.
  ///
  /// In fr, this message translates to:
  /// **'Par étiquette'**
  String get reportByTag;

  /// No description provided for @reportByAccount.
  ///
  /// In fr, this message translates to:
  /// **'Par compte'**
  String get reportByAccount;

  /// No description provided for @reportExportCsv.
  ///
  /// In fr, this message translates to:
  /// **'Exporter en CSV'**
  String get reportExportCsv;

  /// No description provided for @reportExportPdf.
  ///
  /// In fr, this message translates to:
  /// **'Exporter en PDF'**
  String get reportExportPdf;

  /// No description provided for @reportShowDonut.
  ///
  /// In fr, this message translates to:
  /// **'Anneau'**
  String get reportShowDonut;

  /// No description provided for @reportShowBars.
  ///
  /// In fr, this message translates to:
  /// **'Barres'**
  String get reportShowBars;

  /// No description provided for @categoryDetailSubcategories.
  ///
  /// In fr, this message translates to:
  /// **'Sous-catégories'**
  String get categoryDetailSubcategories;

  /// No description provided for @categoryDetailTrend.
  ///
  /// In fr, this message translates to:
  /// **'Évolution sur 6 périodes'**
  String get categoryDetailTrend;

  /// No description provided for @categoryDetailTx.
  ///
  /// In fr, this message translates to:
  /// **'Opérations de la période'**
  String get categoryDetailTx;

  /// No description provided for @insightsAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les alertes'**
  String get insightsAll;

  /// No description provided for @planTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon plan'**
  String get planTitle;

  /// No description provided for @planAddTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get planAddTitle;

  /// No description provided for @planNewBudget.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau budget'**
  String get planNewBudget;

  /// No description provided for @planNewGoal.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel objectif'**
  String get planNewGoal;

  /// No description provided for @planNewRecurring.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle opération récurrente'**
  String get planNewRecurring;

  /// No description provided for @planNewDebt.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle dette ou prêt'**
  String get planNewDebt;

  /// No description provided for @planGoals.
  ///
  /// In fr, this message translates to:
  /// **'Objectifs'**
  String get planGoals;

  /// No description provided for @planBudgets.
  ///
  /// In fr, this message translates to:
  /// **'Budgets'**
  String get planBudgets;

  /// No description provided for @planRecurring.
  ///
  /// In fr, this message translates to:
  /// **'Récurrentes et factures'**
  String get planRecurring;

  /// No description provided for @planDebts.
  ///
  /// In fr, this message translates to:
  /// **'Dettes et prêts'**
  String get planDebts;

  /// No description provided for @budgetsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun budget. Fixez une limite pour mieux maîtriser vos dépenses.'**
  String get budgetsEmpty;

  /// No description provided for @budgetEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le budget'**
  String get budgetEdit;

  /// No description provided for @budgetName.
  ///
  /// In fr, this message translates to:
  /// **'Nom (facultatif)'**
  String get budgetName;

  /// No description provided for @budgetAllCategories.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les dépenses'**
  String get budgetAllCategories;

  /// No description provided for @budgetCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get budgetCategory;

  /// No description provided for @budgetIncludeSub.
  ///
  /// In fr, this message translates to:
  /// **'Inclure les sous-catégories'**
  String get budgetIncludeSub;

  /// No description provided for @budgetPeriodLabel.
  ///
  /// In fr, this message translates to:
  /// **'Période'**
  String get budgetPeriodLabel;

  /// No description provided for @budgetRollover.
  ///
  /// In fr, this message translates to:
  /// **'Reporter le reste'**
  String get budgetRollover;

  /// No description provided for @budgetThresholds.
  ///
  /// In fr, this message translates to:
  /// **'Alertes à 80 % et 100 %'**
  String get budgetThresholds;

  /// No description provided for @budgetSpent.
  ///
  /// In fr, this message translates to:
  /// **'Dépensé'**
  String get budgetSpent;

  /// No description provided for @budgetLeft.
  ///
  /// In fr, this message translates to:
  /// **'Reste'**
  String get budgetLeft;

  /// No description provided for @budgetOverBy.
  ///
  /// In fr, this message translates to:
  /// **'Dépassement'**
  String get budgetOverBy;

  /// No description provided for @budgetPerDay.
  ///
  /// In fr, this message translates to:
  /// **'{amount} / jour'**
  String budgetPerDay(String amount);

  /// No description provided for @budgetProjected.
  ///
  /// In fr, this message translates to:
  /// **'Projection : {amount}'**
  String budgetProjected(String amount);

  /// No description provided for @budgetDaysLeft.
  ///
  /// In fr, this message translates to:
  /// **'{n} jours restants'**
  String budgetDaysLeft(int n);

  /// No description provided for @budgetHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get budgetHistory;

  /// No description provided for @budgetRolloverIn.
  ///
  /// In fr, this message translates to:
  /// **'Report : {amount}'**
  String budgetRolloverIn(String amount);

  /// No description provided for @budgetTransactions.
  ///
  /// In fr, this message translates to:
  /// **'Opérations du budget'**
  String get budgetTransactions;

  /// No description provided for @budgetDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce budget ?'**
  String get budgetDeleteConfirm;

  /// No description provided for @goalsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun objectif. Créez-en un pour épargner avec un but.'**
  String get goalsEmpty;

  /// No description provided for @goalNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel objectif'**
  String get goalNew;

  /// No description provided for @goalEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'objectif'**
  String get goalEdit;

  /// No description provided for @goalTarget.
  ///
  /// In fr, this message translates to:
  /// **'Montant cible'**
  String get goalTarget;

  /// No description provided for @goalDeadline.
  ///
  /// In fr, this message translates to:
  /// **'Échéance'**
  String get goalDeadline;

  /// No description provided for @goalStart.
  ///
  /// In fr, this message translates to:
  /// **'Début'**
  String get goalStart;

  /// No description provided for @goalTracking.
  ///
  /// In fr, this message translates to:
  /// **'Suivi'**
  String get goalTracking;

  /// No description provided for @goalTrackManual.
  ///
  /// In fr, this message translates to:
  /// **'Manuel'**
  String get goalTrackManual;

  /// No description provided for @goalTrackLinked.
  ///
  /// In fr, this message translates to:
  /// **'Lié à un compte'**
  String get goalTrackLinked;

  /// No description provided for @goalLinkedAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte lié'**
  String get goalLinkedAccount;

  /// No description provided for @goalSaved.
  ///
  /// In fr, this message translates to:
  /// **'Épargné'**
  String get goalSaved;

  /// No description provided for @goalRemaining.
  ///
  /// In fr, this message translates to:
  /// **'Reste'**
  String get goalRemaining;

  /// No description provided for @goalContribute.
  ///
  /// In fr, this message translates to:
  /// **'Verser'**
  String get goalContribute;

  /// No description provided for @goalWithdraw.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get goalWithdraw;

  /// No description provided for @goalAmountField.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get goalAmountField;

  /// No description provided for @goalFromAccount.
  ///
  /// In fr, this message translates to:
  /// **'Depuis le compte'**
  String get goalFromAccount;

  /// No description provided for @goalOnTrack.
  ///
  /// In fr, this message translates to:
  /// **'Dans les temps'**
  String get goalOnTrack;

  /// No description provided for @goalBehind.
  ///
  /// In fr, this message translates to:
  /// **'En retard de {n} %'**
  String goalBehind(int n);

  /// No description provided for @goalCompletedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Atteint'**
  String get goalCompletedLabel;

  /// No description provided for @goalNoDeadline.
  ///
  /// In fr, this message translates to:
  /// **'Sans échéance'**
  String get goalNoDeadline;

  /// No description provided for @goalNeeded.
  ///
  /// In fr, this message translates to:
  /// **'{amount} par mois nécessaires'**
  String goalNeeded(String amount);

  /// No description provided for @goalEstimated.
  ///
  /// In fr, this message translates to:
  /// **'Estimation : {date}'**
  String goalEstimated(String date);

  /// No description provided for @goalCelebrate.
  ///
  /// In fr, this message translates to:
  /// **'Objectif atteint ! Bravo 🎉'**
  String get goalCelebrate;

  /// No description provided for @goalMarkComplete.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme atteint'**
  String get goalMarkComplete;

  /// No description provided for @goalReactivate.
  ///
  /// In fr, this message translates to:
  /// **'Réactiver'**
  String get goalReactivate;

  /// No description provided for @goalContributions.
  ///
  /// In fr, this message translates to:
  /// **'Versements'**
  String get goalContributions;

  /// No description provided for @goalDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cet objectif et ses versements ?'**
  String get goalDeleteConfirm;

  /// No description provided for @recurringEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune opération récurrente. Ajoutez vos factures et abonnements.'**
  String get recurringEmpty;

  /// No description provided for @recurringNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle récurrence'**
  String get recurringNew;

  /// No description provided for @recurringEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la récurrence'**
  String get recurringEdit;

  /// No description provided for @recurringNext.
  ///
  /// In fr, this message translates to:
  /// **'Prochaine : {date}'**
  String recurringNext(String date);

  /// No description provided for @recurringPaused.
  ///
  /// In fr, this message translates to:
  /// **'En pause'**
  String get recurringPaused;

  /// No description provided for @recurringSkipNext.
  ///
  /// In fr, this message translates to:
  /// **'Passer la prochaine'**
  String get recurringSkipNext;

  /// No description provided for @recurringDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la récurrence'**
  String get recurringDeleteTitle;

  /// No description provided for @recurringKeepPast.
  ///
  /// In fr, this message translates to:
  /// **'Garder les opérations passées'**
  String get recurringKeepPast;

  /// No description provided for @recurringDeletePast.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer aussi les opérations passées'**
  String get recurringDeletePast;

  /// No description provided for @recurringActive.
  ///
  /// In fr, this message translates to:
  /// **'Active'**
  String get recurringActive;

  /// No description provided for @debtsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune dette ni prêt.'**
  String get debtsEmpty;

  /// No description provided for @debtNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle dette'**
  String get debtNew;

  /// No description provided for @debtEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la dette'**
  String get debtEdit;

  /// No description provided for @debtIOwe.
  ///
  /// In fr, this message translates to:
  /// **'Je dois'**
  String get debtIOwe;

  /// No description provided for @debtOwedToMe.
  ///
  /// In fr, this message translates to:
  /// **'On me doit'**
  String get debtOwedToMe;

  /// No description provided for @debtPerson.
  ///
  /// In fr, this message translates to:
  /// **'Personne'**
  String get debtPerson;

  /// No description provided for @debtAmountField.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get debtAmountField;

  /// No description provided for @debtDue.
  ///
  /// In fr, this message translates to:
  /// **'Échéance'**
  String get debtDue;

  /// No description provided for @debtPaid.
  ///
  /// In fr, this message translates to:
  /// **'Payé'**
  String get debtPaid;

  /// No description provided for @debtRemaining.
  ///
  /// In fr, this message translates to:
  /// **'Reste'**
  String get debtRemaining;

  /// No description provided for @debtAddPayment.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un paiement'**
  String get debtAddPayment;

  /// No description provided for @debtSettle.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme soldé'**
  String get debtSettle;

  /// No description provided for @debtReopen.
  ///
  /// In fr, this message translates to:
  /// **'Rouvrir'**
  String get debtReopen;

  /// No description provided for @debtOverdue.
  ///
  /// In fr, this message translates to:
  /// **'En retard'**
  String get debtOverdue;

  /// No description provided for @debtSettled.
  ///
  /// In fr, this message translates to:
  /// **'Soldé'**
  String get debtSettled;

  /// No description provided for @debtRecordOnly.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer sans toucher aux comptes'**
  String get debtRecordOnly;

  /// No description provided for @debtPayments.
  ///
  /// In fr, this message translates to:
  /// **'Paiements'**
  String get debtPayments;

  /// No description provided for @debtStart.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get debtStart;

  /// No description provided for @debtDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette dette ?'**
  String get debtDeleteConfirm;

  /// No description provided for @debtOpenTab.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get debtOpenTab;

  /// No description provided for @debtSettledTab.
  ///
  /// In fr, this message translates to:
  /// **'Soldées'**
  String get debtSettledTab;

  /// No description provided for @notifCenterTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifCenterTitle;

  /// No description provided for @notifCenterEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification'**
  String get notifCenterEmpty;

  /// No description provided for @notifMarkAllRead.
  ///
  /// In fr, this message translates to:
  /// **'Tout marquer comme lu'**
  String get notifMarkAllRead;

  /// No description provided for @notifClear.
  ///
  /// In fr, this message translates to:
  /// **'Effacer l\'historique'**
  String get notifClear;

  /// No description provided for @notifSettingsMaster.
  ///
  /// In fr, this message translates to:
  /// **'Activer les notifications'**
  String get notifSettingsMaster;

  /// No description provided for @notifSettingsBudget.
  ///
  /// In fr, this message translates to:
  /// **'Alertes de budget'**
  String get notifSettingsBudget;

  /// No description provided for @notifSettingsBills.
  ///
  /// In fr, this message translates to:
  /// **'Factures et récurrentes'**
  String get notifSettingsBills;

  /// No description provided for @notifSettingsGoals.
  ///
  /// In fr, this message translates to:
  /// **'Objectifs'**
  String get notifSettingsGoals;

  /// No description provided for @notifSettingsDebts.
  ///
  /// In fr, this message translates to:
  /// **'Dettes et prêts'**
  String get notifSettingsDebts;

  /// No description provided for @notifSettingsDaily.
  ///
  /// In fr, this message translates to:
  /// **'Rappel quotidien'**
  String get notifSettingsDaily;

  /// No description provided for @notifSettingsDailyTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure du rappel'**
  String get notifSettingsDailyTime;

  /// No description provided for @notifSettingsBackup.
  ///
  /// In fr, this message translates to:
  /// **'Rappels de sauvegarde'**
  String get notifSettingsBackup;

  /// No description provided for @notifPermissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'Les notifications sont désactivées pour Floos dans les réglages du système.'**
  String get notifPermissionDenied;

  /// No description provided for @notifRequestPermission.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser les notifications'**
  String get notifRequestPermission;

  /// No description provided for @notifSendTest.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer une notification test'**
  String get notifSendTest;

  /// No description provided for @backupNow.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder maintenant'**
  String get backupNow;

  /// No description provided for @backupPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe (facultatif)'**
  String get backupPassword;

  /// No description provided for @backupPasswordHint.
  ///
  /// In fr, this message translates to:
  /// **'Laissez vide pour une sauvegarde non chiffrée'**
  String get backupPasswordHint;

  /// No description provided for @backupCreated.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde créée'**
  String get backupCreated;

  /// No description provided for @backupShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager la sauvegarde'**
  String get backupShare;

  /// No description provided for @backupAuto.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde automatique'**
  String get backupAuto;

  /// No description provided for @backupAutoOff.
  ///
  /// In fr, this message translates to:
  /// **'Désactivée'**
  String get backupAutoOff;

  /// No description provided for @backupAutoDaily.
  ///
  /// In fr, this message translates to:
  /// **'Quotidienne'**
  String get backupAutoDaily;

  /// No description provided for @backupAutoWeekly.
  ///
  /// In fr, this message translates to:
  /// **'Hebdomadaire'**
  String get backupAutoWeekly;

  /// No description provided for @backupAutoMonthly.
  ///
  /// In fr, this message translates to:
  /// **'Mensuelle'**
  String get backupAutoMonthly;

  /// No description provided for @backupKeep.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegardes conservées'**
  String get backupKeep;

  /// No description provided for @backupLast.
  ///
  /// In fr, this message translates to:
  /// **'Dernière sauvegarde : {date}'**
  String backupLast(String date);

  /// No description provided for @backupNever.
  ///
  /// In fr, this message translates to:
  /// **'Aucune sauvegarde pour l\'instant'**
  String get backupNever;

  /// No description provided for @backupRestore.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer une sauvegarde'**
  String get backupRestore;

  /// No description provided for @backupRestorePreview.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde du {date} · {n} opérations'**
  String backupRestorePreview(String date, int n);

  /// No description provided for @backupRestoreWarning.
  ///
  /// In fr, this message translates to:
  /// **'La restauration remplace toutes les données actuelles. Une sauvegarde de sécurité sera créée avant.'**
  String get backupRestoreWarning;

  /// No description provided for @backupRestoreDone.
  ///
  /// In fr, this message translates to:
  /// **'Restauration terminée'**
  String get backupRestoreDone;

  /// No description provided for @backupEncrypted.
  ///
  /// In fr, this message translates to:
  /// **'Cette sauvegarde est chiffrée. Saisissez le mot de passe.'**
  String get backupEncrypted;

  /// No description provided for @dataExportCsv.
  ///
  /// In fr, this message translates to:
  /// **'Exporter les opérations (CSV)'**
  String get dataExportCsv;

  /// No description provided for @dataImportCsv.
  ///
  /// In fr, this message translates to:
  /// **'Importer un fichier CSV'**
  String get dataImportCsv;

  /// No description provided for @dataDeleteAll.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer toutes les données'**
  String get dataDeleteAll;

  /// No description provided for @dataDeleteAllBody.
  ///
  /// In fr, this message translates to:
  /// **'Toutes vos données seront définitivement supprimées. Tapez SUPPRIMER pour confirmer.'**
  String get dataDeleteAllBody;

  /// No description provided for @dataDeleteWord.
  ///
  /// In fr, this message translates to:
  /// **'SUPPRIMER'**
  String get dataDeleteWord;

  /// No description provided for @dataDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Données supprimées'**
  String get dataDeleted;

  /// No description provided for @csvStepFile.
  ///
  /// In fr, this message translates to:
  /// **'Fichier'**
  String get csvStepFile;

  /// No description provided for @csvStepMapping.
  ///
  /// In fr, this message translates to:
  /// **'Colonnes'**
  String get csvStepMapping;

  /// No description provided for @csvStepReview.
  ///
  /// In fr, this message translates to:
  /// **'Vérification'**
  String get csvStepReview;

  /// No description provided for @csvStepImport.
  ///
  /// In fr, this message translates to:
  /// **'Import'**
  String get csvStepImport;

  /// No description provided for @csvPickFile.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un fichier CSV'**
  String get csvPickFile;

  /// No description provided for @csvDateFormat.
  ///
  /// In fr, this message translates to:
  /// **'Format de date'**
  String get csvDateFormat;

  /// No description provided for @csvDecimalComma.
  ///
  /// In fr, this message translates to:
  /// **'Virgule décimale'**
  String get csvDecimalComma;

  /// No description provided for @csvNotMapped.
  ///
  /// In fr, this message translates to:
  /// **'— Non importé —'**
  String get csvNotMapped;

  /// No description provided for @csvRows.
  ///
  /// In fr, this message translates to:
  /// **'{n} lignes valides, {e} erreurs, {d} doublons'**
  String csvRows(int n, int e, int d);

  /// No description provided for @csvImportDuplicates.
  ///
  /// In fr, this message translates to:
  /// **'Importer aussi les doublons'**
  String get csvImportDuplicates;

  /// No description provided for @csvUnknownAccounts.
  ///
  /// In fr, this message translates to:
  /// **'Comptes inconnus (créés automatiquement)'**
  String get csvUnknownAccounts;

  /// No description provided for @csvUnknownCategories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories inconnues (créées automatiquement)'**
  String get csvUnknownCategories;

  /// No description provided for @csvDoImport.
  ///
  /// In fr, this message translates to:
  /// **'Importer'**
  String get csvDoImport;

  /// No description provided for @csvReport.
  ///
  /// In fr, this message translates to:
  /// **'{n} importées, {s} ignorées, {e} erreurs'**
  String csvReport(int n, int s, int e);

  /// No description provided for @csvFallbackAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte par défaut'**
  String get csvFallbackAccount;

  /// No description provided for @csvFieldDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get csvFieldDate;

  /// No description provided for @csvFieldTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure'**
  String get csvFieldTime;

  /// No description provided for @csvFieldType.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get csvFieldType;

  /// No description provided for @csvFieldAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get csvFieldAmount;

  /// No description provided for @csvFieldCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Devise'**
  String get csvFieldCurrency;

  /// No description provided for @csvFieldAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get csvFieldAccount;

  /// No description provided for @csvFieldToAccount.
  ///
  /// In fr, this message translates to:
  /// **'Vers le compte'**
  String get csvFieldToAccount;

  /// No description provided for @csvFieldToAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant reçu'**
  String get csvFieldToAmount;

  /// No description provided for @csvFieldCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get csvFieldCategory;

  /// No description provided for @csvFieldParentCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie parente'**
  String get csvFieldParentCategory;

  /// No description provided for @csvFieldPayee.
  ///
  /// In fr, this message translates to:
  /// **'Bénéficiaire'**
  String get csvFieldPayee;

  /// No description provided for @csvFieldNote.
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get csvFieldNote;

  /// No description provided for @csvFieldTags.
  ///
  /// In fr, this message translates to:
  /// **'Étiquettes'**
  String get csvFieldTags;

  /// No description provided for @csvFieldId.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant'**
  String get csvFieldId;
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
