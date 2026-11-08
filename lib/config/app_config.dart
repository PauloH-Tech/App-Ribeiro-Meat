class AppConfig {
  /// URL da API. Pode ser sobrescrita no build:
  /// flutter build web --dart-define=API_URL=https://api.minhaloja.com.br
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8081',
  );
}
