class UserModel {
  final String id;
  final String role;          // primary role stored in profiles table
  final String fullName;
  final String email;
  final String phone;
  final String? avatarUrl;
  final DateTime createdAt;
  /// All roles this user has signed up for (checked across role tables)
  final List<String> activeRoles;
  /// The role currently chosen for this session (may differ from primary role)
  final String activeSessionRole;

  UserModel({
    required this.id,
    required this.role,
    required this.fullName,
    required this.email,
    required this.phone,
    this.avatarUrl,
    required this.createdAt,
    List<String>? activeRoles,
    String? activeSessionRole,
  })  : activeRoles = activeRoles ?? [role],
        activeSessionRole = activeSessionRole ?? role;

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final role = map['role'] ?? 'customer';
    return UserModel(
      id: map['id'] ?? '',
      role: role,
      fullName: map['full_name'] ?? map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      avatarUrl: map['avatar_url'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      activeRoles: (map['activeRoles'] as List<dynamic>?)?.cast<String>() ?? [role],
      activeSessionRole: map['activeSessionRole'] as String? ?? role,
    );
  }

  UserModel copyWith({
    String? activeSessionRole,
    List<String>? activeRoles,
  }) {
    return UserModel(
      id: id,
      role: role,
      fullName: fullName,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl,
      createdAt: createdAt,
      activeRoles: activeRoles ?? this.activeRoles,
      activeSessionRole: activeSessionRole ?? this.activeSessionRole,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'role': role,
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'avatar_url': avatarUrl,
  };

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (fullName.isNotEmpty) {
      return fullName[0].toUpperCase();
    }
    return 'U';
  }

  /// Human-readable label for a given role string
  static String roleLabel(String r) {
    switch (r) {
      case 'seller':           return 'Seller';
      case 'delivery_partner': return 'Delivery Partner';
      case 'customer':         return 'Customer';
      default:                 return r;
    }
  }

  /// Human-readable label for the current primary role
  String get roleDisplay => roleLabel(role);

  /// Human-readable label for the active session role
  String get sessionRoleDisplay => roleLabel(activeSessionRole);
}
