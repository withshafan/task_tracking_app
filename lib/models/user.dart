class AppUser {
  final String id;
  final String email;
  final String name;
  final bool isAdmin;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.isAdmin,
  });

  // Convert from Firestore document
  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      isAdmin: data['isAdmin'] ?? false,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'isAdmin': isAdmin,
    };
  }
}
