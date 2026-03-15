class AppConstants {
  // API
  static const String baseUrl = 'https://api.example.com'; // TODO: Update with actual API URL
  static const String apiVersion = 'v1';
  
  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userTypeKey = 'user_type';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
  
  // Azerbaijan specific
  static const List<String> azerbaijanCities = [
    'Bakı', 'Gəncə', 'Sumqayıt', 'Mingəçevir', 'Şirvan',
    'Naxçıvan', 'Şəki', 'Lənkəran', 'Yevlax', 'Xaçmaz',
    'Şamaxı', 'Quba', 'Qəbələ', 'Zaqatala', 'Bərdə',
    'Ağdam', 'Ağcabədi', 'Göyçay', 'Masallı', 'Sabirabad',
  ];

  static const List<String> bakuDistricts = [
    'Nəsimi', 'Yasamal', 'Xətai', 'Səbail', 'Nizami',
    'Binəqədi', 'Nərimanov', 'Suraxanı', 'Xəzər', 'Qaradağ',
    'Sabunçu', 'Pirallahı', 'Abşeron',
  ];
  static const String defaultCurrency = 'AZN';
  static const String currencySymbol = '₼';
  static const String phonePrefix = '+994';
  static const String dateFormat = 'dd.MM.yyyy';
  static const String timeFormat = 'HH:mm';
  
  // File Upload
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int maxDocumentSizeBytes = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png'];
  static const List<String> allowedDocumentExtensions = ['pdf', 'doc', 'docx'];
}
