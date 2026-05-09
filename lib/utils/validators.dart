class AppValidators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Minimum 6 characters required';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    if (value.length != 10) return 'Enter valid 10-digit number';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) return 'Enter valid Indian mobile number';
    return null;
  }

  static String? required(String? value, {String field = 'Field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? pinCode(String? value) {
    if (value == null || value.isEmpty) return 'Pin code is required';
    if (!RegExp(r'^\d{6}$').hasMatch(value)) return 'Enter valid 6-digit pin code';
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.isEmpty) return 'Price is required';
    final p = double.tryParse(value);
    if (p == null || p <= 0) return 'Enter a valid price';
    return null;
  }
}
