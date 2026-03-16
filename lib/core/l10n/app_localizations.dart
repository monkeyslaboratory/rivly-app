import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLocales = [Locale('en'), Locale('ru')];

  bool get isRussian => locale.languageCode == 'ru';

  // Helper
  String _t(String en, String ru) => isRussian ? ru : en;

  // -- Common --
  String get appName => 'Rivly';
  String get loading => _t('Loading...', '\u0417\u0430\u0433\u0440\u0443\u0437\u043a\u0430...');
  String get error => _t('Error', '\u041e\u0448\u0438\u0431\u043a\u0430');
  String get retry => _t('Retry', '\u041f\u043e\u0432\u0442\u043e\u0440\u0438\u0442\u044c');
  String get cancel => _t('Cancel', '\u041e\u0442\u043c\u0435\u043d\u0430');
  String get save => _t('Save', '\u0421\u043e\u0445\u0440\u0430\u043d\u0438\u0442\u044c');
  String get delete => _t('Delete', '\u0423\u0434\u0430\u043b\u0438\u0442\u044c');
  String get back => _t('Back', '\u041d\u0430\u0437\u0430\u0434');
  String get next => _t('Continue', '\u041f\u0440\u043e\u0434\u043e\u043b\u0436\u0438\u0442\u044c');
  String get skip => _t('Skip', '\u041f\u0440\u043e\u043f\u0443\u0441\u0442\u0438\u0442\u044c');
  String get close => _t('Close', '\u0417\u0430\u043a\u0440\u044b\u0442\u044c');
  String get done => _t('Done', '\u0413\u043e\u0442\u043e\u0432\u043e');
  String get yes => _t('Yes', '\u0414\u0430');
  String get no => _t('No', '\u041d\u0435\u0442');

  // -- Auth --
  String get signIn => _t('Sign In', '\u0412\u043e\u0439\u0442\u0438');
  String get signUp => _t('Sign Up', '\u0420\u0435\u0433\u0438\u0441\u0442\u0440\u0430\u0446\u0438\u044f');
  String get signOut => _t('Sign Out', '\u0412\u044b\u0439\u0442\u0438');
  String get email => _t('Email', 'Email');
  String get password => _t('Password', '\u041f\u0430\u0440\u043e\u043b\u044c');
  String get username => _t('Username', '\u0418\u043c\u044f \u043f\u043e\u043b\u044c\u0437\u043e\u0432\u0430\u0442\u0435\u043b\u044f');
  String get forgotPassword => _t('Forgot password?', '\u0417\u0430\u0431\u044b\u043b\u0438 \u043f\u0430\u0440\u043e\u043b\u044c?');
  String get dontHaveAccount =>
      _t("Don't have an account?", '\u041d\u0435\u0442 \u0430\u043a\u043a\u0430\u0443\u043d\u0442\u0430?');
  String get alreadyHaveAccount =>
      _t('Already have an account?', '\u0423\u0436\u0435 \u0435\u0441\u0442\u044c \u0430\u043a\u043a\u0430\u0443\u043d\u0442?');
  String get continueWithGoogle =>
      _t('Continue with Google', '\u0412\u043e\u0439\u0442\u0438 \u0447\u0435\u0440\u0435\u0437 Google');
  String get competitiveIntelligence => _t(
      'Competitive intelligence, automated.',
      '\u041a\u043e\u043d\u043a\u0443\u0440\u0435\u043d\u0442\u043d\u0430\u044f \u0440\u0430\u0437\u0432\u0435\u0434\u043a\u0430, \u0430\u0432\u0442\u043e\u043c\u0430\u0442\u0438\u0447\u0435\u0441\u043a\u0438.');

  // -- Dashboard --
  String get dashboard => _t('Dashboard', '\u041f\u0430\u043d\u0435\u043b\u044c \u0443\u043f\u0440\u0430\u0432\u043b\u0435\u043d\u0438\u044f');
  String get noAnalysesYet => _t('No analyses yet', '\u0410\u043d\u0430\u043b\u0438\u0437\u043e\u0432 \u043f\u043e\u043a\u0430 \u043d\u0435\u0442');
  String get createFirstAnalysis =>
      _t('Create First Analysis', '\u0421\u043e\u0437\u0434\u0430\u0442\u044c \u043f\u0435\u0440\u0432\u044b\u0439 \u0430\u043d\u0430\u043b\u0438\u0437');
  String get setUpFirstAnalysis => _t(
      'Set up your first competitor analysis in under 2 minutes',
      '\u041d\u0430\u0441\u0442\u0440\u043e\u0439\u0442\u0435 \u043f\u0435\u0440\u0432\u044b\u0439 \u0430\u043d\u0430\u043b\u0438\u0437 \u043a\u043e\u043d\u043a\u0443\u0440\u0435\u043d\u0442\u043e\u0432 \u043c\u0435\u043d\u0435\u0435 \u0447\u0435\u043c \u0437\u0430 2 \u043c\u0438\u043d\u0443\u0442\u044b');
  String get freePlanInfo => _t(
      'Free plan includes 1 job with 2 competitors',
      '\u0411\u0435\u0441\u043f\u043b\u0430\u0442\u043d\u044b\u0439 \u043f\u043b\u0430\u043d: 1 \u0437\u0430\u0434\u0430\u0447\u0430, 2 \u043a\u043e\u043d\u043a\u0443\u0440\u0435\u043d\u0442\u0430');
  String get yourJobs => _t('Your Jobs', '\u0412\u0430\u0448\u0438 \u0437\u0430\u0434\u0430\u0447\u0438');
  String get recentRuns => _t('Recent Runs', '\u041f\u043e\u0441\u043b\u0435\u0434\u043d\u0438\u0435 \u0437\u0430\u043f\u0443\u0441\u043a\u0438');
  String get newJob => _t('New Job', '\u041d\u043e\u0432\u0430\u044f \u0437\u0430\u0434\u0430\u0447\u0430');
  String get deleteJob => _t('Delete Job', '\u0423\u0434\u0430\u043b\u0438\u0442\u044c \u0437\u0430\u0434\u0430\u0447\u0443');
  String get confirmDelete =>
      _t('Are you sure you want to delete', '\u0412\u044b \u0443\u0432\u0435\u0440\u0435\u043d\u044b, \u0447\u0442\u043e \u0445\u043e\u0442\u0438\u0442\u0435 \u0443\u0434\u0430\u043b\u0438\u0442\u044c');
  String get run => _t('Run', '\u0417\u0430\u043f\u0443\u0441\u043a');
  String competitors(int n) => _t('$n competitors', '$n \u043a\u043e\u043d\u043a\u0443\u0440\u0435\u043d\u0442\u043e\u0432');

  // -- Job Creation Modal --
  String get newAnalysis => _t('New Analysis', '\u041d\u043e\u0432\u044b\u0439 \u0430\u043d\u0430\u043b\u0438\u0437');
  String get productUrl =>
      _t("What's your product URL?", 'URL \u0432\u0430\u0448\u0435\u0433\u043e \u043f\u0440\u043e\u0434\u0443\u043a\u0442\u0430');
  String get analyze => _t('Analyze', '\u0410\u043d\u0430\u043b\u0438\u0437\u0438\u0440\u043e\u0432\u0430\u0442\u044c');
  String get analyzingProduct =>
      _t('Analyzing your product...', '\u0410\u043d\u0430\u043b\u0438\u0437\u0438\u0440\u0443\u0435\u043c \u0432\u0430\u0448 \u043f\u0440\u043e\u0434\u0443\u043a\u0442...');
  String get edit => _t('Edit', '\u0418\u0437\u043c\u0435\u043d\u0438\u0442\u044c');
  String get competitorsStep => _t('Competitors', '\u041a\u043e\u043d\u043a\u0443\u0440\u0435\u043d\u0442\u044b');
  String get findWithAi =>
      _t('Find competitors with AI', '\u041d\u0430\u0439\u0442\u0438 \u043a\u043e\u043d\u043a\u0443\u0440\u0435\u043d\u0442\u043e\u0432 \u0441 \u043f\u043e\u043c\u043e\u0449\u044c\u044e AI');
  String get discoverCompetitors =>
      _t('Discover Competitors', '\u041d\u0430\u0439\u0442\u0438 \u043a\u043e\u043d\u043a\u0443\u0440\u0435\u043d\u0442\u043e\u0432');
  String get discoveringCompetitors => _t(
      'Discovering competitors with AI...',
      '\u0418\u0449\u0435\u043c \u043a\u043e\u043d\u043a\u0443\u0440\u0435\u043d\u0442\u043e\u0432 \u0441 \u043f\u043e\u043c\u043e\u0449\u044c\u044e AI...');
  String get autoFind => _t('Auto-find', '\u0410\u0432\u0442\u043e\u043f\u043e\u0438\u0441\u043a');
  String get aiWillDiscover => _t(
      'AI will discover competitors after analysis',
      'AI \u043d\u0430\u0439\u0434\u0451\u0442 \u043a\u043e\u043d\u043a\u0443\u0440\u0435\u043d\u0442\u043e\u0432 \u043f\u043e\u0441\u043b\u0435 \u0430\u043d\u0430\u043b\u0438\u0437\u0430');
  String get enterManually =>
      _t('Enter competitor URLs manually', '\u0412\u0432\u0435\u0434\u0438\u0442\u0435 URL \u043a\u043e\u043d\u043a\u0443\u0440\u0435\u043d\u0442\u043e\u0432 \u0432\u0440\u0443\u0447\u043d\u0443\u044e');
  String get accessCheck => _t('Access Check', '\u041f\u0440\u043e\u0432\u0435\u0440\u043a\u0430 \u0434\u043e\u0441\u0442\u0443\u043f\u0430');
  String get verifyingAccess => _t(
      'Verifying competitor accessibility',
      '\u041f\u0440\u043e\u0432\u0435\u0440\u044f\u0435\u043c \u0434\u043e\u0441\u0442\u0443\u043f\u043d\u043e\u0441\u0442\u044c \u043a\u043e\u043d\u043a\u0443\u0440\u0435\u043d\u0442\u043e\u0432');
  String get accessible => _t('Accessible', '\u0414\u043e\u0441\u0442\u0443\u043f\u0435\u043d');
  String get blocked => _t('Blocked', '\u0417\u0430\u0431\u043b\u043e\u043a\u0438\u0440\u043e\u0432\u0430\u043d');
  String get geoRestricted => _t('Geo-restricted', '\u0413\u0435\u043e\u0431\u043b\u043e\u043a\u0438\u0440\u043e\u0432\u043a\u0430');
  String get checking => _t('Checking...', '\u041f\u0440\u043e\u0432\u0435\u0440\u044f\u0435\u043c...');
  String get schedule => _t('Schedule', '\u0420\u0430\u0441\u043f\u0438\u0441\u0430\u043d\u0438\u0435');
  String get setAnalysisCadence =>
      _t('Set your analysis cadence', '\u0427\u0430\u0441\u0442\u043e\u0442\u0430 \u0430\u043d\u0430\u043b\u0438\u0437\u0430');
  String get oneTime => _t('One-time', '\u0420\u0430\u0437\u043e\u0432\u044b\u0439');
  String get runOnce =>
      _t('Run the analysis once', '\u0417\u0430\u043f\u0443\u0441\u0442\u0438\u0442\u044c \u0430\u043d\u0430\u043b\u0438\u0437 \u043e\u0434\u0438\u043d \u0440\u0430\u0437');
  String get weekly => _t('Weekly', '\u0415\u0436\u0435\u043d\u0435\u0434\u0435\u043b\u044c\u043d\u043e');
  String get repeatWeekly =>
      _t('Repeat every week', '\u041f\u043e\u0432\u0442\u043e\u0440\u044f\u0442\u044c \u043a\u0430\u0436\u0434\u0443\u044e \u043d\u0435\u0434\u0435\u043b\u044e');
  String get biweekly => _t('Bi-weekly', '\u0420\u0430\u0437 \u0432 2 \u043d\u0435\u0434\u0435\u043b\u0438');
  String get repeatBiweekly =>
      _t('Repeat every two weeks', '\u041f\u043e\u0432\u0442\u043e\u0440\u044f\u0442\u044c \u043a\u0430\u0436\u0434\u044b\u0435 \u0434\u0432\u0435 \u043d\u0435\u0434\u0435\u043b\u0438');
  String get monthly => _t('Monthly', '\u0415\u0436\u0435\u043c\u0435\u0441\u044f\u0447\u043d\u043e');
  String get repeatMonthly =>
      _t('Repeat every month', '\u041f\u043e\u0432\u0442\u043e\u0440\u044f\u0442\u044c \u043a\u0430\u0436\u0434\u044b\u0439 \u043c\u0435\u0441\u044f\u0446');
  String get dayOfWeek => _t('Day of week', '\u0414\u0435\u043d\u044c \u043d\u0435\u0434\u0435\u043b\u0438');
  String get dayOfMonth => _t('Day of month', '\u0414\u0435\u043d\u044c \u043c\u0435\u0441\u044f\u0446\u0430');
  String get time => _t('Time', '\u0412\u0440\u0435\u043c\u044f');
  String get device => _t('Device', '\u0423\u0441\u0442\u0440\u043e\u0439\u0441\u0442\u0432\u043e');
  String get chooseDevices =>
      _t('Choose target devices', '\u0412\u044b\u0431\u0435\u0440\u0438\u0442\u0435 \u0443\u0441\u0442\u0440\u043e\u0439\u0441\u0442\u0432\u0430');
  String get desktopOnly => _t('Desktop only', '\u0422\u043e\u043b\u044c\u043a\u043e \u0434\u0435\u0441\u043a\u0442\u043e\u043f');
  String get mobileOnly => _t('Mobile only', '\u0422\u043e\u043b\u044c\u043a\u043e \u043c\u043e\u0431\u0438\u043b\u044c\u043d\u044b\u0439');
  String get both => _t('Both', '\u041e\u0431\u0430');
  String get desktopViewport =>
      _t('Standard desktop viewport', '\u0421\u0442\u0430\u043d\u0434\u0430\u0440\u0442\u043d\u044b\u0439 \u0434\u0435\u0441\u043a\u0442\u043e\u043f\u043d\u044b\u0439 \u0432\u044c\u044e\u043f\u043e\u0440\u0442');
  String get mobileViewport =>
      _t('Mobile viewport (375px)', '\u041c\u043e\u0431\u0438\u043b\u044c\u043d\u044b\u0439 \u0432\u044c\u044e\u043f\u043e\u0440\u0442 (375px)');
  String get bothViewports =>
      _t('Desktop & mobile viewports', '\u0414\u0435\u0441\u043a\u0442\u043e\u043f\u043d\u044b\u0439 \u0438 \u043c\u043e\u0431\u0438\u043b\u044c\u043d\u044b\u0439 \u0432\u044c\u044e\u043f\u043e\u0440\u0442');
  String get reviewLaunch => _t('Review & Launch', '\u041e\u0431\u0437\u043e\u0440 \u0438 \u0437\u0430\u043f\u0443\u0441\u043a');
  String get confirmLaunch =>
      _t('Confirm and launch your analysis', '\u041f\u043e\u0434\u0442\u0432\u0435\u0440\u0434\u0438\u0442\u0435 \u0438 \u0437\u0430\u043f\u0443\u0441\u0442\u0438\u0442\u0435 \u0430\u043d\u0430\u043b\u0438\u0437');
  String get product => _t('Product', '\u041f\u0440\u043e\u0434\u0443\u043a\u0442');
  String get analysisAreas => _t('Analysis areas', '\u041e\u0431\u043b\u0430\u0441\u0442\u0438 \u0430\u043d\u0430\u043b\u0438\u0437\u0430');
  String get fullAutoAnalysis =>
      _t('Full auto-analysis', '\u041f\u043e\u043b\u043d\u044b\u0439 \u0430\u0432\u0442\u043e\u0430\u043d\u0430\u043b\u0438\u0437');
  String get launchAnalysis =>
      _t('Launch Analysis', '\u0417\u0430\u043f\u0443\u0441\u0442\u0438\u0442\u044c \u0430\u043d\u0430\u043b\u0438\u0437');
  String get creatingAnalysis =>
      _t('Creating analysis...', '\u0421\u043e\u0437\u0434\u0430\u0451\u043c \u0430\u043d\u0430\u043b\u0438\u0437...');
  String get analysisStarted =>
      _t('Analysis started!', '\u0410\u043d\u0430\u043b\u0438\u0437 \u0437\u0430\u043f\u0443\u0449\u0435\u043d!');
  String get jobName => _t('Job Name', '\u041d\u0430\u0437\u0432\u0430\u043d\u0438\u0435 \u0437\u0430\u0434\u0430\u0447\u0438');

  // -- Run Progress --
  String get runProgress => _t('Run Progress', '\u041f\u0440\u043e\u0433\u0440\u0435\u0441\u0441 \u0430\u043d\u0430\u043b\u0438\u0437\u0430');
  String get estimating => _t('Estimating...', '\u041e\u0446\u0435\u043d\u0438\u0432\u0430\u0435\u043c...');
  String get starting => _t('Starting...', '\u0417\u0430\u043f\u0443\u0441\u043a\u0430\u0435\u043c...');
  String get almostDone => _t('Almost done...', '\u041f\u043e\u0447\u0442\u0438 \u0433\u043e\u0442\u043e\u0432\u043e...');
  String remaining(String time) =>
      _t('~$time remaining', '~$time \u043e\u0441\u0442\u0430\u043b\u043e\u0441\u044c');
  String get preflight => _t('Preflight', '\u041f\u0440\u0435\u0434\u0432\u0430\u0440\u0438\u0442\u0435\u043b\u044c\u043d\u0430\u044f \u043f\u0440\u043e\u0432\u0435\u0440\u043a\u0430');
  String get screenshots => _t('Screenshots', '\u0421\u043a\u0440\u0438\u043d\u0448\u043e\u0442\u044b');
  String get aiAnalysis => _t('AI Analysis', 'AI-\u0430\u043d\u0430\u043b\u0438\u0437');
  String get scoring => _t('Scoring', '\u041e\u0446\u0435\u043d\u043a\u0430');
  String get comparison => _t('Comparison', '\u0421\u0440\u0430\u0432\u043d\u0435\u043d\u0438\u0435');
  String get review => _t('Review', '\u041e\u0431\u0437\u043e\u0440');
  String get complete => _t('Complete', '\u0417\u0430\u0432\u0435\u0440\u0448\u0435\u043d\u043e');
  String get failed => _t('Failed', '\u041e\u0448\u0438\u0431\u043a\u0430');
  String get reviewRequired =>
      _t('Review Required', '\u0422\u0440\u0435\u0431\u0443\u0435\u0442\u0441\u044f \u043f\u0440\u043e\u0432\u0435\u0440\u043a\u0430');
  String get reviewDiscoveredPages =>
      _t('Review Discovered Pages', '\u041f\u043e\u0441\u043c\u043e\u0442\u0440\u0435\u0442\u044c \u043d\u0430\u0439\u0434\u0435\u043d\u043d\u044b\u0435 \u0441\u0442\u0440\u0430\u043d\u0438\u0446\u044b');
  String get viewReport => _t('View Report', '\u041f\u0440\u043e\u0441\u043c\u043e\u0442\u0440 \u043e\u0442\u0447\u0451\u0442\u0430');
  String get backToDashboard =>
      _t('Back to Dashboard', '\u0412\u0435\u0440\u043d\u0443\u0442\u044c\u0441\u044f \u043d\u0430 \u043f\u0430\u043d\u0435\u043b\u044c');

  // -- Review Screen --
  String get reviewPages => _t('Review Pages', '\u041e\u0431\u0437\u043e\u0440 \u0441\u0442\u0440\u0430\u043d\u0438\u0446');
  String pagesFound(int n) => _t('We found $n pages', '\u041d\u0430\u0439\u0434\u0435\u043d\u043e $n \u0441\u0442\u0440\u0430\u043d\u0438\u0446');
  String pagesCaptured(int n) =>
      _t('$n captured successfully', '$n \u0443\u0441\u043f\u0435\u0448\u043d\u043e \u0437\u0430\u0445\u0432\u0430\u0447\u0435\u043d\u043e');
  String get reviewInstructions => _t(
        'Review the discovered pages. Uncheck any pages you want to exclude, or add custom URLs below. Then start AI analysis.',
        '\u041f\u0440\u043e\u0441\u043c\u043e\u0442\u0440\u0438\u0442\u0435 \u043d\u0430\u0439\u0434\u0435\u043d\u043d\u044b\u0435 \u0441\u0442\u0440\u0430\u043d\u0438\u0446\u044b. \u0421\u043d\u0438\u043c\u0438\u0442\u0435 \u043e\u0442\u043c\u0435\u0442\u043a\u0443 \u0441\u043e \u0441\u0442\u0440\u0430\u043d\u0438\u0446, \u043a\u043e\u0442\u043e\u0440\u044b\u0435 \u0445\u043e\u0442\u0438\u0442\u0435 \u0438\u0441\u043a\u043b\u044e\u0447\u0438\u0442\u044c, \u0438\u043b\u0438 \u0434\u043e\u0431\u0430\u0432\u044c\u0442\u0435 \u0441\u0432\u043e\u0438 URL \u043d\u0438\u0436\u0435. \u0417\u0430\u0442\u0435\u043c \u0437\u0430\u043f\u0443\u0441\u0442\u0438\u0442\u0435 AI-\u0430\u043d\u0430\u043b\u0438\u0437.',
      );
  String get addCustomPage =>
      _t('Add a custom page', '\u0414\u043e\u0431\u0430\u0432\u0438\u0442\u044c \u0441\u0432\u043e\u044e \u0441\u0442\u0440\u0430\u043d\u0438\u0446\u0443');
  String get addCustomPageHint => _t(
      "Add a specific URL that wasn't discovered automatically.",
      '\u0414\u043e\u0431\u0430\u0432\u044c\u0442\u0435 URL, \u043a\u043e\u0442\u043e\u0440\u044b\u0439 \u043d\u0435 \u0431\u044b\u043b \u043d\u0430\u0439\u0434\u0435\u043d \u0430\u0432\u0442\u043e\u043c\u0430\u0442\u0438\u0447\u0435\u0441\u043a\u0438.');
  String get add => _t('Add', '\u0414\u043e\u0431\u0430\u0432\u0438\u0442\u044c');
  String pagesSelected(int n) =>
      _t('$n page${n == 1 ? '' : 's'} selected', '$n \u0441\u0442\u0440. \u0432\u044b\u0431\u0440\u0430\u043d\u043e');
  String get selectAtLeastOne =>
      _t('Select at least one page', '\u0412\u044b\u0431\u0435\u0440\u0438\u0442\u0435 \u0445\u043e\u0442\u044f \u0431\u044b \u043e\u0434\u043d\u0443 \u0441\u0442\u0440\u0430\u043d\u0438\u0446\u0443');
  String get startAnalysis => _t('Start Analysis', '\u041d\u0430\u0447\u0430\u0442\u044c \u0430\u043d\u0430\u043b\u0438\u0437');

  // -- Auth Wall --
  String pagesRequireLogin(int n) =>
      _t('$n page${n == 1 ? '' : 's'} require login',
          '$n \u0441\u0442\u0440. \u0442\u0440\u0435\u0431\u0443\u044e\u0442 \u0430\u0432\u0442\u043e\u0440\u0438\u0437\u0430\u0446\u0438\u0438');
  String get authWallDescription => _t(
        'These pages show a login form instead of content. Provide credentials to capture the authenticated experience.',
        '\u042d\u0442\u0438 \u0441\u0442\u0440\u0430\u043d\u0438\u0446\u044b \u043f\u043e\u043a\u0430\u0437\u044b\u0432\u0430\u044e\u0442 \u0444\u043e\u0440\u043c\u0443 \u0432\u0445\u043e\u0434\u0430 \u0432\u043c\u0435\u0441\u0442\u043e \u043a\u043e\u043d\u0442\u0435\u043d\u0442\u0430. \u0423\u043a\u0430\u0436\u0438\u0442\u0435 \u0443\u0447\u0451\u0442\u043d\u044b\u0435 \u0434\u0430\u043d\u043d\u044b\u0435 \u0434\u043b\u044f \u0437\u0430\u0445\u0432\u0430\u0442\u0430 \u0430\u0432\u0442\u043e\u0440\u0438\u0437\u043e\u0432\u0430\u043d\u043d\u043e\u0433\u043e \u0438\u043d\u0442\u0435\u0440\u0444\u0435\u0439\u0441\u0430.',
      );
  String get loginCredentials =>
      _t('Login Credentials', '\u0423\u0447\u0451\u0442\u043d\u044b\u0435 \u0434\u0430\u043d\u043d\u044b\u0435');
  String get credentialsPrivacy => _t(
        'Credentials are used only for this analysis and are not shared with third parties.',
        '\u0423\u0447\u0451\u0442\u043d\u044b\u0435 \u0434\u0430\u043d\u043d\u044b\u0435 \u0438\u0441\u043f\u043e\u043b\u044c\u0437\u0443\u044e\u0442\u0441\u044f \u0442\u043e\u043b\u044c\u043a\u043e \u0434\u043b\u044f \u044d\u0442\u043e\u0433\u043e \u0430\u043d\u0430\u043b\u0438\u0437\u0430 \u0438 \u043d\u0435 \u043f\u0435\u0440\u0435\u0434\u0430\u044e\u0442\u0441\u044f \u0442\u0440\u0435\u0442\u044c\u0438\u043c \u043b\u0438\u0446\u0430\u043c.',
      );
  String get loginUrl =>
      _t('Login URL (optional)', 'URL \u0441\u0442\u0440\u0430\u043d\u0438\u0446\u044b \u0432\u0445\u043e\u0434\u0430 (\u043d\u0435\u043e\u0431\u044f\u0437\u0430\u0442\u0435\u043b\u044c\u043d\u043e)');
  String get emailOrUsername => _t('Email / Username', 'Email / \u041b\u043e\u0433\u0438\u043d');
  String get authenticateRecapture =>
      _t('Authenticate & Re-capture', '\u0410\u0432\u0442\u043e\u0440\u0438\u0437\u043e\u0432\u0430\u0442\u044c\u0441\u044f \u0438 \u043f\u0435\u0440\u0435\u0437\u0430\u0445\u0432\u0430\u0442\u0438\u0442\u044c');
  String get skipAuthNote => _t(
        'Or skip \u2014 analysis will only cover publicly accessible pages.',
        '\u0418\u043b\u0438 \u043f\u0440\u043e\u043f\u0443\u0441\u0442\u0438\u0442\u0435 \u2014 \u0430\u043d\u0430\u043b\u0438\u0437 \u0431\u0443\u0434\u0435\u0442 \u043e\u0445\u0432\u0430\u0442\u044b\u0432\u0430\u0442\u044c \u0442\u043e\u043b\u044c\u043a\u043e \u043f\u0443\u0431\u043b\u0438\u0447\u043d\u044b\u0435 \u0441\u0442\u0440\u0430\u043d\u0438\u0446\u044b.',
      );
  String get loginRequired => _t('login required', '\u0442\u0440\u0435\u0431\u0443\u0435\u0442\u0441\u044f \u0432\u0445\u043e\u0434');
  String get authFailed => _t('auth failed', '\u043e\u0448\u0438\u0431\u043a\u0430 \u0432\u0445\u043e\u0434\u0430');
  String get authenticating => _t('Authenticating...', '\u0410\u0432\u0442\u043e\u0440\u0438\u0437\u0430\u0446\u0438\u044f...');
  String get authSuccess =>
      _t('Authenticated pages re-captured!', '\u0410\u0432\u0442\u043e\u0440\u0438\u0437\u043e\u0432\u0430\u043d\u043d\u044b\u0435 \u0441\u0442\u0440\u0430\u043d\u0438\u0446\u044b \u043f\u0435\u0440\u0435\u0437\u0430\u0445\u0432\u0430\u0447\u0435\u043d\u044b!');

  // -- Report --
  String get analysisReport => _t('Analysis Report', '\u041e\u0442\u0447\u0451\u0442 \u043f\u043e \u0430\u043d\u0430\u043b\u0438\u0437\u0443');
  String get analysisComplete =>
      _t('Analysis Complete', '\u0410\u043d\u0430\u043b\u0438\u0437 \u0437\u0430\u0432\u0435\u0440\u0448\u0451\u043d');
  String get analysisFailed =>
      _t('Analysis Failed', '\u0410\u043d\u0430\u043b\u0438\u0437 \u043d\u0435 \u0443\u0434\u0430\u043b\u0441\u044f');
  String get inProgress => _t('In Progress', '\u0412 \u043f\u0440\u043e\u0446\u0435\u0441\u0441\u0435');
  String completedIn(String duration) =>
      _t('Completed in $duration', '\u0417\u0430\u0432\u0435\u0440\u0448\u0451\u043d \u0437\u0430 $duration');
  String get competitorScores =>
      _t('Competitor Scores', '\u041e\u0446\u0435\u043d\u043a\u0438 \u043a\u043e\u043d\u043a\u0443\u0440\u0435\u043d\u0442\u043e\u0432');
  String get executiveSummary =>
      _t('Executive Summary', '\u041a\u043b\u044e\u0447\u0435\u0432\u044b\u0435 \u0432\u044b\u0432\u043e\u0434\u044b');
  String get competitivePosition =>
      _t('Competitive Position', '\u041a\u043e\u043d\u043a\u0443\u0440\u0435\u043d\u0442\u043d\u0430\u044f \u043f\u043e\u0437\u0438\u0446\u0438\u044f');
  String get publicPages => _t('Public Pages', '\u041f\u0443\u0431\u043b\u0438\u0447\u043d\u044b\u0435 \u0441\u0442\u0440\u0430\u043d\u0438\u0446\u044b');
  String get authenticatedPages =>
      _t('Authenticated Pages', '\u0410\u0432\u0442\u043e\u0440\u0438\u0437\u043e\u0432\u0430\u043d\u043d\u044b\u0435 \u0441\u0442\u0440\u0430\u043d\u0438\u0446\u044b');
  String get detailedAnalysis =>
      _t('Detailed Analysis', '\u0414\u0435\u0442\u0430\u043b\u044c\u043d\u044b\u0439 \u0430\u043d\u0430\u043b\u0438\u0437');
  String get featureMatrix => _t('Feature Matrix', '\u041c\u0430\u0442\u0440\u0438\u0446\u0430 \u0444\u0438\u0447');
  String get recommendations =>
      _t('Recommendations', '\u0420\u0435\u043a\u043e\u043c\u0435\u043d\u0434\u0430\u0446\u0438\u0438');
  String get noDataYet =>
      _t('No analysis data available yet.', '\u0414\u0430\u043d\u043d\u044b\u0435 \u0430\u043d\u0430\u043b\u0438\u0437\u0430 \u043f\u043e\u043a\u0430 \u043d\u0435\u0434\u043e\u0441\u0442\u0443\u043f\u043d\u044b.');

  // -- Settings --
  String get settings => _t('Settings', '\u041d\u0430\u0441\u0442\u0440\u043e\u0439\u043a\u0438');
  String get language => _t('Language', '\u042f\u0437\u044b\u043a');
  String get theme => _t('Theme', '\u0422\u0435\u043c\u0430');
  String get darkMode => _t('Dark mode', '\u0422\u0451\u043c\u043d\u0430\u044f \u0442\u0435\u043c\u0430');
  String get lightMode => _t('Light mode', '\u0421\u0432\u0435\u0442\u043b\u0430\u044f \u0442\u0435\u043c\u0430');

  // -- Days --
  List<String> get weekDays => isRussian
      ? ['\u041f\u043d', '\u0412\u0442', '\u0421\u0440', '\u0427\u0442', '\u041f\u0442', '\u0421\u0431', '\u0412\u0441']
      : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ru'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
