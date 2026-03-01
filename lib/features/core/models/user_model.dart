class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String role; // 'pet_parent' or 'service_provider'

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
  });

  // Convert Supabase data to our AppUser object
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'],
      fullName: map['full_name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'pet_parent',
    );
  }

  // Convert AppUser object to Map for saving to Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'role': role,
    };
  }
}