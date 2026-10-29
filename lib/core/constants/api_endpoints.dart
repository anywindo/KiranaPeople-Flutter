class ApiEndpoints {
  // Authentication
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/profile';
  static const String changePassword = '/auth/change-password';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resetPassword = '/auth/reset-password';
  static const String onboardingPassword = '/onboarding/password';

  // Attendance
  static const String todayAttendance = '/employee/attendance/today';
  static const String attendanceEvents = '/employee/attendance/events';
  static const String attendanceHistory = '/employee/attendance/history';
}
