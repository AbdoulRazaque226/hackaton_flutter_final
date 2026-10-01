enum UserRole { client, professionnel, admin }

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String phone;
  final UserRole role;
  final bool bloque;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.phone,
    required this.role,
    this.bloque = false,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: map['email'] as String,
      displayName: map['displayName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.client,
      ),
      bloque: map['bloque'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'phone': phone,
      'role': role.name,
      'bloque': bloque,
    };
  }
}
