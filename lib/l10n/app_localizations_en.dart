// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Temple Directory India';

  @override
  String get appTitleShort => 'Temple Directory';

  @override
  String get india => 'India';

  @override
  String get home => 'Home';

  @override
  String get allTemples => 'All Temples';

  @override
  String get search => 'Search';

  @override
  String get searchSection => 'SEARCH';

  @override
  String get filtersSection => 'FILTERS';

  @override
  String get aboutSection => 'ABOUT';

  @override
  String get licences => 'Licences';

  @override
  String get adPrivacyChoices => 'Ad privacy choices';

  @override
  String get moreTooltip => 'More';

  @override
  String get adminSignIn => 'Admin sign-in';

  @override
  String get notAdmin => 'Not admin';

  @override
  String get adminPanel => 'Admin Panel';

  @override
  String get retry => 'Retry';

  @override
  String get tryAgain => 'Try again';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get clear => 'Clear';

  @override
  String get update => 'Update';

  @override
  String get notNow => 'Not now';

  @override
  String get edit => 'Edit';

  @override
  String get upload => 'Upload';

  @override
  String get signOut => 'Sign out';

  @override
  String get signIn => 'Sign in';

  @override
  String get orDivider => 'or';

  @override
  String get continueLabel => 'Continue';

  @override
  String get discover => 'Discover';

  @override
  String get indiasSacredTemples => 'India\'s Sacred Temples';

  @override
  String get noTemplesLoadedYet => 'No temples loaded yet';

  @override
  String templesAcrossIndia(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count temples across India',
      one: '$count temples across India',
    );
    return '$_temp0';
  }

  @override
  String get drawerAboutEmpty =>
      'Explore famous temples across Tamil Nadu, Kerala, Karnataka, Andhra Pradesh, Telangana, Gujarat, Odisha, Uttar Pradesh, Jammu and Kashmir, Maharashtra, Rajasthan, West Bengal, Madhya Pradesh, Bihar, and Himachal Pradesh. Discover histories, legends, timings and specialities — all in one curated directory.';

  @override
  String drawerAboutWithCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Explore $count famous temples across Tamil Nadu, Kerala, Karnataka, Andhra Pradesh, Telangana, Gujarat, Odisha, Uttar Pradesh, Jammu and Kashmir, Maharashtra, Rajasthan, West Bengal, Madhya Pradesh, Bihar, and Himachal Pradesh. Discover histories, legends, timings and specialities — all in one curated directory.',
      one:
          'Explore $count famous temples across Tamil Nadu, Kerala, Karnataka, Andhra Pradesh, Telangana, Gujarat, Odisha, Uttar Pradesh, Jammu and Kashmir, Maharashtra, Rajasthan, West Bengal, Madhya Pradesh, Bihar, and Himachal Pradesh. Discover histories, legends, timings and specialities — all in one curated directory.',
    );
    return '$_temp0';
  }

  @override
  String get loadingTemplesEllipsis => 'Loading temples…';

  @override
  String get preparingDirectory =>
      'Preparing the directory. This usually takes a moment.';

  @override
  String get couldNotLoadTemplesPeriod => 'Could not load temples.';

  @override
  String get checkConnection => 'Check your connection and try again.';

  @override
  String get noTemplesAvailable => 'No temples available yet.';

  @override
  String get directoryEmptyRetry =>
      'The directory came back empty. Tap Retry, or try again later.';

  @override
  String browseTempleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Browse $count Temples',
      one: 'Browse $count Temple',
      zero: 'Browse temples',
    );
    return '$_temp0';
  }

  @override
  String drawerBrowseTempleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Browse $count Temples',
      one: 'Browse $count Temple',
    );
    return '$_temp0';
  }

  @override
  String get openDirectoryHint =>
      'Open the directory for temple cards, search, and filters. You can also use the menu (☰).';

  @override
  String get heritageContinuesBelow => 'Heritage reading continues below';

  @override
  String get templeHeritageTitle => 'Temple Heritage of India';

  @override
  String get templeHeritageSubtitle =>
      'A comprehensive exploration of India\'s sacred architectural legacy';

  @override
  String get couldNotLoadThisTemple => 'Could not load this temple.';

  @override
  String get couldNotOpenDirections =>
      'Couldn\'t open directions on this device.';

  @override
  String listedFocus(String deity) {
    return 'Listed focus: $deity';
  }

  @override
  String get pageMayBeOutOfDate => 'This page may be out of date.';

  @override
  String get location => 'Location';

  @override
  String get notListedInEntry => 'Not listed in this entry.';

  @override
  String get coordinates => 'Coordinates';

  @override
  String coordinatesNorthEast(String lat, String lng) {
    return '$lat° N, $lng° E';
  }

  @override
  String get howToReach => 'How to Reach';

  @override
  String get getDirections => 'Get Directions';

  @override
  String get about => 'About';

  @override
  String get specialities => 'Specialities';

  @override
  String galleryPosition(int current, int total) {
    return '$current / $total';
  }

  @override
  String get photoPending => 'Photo pending';

  @override
  String get noVerifiedPhotograph => 'No verified photograph is on file.';

  @override
  String get photoPendingSemantics =>
      'Photo pending. No verified photograph is on file.';

  @override
  String get templePhotoSemantics => 'Temple photo';

  @override
  String get heritageVisit => 'Heritage visit';

  @override
  String get livingTemple => 'Living temple';

  @override
  String get visitingHours => 'Visiting hours';

  @override
  String get timings => 'Timings';

  @override
  String get aboutThisPlace => 'About this place';

  @override
  String get templeStory => 'Temple story';

  @override
  String get siteHistory => 'Site history';

  @override
  String get background => 'Background';

  @override
  String get traditionJain => 'Jain';

  @override
  String get traditionBuddhist => 'Buddhist';

  @override
  String get traditionSikh => 'Sikh';

  @override
  String get jainPilgrimageSite => 'Jain pilgrimage site.';

  @override
  String get buddhistPilgrimageSite => 'Buddhist pilgrimage site.';

  @override
  String get sikhSite => 'Sikh site.';

  @override
  String get livingTempleUnspecifiedNote =>
      'Notes describe continuing worship at a living temple. The hours below are published text from the listing.';

  @override
  String get livingTempleTraditionNote =>
      'Notes describe continuing observance. The hours below are published text from the listing.';

  @override
  String get monumentVisitNote =>
      'Heritage visit. The hours below are visitor access for a monument or archaeological site.';

  @override
  String get neutralFramingNote =>
      'These notes do not say clearly whether worship continues or this is only a monument visit.';

  @override
  String get timingsMissing =>
      'No visiting hours are published in this listing. Confirm locally. Nothing here is an always-open clock.';

  @override
  String get timingsSeasonalMulti =>
      'Provisional / seasonal. Several visiting windows or a limited season are described. This is not a single always-open clock. Confirm before you travel.';

  @override
  String get timingsSeasonal =>
      'Provisional / seasonal. These notes describe season-dependent access. This is not a single always-open clock. Confirm before you travel.';

  @override
  String get timingsMultiWindow =>
      'Provisional. More than one visiting window is listed, or the notes disagree. This is not a single always-open clock. Confirm the day\'s board.';

  @override
  String get timingsProvisional =>
      'Provisional. Published hours here are thin or incomplete. This is not a fixed always-open clock. Confirm locally.';

  @override
  String get offlineMessage => 'You\'re offline';

  @override
  String get offlineWithSavedTemples =>
      'You\'re offline. Showing temples saved on this device.';

  @override
  String get savedListOffline => 'Offline, showing saved list';

  @override
  String get savedListOnline => 'Showing saved list';

  @override
  String get softUpdateMessage => 'A newer version is ready on the Play Store.';

  @override
  String get forceUpdateTitle => 'Update required';

  @override
  String get forceUpdateBody =>
      'This version of Temple Directory India is no longer supported. Install the latest version from the Play Store to continue.';

  @override
  String get forceUpdateButton => 'Update on Play Store';

  @override
  String get couldNotOpenPlayStore => 'Could not open the Play Store.';

  @override
  String get maintenanceTitle => 'We\'ll be back soon';

  @override
  String get maintenanceFallback =>
      'Temple Directory is temporarily unavailable. Please try again later.';

  @override
  String get acceptAndContinue => 'Accept & continue';

  @override
  String get acceptHint => 'Agrees to the Terms of Service and Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get termsShort => 'Terms';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get opensInTheApp => 'Opens in the app';

  @override
  String get beforeYouBegin => 'Before you begin';

  @override
  String get policyFirstLaunchLead =>
      'To use the app, please review and accept our ';

  @override
  String get policyFirstLaunchTail => '.';

  @override
  String get policyUpdatedTitle => 'We\'ve updated our terms';

  @override
  String get policyUpdateLead => 'Please review and accept the updated ';

  @override
  String get policyUpdateTail => ' to continue.';

  @override
  String get policyAnd => ' and ';

  @override
  String get policySaveFailed =>
      'Could not save your acceptance on this device. Please try again.';

  @override
  String get policyLinkFailed => 'Could not open that link.';

  @override
  String get districtBoundaries => 'District boundaries';

  @override
  String get bharatlasLink => 'Bharatlas LGD Districts';

  @override
  String get ccBy40 => 'CC BY 4.0';

  @override
  String districtBundlingNote(String version, String updated, String fetched) {
    return 'Dataset $version, updated $updated, fetched $fetched. The polygons in this app were simplified.';
  }

  @override
  String get nearMeTitle => 'Temples near me';

  @override
  String get nearMeRationaleTitle => 'Sort by distance';

  @override
  String get nearMeRationaleBody =>
      'Used once on your phone to sort temples by distance. Never stored or sent.';

  @override
  String get nearMeLocating => 'Finding temples near you…';

  @override
  String get nearMeNearestHeading => 'Nearest temples';

  @override
  String get nearMeDeniedBody =>
      'Location is off for this app. Pick a state or city and the list is sorted from there.';

  @override
  String get nearMeDeniedForeverBody =>
      'Location stays off until you allow approximate location in settings. You can still pick a state or city.';

  @override
  String get nearMeOpenSettings => 'Open settings';

  @override
  String get nearMeEnableLocation => 'Enable location';

  @override
  String get nearMeServiceOffBody =>
      'Location is turned off on this phone. Turn it on and try again, or pick a state or city.';

  @override
  String get nearMeOpenLocationSettings => 'Open location settings';

  @override
  String get nearMeTimedOutBody =>
      'Could not read a location in time. Try again, or pick a state or city.';

  @override
  String get nearMeDeclinedBody => 'Pick a state or city to sort the list.';

  @override
  String get nearMeUseLocation => 'Use approximate location';

  @override
  String get chooseState => 'Choose a state';

  @override
  String get chooseCity => 'Choose a city';

  @override
  String get chooseDistrict => 'Choose a district';

  @override
  String get anyCity => 'Any city';

  @override
  String get anyDistrict => 'Any district';

  @override
  String get nearMeNoMapPoints => 'None of these listings have a map point.';

  @override
  String get nearMeNoAnchorMatch =>
      'None of the temples in that place have a map point.';

  @override
  String get nearMeKilometres => 'km';

  @override
  String nearMeSortedFrom(String place) {
    return 'Sorted from $place';
  }

  @override
  String get stateLabel => 'State';

  @override
  String get clearStateFilter => 'Clear state filter';

  @override
  String get allDistricts => 'All districts';

  @override
  String get clearDistrictFilter => 'Clear district filter';

  @override
  String get deityLabel => 'Deity';

  @override
  String get chooseDeity => 'Choose a deity';

  @override
  String get clearDeityFilter => 'Clear deity filter';

  @override
  String get stateSection => 'STATE';

  @override
  String get anyState => 'Any state';

  @override
  String get districtSection => 'DISTRICT';

  @override
  String get deitySection => 'DEITY';

  @override
  String get anyDeity => 'Any deity';

  @override
  String get filters => 'Filters';

  @override
  String get closeFilters => 'Close filters';

  @override
  String get filterSheetWithDistrict =>
      'State, district, and deity, on the temples already loaded.';

  @override
  String get filterSheetNoDistrict =>
      'State and deity, on the temples already loaded.';

  @override
  String showTempleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $count temples',
      one: 'Show $count temple',
    );
    return '$_temp0';
  }

  @override
  String get emptyFilterWithDistrict =>
      'Nothing in the loaded directory fits this state, district, and deity.';

  @override
  String get emptyFilterStateDeity =>
      'Nothing in the loaded directory fits this state and deity.';

  @override
  String deityTraditionNote(String traditions) {
    return '$traditions labels are the listed tradition, not Hindu darshan filters.';
  }

  @override
  String listPair(String first, String second) {
    return '$first and $second';
  }

  @override
  String listAndLast(String rest, String last) {
    return '$rest, and $last';
  }

  @override
  String get clearSearchAndFilters => 'Clear search and filters';

  @override
  String get clearAllFilters => 'Clear All Filters';

  @override
  String get searchDirectory => 'Search directory';

  @override
  String get noMatchingTemples => 'No matching temples';

  @override
  String viewMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'View $count matches',
      one: 'View $count match',
    );
    return '$_temp0';
  }

  @override
  String get loadingTemples => 'Loading temples';

  @override
  String get fetchingDirectory => 'Fetching the directory.';

  @override
  String get couldNotLoadTemples => 'Could not load temples';

  @override
  String get directoryDidNotLoad =>
      'The directory did not load. Go back and try again.';

  @override
  String get searchHint => 'Name, city, state, deity, or address';

  @override
  String get clearSearch => 'Clear search';

  @override
  String noMatchFiltersAndQuery(String query) {
    return 'No temples match these filters and \"$query\".';
  }

  @override
  String get noMatchFilters => 'No temples match these filters.';

  @override
  String noMatchQuery(String query) {
    return 'No temples match \"$query\".';
  }

  @override
  String get noTemplesToBrowse => 'No temples to browse';

  @override
  String get clearFiltersOrSearch =>
      'Clear the filters or the search. The list is the directory already loaded.';

  @override
  String get trySearchHint => 'Try a name, city, state, deity, or address.';

  @override
  String get nothingListedYet => 'Nothing is listed in this view yet.';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String templeCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count temples',
      one: '$count temple',
    );
    return '$_temp0';
  }

  @override
  String get offlineSampleTemples =>
      'Could not load temples. Showing the offline sample.';

  @override
  String offlineSampleTemplesIn(String states) {
    return 'Could not load temples in $states. Showing the offline sample.';
  }

  @override
  String couldNotLoadTemplesIn(String states) {
    return 'Could not load temples in $states.';
  }

  @override
  String get adminCmsUnavailable =>
      'Admin CMS is available in debug or demo builds (ENABLE_ADMIN_TOOLS).';

  @override
  String get createTemple => 'Create temple';

  @override
  String get createATemple => 'Create a temple';

  @override
  String get addTemple => 'Add temple';

  @override
  String get deleteTempleTitle => 'Delete temple?';

  @override
  String deleteTempleBody(String name, String id) {
    return 'Permanently remove \"$name\" from Firestore? Images uploaded under temples/$id/ in Storage will also be deleted. External image URLs (for example seed photos) are not Storage files and are left as-is.';
  }

  @override
  String imageCount(int count) {
    return '$count image(s)';
  }

  @override
  String get deleting => 'Deleting…';

  @override
  String get editTemple => 'Edit temple';

  @override
  String get adminFormIntro =>
      'Same Firestore fields as Seed and the public directory (name, state, city, deity, address, story, timings, …).';

  @override
  String get nameLabel => 'Name';

  @override
  String get cityLabel => 'City';

  @override
  String get adminStateHint =>
      'Tamil Nadu, Kerala, Karnataka, Andhra Pradesh, Telangana, Gujarat, Odisha, Uttar Pradesh, Jammu and Kashmir, Maharashtra, Rajasthan, West Bengal, Madhya Pradesh, Bihar, Himachal Pradesh';

  @override
  String get deityHint => 'Shiva, Vishnu, Devi, Murugan, …';

  @override
  String get locationAddressLabel => 'Location / address';

  @override
  String get timingsHint => '5:00 AM – 12:30 PM, 4:00 PM – 10:00 PM';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get storyLabel => 'Story';

  @override
  String get specialitiesHint => 'One per line, or comma-separated';

  @override
  String get photos => 'Photos';

  @override
  String get noPhotosYet =>
      'No photos yet. The temple stays Photo pending. Seed does not add stock photos.';

  @override
  String get photoCoverHelp =>
      'First photo is the cover. Long-press a tile to reorder. Each photo needs a licence before Save.';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get saving => 'Saving…';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get waitForPhotoUploads => 'Wait for photo uploads to finish.';

  @override
  String get retryFailedPhotos => 'Retry the photos that failed to upload.';

  @override
  String get addLicenceBeforeSaving =>
      'Add a licence to every photo before saving.';

  @override
  String get addCreditBeforeSaving =>
      'Add a credit for CC-BY and CC-BY-SA photos before saving.';

  @override
  String get finishPhotoGrid => 'Finish the photo grid before saving.';

  @override
  String maxPhotos(int max) {
    return 'A temple can have at most $max photos.';
  }

  @override
  String get enterNameBeforePhotos =>
      'Enter a temple name before adding photos.';

  @override
  String couldNotOpenPhotoPicker(String error) {
    return 'Could not open the photo picker. $error';
  }

  @override
  String extraPhotosSkipped(int max) {
    return 'Only $max photos can be saved. Extra picks were skipped.';
  }

  @override
  String uploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get fixHighlightedFields =>
      'Fix the highlighted fields and try again.';

  @override
  String get addPhoto => '+ Add photo';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get needsLicence => 'Needs licence';

  @override
  String get needsCredit => 'Needs credit';

  @override
  String get cover => 'Cover';

  @override
  String get photoLicence => 'Photo licence';

  @override
  String get photoLicenceHelp =>
      'CC-BY and CC-BY-SA need a credit. CC0, Own, and Permission can leave credit blank.';

  @override
  String get creditRequired => 'Credit required';

  @override
  String get creditOptional => 'Credit optional';

  @override
  String get creditRequiredLabel => 'Credit (required)';

  @override
  String get creditLabel => 'Credit';

  @override
  String get creditHint => 'Photographer or source';

  @override
  String get useThisLicence => 'Use this licence';

  @override
  String get adminSignInRequired => 'Admin sign-in required';

  @override
  String get adminSignInBody =>
      'Temple data is publicly readable, but Seed and Admin writes need a signed-in account with the Firebase custom claim admin: true. Production browsing does not require signing in.';

  @override
  String get adminEmail => 'Admin email';

  @override
  String get password => 'Password';

  @override
  String get enterEmailAndPassword => 'Enter email and password.';

  @override
  String get signingIn => 'Signing in…';

  @override
  String get thisAccount => 'this account';

  @override
  String get signedInNotAdmin => 'Signed in, but not an admin';

  @override
  String signedInNotAdminBody(String who) {
    return 'Signed in as $who. Writes are blocked until this user has the custom claim admin: true. Grant the claim with scripts/grant_admin.js, then refresh or sign out and back in.';
  }

  @override
  String get refreshAdminStatus => 'Refresh admin status';

  @override
  String get seedUnauthorized =>
      'Sign in as an admin (custom claim admin: true) to seed Firestore.';

  @override
  String get seedingSampleTemples => 'Seeding sample temples…';

  @override
  String get seedingFailed => 'Seeding failed.';

  @override
  String get seedBundledTooltip => 'Seed bundled sample temples into Firestore';

  @override
  String get seed => 'Seed';

  @override
  String get seeding => 'Seeding';

  @override
  String get seeded => 'Seeded';

  @override
  String get adminSignInRequiredToSeed => 'Admin sign-in required to seed';

  @override
  String get noTemplesInFirestore => 'No temples in Firestore';

  @override
  String get seedPanelBody =>
      'Seed the bundled sample temples to populate the Admin list. Re-running is safe — each temple uses a stable document ID, so you will not get duplicates.';

  @override
  String get seedingEllipsis => 'Seeding…';

  @override
  String get retrySeed => 'Retry seed';

  @override
  String get seedAgain => 'Seed again';

  @override
  String get seedSampleTemples => 'Seed sample temples';

  @override
  String seededCreatedOnly(int count) {
    return 'Seeded $count temples into Firestore.';
  }

  @override
  String seededUpdatedOnly(int count) {
    return 'Updated $count existing sample temples. No duplicates created.';
  }

  @override
  String seededCreatedAndUpdated(int written, int created, int updated) {
    return 'Seeded $written temples ($created new, $updated updated).';
  }

  @override
  String get deletedTemple => 'Deleted temple.';

  @override
  String deletedTempleAndImages(int count) {
    return 'Deleted temple and $count uploaded image(s).';
  }
}
