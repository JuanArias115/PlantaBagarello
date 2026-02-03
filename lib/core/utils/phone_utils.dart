class PhoneUtils {
  static String normalize(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('57')) {
      return '+$digits';
    }
    // Asumimos indicativo +57 (Colombia) cuando el usuario no lo incluye.
    return '+57$digits';
  }
}
