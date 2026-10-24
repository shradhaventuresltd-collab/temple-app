import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_or.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('bn'),
    Locale('hi'),
    Locale('kn'),
    Locale('ml'),
    Locale('mr'),
    Locale('or'),
    Locale('ta'),
    Locale('te'),
  ];

  /// App name in the policy header, task switcher, and error fallback copy.
  ///
  /// In en, this message translates to:
  /// **'Temple Directory India'**
  String get appName;

  /// Home and drawer title.
  ///
  /// In en, this message translates to:
  /// **'Temple Directory'**
  String get appTitleShort;

  /// Drawer subtitle under the app title.
  ///
  /// In en, this message translates to:
  /// **'India'**
  String get india;

  /// Drawer navigation label for the home screen.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Browse-all label in the drawer and empty filter title.
  ///
  /// In en, this message translates to:
  /// **'All Temples'**
  String get allTemples;

  /// Browse title when only a search is active, and the search section is separate.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Drawer section heading above the search field.
  ///
  /// In en, this message translates to:
  /// **'SEARCH'**
  String get searchSection;

  /// Drawer section heading above the filter chips.
  ///
  /// In en, this message translates to:
  /// **'FILTERS'**
  String get filtersSection;

  /// Drawer section heading above the directory blurb.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get aboutSection;

  /// Drawer item and licences screen title.
  ///
  /// In en, this message translates to:
  /// **'Licences'**
  String get licences;

  /// Drawer item that opens ad privacy options.
  ///
  /// In en, this message translates to:
  /// **'Ad privacy choices'**
  String get adPrivacyChoices;

  /// Tooltip for the home overflow menu.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTooltip;

  /// Home overflow and debug action that opens admin sign-in.
  ///
  /// In en, this message translates to:
  /// **'Admin sign-in'**
  String get adminSignIn;

  /// Debug home action when the signed-in user is not an admin.
  ///
  /// In en, this message translates to:
  /// **'Not admin'**
  String get notAdmin;

  /// Admin screen title and debug tooltip.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// Button that tries a failed load or upload again.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Near-me button after a location failure.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// Dismiss button on the delete-temple dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Confirm button that deletes a temple.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Clears the active directory filters.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Soft-update banner action that opens the Play Store.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// Dismisses the soft-update banner or the location rationale.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// Opens the temple form for an existing temple.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Opens the temple form to add photos.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// Signs the admin out.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// Submits the admin sign-in form.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// Divider between seeding and creating a temple.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// Accepts approximate location on the near-me rationale.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// Home mosaic kicker.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// Home mosaic headline.
  ///
  /// In en, this message translates to:
  /// **'India\'s Sacred Temples'**
  String get indiasSacredTemples;

  /// Home mosaic subtitle when the directory is empty.
  ///
  /// In en, this message translates to:
  /// **'No temples loaded yet'**
  String get noTemplesLoadedYet;

  /// Home mosaic subtitle with the loaded directory size. The word stays temples for every count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} temples across India} other{{count} temples across India}}'**
  String templesAcrossIndia(int count);

  /// Drawer about blurb when no temples are loaded.
  ///
  /// In en, this message translates to:
  /// **'Explore famous temples across Tamil Nadu, Kerala, Karnataka, Andhra Pradesh, Telangana, Gujarat, Odisha, Uttar Pradesh, Jammu and Kashmir, Maharashtra, Rajasthan, West Bengal, Madhya Pradesh, Bihar, and Himachal Pradesh. Discover histories, legends, timings and specialities — all in one curated directory.'**
  String get drawerAboutEmpty;

  /// Drawer about blurb including the loaded temple count. The word stays temples for every count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Explore {count} famous temples across Tamil Nadu, Kerala, Karnataka, Andhra Pradesh, Telangana, Gujarat, Odisha, Uttar Pradesh, Jammu and Kashmir, Maharashtra, Rajasthan, West Bengal, Madhya Pradesh, Bihar, and Himachal Pradesh. Discover histories, legends, timings and specialities — all in one curated directory.} other{Explore {count} famous temples across Tamil Nadu, Kerala, Karnataka, Andhra Pradesh, Telangana, Gujarat, Odisha, Uttar Pradesh, Jammu and Kashmir, Maharashtra, Rajasthan, West Bengal, Madhya Pradesh, Bihar, and Himachal Pradesh. Discover histories, legends, timings and specialities — all in one curated directory.}}'**
  String drawerAboutWithCount(int count);

  /// Home loading title.
  ///
  /// In en, this message translates to:
  /// **'Loading temples…'**
  String get loadingTemplesEllipsis;

  /// Home loading detail.
  ///
  /// In en, this message translates to:
  /// **'Preparing the directory. This usually takes a moment.'**
  String get preparingDirectory;

  /// Home error title.
  ///
  /// In en, this message translates to:
  /// **'Could not load temples.'**
  String get couldNotLoadTemplesPeriod;

  /// Home error detail when no shard message is available.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get checkConnection;

  /// Home empty-directory title.
  ///
  /// In en, this message translates to:
  /// **'No temples available yet.'**
  String get noTemplesAvailable;

  /// Home empty-directory detail.
  ///
  /// In en, this message translates to:
  /// **'The directory came back empty. Tap Retry, or try again later.'**
  String get directoryEmptyRetry;

  /// Home button that opens the directory. Zero keeps the uncounted label.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Browse temples} one{Browse {count} Temple} other{Browse {count} Temples}}'**
  String browseTempleCount(int count);

  /// Drawer button that opens the filtered directory.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Browse {count} Temple} other{Browse {count} Temples}}'**
  String drawerBrowseTempleCount(int count);

  /// Hint under the home browse button.
  ///
  /// In en, this message translates to:
  /// **'Open the directory for temple cards, search, and filters. You can also use the menu (☰).'**
  String get openDirectoryHint;

  /// Note under the home browse actions.
  ///
  /// In en, this message translates to:
  /// **'Heritage reading continues below'**
  String get heritageContinuesBelow;

  /// Heading of the home heritage essay.
  ///
  /// In en, this message translates to:
  /// **'Temple Heritage of India'**
  String get templeHeritageTitle;

  /// Subtitle of the home heritage essay.
  ///
  /// In en, this message translates to:
  /// **'A comprehensive exploration of India\'s sacred architectural legacy'**
  String get templeHeritageSubtitle;

  /// Detail screen when the temple document is missing.
  ///
  /// In en, this message translates to:
  /// **'Could not load this temple.'**
  String get couldNotLoadThisTemple;

  /// Snack bar when maps cannot be opened.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open directions on this device.'**
  String get couldNotOpenDirections;

  /// Detail line for the listed deity.
  ///
  /// In en, this message translates to:
  /// **'Listed focus: {deity}'**
  String listedFocus(String deity);

  /// Shown when the detail document came from cache.
  ///
  /// In en, this message translates to:
  /// **'This page may be out of date.'**
  String get pageMayBeOutOfDate;

  /// Detail card title for the address.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// Timings card when the listing has no hours.
  ///
  /// In en, this message translates to:
  /// **'Not listed in this entry.'**
  String get notListedInEntry;

  /// Detail card title for latitude and longitude.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get coordinates;

  /// Coordinate line. Digits stay Latin.
  ///
  /// In en, this message translates to:
  /// **'{lat}° N, {lng}° E'**
  String coordinatesNorthEast(String lat, String lng);

  /// Detail section heading for directions.
  ///
  /// In en, this message translates to:
  /// **'How to Reach'**
  String get howToReach;

  /// Button that opens maps.
  ///
  /// In en, this message translates to:
  /// **'Get Directions'**
  String get getDirections;

  /// Detail section heading for the description.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Detail section heading and admin form label.
  ///
  /// In en, this message translates to:
  /// **'Specialities'**
  String get specialities;

  /// Detail gallery page indicator.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String galleryPosition(int current, int total);

  /// Placeholder title when no verified photo is on file.
  ///
  /// In en, this message translates to:
  /// **'Photo pending'**
  String get photoPending;

  /// Placeholder caption under Photo pending.
  ///
  /// In en, this message translates to:
  /// **'No verified photograph is on file.'**
  String get noVerifiedPhotograph;

  /// Screen-reader label for the photo placeholder.
  ///
  /// In en, this message translates to:
  /// **'Photo pending. No verified photograph is on file.'**
  String get photoPendingSemantics;

  /// Screen-reader label for a mosaic tile that is still loading.
  ///
  /// In en, this message translates to:
  /// **'Temple photo'**
  String get templePhotoSemantics;

  /// Chip for a monument or archaeological site.
  ///
  /// In en, this message translates to:
  /// **'Heritage visit'**
  String get heritageVisit;

  /// Chip when notes describe continuing worship and no tradition chip is shown.
  ///
  /// In en, this message translates to:
  /// **'Living temple'**
  String get livingTemple;

  /// Timings heading for a heritage visit.
  ///
  /// In en, this message translates to:
  /// **'Visiting hours'**
  String get visitingHours;

  /// Timings heading for a living or unspecified site, and the admin form label.
  ///
  /// In en, this message translates to:
  /// **'Timings'**
  String get timings;

  /// Story heading when a tradition chip is shown.
  ///
  /// In en, this message translates to:
  /// **'About this place'**
  String get aboutThisPlace;

  /// Story heading for a living temple.
  ///
  /// In en, this message translates to:
  /// **'Temple story'**
  String get templeStory;

  /// Story heading for a heritage visit.
  ///
  /// In en, this message translates to:
  /// **'Site history'**
  String get siteHistory;

  /// Story heading when the listing is neutral.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get background;

  /// Tradition chip.
  ///
  /// In en, this message translates to:
  /// **'Jain'**
  String get traditionJain;

  /// Tradition chip.
  ///
  /// In en, this message translates to:
  /// **'Buddhist'**
  String get traditionBuddhist;

  /// Tradition chip.
  ///
  /// In en, this message translates to:
  /// **'Sikh'**
  String get traditionSikh;

  /// Opening sentence of the detail framing note.
  ///
  /// In en, this message translates to:
  /// **'Jain pilgrimage site.'**
  String get jainPilgrimageSite;

  /// Opening sentence of the detail framing note.
  ///
  /// In en, this message translates to:
  /// **'Buddhist pilgrimage site.'**
  String get buddhistPilgrimageSite;

  /// Opening sentence of the detail framing note.
  ///
  /// In en, this message translates to:
  /// **'Sikh site.'**
  String get sikhSite;

  /// Framing note for a living temple with no tradition chip.
  ///
  /// In en, this message translates to:
  /// **'Notes describe continuing worship at a living temple. The hours below are published text from the listing.'**
  String get livingTempleUnspecifiedNote;

  /// Framing note for a living site that already has a tradition sentence.
  ///
  /// In en, this message translates to:
  /// **'Notes describe continuing observance. The hours below are published text from the listing.'**
  String get livingTempleTraditionNote;

  /// Framing note for a heritage visit.
  ///
  /// In en, this message translates to:
  /// **'Heritage visit. The hours below are visitor access for a monument or archaeological site.'**
  String get monumentVisitNote;

  /// Framing note when the listing is ambiguous.
  ///
  /// In en, this message translates to:
  /// **'These notes do not say clearly whether worship continues or this is only a monument visit.'**
  String get neutralFramingNote;

  /// Caveat when the listing has no timings.
  ///
  /// In en, this message translates to:
  /// **'No visiting hours are published in this listing. Confirm locally. Nothing here is an always-open clock.'**
  String get timingsMissing;

  /// Caveat for seasonal notes that also list more than one window.
  ///
  /// In en, this message translates to:
  /// **'Provisional / seasonal. Several visiting windows or a limited season are described. This is not a single always-open clock. Confirm before you travel.'**
  String get timingsSeasonalMulti;

  /// Caveat for season-dependent access.
  ///
  /// In en, this message translates to:
  /// **'Provisional / seasonal. These notes describe season-dependent access. This is not a single always-open clock. Confirm before you travel.'**
  String get timingsSeasonal;

  /// Caveat when more than one visiting window is listed.
  ///
  /// In en, this message translates to:
  /// **'Provisional. More than one visiting window is listed, or the notes disagree. This is not a single always-open clock. Confirm the day\'s board.'**
  String get timingsMultiWindow;

  /// Caveat when published hours are thin or incomplete.
  ///
  /// In en, this message translates to:
  /// **'Provisional. Published hours here are thin or incomplete. This is not a fixed always-open clock. Confirm locally.'**
  String get timingsProvisional;

  /// Banner when the device is offline and nothing is cached.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get offlineMessage;

  /// Banner when the device is offline and cached temples are on screen.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Showing temples saved on this device.'**
  String get offlineWithSavedTemples;

  /// Saved-list banner while the device is offline.
  ///
  /// In en, this message translates to:
  /// **'Offline, showing saved list'**
  String get savedListOffline;

  /// Saved-list banner while a refresh is not in progress.
  ///
  /// In en, this message translates to:
  /// **'Showing saved list'**
  String get savedListOnline;

  /// Dismissible soft-update banner.
  ///
  /// In en, this message translates to:
  /// **'A newer version is ready on the Play Store.'**
  String get softUpdateMessage;

  /// Full-screen title when the installed build is below the minimum.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get forceUpdateTitle;

  /// Full-screen explanation for a required update.
  ///
  /// In en, this message translates to:
  /// **'This version of Temple Directory India is no longer supported. Install the latest version from the Play Store to continue.'**
  String get forceUpdateBody;

  /// Button that opens the Play listing from the required-update screen.
  ///
  /// In en, this message translates to:
  /// **'Update on Play Store'**
  String get forceUpdateButton;

  /// Snack bar when the Play listing cannot be opened.
  ///
  /// In en, this message translates to:
  /// **'Could not open the Play Store.'**
  String get couldNotOpenPlayStore;

  /// Full-screen title while the kill switch is on.
  ///
  /// In en, this message translates to:
  /// **'We\'ll be back soon'**
  String get maintenanceTitle;

  /// Maintenance body when Remote Config sends an empty message.
  ///
  /// In en, this message translates to:
  /// **'Temple Directory is temporarily unavailable. Please try again later.'**
  String get maintenanceFallback;

  /// Policy gate accept button and its accessibility label.
  ///
  /// In en, this message translates to:
  /// **'Accept & continue'**
  String get acceptAndContinue;

  /// Accessibility hint for the policy accept button.
  ///
  /// In en, this message translates to:
  /// **'Agrees to the Terms of Service and Privacy Policy'**
  String get acceptHint;

  /// First-launch link to the terms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// Policy-update link to the terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get termsShort;

  /// Link to the privacy policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Accessibility hint for a policy link.
  ///
  /// In en, this message translates to:
  /// **'Opens in the app'**
  String get opensInTheApp;

  /// First-launch policy gate title.
  ///
  /// In en, this message translates to:
  /// **'Before you begin'**
  String get beforeYouBegin;

  /// Text before the first-launch policy links. The trailing space is intentional.
  ///
  /// In en, this message translates to:
  /// **'To use the app, please review and accept our '**
  String get policyFirstLaunchLead;

  /// Text after the first-launch policy links.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get policyFirstLaunchTail;

  /// Title when the policy version has changed.
  ///
  /// In en, this message translates to:
  /// **'We\'ve updated our terms'**
  String get policyUpdatedTitle;

  /// Text before the updated policy links. The trailing space is intentional.
  ///
  /// In en, this message translates to:
  /// **'Please review and accept the updated '**
  String get policyUpdateLead;

  /// Text after the updated policy links.
  ///
  /// In en, this message translates to:
  /// **' to continue.'**
  String get policyUpdateTail;

  /// Conjunction between the terms and privacy links, including both spaces.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get policyAnd;

  /// Snack bar when policy acceptance cannot be stored.
  ///
  /// In en, this message translates to:
  /// **'Could not save your acceptance on this device. Please try again.'**
  String get policySaveFailed;

  /// Snack bar when a policy link cannot be opened.
  ///
  /// In en, this message translates to:
  /// **'Could not open that link.'**
  String get policyLinkFailed;

  /// Licences screen section heading.
  ///
  /// In en, this message translates to:
  /// **'District boundaries'**
  String get districtBoundaries;

  /// Link label for the district source page.
  ///
  /// In en, this message translates to:
  /// **'Bharatlas LGD Districts'**
  String get bharatlasLink;

  /// Link label for the Creative Commons licence.
  ///
  /// In en, this message translates to:
  /// **'CC BY 4.0'**
  String get ccBy40;

  /// Licences note for the bundled district polygons.
  ///
  /// In en, this message translates to:
  /// **'Dataset {version}, updated {updated}, fetched {fetched}. The polygons in this app were simplified.'**
  String districtBundlingNote(String version, String updated, String fetched);

  /// Near-me screen title and home button.
  ///
  /// In en, this message translates to:
  /// **'Temples near me'**
  String get nearMeTitle;

  /// Title of the approximate-location explanation.
  ///
  /// In en, this message translates to:
  /// **'Sort by distance'**
  String get nearMeRationaleTitle;

  /// Body of the approximate-location explanation. Must match the platform permission text.
  ///
  /// In en, this message translates to:
  /// **'Used once on your phone to sort temples by distance. Never stored or sent.'**
  String get nearMeRationaleBody;

  /// Status while a location fix is in progress.
  ///
  /// In en, this message translates to:
  /// **'Finding temples near you…'**
  String get nearMeLocating;

  /// Heading when results are sorted from the device location.
  ///
  /// In en, this message translates to:
  /// **'Nearest temples'**
  String get nearMeNearestHeading;

  /// Shown when location permission is denied.
  ///
  /// In en, this message translates to:
  /// **'Location is off for this app. Pick a state or city and the list is sorted from there.'**
  String get nearMeDeniedBody;

  /// Shown when location permission is permanently denied.
  ///
  /// In en, this message translates to:
  /// **'Location stays off until you allow approximate location in settings. You can still pick a state or city.'**
  String get nearMeDeniedForeverBody;

  /// Opens app settings so location can be allowed.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get nearMeOpenSettings;

  /// Asks for approximate location again.
  ///
  /// In en, this message translates to:
  /// **'Enable location'**
  String get nearMeEnableLocation;

  /// Shown when the device location service is off.
  ///
  /// In en, this message translates to:
  /// **'Location is turned off on this phone. Turn it on and try again, or pick a state or city.'**
  String get nearMeServiceOffBody;

  /// Opens the system location settings.
  ///
  /// In en, this message translates to:
  /// **'Open location settings'**
  String get nearMeOpenLocationSettings;

  /// Shown when a location fix times out.
  ///
  /// In en, this message translates to:
  /// **'Could not read a location in time. Try again, or pick a state or city.'**
  String get nearMeTimedOutBody;

  /// Shown when the person skips location.
  ///
  /// In en, this message translates to:
  /// **'Pick a state or city to sort the list.'**
  String get nearMeDeclinedBody;

  /// Offers location after it was skipped.
  ///
  /// In en, this message translates to:
  /// **'Use approximate location'**
  String get nearMeUseLocation;

  /// Near-me and filter prompt for a state.
  ///
  /// In en, this message translates to:
  /// **'Choose a state'**
  String get chooseState;

  /// Near-me prompt for a city.
  ///
  /// In en, this message translates to:
  /// **'Choose a city'**
  String get chooseCity;

  /// Near-me and filter prompt for a district.
  ///
  /// In en, this message translates to:
  /// **'Choose a district'**
  String get chooseDistrict;

  /// Near-me city option that clears the city.
  ///
  /// In en, this message translates to:
  /// **'Any city'**
  String get anyCity;

  /// Near-me district option that clears the district.
  ///
  /// In en, this message translates to:
  /// **'Any district'**
  String get anyDistrict;

  /// Shown when no result has coordinates.
  ///
  /// In en, this message translates to:
  /// **'None of these listings have a map point.'**
  String get nearMeNoMapPoints;

  /// Shown when the chosen place has no coordinates.
  ///
  /// In en, this message translates to:
  /// **'None of the temples in that place have a map point.'**
  String get nearMeNoAnchorMatch;

  /// Distance unit. The number is formatted in code and stays in Latin digits.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get nearMeKilometres;

  /// Heading when results are sorted from a chosen place.
  ///
  /// In en, this message translates to:
  /// **'Sorted from {place}'**
  String nearMeSortedFrom(String place);

  /// Filter chip when no state is selected, and the admin form label.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get stateLabel;

  /// Tooltip that clears the state chip.
  ///
  /// In en, this message translates to:
  /// **'Clear state filter'**
  String get clearStateFilter;

  /// District chip and sheet option for every district.
  ///
  /// In en, this message translates to:
  /// **'All districts'**
  String get allDistricts;

  /// Tooltip that clears the district chip.
  ///
  /// In en, this message translates to:
  /// **'Clear district filter'**
  String get clearDistrictFilter;

  /// Filter chip when no deity is selected, and the admin form label.
  ///
  /// In en, this message translates to:
  /// **'Deity'**
  String get deityLabel;

  /// Tooltip that opens the deity filter.
  ///
  /// In en, this message translates to:
  /// **'Choose a deity'**
  String get chooseDeity;

  /// Tooltip that clears the deity chip.
  ///
  /// In en, this message translates to:
  /// **'Clear deity filter'**
  String get clearDeityFilter;

  /// Filter sheet section heading.
  ///
  /// In en, this message translates to:
  /// **'STATE'**
  String get stateSection;

  /// Filter sheet option that clears the state.
  ///
  /// In en, this message translates to:
  /// **'Any state'**
  String get anyState;

  /// Filter sheet section heading.
  ///
  /// In en, this message translates to:
  /// **'DISTRICT'**
  String get districtSection;

  /// Filter sheet section heading.
  ///
  /// In en, this message translates to:
  /// **'DEITY'**
  String get deitySection;

  /// Filter sheet option that clears the deity.
  ///
  /// In en, this message translates to:
  /// **'Any deity'**
  String get anyDeity;

  /// Filter sheet title.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// Tooltip that closes the filter sheet.
  ///
  /// In en, this message translates to:
  /// **'Close filters'**
  String get closeFilters;

  /// Filter sheet explanation when the district section is shown.
  ///
  /// In en, this message translates to:
  /// **'State, district, and deity, on the temples already loaded.'**
  String get filterSheetWithDistrict;

  /// Filter sheet explanation when the district section is hidden.
  ///
  /// In en, this message translates to:
  /// **'State and deity, on the temples already loaded.'**
  String get filterSheetNoDistrict;

  /// Filter sheet button that applies the draft and shows how many temples match.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Show {count} temple} other{Show {count} temples}}'**
  String showTempleCount(int count);

  /// Empty browse message when a district filter is active.
  ///
  /// In en, this message translates to:
  /// **'Nothing in the loaded directory fits this state, district, and deity.'**
  String get emptyFilterWithDistrict;

  /// Empty browse message when state and deity filters exclude a district.
  ///
  /// In en, this message translates to:
  /// **'Nothing in the loaded directory fits this state and deity.'**
  String get emptyFilterStateDeity;

  /// Note under deity filters that include a non-Hindu tradition.
  ///
  /// In en, this message translates to:
  /// **'{traditions} labels are the listed tradition, not Hindu darshan filters.'**
  String deityTraditionNote(String traditions);

  /// Joins two labels in a sentence.
  ///
  /// In en, this message translates to:
  /// **'{first} and {second}'**
  String listPair(String first, String second);

  /// Joins a comma-separated list to its last item.
  ///
  /// In en, this message translates to:
  /// **'{rest}, and {last}'**
  String listAndLast(String rest, String last);

  /// Drawer action while a search draft is also set.
  ///
  /// In en, this message translates to:
  /// **'Clear search and filters'**
  String get clearSearchAndFilters;

  /// Drawer action that clears applied filters.
  ///
  /// In en, this message translates to:
  /// **'Clear All Filters'**
  String get clearAllFilters;

  /// Drawer button before a query is typed.
  ///
  /// In en, this message translates to:
  /// **'Search directory'**
  String get searchDirectory;

  /// Drawer button when the query matches nothing.
  ///
  /// In en, this message translates to:
  /// **'No matching temples'**
  String get noMatchingTemples;

  /// Drawer button that opens the search results.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{View {count} match} other{View {count} matches}}'**
  String viewMatchCount(int count);

  /// Browse list title while the directory loads.
  ///
  /// In en, this message translates to:
  /// **'Loading temples'**
  String get loadingTemples;

  /// Browse list detail while the directory loads.
  ///
  /// In en, this message translates to:
  /// **'Fetching the directory.'**
  String get fetchingDirectory;

  /// Browse list title after a load failure.
  ///
  /// In en, this message translates to:
  /// **'Could not load temples'**
  String get couldNotLoadTemples;

  /// Browse list detail after a load failure.
  ///
  /// In en, this message translates to:
  /// **'The directory did not load. Go back and try again.'**
  String get directoryDidNotLoad;

  /// Search field hint.
  ///
  /// In en, this message translates to:
  /// **'Name, city, state, deity, or address'**
  String get searchHint;

  /// Tooltip and button that clear the search field.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// Empty title when filters and a query are both active.
  ///
  /// In en, this message translates to:
  /// **'No temples match these filters and \"{query}\".'**
  String noMatchFiltersAndQuery(String query);

  /// Empty title when only filters are active.
  ///
  /// In en, this message translates to:
  /// **'No temples match these filters.'**
  String get noMatchFilters;

  /// Empty title when only a query is active.
  ///
  /// In en, this message translates to:
  /// **'No temples match \"{query}\".'**
  String noMatchQuery(String query);

  /// Empty title when the directory view has no rows.
  ///
  /// In en, this message translates to:
  /// **'No temples to browse'**
  String get noTemplesToBrowse;

  /// Empty detail when filters and a query are both active.
  ///
  /// In en, this message translates to:
  /// **'Clear the filters or the search. The list is the directory already loaded.'**
  String get clearFiltersOrSearch;

  /// Empty detail when a query matches nothing.
  ///
  /// In en, this message translates to:
  /// **'Try a name, city, state, deity, or address.'**
  String get trySearchHint;

  /// Empty detail when the view has no rows and no query.
  ///
  /// In en, this message translates to:
  /// **'Nothing is listed in this view yet.'**
  String get nothingListedYet;

  /// Button on the empty filter state.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// Count line above a filtered browse list.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} temple} other{{count} temples}}'**
  String templeCountLabel(int count);

  /// Notice when the whole directory fell back to the bundled sample.
  ///
  /// In en, this message translates to:
  /// **'Could not load temples. Showing the offline sample.'**
  String get offlineSampleTemples;

  /// Notice when named states fell back to the bundled sample.
  ///
  /// In en, this message translates to:
  /// **'Could not load temples in {states}. Showing the offline sample.'**
  String offlineSampleTemplesIn(String states);

  /// Notice when named states could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'Could not load temples in {states}.'**
  String couldNotLoadTemplesIn(String states);

  /// Shown when admin tools are not compiled in.
  ///
  /// In en, this message translates to:
  /// **'Admin CMS is available in debug or demo builds (ENABLE_ADMIN_TOOLS).'**
  String get adminCmsUnavailable;

  /// App-bar tooltip and form title for a new temple.
  ///
  /// In en, this message translates to:
  /// **'Create temple'**
  String get createTemple;

  /// Empty admin list button.
  ///
  /// In en, this message translates to:
  /// **'Create a temple'**
  String get createATemple;

  /// Admin list action. Kept for the same English label where the button says Add temple.
  ///
  /// In en, this message translates to:
  /// **'Add temple'**
  String get addTemple;

  /// Confirmation dialog title.
  ///
  /// In en, this message translates to:
  /// **'Delete temple?'**
  String get deleteTempleTitle;

  /// Confirmation dialog body. The id is the Firestore document id.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove \"{name}\" from Firestore? Images uploaded under temples/{id}/ in Storage will also be deleted. External image URLs (for example seed photos) are not Storage files and are left as-is.'**
  String deleteTempleBody(String name, String id);

  /// Admin row subtitle for how many photos a temple has.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} image} other{{count} images}}'**
  String imageCount(int count);

  /// Admin row status while a delete is in progress.
  ///
  /// In en, this message translates to:
  /// **'Deleting…'**
  String get deleting;

  /// Form title when editing an existing temple.
  ///
  /// In en, this message translates to:
  /// **'Edit temple'**
  String get editTemple;

  /// Intro on the admin temple form.
  ///
  /// In en, this message translates to:
  /// **'Same Firestore fields as Seed and the public directory (name, state, city, deity, address, story, timings, …).'**
  String get adminFormIntro;

  /// Admin form label for the temple name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// Admin form label for the city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// Admin form hint listing known state names.
  ///
  /// In en, this message translates to:
  /// **'Tamil Nadu, Kerala, Karnataka, Andhra Pradesh, Telangana, Gujarat, Odisha, Uttar Pradesh, Jammu and Kashmir, Maharashtra, Rajasthan, West Bengal, Madhya Pradesh, Bihar, Himachal Pradesh'**
  String get adminStateHint;

  /// Admin form hint for the deity field.
  ///
  /// In en, this message translates to:
  /// **'Shiva, Vishnu, Devi, Murugan, …'**
  String get deityHint;

  /// Admin form label for the address.
  ///
  /// In en, this message translates to:
  /// **'Location / address'**
  String get locationAddressLabel;

  /// Admin form hint for timings.
  ///
  /// In en, this message translates to:
  /// **'5:00 AM – 12:30 PM, 4:00 PM – 10:00 PM'**
  String get timingsHint;

  /// Admin form label for the description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// Admin form label for the story.
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get storyLabel;

  /// Admin form hint for specialities.
  ///
  /// In en, this message translates to:
  /// **'One per line, or comma-separated'**
  String get specialitiesHint;

  /// Admin form section heading.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// Admin form help before any photo is added.
  ///
  /// In en, this message translates to:
  /// **'No photos yet. The temple stays Photo pending. Seed does not add stock photos.'**
  String get noPhotosYet;

  /// Admin form help after a photo is added.
  ///
  /// In en, this message translates to:
  /// **'First photo is the cover. Long-press a tile to reorder. Each photo needs a licence before Save.'**
  String get photoCoverHelp;

  /// Admin form label.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// Admin form label.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// Admin form button while a save is in progress.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// Admin form button when editing.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// Form error while uploads are still running.
  ///
  /// In en, this message translates to:
  /// **'Wait for photo uploads to finish.'**
  String get waitForPhotoUploads;

  /// Form error when a photo upload failed.
  ///
  /// In en, this message translates to:
  /// **'Retry the photos that failed to upload.'**
  String get retryFailedPhotos;

  /// Form error when a photo has no licence.
  ///
  /// In en, this message translates to:
  /// **'Add a licence to every photo before saving.'**
  String get addLicenceBeforeSaving;

  /// Form error when a credited licence has no credit.
  ///
  /// In en, this message translates to:
  /// **'Add a credit for CC-BY and CC-BY-SA photos before saving.'**
  String get addCreditBeforeSaving;

  /// Form error when the photo grid is incomplete.
  ///
  /// In en, this message translates to:
  /// **'Finish the photo grid before saving.'**
  String get finishPhotoGrid;

  /// Form error when another photo would pass the cap.
  ///
  /// In en, this message translates to:
  /// **'A temple can have at most {max} photos.'**
  String maxPhotos(int max);

  /// Form error when photos are added before a name.
  ///
  /// In en, this message translates to:
  /// **'Enter a temple name before adding photos.'**
  String get enterNameBeforePhotos;

  /// Snack bar when the photo picker fails. The error is the existing admin write message.
  ///
  /// In en, this message translates to:
  /// **'Could not open the photo picker. {error}'**
  String couldNotOpenPhotoPicker(String error);

  /// Snack bar when the picker returns more photos than the cap.
  ///
  /// In en, this message translates to:
  /// **'Only {max} photos can be saved. Extra picks were skipped.'**
  String extraPhotosSkipped(int max);

  /// Form error when a photo upload fails. The error is the existing admin write message.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String uploadFailed(String error);

  /// Form error when validation fails.
  ///
  /// In en, this message translates to:
  /// **'Fix the highlighted fields and try again.'**
  String get fixHighlightedFields;

  /// Admin photo grid add tile.
  ///
  /// In en, this message translates to:
  /// **'+ Add photo'**
  String get addPhoto;

  /// Tooltip that removes a photo tile.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// Badge on a photo that has no licence.
  ///
  /// In en, this message translates to:
  /// **'Needs licence'**
  String get needsLicence;

  /// Badge on a photo whose licence requires a credit.
  ///
  /// In en, this message translates to:
  /// **'Needs credit'**
  String get needsCredit;

  /// Badge on the first photo.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get cover;

  /// Title of the licence sheet.
  ///
  /// In en, this message translates to:
  /// **'Photo licence'**
  String get photoLicence;

  /// Help on the licence sheet.
  ///
  /// In en, this message translates to:
  /// **'CC-BY and CC-BY-SA need a credit. CC0, Own, and Permission can leave credit blank.'**
  String get photoLicenceHelp;

  /// Subtitle for a licence that needs a credit.
  ///
  /// In en, this message translates to:
  /// **'Credit required'**
  String get creditRequired;

  /// Subtitle for a licence that does not need a credit.
  ///
  /// In en, this message translates to:
  /// **'Credit optional'**
  String get creditOptional;

  /// Credit field label when a credit is required.
  ///
  /// In en, this message translates to:
  /// **'Credit (required)'**
  String get creditRequiredLabel;

  /// Credit field label when a credit is optional.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get creditLabel;

  /// Credit field hint.
  ///
  /// In en, this message translates to:
  /// **'Photographer or source'**
  String get creditHint;

  /// Button that applies the chosen licence.
  ///
  /// In en, this message translates to:
  /// **'Use this licence'**
  String get useThisLicence;

  /// Title of the admin sign-in card.
  ///
  /// In en, this message translates to:
  /// **'Admin sign-in required'**
  String get adminSignInRequired;

  /// Explanation on the admin sign-in card.
  ///
  /// In en, this message translates to:
  /// **'Temple data is publicly readable, but Seed and Admin writes need a signed-in account with the Firebase custom claim admin: true. Production browsing does not require signing in.'**
  String get adminSignInBody;

  /// Admin sign-in email field label.
  ///
  /// In en, this message translates to:
  /// **'Admin email'**
  String get adminEmail;

  /// Admin sign-in password field label.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Validation message on the admin sign-in form.
  ///
  /// In en, this message translates to:
  /// **'Enter email and password.'**
  String get enterEmailAndPassword;

  /// Admin sign-in button while the request is in progress.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get signingIn;

  /// Fallback name when a signed-in admin has no email or uid.
  ///
  /// In en, this message translates to:
  /// **'this account'**
  String get thisAccount;

  /// Title when the account lacks the admin claim.
  ///
  /// In en, this message translates to:
  /// **'Signed in, but not an admin'**
  String get signedInNotAdmin;

  /// Explanation when the account lacks the admin claim.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {who}. Writes are blocked until this user has the custom claim admin: true. Grant the claim with scripts/grant_admin.js, then refresh or sign out and back in.'**
  String signedInNotAdminBody(String who);

  /// Button that reloads the admin custom claim.
  ///
  /// In en, this message translates to:
  /// **'Refresh admin status'**
  String get refreshAdminStatus;

  /// Message when Seed is tapped without admin write access.
  ///
  /// In en, this message translates to:
  /// **'Sign in as an admin (custom claim admin: true) to seed Firestore.'**
  String get seedUnauthorized;

  /// Status while the sample seed is running.
  ///
  /// In en, this message translates to:
  /// **'Seeding sample temples…'**
  String get seedingSampleTemples;

  /// Fallback when a seed error has no message.
  ///
  /// In en, this message translates to:
  /// **'Seeding failed.'**
  String get seedingFailed;

  /// Tooltip on the compact seed button.
  ///
  /// In en, this message translates to:
  /// **'Seed bundled sample temples into Firestore'**
  String get seedBundledTooltip;

  /// Compact seed button while idle.
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get seed;

  /// Compact seed button while running.
  ///
  /// In en, this message translates to:
  /// **'Seeding'**
  String get seeding;

  /// Compact seed button after success.
  ///
  /// In en, this message translates to:
  /// **'Seeded'**
  String get seeded;

  /// Title of the locked seed panel.
  ///
  /// In en, this message translates to:
  /// **'Admin sign-in required to seed'**
  String get adminSignInRequiredToSeed;

  /// Empty admin seed panel title.
  ///
  /// In en, this message translates to:
  /// **'No temples in Firestore'**
  String get noTemplesInFirestore;

  /// Empty admin seed panel explanation.
  ///
  /// In en, this message translates to:
  /// **'Seed the bundled sample temples to populate the Admin list. Re-running is safe — each temple uses a stable document ID, so you will not get duplicates.'**
  String get seedPanelBody;

  /// Seed panel button while running.
  ///
  /// In en, this message translates to:
  /// **'Seeding…'**
  String get seedingEllipsis;

  /// Seed panel button after a failure.
  ///
  /// In en, this message translates to:
  /// **'Retry seed'**
  String get retrySeed;

  /// Seed panel button after success.
  ///
  /// In en, this message translates to:
  /// **'Seed again'**
  String get seedAgain;

  /// Seed panel button while idle.
  ///
  /// In en, this message translates to:
  /// **'Seed sample temples'**
  String get seedSampleTemples;

  /// Seed result when every write created a document.
  ///
  /// In en, this message translates to:
  /// **'Seeded {count} temples into Firestore.'**
  String seededCreatedOnly(int count);

  /// Seed result when every write updated an existing document.
  ///
  /// In en, this message translates to:
  /// **'Updated {count} existing sample temples. No duplicates created.'**
  String seededUpdatedOnly(int count);

  /// Seed result when some documents were created and some updated.
  ///
  /// In en, this message translates to:
  /// **'Seeded {written} temples ({created} new, {updated} updated).'**
  String seededCreatedAndUpdated(int written, int created, int updated);

  /// Snack bar after a temple document is deleted with no Storage objects.
  ///
  /// In en, this message translates to:
  /// **'Deleted temple.'**
  String get deletedTemple;

  /// Snack bar after a temple and its uploaded images are deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted temple and {count} uploaded image(s).'**
  String deletedTempleAndImages(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'bn',
    'en',
    'hi',
    'kn',
    'ml',
    'mr',
    'or',
    'ta',
    'te',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'ml':
      return AppLocalizationsMl();
    case 'mr':
      return AppLocalizationsMr();
    case 'or':
      return AppLocalizationsOr();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
