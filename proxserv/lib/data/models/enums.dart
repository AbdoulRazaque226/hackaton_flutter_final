/// Métiers proposés par ProxServ.
enum Metier {
  plombier,
  electricien,
  macon,
  menuisier,
  peintre,
  reparateur,
  nettoyage,
  autre;

  String get label {
    switch (this) {
      case Metier.plombier:
        return 'Plombier';
      case Metier.electricien:
        return 'Électricien';
      case Metier.macon:
        return 'Maçon';
      case Metier.menuisier:
        return 'Menuisier';
      case Metier.peintre:
        return 'Peintre';
      case Metier.reparateur:
        return 'Réparateur';
      case Metier.nettoyage:
        return 'Nettoyage';
      case Metier.autre:
        return 'Autre';
    }
  }

  static Metier fromName(String name) => Metier.values.firstWhere(
    (m) => m.name == name,
    orElse: () => Metier.autre,
  );
}

/// Statut d'une demande d'intervention (7 Statuts officiels de la Mission 2A).
enum RequestStatus {
  enAttente,
  acceptee,
  enCours,
  terminee,
  refusee,
  annulee,
  sansReponse;

  String get label {
    switch (this) {
      case RequestStatus.enAttente:
        return 'En attente';
      case RequestStatus.acceptee:
        return 'Acceptée';
      case RequestStatus.enCours:
        return 'En cours';
      case RequestStatus.terminee:
        return 'Terminée';
      case RequestStatus.refusee:
        return 'Refusée';
      case RequestStatus.annulee:
        return 'Annulée';
      case RequestStatus.sansReponse:
        return 'Sans réponse';
    }
  }

  static RequestStatus fromName(String name) => RequestStatus.values.firstWhere(
    (s) => s.name == name,
    orElse: () => RequestStatus.enAttente,
  );
}
