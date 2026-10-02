/// Motif de route à déclarer dans le `GoRouter`, avec le paramètre nommé que
/// go_router expose dans `state.pathParameters`.
const chatRoutePattern = '/chat/:requestId';

/// Nom du paramètre de chemin portant l'identifiant de la demande.
const chatRequestIdParam = 'requestId';

/// Chemin de la route d'un fil de discussion.
///
/// Déclaré ici pour que le routeur et les écrans qui ouvrent le chat
/// partagent la même chaîne, sans import circulaire entre le routeur et les
/// écrans qu'il construit.
String chatRoutePath(String requestId) => '/chat/$requestId';