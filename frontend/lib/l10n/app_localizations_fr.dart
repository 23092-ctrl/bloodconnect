// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'BloodConnect';

  @override
  String get tagline => 'Sauver des vies, ensemble';

  @override
  String get welcomeBack => 'Bon retour';

  @override
  String get signInSubtitle =>
      'Connectez-vous pour continuer à sauver des vies';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de passe';

  @override
  String get fullName => 'Nom complet';

  @override
  String get phone => 'Téléphone';

  @override
  String get bloodType => 'Groupe sanguin';

  @override
  String get gender => 'Sexe';

  @override
  String get male => 'Homme';

  @override
  String get female => 'Femme';

  @override
  String get noAccount => 'Pas de compte ? S\'inscrire';

  @override
  String get home => 'Accueil';

  @override
  String get donations => 'Dons';

  @override
  String get map => 'Carte';

  @override
  String get alerts => 'Alertes';

  @override
  String get profile => 'Profil';

  @override
  String get admin => 'Admin';

  @override
  String get notifications => 'Notifications';

  @override
  String get donate => 'Donner';

  @override
  String get cancel => 'Annuler';

  @override
  String get saveChanges => 'Sauvegarder';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get settings => 'Paramètres';

  @override
  String get account => 'Compte';

  @override
  String get signOutConfirmTitle => 'Déconnexion';

  @override
  String get signOutConfirmBody =>
      'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get eligibleToDonate => 'Éligible au don';

  @override
  String get notYetEligible => 'Pas encore éligible';

  @override
  String get noDonationHistory => 'Aucun historique de don';

  @override
  String get nationalBloodStock => 'Stock national de sang';

  @override
  String get realTimeInventory =>
      'Inventaire en temps réel dans toutes les banques de sang';

  @override
  String get nearbyBloodCenters => 'Centres de sang à proximité';

  @override
  String get shortageAlerts => 'Alertes de pénurie';

  @override
  String get shortageAlertsSubtitle =>
      'Recevoir des notifications en cas de pénurie critique';

  @override
  String get medicalStatus => 'Statut médical';

  @override
  String get myRequests => 'Mes demandes';

  @override
  String get newRequest => 'Nouvelle demande';

  @override
  String get markAllRead => 'Tout marquer comme lu';

  @override
  String get noNotificationsYet => 'Aucune notification';

  @override
  String get youCanDonateToday => 'Vous pouvez donner aujourd\'hui !';

  @override
  String get findNearestBloodBank =>
      'Trouvez votre banque de sang la plus proche';

  @override
  String get donatedRecently => 'Vous avez donné récemment. Merci !';

  @override
  String hello(String name) {
    return 'Bonjour, $name !';
  }

  @override
  String daysUntilNextDonation(int days) {
    return '$days jours avant le prochain don';
  }

  @override
  String lastDonationDaysAgo(int days) {
    return 'Dernier don : il y a $days jours';
  }
}
