class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.fullName,
    this.phone,
  });

  final String id;
  final String email;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final String? fullName;
  final String? phone;

  String get displayName => (fullName != null && fullName!.trim().isNotEmpty)
      ? fullName!.trim()
      : email;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'].toString(),
      email: (json['email'] as String?) ?? '',
      role: (json['role'] as String?) ?? 'customer',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
    );
  }
}
