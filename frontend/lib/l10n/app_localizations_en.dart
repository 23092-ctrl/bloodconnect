// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'BloodConnect';

  @override
  String get tagline => 'Saving lives, together';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInSubtitle => 'Sign in to continue saving lives';

  @override
  String get signIn => 'Sign In';

  @override
  String get signOut => 'Sign Out';

  @override
  String get createAccount => 'Create Account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get fullName => 'Full Name';

  @override
  String get phone => 'Phone';

  @override
  String get bloodType => 'Blood Type';

  @override
  String get gender => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get noAccount => 'Don\'t have an account? Register';

  @override
  String get home => 'Home';

  @override
  String get donations => 'Donations';

  @override
  String get map => 'Map';

  @override
  String get alerts => 'Alerts';

  @override
  String get profile => 'Profile';

  @override
  String get admin => 'Admin';

  @override
  String get notifications => 'Notifications';

  @override
  String get donate => 'Donate';

  @override
  String get cancel => 'Cancel';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get settings => 'Settings';

  @override
  String get account => 'Account';

  @override
  String get signOutConfirmTitle => 'Sign Out';

  @override
  String get signOutConfirmBody => 'Are you sure you want to sign out?';

  @override
  String get eligibleToDonate => 'Eligible to donate';

  @override
  String get notYetEligible => 'Not yet eligible';

  @override
  String get noDonationHistory => 'No donation history';

  @override
  String get nationalBloodStock => 'National Blood Stock';

  @override
  String get realTimeInventory => 'Real-time inventory across all blood banks';

  @override
  String get nearbyBloodCenters => 'Nearby Blood Centers';

  @override
  String get shortageAlerts => 'Shortage Alerts';

  @override
  String get shortageAlertsSubtitle =>
      'Receive notifications when blood is critically low';

  @override
  String get medicalStatus => 'Medical Status';

  @override
  String get myRequests => 'My Requests';

  @override
  String get newRequest => 'New Request';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get youCanDonateToday => 'You can donate today!';

  @override
  String get findNearestBloodBank => 'Find your nearest blood bank';

  @override
  String get donatedRecently => 'You donated recently. Thank you!';

  @override
  String hello(String name) {
    return 'Hello, $name!';
  }

  @override
  String daysUntilNextDonation(int days) {
    return '$days days until next donation';
  }

  @override
  String lastDonationDaysAgo(int days) {
    return 'Last donation: $days days ago';
  }
}
