import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/settings_providers.dart';
import '../../data/models/app_user.dart';
import '../../data/models/enums.dart';

enum AppLanguage { fr, en }

final appLanguageNotifierProvider =
    NotifierProvider<AppLanguageNotifier, AppLanguage>(AppLanguageNotifier.new);

class AppLanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() {
    return ref.watch(syncedLanguageProvider);
  }

  void setLanguage(AppLanguage lang) {
    state = lang;
  }
}

class AppLocalizations {
  final AppLanguage language;

  AppLocalizations(this.language);

  static AppLocalizations fromContext(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode == 'en'
        ? AppLanguage.en
        : AppLanguage.fr;
    return AppLocalizations(language);
  }

  String text(String french, String english) => isFr ? french : english;

  String metierLabel(Metier metier) {
    if (isFr) return metier.label;
    return switch (metier) {
      Metier.plombier => 'Plumber',
      Metier.electricien => 'Electrician',
      Metier.macon => 'Mason',
      Metier.menuisier => 'Carpenter',
      Metier.peintre => 'Painter',
      Metier.reparateur => 'Repair technician',
      Metier.nettoyage => 'Cleaning',
      Metier.autre => 'Other',
    };
  }

  String roleLabel(UserRole role) => switch (role) {
    UserRole.client => text('Client', 'Client'),
    UserRole.professionnel => text('Professionnel', 'Professional'),
    UserRole.admin => text('Administrateur', 'Administrator'),
  };

  static AppLocalizations of(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageNotifierProvider);
    return AppLocalizations(lang);
  }

  bool get isFr => language == AppLanguage.fr;

  // -- AUTHENTIFICATION --
  String get loginTitle => isFr ? 'Se connecter' : 'Sign In';
  String get registerTitle => isFr ? 'Créer un compte' : 'Create Account';
  String get emailLabel => isFr ? 'Adresse e-mail' : 'Email Address';
  String get passwordLabel => isFr ? 'Mot de passe' : 'Password';
  String get confirmPasswordLabel =>
      isFr ? 'Confirmer le mot de passe' : 'Confirm Password';
  String get fullNameLabel => isFr ? 'Nom complet' : 'Full Name';
  String get phoneLabel => isFr ? 'Numéro de téléphone' : 'Phone Number';
  String get iAmClient => isFr ? 'Un client' : 'A Client';
  String get iAmPro => isFr ? 'Un professionnel' : 'A Professional';
  String get noAccount =>
      isFr ? "Pas encore de compte ? S'inscrire" : "No account? Register";
  String get hasAccount =>
      isFr ? "J'ai déjà un compte" : "Already have an account";

  // -- NAVIGATION --
  String get homeTab => isFr ? 'Accueil' : 'Home';
  String get exploreTab => isFr ? 'Explorer' : 'Explore';
  String get requestsTab => isFr ? 'Demandes' : 'Requests';
  String get messagesTab => isFr ? 'Messages' : 'Messages';
  String get profileTab => isFr ? 'Profil' : 'Profile';
  String get settingsTab => isFr ? 'Paramètres' : 'Settings';
  String get dashboardTab => isFr ? 'Tableau de bord' : 'Dashboard';
  String get adminTab => isFr ? 'Administration' : 'Admin';

  // -- HOME CLIENT --
  String get homeQuestion =>
      isFr ? 'De quel service avez-vous besoin ?' : 'What service do you need?';
  String get searchHint => isFr
      ? 'Quel est votre problème ? (ex: fuite d\'eau)'
      : 'What is your problem? (e.g. pipe leak)';
  String get viewMap => isFr ? 'Voir la carte' : 'View Map';
  String get viewList => isFr ? 'Voir la liste' : 'View List';
  String get availablePros =>
      isFr ? 'professionnels disponibles' : 'available professionals';
  String get noProsAvailable =>
      isFr ? 'Aucun professionnel disponible' : 'No professionals available';

  // -- FICHE PRO --
  String get proProfileTitle =>
      isFr ? 'Fiche Professionnel' : 'Professional Profile';
  String get callPro => isFr ? 'Appeler le professionnel' : 'Call Professional';
  String get requestIntervention =>
      isFr ? 'Demander une intervention' : 'Request Intervention';
  String get availableNow => isFr ? 'Disponible maintenant' : 'Available now';
  String get currentlyUnavailable =>
      isFr ? 'Actuellement indisponible' : 'Currently unavailable';
  String get noReviewsYet => isFr ? 'Nouveau (0 avis)' : 'New (0 reviews)';

  // -- FORMULAIRE DEMANDE --
  String get requestFormTitle =>
      isFr ? 'Demande d\'intervention' : 'Intervention Request';
  String get needDescription =>
      isFr ? 'Description de votre besoin' : 'Description of your need';
  String get gpsRecorded =>
      isFr ? 'Position GPS enregistrée' : 'GPS position recorded';
  String get sendRequest => isFr ? 'Envoyer la demande' : 'Send Request';

  // -- STATUTS (EXACTEMENT 7 STATUTS) --
  String statusLabel(String status) {
    switch (status) {
      case 'enAttente':
        return isFr ? 'En attente' : 'Pending';
      case 'acceptee':
        return isFr ? 'Acceptée' : 'Accepted';
      case 'enCours':
        return isFr ? 'En cours' : 'In progress';
      case 'terminee':
        return isFr ? 'Terminée' : 'Completed';
      case 'refusee':
        return isFr ? 'Refusée' : 'Declined';
      case 'annulee':
        return isFr ? 'Annulée' : 'Cancelled';
      case 'sansReponse':
        return isFr ? 'Sans réponse' : 'No response';
      default:
        return status;
    }
  }

  // -- SETTINGS --
  String get appearance => isFr ? 'Apparence' : 'Appearance';
  String get lightTheme => isFr ? 'Clair' : 'Light';
  String get darkTheme => isFr ? 'Sombre' : 'Dark';
  String get systemTheme => isFr ? 'Système' : 'System';
  String get languageSection => isFr ? 'Langue' : 'Language';
  String get french => isFr ? 'Français' : 'French';
  String get english => isFr ? 'English' : 'English';
  String get logout => isFr ? 'Se déconnecter' : 'Log Out';
}
