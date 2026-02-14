class Validators {
  static final RegExp emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static bool isValidEmail(String email) => emailRegex.hasMatch(email);

  static bool isValidPassword(String password) => password.length >= 6;

  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'אנא הזן/י כתובת אימייל';
    }
    if (!isValidEmail(email.trim())) {
      return 'כתובת אימייל לא תקינה';
    }
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'אנא הזן/י סיסמה';
    }
    if (!isValidPassword(password)) {
      return 'הסיסמה חייבת להכיל לפחות 6 תווים';
    }
    return null;
  }

  static String? validateConfirmPassword(String? password, String? confirm) {
    if (confirm == null || confirm.isEmpty) {
      return 'אנא אמת/י את הסיסמה';
    }
    if (password != confirm) {
      return 'הסיסמאות אינן תואמות';
    }
    return null;
  }

  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'אנא הזן/י שם מלא';
    }
    return null;
  }
}
