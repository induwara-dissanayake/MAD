class Validators {
  Validators._();

  // Sri Lankan NIC: old format = 9 digits + V/X, new format = 12 digits
  static final _nicOldFormat = RegExp(r'^\d{9}[VvXx]$');
  static final _nicNewFormat = RegExp(r'^\d{12}$');

  static String? validateNic(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'NIC number is required';
    }
    final trimmed = value.trim();
    if (!_nicOldFormat.hasMatch(trimmed) && !_nicNewFormat.hasMatch(trimmed)) {
      return 'Enter a valid NIC (e.g., 987654321V or 200012345678)';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 3) {
      return 'Full name must be at least 3 characters';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
    if (!RegExp(r'^(\+94\d{9}|0\d{9})$').hasMatch(cleaned)) {
      return 'Enter a valid phone number (e.g., +94771234567)';
    }
    return null;
  }

  /// Convert NIC to a synthetic email for Firebase Auth.
  static String nicToEmail(String nic) {
    return '${nic.trim().toLowerCase()}@villageconnect.local';
  }
}
