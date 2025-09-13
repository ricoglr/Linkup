class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email adresi gereklidir';
    }

    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Geçerli bir email adresi giriniz';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gereklidir';
    }

    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalıdır';
    }

    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefon numarası gereklidir';
    }

    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
      return 'Geçerli bir telefon numarası giriniz';
    }

    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName gereklidir';
    }
    return null;
  }

  static String? validateEventName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Etkinlik adı gereklidir';
    }

    if (value.trim().length < 3) {
      return 'Etkinlik adı en az 3 karakter olmalıdır';
    }

    if (value.trim().length > 100) {
      return 'Etkinlik adı en fazla 100 karakter olmalıdır';
    }

    return null;
  }

  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Açıklama gereklidir';
    }

    if (value.trim().length < 10) {
      return 'Açıklama en az 10 karakter olmalıdır';
    }

    if (value.trim().length > 1000) {
      return 'Açıklama en fazla 1000 karakter olmalıdır';
    }

    return null;
  }
}
