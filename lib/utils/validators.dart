class Validators {
  static String? validateIP(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter router IP address';
    }

    // Simple IPv4 validation regex
    final ipRegExp = RegExp(
      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );

    if (!ipRegExp.hasMatch(value)) {
      return 'Please enter a valid IP address';
    }
    return null;
  }

  static String? validatePort(String? value) {
    if (value != null && value.isNotEmpty) {
      final port = int.tryParse(value);
      if (port == null || port < 1 || port > 65535) {
        return 'Port must be between 1 and 65535';
      }
    }
    return null;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter username';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter password';
    }
    if (value.length < 5) {
      return 'Password must be at least 5 characters';
    }
    return null;
  }

  static String? validateOptionalPassword(String? value) {
    // Optional password - can be empty or null
    if (value != null && value.isNotEmpty && value.length < 5) {
      return 'Password must be at least 5 characters';
    }
    return null;
  }
}
