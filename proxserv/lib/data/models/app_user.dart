enum UserRole { client, professionnel, admin }

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String phone;
  final UserRole role;
  final String country;
  final String city;
  final String neighborhood;
  final bool bloque;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.phone,
    required this.role,
    this.country = '',
    this.city = '',
    this.neighborhood = '',
    this.bloque = false,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.client,
      ),
      country: map['country'] as String? ?? '',
      city: map['city'] as String? ?? '',
      neighborhood: map['neighborhood'] as String? ?? '',
      bloque: map['bloque'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'phone': phone,
      'role': role.name,
      'country': country,
      'city': city,
      'neighborhood': neighborhood,
      'bloque': bloque,
    };
  }
}
