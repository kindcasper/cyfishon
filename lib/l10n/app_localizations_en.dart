import 'app_localizations.dart';

/// English localization
class AppLocalizationsEn extends AppLocalizations {
  // General
  @override
  String get appName => 'CyFishON';
  @override
  String get ok => 'OK';
  @override
  String get cancel => 'Cancel';
  @override
  String get save => 'Save';
  @override
  String get delete => 'Delete';
  @override
  String get edit => 'Edit';
  @override
  String get close => 'Close';
  @override
  String get back => 'Back';
  @override
  String get next => 'Next';
  @override
  String get loading => 'Loading...';
  @override
  String get error => 'Error';
  @override
  String get success => 'Success';
  @override
  String get warning => 'Warning';
  @override
  String get info => 'Info';
  @override
  String get retry => 'Retry';
  @override
  String get yes => 'Yes';
  @override
  String get no => 'No';

  // Navigation
  @override
  String get home => 'Home';
  @override
  String get map => 'Map';
  @override
  String get history => 'History';
  @override
  String get logs => 'Logs';
  @override
  String get settings => 'Settings';

  // Authentication
  @override
  String get welcome => 'Welcome';
  @override
  String get login => 'Login';
  @override
  String get register => 'Register';
  @override
  String get logout => 'Logout';
  @override
  String get email => 'Email';
  @override
  String get password => 'Password';
  @override
  String get name => 'Name';
  @override
  String get confirmPassword => 'Confirm Password';
  @override
  String get forgotPassword => 'Forgot Password?';
  @override
  String get createAccount => 'Create Account';
  @override
  String get alreadyHaveAccount => 'Already have an account?';
  @override
  String get dontHaveAccount => 'Don\'t have an account?';
  @override
  String get enterEmail => 'Enter email';
  @override
  String get enterPassword => 'Enter password';
  @override
  String get enterName => 'Enter name';
  @override
  String get enterValidEmail => 'Enter valid email';
  @override
  String get passwordTooShort => 'Password too short';
  @override
  String get passwordsDontMatch => 'Passwords don\'t match';
  @override
  String get nameTooShort => 'Name too short';
  @override
  String get loginSuccess => 'Login successful';
  @override
  String get registerSuccess => 'Registration successful';
  @override
  String get logoutSuccess => 'Logout successful';
  @override
  String get invalidCredentials => 'Invalid email or password';
  @override
  String get userAlreadyExists => 'User already exists';
  @override
  String get userNotFound => 'User not found';
  @override
  String get weakPassword => 'Weak password';
  @override
  String get emailInUse => 'Email already in use';
  @override
  String get networkError => 'Network error';
  @override
  String get unknownError => 'Unknown error';
  @override
  String get passwordResetSent => 'Password reset sent to email';
  @override
  String get passwordResetError => 'Password reset error';

  // Catches
  @override
  String get fishOn => 'Fish ON!';
  @override
  String get doubleFish => 'Double!';
  @override
  String get tripleFish => 'Triple!';
  @override
  String get addCatch => 'Add Catch';
  @override
  String get catchType => 'Catch Type';
  @override
  String get location => 'Location';
  @override
  String get coordinates => 'Coordinates';
  @override
  String get accuracy => 'Accuracy';
  @override
  String get timestamp => 'Time';
  @override
  String get fisherman => 'Fisherman';
  @override
  String get catchAdded => 'Catch added';
  @override
  String get catchError => 'Error adding catch';
  @override
  String get noCatches => 'No catches';
  @override
  String get recentCatches => 'Recent Catches';
  @override
  String get allCatches => 'All Catches';
  @override
  String get myCatches => 'My Catches';
  @override
  String get mine => 'Mine';
  @override
  String get syncCatches => 'Sync Catches';
  @override
  String get syncSuccess => 'Sync completed';
  @override
  String get syncError => 'Sync error';
  @override
  String get sendingToTelegram => 'Sending to Telegram...';
  @override
  String get sentToTelegram => 'Sent to Telegram';
  @override
  String get telegramError => 'Telegram error';
  @override
  String get sendingToServer => 'Sending to server...';
  @override
  String get sentToServer => 'Sent to server';
  @override
  String get serverError => 'Server error';

  // Map
  @override
  String get mapView => 'Map View';
  @override
  String get satellite => 'Satellite';
  @override
  String get terrain => 'Terrain';
  @override
  String get hybrid => 'Hybrid';
  @override
  String get myLocation => 'My Location';
  @override
  String get centerMap => 'Center Map';
  @override
  String get zoomIn => 'Zoom In';
  @override
  String get zoomOut => 'Zoom Out';
  @override
  String get compass => 'Compass';
  @override
  String get bearing => 'Bearing';
  @override
  String get distance => 'Distance';
  @override
  String get showCatches => 'Show Catches';
  @override
  String get hideCatches => 'Hide Catches';

  // Settings
  @override
  String get generalSettings => 'General Settings';
  @override
  String get user => 'User';
  @override
  String get userName => 'User Name';
  @override
  String get language => 'Language';
  @override
  String get notifications => 'Notifications';
  @override
  String get sync => 'Sync';
  @override
  String get about => 'About';
  @override
  String get online => 'Online';
  @override
  String get syncActive => 'Sync active';
  @override
  String get total => 'Total';
  @override
  String get sent => 'Sent';
  @override
  String get pending => 'Pending';
  @override
  String get authorizedAs => 'Authorized as';
  @override
  String get version => 'Version';
  @override
  String get developer => 'Developer';
  @override
  String get contact => 'Contact';
  @override
  String get privacy => 'Privacy';
  @override
  String get terms => 'Terms of Use';
  @override
  String get licenses => 'Licenses';
  @override
  String get clearData => 'Clear Data';
  @override
  String get clearDataConfirm => 'Are you sure you want to clear all data?';
  @override
  String get exportData => 'Export Data';
  @override
  String get importData => 'Import Data';
  @override
  String get backup => 'Backup';
  @override
  String get restore => 'Restore';
  @override
  String get theme => 'Theme';
  @override
  String get lightTheme => 'Light';
  @override
  String get darkTheme => 'Dark';
  @override
  String get systemTheme => 'System';
  @override
  String get autoSync => 'Auto Sync';
  @override
  String get syncInterval => 'Sync Interval';
  @override
  String get offlineMode => 'Offline Mode';
  @override
  String get enableNotifications => 'Enable Notifications';
  @override
  String get soundEnabled => 'Sound Enabled';
  @override
  String get vibrationEnabled => 'Vibration Enabled';

  // Location
  @override
  String get locationPermission => 'Location Permission';
  @override
  String get locationPermissionDenied => 'Location permission denied';
  @override
  String get locationPermissionRequired => 'Location permission required';
  @override
  String get locationServiceDisabled => 'Location services disabled';
  @override
  String get gettingLocation => 'Getting location...';
  @override
  String get locationError => 'Location error';
  @override
  String get locationAccuracy => 'Location Accuracy';
  @override
  String get highAccuracy => 'High Accuracy';
  @override
  String get mediumAccuracy => 'Medium Accuracy';
  @override
  String get lowAccuracy => 'Low Accuracy';
  @override
  String get gpsSignal => 'GPS Signal';
  @override
  String get noGpsSignal => 'No GPS Signal';
  @override
  String get waitingForGps => 'Waiting for GPS...';

  // Logs
  @override
  String get viewLogs => 'View Logs';
  @override
  String get clearLogs => 'Clear Logs';
  @override
  String get exportLogs => 'Export Logs';
  @override
  String get logLevel => 'Log Level';
  @override
  String get logInfo => 'Info';
  @override
  String get logWarning => 'Warning';
  @override
  String get logError => 'Error';
  @override
  String get noLogs => 'No logs';
  @override
  String get logsCleared => 'Logs cleared';
  @override
  String get logsExported => 'Logs exported';

  // History
  @override
  String get catchHistory => 'Catch History';
  @override
  String get filterBy => 'Filter by';
  @override
  String get filterByType => 'By Type';
  @override
  String get filterByDate => 'By Date';
  @override
  String get filterByLocation => 'By Location';
  @override
  String get sortBy => 'Sort by';
  @override
  String get sortByDate => 'By Date';
  @override
  String get sortByType => 'By Type';
  @override
  String get sortByDistance => 'By Distance';
  @override
  String get ascending => 'Ascending';
  @override
  String get descending => 'Descending';
  @override
  String get today => 'Today';
  @override
  String get yesterday => 'Yesterday';
  @override
  String get thisWeek => 'This Week';
  @override
  String get thisMonth => 'This Month';
  @override
  String get allTime => 'All Time';

  // Statistics
  @override
  String get statistics => 'Statistics';
  @override
  String get totalCatches => 'Total Catches';
  @override
  String get fishOnCount => 'Fish ON';
  @override
  String get doubleCount => 'Double';
  @override
  String get tripleCount => 'Triple';
  @override
  String get averagePerDay => 'Average per Day';
  @override
  String get bestDay => 'Best Day';
  @override
  String get bestLocation => 'Best Location';
  @override
  String get longestStreak => 'Longest Streak';
  @override
  String get currentStreak => 'Current Streak';

  // Errors and Messages
  @override
  String get connectionError => 'Connection error';
  @override
  String get serverUnavailable => 'Server unavailable';
  @override
  String get timeoutError => 'Timeout error';
  @override
  String get dataCorrupted => 'Data corrupted';
  @override
  String get insufficientStorage => 'Insufficient storage';
  @override
  String get permissionDenied => 'Permission denied';
  @override
  String get featureNotAvailable => 'Feature not available';
  @override
  String get updateRequired => 'Update required';
  @override
  String get maintenanceMode => 'Maintenance mode';
  @override
  String get rateLimitExceeded => 'Rate limit exceeded';

  // Dialogs
  @override
  String get confirmDelete => 'Confirm delete';
  @override
  String get confirmClear => 'Confirm clear';
  @override
  String get confirmLogout => 'Confirm logout';
  @override
  String get confirmExit => 'Confirm exit';
  @override
  String get unsavedChanges => 'Unsaved changes';
  @override
  String get discardChanges => 'Discard changes';
  @override
  String get saveChanges => 'Save changes';

  // Time
  @override
  String get now => 'Now';
  @override
  String get minutesAgo => 'minutes ago';
  @override
  String get hoursAgo => 'hours ago';
  @override
  String get daysAgo => 'days ago';
  @override
  String get weeksAgo => 'weeks ago';
  @override
  String get monthsAgo => 'months ago';
  @override
  String get yearsAgo => 'years ago';

  // Units
  @override
  String get meters => 'm';
  @override
  String get kilometers => 'km';
  @override
  String get feet => 'ft';
  @override
  String get miles => 'mi';
  @override
  String get degrees => '°';
  @override
  String get seconds => 'sec';
  @override
  String get minutes => 'min';
  @override
  String get hours => 'h';
  @override
  String get days => 'd';

  // Directions
  @override
  String get north => 'N';
  @override
  String get south => 'S';
  @override
  String get east => 'E';
  @override
  String get west => 'W';
  @override
  String get northeast => 'NE';
  @override
  String get northwest => 'NW';
  @override
  String get southeast => 'SE';
  @override
  String get southwest => 'SW';

  // Additional strings for logs
  @override
  String get clearAllLogs => 'Clear All';
  
  @override
  String get clearLogsTitle => 'Clear Logs';
  
  @override
  String get clearLogsConfirm => 'Are you sure you want to delete all logs?';
  
  @override
  String get filterByLevel => 'Filter by level:';
  
  @override
  String get all => 'All';
  
  @override
  String get infoLogs => 'Info';
  
  @override
  String get warningLogs => 'Warnings';
  
  @override
  String get errorLogs => 'Errors';
  
  @override
  String get loadingLogsError => 'Error loading logs';
  
  @override
  String get clearingError => 'Clearing error';

  // Additional strings for full localization
  @override
  String get retryInterval => 'Retry Interval';
  
  @override
  String get minutesShort => 'min';
  
  @override
  String get account => 'Account';
  
  @override
  String get pendingSend => 'Pending Send';
  
  @override
  String get catchMap => 'Catch Map';
  
  @override
  String get catches => 'catches';

  @override
  String get cooldownMessage => 'sec minimum cooldown';

  @override
  String get dailyLimitReached => 'Daily limit reached';

  @override
  String get catchSaved => 'Catch saved!';

  @override
  String get locationPermissionNeeded => 'Location permission needed';

  @override
  String get status => 'Status';

  @override
  String get locationPermissionDescription => 'Location permission is required to create a catch.';

  @override
  String get pleaseGrantPermission => 'Please grant permission in settings.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get permissionGranted => 'Permission granted!';

  @override
  String get nameCannotBeEmpty => 'Name cannot be empty';

  @override
  String get nameCannotBeLonger => 'Name cannot be longer than';

  @override
  String get symbols => 'characters';

  @override
  String get nameNotChanged => 'Name not changed';

  @override
  String get nameSaved => 'Name saved';

  @override
  String get intervalSaved => 'Interval saved';

  @override
  String get minute => 'minute';

  @override
  String get minutes2to4 => 'minutes';

  @override
  String get minutes5plus => 'minutes';

  @override
  String get clearAllData => 'Clear all data';

  @override
  String get clearAllDataConfirmation => 'This will delete all catches and logs. This action cannot be undone. Continue?';

  @override
  String get dataCleared => 'Data cleared';

  @override
  String get offline => 'Offline';

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String get appDescription => 'Application for the Cyprus fishing community. Allows quick sharing of tuna catch information.';

  @override
  String get developedForSea => 'Developed for use at sea without stable internet connection.';

  @override
  String get languageLabel => 'Language / Язык';

  @override
  String get chooseLanguage => 'Choose Language / Выберите язык';

  @override
  String get cancelSlashCancel => 'Cancel / Отмена';

  @override
  String get languageChanged => 'Language changed / Язык изменен';

  @override
  String get signOutTitle => 'Sign out';

  @override
  String get signOutConfirmation => 'Are you sure you want to sign out? All unsaved data will be lost.';

  @override
  String get signOut => 'Sign out';
}
