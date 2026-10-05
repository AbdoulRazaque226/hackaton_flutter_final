# ProxServ

Application mobile et web de **mise en relation entre clients et artisans de proximité** 
(plombier, électricien, maçon, menuisier, peintre, réparateur, nettoyage, etc.).

Le client peut rechercher un professionnel disponible à proximité, consulter son profil, 
envoyer une demande d'intervention, suivre son évolution et échanger avec le professionnel 
via un système de chat.

Le projet a été réalisé dans le cadre d'un **hackathon Flutter**.

---

## Fonctionnalités

###  Client

- Inscription et connexion par e-mail et mot de passe
- Recherche de professionnels par métier
- Tri des professionnels par proximité
- Calcul de la distance à vol d'oiseau avec la formule de **Haversine**
- Affichage des professionnels sur une carte interactive
- Consultation du profil détaillé d'un professionnel
- Consultation du métier, de la zone d'intervention et de la note
- Envoi d'une demande d'intervention
- Récupération de la position GPS du client
- Suivi du statut des demandes
- Consultation de l'historique des demandes
- Évaluation d'un professionnel

###  Professionnel

- Tableau de bord des demandes reçues
- Notification et alerte sonore lors de l'arrivée d'une nouvelle demande
- Bascule de disponibilité :
  - En ligne
  - Hors ligne
- Mise à jour de la position GPS lors du passage en ligne
- Consultation des informations du client
- Gestion du statut des demandes :
  - En attente
  - Acceptée
  - En cours
  - Terminée
  - Refusée
  - Annulée
  - Sans réponse

###  Administrateur

- Tableau de bord administrateur
- Consultation des statistiques globales
- Nombre d'utilisateurs
- Nombre de professionnels
- Nombre de demandes
- Blocage d'un compte
- Déblocage d'un compte
- Gestion des utilisateurs

###  Fonctionnalités communes

- Authentification avec **Firebase Authentication**
- Gestion des rôles :
  - `client`
  - `professionnel`
  - `admin`
- Redirection automatique selon le rôle
- Chat associé à chaque demande
- Badge indiquant les messages non lus
- Interface bilingue :
  - Français
  - Anglais
- Thème clair / sombre
- Cache et fonctionnement hors ligne de Firestore
- Interface responsive pour mobile et web

---

# 🏗️ Architecture

Le projet utilise une **Architecture en couches (Layered Architecture)** avec 
**Riverpod** pour la gestion de l'état.

Cette architecture permet de séparer les responsabilités de l'application et de 
faciliter sa maintenance, son évolution et ses tests.

## Structure du projet

```text
lib/
│
├── core/
│   ├── theme/
│   ├── localization/
│   └── utils/
│
├── data/
│   ├── models/
│   │   ├── app_user.dart
│   │   ├── professional_profile.dart
│   │   ├── service_request.dart
│   │   └── ...
│   │
│   └── services/
│       ├── firebase_service.dart
│       ├── location_service.dart
│       └── ...
│
├── application/
│   └── providers/
│       ├── user_provider.dart
│       ├── request_provider.dart
│       ├── chat_provider.dart
│       ├── settings_provider.dart
│       └── ...
│
├── presentation/
│   ├── screens/
│   │   ├── client/
│   │   ├── professional/
│   │   ├── admin/
│   │   ├── chat/
│   │   └── profile/
│   │
│   ├── widgets/
│   └── navigation/
│
├── firebase_options.dart
├── router.dart
└── main.dart

Installation
Prérequis
Flutter compatible avec Dart ^3.12.0
Un projet Firebase avec Authentication (e-mail / mot de passe) et Cloud Firestore activés
Firebase CLI et FlutterFire CLI (pour reconfigurer Firebase)

Lancer le projet avec ses commande

git clone https://github.com/AbdoulRazaque226/hackaton_flutter_final.git
cd hackaton_flutter_final/proxserv
git checkout dev

flutter pub get
flutter run            # appareil / émulateur
flutter run -d chrome  # version web
dart pub global activate flutterfire_cli
flutterfire configure   # régénère lib/firebase_options.dart et google-services.json
firebase deploy --only firestore:rules,firestore:indexes #Déployer les règles Firestore


 