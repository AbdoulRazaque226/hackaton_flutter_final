enum UserRole { client, professionnel }

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String phone;
  final UserRole role;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.phone,
    required this.role,
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'phone': phone,
      'role': role.name,
    };
  }
}
