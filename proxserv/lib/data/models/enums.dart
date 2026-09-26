/// Métiers proposés par ProxServ pour le MVP du hackathon.
enum Metier {
  plombier,
  electricien,
  macon,
  menuisier,
  peintre,
  reparateur,
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
      case Metier.autre:
        return 'Autre';
    }
  }

  static Metier fromName(String name) =>
      Metier.values.firstWhere((m) => m.name == name, orElse: () => Metier.autre);
}

/// Statut d'une demande d'intervention.
enum RequestStatus {
  enAttente,
  acceptee,
  refusee,
  terminee;

  String get label {
    switch (this) {
      case RequestStatus.enAttente:
        return 'En attente';
      case RequestStatus.acceptee:
        return 'Acceptée';
      case RequestStatus.refusee:
        return 'Refusée';
      case RequestStatus.terminee:
        return 'Terminée';
    }
  }

  static RequestStatus fromName(String name) => RequestStatus.values
      .firstWhere((s) => s.name == name, orElse: () => RequestStatus.enAttente);
}
