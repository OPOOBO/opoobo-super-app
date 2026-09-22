class SsoConfig {
  static const String issuer = 'https://account.opoobo.com/realms/opoobo';
  static const String clientId = 'opoobo-mobile';
  static const String redirectUrl = 'opoobo-one://callback';
  static const String discoveryUrl =
      'https://account.opoobo.com/realms/opoobo/.well-known/openid-configuration';
  static const List<String> scopes = [
    'openid',
    'profile',
    'email',
    'offline_access',
  ];
}
