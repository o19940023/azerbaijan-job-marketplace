import '../constants/app_constants.dart';

class Validators {
  // Email validation
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Phone validation (Azerbaijan format: +994XXXXXXXXX)
  static bool isValidAzerbaijanPhone(String phone) {
    final phoneRegex = RegExp(r'^\+994[0-9]{9}$');
    return phoneRegex.hasMatch(phone);
  }

  // Password validation (min 8 chars, at least 1 uppercase, 1 number)
  static bool isValidPassword(String password) {
    if (password.length < AppConstants.minPasswordLength) {
      return false;
    }
    
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    
    return hasUppercase && hasNumber;
  }

  // Get password validation error message
  static String? getPasswordError(String password) {
    if (password.isEmpty) {
      return 'Şifrə tələb olunur';
    }
    if (password.length < AppConstants.minPasswordLength) {
      return 'Şifrə ən azı ${AppConstants.minPasswordLength} simvol olmalıdır';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Şifrə ən azı bir böyük hərf ehtiva etməlidir';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Şifrə ən azı bir rəqəm ehtiva etməlidir';
    }
    return null;
  }

  // Empty field validation
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  // Name validation
  static bool isValidName(String name) {
    return name.trim().length >= 2;
  }
}
