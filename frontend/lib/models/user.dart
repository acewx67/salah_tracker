/// Represents app user data.
class AppUser {
  final String id;
  final String googleId;
  final String? email;
  final String? displayName;
  final DateTime? performanceStartDate;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.googleId,
    this.email,
    this.displayName,
    this.performanceStartDate,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      googleId: json['google_id'],
      email: json['email'],
      displayName: json['display_name'],
      performanceStartDate: json['performance_start_date'] != null
          ? DateTime.parse(json['performance_start_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
