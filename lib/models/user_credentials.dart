class UserCredentials {
  final String email;
  final String appPassword;

  UserCredentials({
    required String email,
    required String appPassword,
  })  : email = email.trim(),
        appPassword = appPassword.replaceAll(' ', '').trim();

  /// Validates basic email and app password requirements
  bool get isValid {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email) && appPassword.length >= 16;
  }

  /// Formatted email for display
  String get maskedEmail {
    if (email.contains('@')) {
      final parts = email.split('@');
      final username = parts[0];
      if (username.length > 3) {
        return '${username.substring(0, 3)}***@${parts[1]}';
      }
    }
    return email;
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'appPassword': appPassword,
      };

  factory UserCredentials.fromJson(Map<String, dynamic> json) {
    return UserCredentials(
      email: json['email'] ?? '',
      appPassword: json['appPassword'] ?? '',
    );
  }
}
