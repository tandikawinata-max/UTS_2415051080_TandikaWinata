/// Konfigurasi publik aplikasi, bukan service-role/secret key.
class AppConfiguration {
  final String supabaseUrl;
  final String supabasePublishableKey;

  const AppConfiguration({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
  });

  const AppConfiguration.fromEnvironment()
    : supabaseUrl = const String.fromEnvironment('SUPABASE_URL'),
      supabasePublishableKey = const String.fromEnvironment(
        'SUPABASE_PUBLISHABLE_KEY',
      );

  factory AppConfiguration.fromJson(Map<String, dynamic> json) =>
      AppConfiguration(
        supabaseUrl: json['SUPABASE_URL'] is String
            ? json['SUPABASE_URL'] as String
            : '',
        supabasePublishableKey: json['SUPABASE_PUBLISHABLE_KEY'] is String
            ? json['SUPABASE_PUBLISHABLE_KEY'] as String
            : '',
      );

  void validate() {
    final uri = Uri.tryParse(supabaseUrl);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        supabaseUrl != supabaseUrl.trim()) {
      throw const AppConfigurationException(
        'SUPABASE_URL harus berupa URL HTTPS proyek.',
      );
    }
    if (!RegExp(
      r'^sb_publishable_[A-Za-z0-9_-]+$',
    ).hasMatch(supabasePublishableKey)) {
      throw const AppConfigurationException(
        'SUPABASE_PUBLISHABLE_KEY harus berupa publishable key (sb_publishable_...). '
        'Secret key dan service-role key tidak boleh digunakan pada aplikasi.',
      );
    }
  }
}

class AppConfigurationException implements Exception {
  final String message;
  const AppConfigurationException(this.message);
  @override
  String toString() => message;
}
