import '../../data/models/enums.dart';

Metier? classifyProblem(String problem) {
  final query = _normalize(problem);
  if (query.isEmpty) return null;

  const rules = <(Metier, List<String>)>[
    (
      Metier.plombier,
      ['fuite', 'plomb', 'robinet', 'tuyau', 'canalisation', 'evier', 'sink'],
    ),
    (
      Metier.electricien,
      [
        'electri',
        'prise',
        'courant',
        'cable',
        'lumiere',
        'outlet',
        'power',
        'wiring',
      ],
    ),
    (
      Metier.menuisier,
      [
        'menuis',
        'porte',
        'fenetre',
        'meuble',
        'armoire',
        'placard',
        'serrure',
        'furniture',
        'carpenter',
        'door',
      ],
    ),
    (
      Metier.peintre,
      ['peint', 'peind', 'repeind', 'paint', 'salon', 'wallpaper'],
    ),
    (
      Metier.macon,
      [
        'macon',
        'maconnerie',
        'mur',
        'brique',
        'ciment',
        'construire',
        'construction',
        'mason',
        'brick',
      ],
    ),
    (
      Metier.reparateur,
      [
        'repar',
        'appareil',
        'electromenager',
        'machine',
        'panne',
        'broken',
        'appliance',
        'repair',
      ],
    ),
    (
      Metier.nettoyage,
      [
        'nettoy',
        'menage',
        'clean',
        'housekeeping',
        'house cleaning',
      ],
    ),
  ];

  for (final (metier, keywords) in rules) {
    if (keywords.any((keyword) => _matchesKeyword(query, keyword))) {
      return metier;
    }
  }
  return null;
}

bool _matchesKeyword(String query, String keyword) {
  if (keyword.contains(' ')) return query.contains(keyword);
  return query.split(' ').any((word) => word.startsWith(keyword));
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp('[àáâäãå]'), 'a')
      .replaceAll(RegExp('[èéêë]'), 'e')
      .replaceAll(RegExp('[ìíîï]'), 'i')
      .replaceAll(RegExp('[òóôöõ]'), 'o')
      .replaceAll(RegExp('[ùúûü]'), 'u')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
