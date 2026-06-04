enum AuthRole {
  admin,
  doctor,
  assistant,
  unknown;

  static AuthRole fromValue(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'admin':
      case 'administrator':
      case 'superadmin':
        return AuthRole.admin;
      case 'doctor':
        return AuthRole.doctor;
      case 'assistant':
      case 'teaching_assistant':
      case 'ta':
      case 'staff':
        return AuthRole.assistant;
      default:
        return AuthRole.unknown;
    }
  }

  String get value => switch (this) {
    AuthRole.admin => 'admin',
    AuthRole.doctor => 'doctor',
    AuthRole.assistant => 'assistant',
    AuthRole.unknown => 'unknown',
  };

  bool get isAdmin => this == AuthRole.admin;

  bool get isDoctorAssistant =>
      this == AuthRole.doctor || this == AuthRole.assistant;
}
