import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @updateName.
  ///
  /// In en, this message translates to:
  /// **'Update Name'**
  String get updateName;

  /// No description provided for @nameUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Name updated successfully!'**
  String get nameUpdatedSuccess;

  /// No description provided for @nameUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error updating name'**
  String get nameUpdateError;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @passwordUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully!'**
  String get passwordUpdatedSuccess;

  /// No description provided for @passwordUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error updating password'**
  String get passwordUpdateError;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get language;

  /// No description provided for @newsTitle.
  ///
  /// In en, this message translates to:
  /// **'PheliFla News'**
  String get newsTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @latestNews.
  ///
  /// In en, this message translates to:
  /// **'Latest Mengão News:'**
  String get latestNews;

  /// No description provided for @storeTitle.
  ///
  /// In en, this message translates to:
  /// **'PheliFla Official Store'**
  String get storeTitle;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @noProducts.
  ///
  /// In en, this message translates to:
  /// **'No products found.'**
  String get noProducts;

  /// No description provided for @invalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid product URL.'**
  String get invalidUrl;

  /// No description provided for @openLinkError.
  ///
  /// In en, this message translates to:
  /// **'Error trying to open link: {error}'**
  String openLinkError(Object error);

  /// No description provided for @openLinkFail.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link: {url}'**
  String openLinkFail(Object url);

  /// No description provided for @agendaTitle.
  ///
  /// In en, this message translates to:
  /// **'Red-Black Schedule'**
  String get agendaTitle;

  /// No description provided for @newsGeTitle.
  ///
  /// In en, this message translates to:
  /// **'GE News'**
  String get newsGeTitle;

  /// No description provided for @colunaTitle.
  ///
  /// In en, this message translates to:
  /// **'Coluna do Fla'**
  String get colunaTitle;

  /// No description provided for @youtubeTitle.
  ///
  /// In en, this message translates to:
  /// **'PheliFla Videos'**
  String get youtubeTitle;

  /// No description provided for @bottomNavGe.
  ///
  /// In en, this message translates to:
  /// **'GE'**
  String get bottomNavGe;

  /// No description provided for @bottomNavColuna.
  ///
  /// In en, this message translates to:
  /// **'Coluna'**
  String get bottomNavColuna;

  /// No description provided for @bottomNavYoutube.
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get bottomNavYoutube;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'Todos'**
  String get all;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryShirtsAndCaps.
  ///
  /// In en, this message translates to:
  /// **'Shirts and Caps'**
  String get categoryShirtsAndCaps;

  /// No description provided for @categoryShirts.
  ///
  /// In en, this message translates to:
  /// **'Camisas'**
  String get categoryShirts;

  /// No description provided for @categoryCaps.
  ///
  /// In en, this message translates to:
  /// **'Bonés'**
  String get categoryCaps;

  /// No description provided for @categoryAccessories.
  ///
  /// In en, this message translates to:
  /// **'Acessórios'**
  String get categoryAccessories;

  /// No description provided for @categoryMugs.
  ///
  /// In en, this message translates to:
  /// **'Canecas'**
  String get categoryMugs;

  /// No description provided for @categoryCropped.
  ///
  /// In en, this message translates to:
  /// **'Cropped'**
  String get categoryCropped;

  /// No description provided for @categoryBody.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get categoryBody;

  /// No description provided for @categoryKit.
  ///
  /// In en, this message translates to:
  /// **'Kit'**
  String get categoryKit;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderUnisex.
  ///
  /// In en, this message translates to:
  /// **'Unisex'**
  String get genderUnisex;

  /// No description provided for @typeChild.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get typeChild;

  /// No description provided for @typeAdult.
  ///
  /// In en, this message translates to:
  /// **'Adult'**
  String get typeAdult;

  /// No description provided for @storeCode.
  ///
  /// In en, this message translates to:
  /// **'Store Code'**
  String get storeCode;

  /// No description provided for @assinaturaPlus.
  ///
  /// In en, this message translates to:
  /// **'Plus Subscription'**
  String get assinaturaPlus;

  /// No description provided for @bemVindoAoPlus.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Flamengo Plus!'**
  String get bemVindoAoPlus;

  /// No description provided for @descricaoAssinaturaPlus.
  ///
  /// In en, this message translates to:
  /// **'Unlock exclusive benefits and help keep the app running.'**
  String get descricaoAssinaturaPlus;

  /// No description provided for @semAnuncios.
  ///
  /// In en, this message translates to:
  /// **'Ad-free experience'**
  String get semAnuncios;

  /// No description provided for @acessoAntecipadoNoticias.
  ///
  /// In en, this message translates to:
  /// **'Early access to news'**
  String get acessoAntecipadoNoticias;

  /// No description provided for @chatExclusivo.
  ///
  /// In en, this message translates to:
  /// **'Exclusive chat for subscribers'**
  String get chatExclusivo;

  /// No description provided for @ajudeProjeto.
  ///
  /// In en, this message translates to:
  /// **'Support the project'**
  String get ajudeProjeto;

  /// No description provided for @assinarAgora.
  ///
  /// In en, this message translates to:
  /// **'Subscribe now'**
  String get assinarAgora;

  /// No description provided for @termosAssinatura.
  ///
  /// In en, this message translates to:
  /// **'Terms and cancellation policy'**
  String get termosAssinatura;

  /// No description provided for @assinaturaEmBreve.
  ///
  /// In en, this message translates to:
  /// **'Subscription system coming soon'**
  String get assinaturaEmBreve;

  /// No description provided for @local_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get local_all;

  /// No description provided for @local_categoryShirts.
  ///
  /// In en, this message translates to:
  /// **'Shirts'**
  String get local_categoryShirts;

  /// No description provided for @local_categoryCaps.
  ///
  /// In en, this message translates to:
  /// **'Caps'**
  String get local_categoryCaps;

  /// No description provided for @local_categoryAccessories.
  ///
  /// In en, this message translates to:
  /// **'Accessories'**
  String get local_categoryAccessories;

  /// No description provided for @local_categoryMugs.
  ///
  /// In en, this message translates to:
  /// **'Mugs'**
  String get local_categoryMugs;

  /// No description provided for @local_categoryCropped.
  ///
  /// In en, this message translates to:
  /// **'Cropped'**
  String get local_categoryCropped;

  /// No description provided for @local_categoryBody.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get local_categoryBody;

  /// No description provided for @local_categoryKit.
  ///
  /// In en, this message translates to:
  /// **'Kit'**
  String get local_categoryKit;

  /// No description provided for @local_genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get local_genderMale;

  /// No description provided for @local_genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get local_genderFemale;

  /// No description provided for @local_escolhaLoja.
  ///
  /// In en, this message translates to:
  /// **'Choose your store'**
  String get local_escolhaLoja;
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
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
