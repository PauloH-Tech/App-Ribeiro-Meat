class AppConfig {
  /// URL da API. Pode ser sobrescrita no build:
  /// flutter build web --dart-define=API_URL=https://api.techpaulo.com.br
  // static const String apiUrl = String.fromEnvironment(
  //   'API_URL',
  //   defaultValue: 'https://api.techpaulo.com.br',
  // );
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080',
  );
}
