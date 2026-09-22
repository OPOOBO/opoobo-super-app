class PaymentMethodData {
  final int id;
  final String type;
  final String provider;
  final String lastFour;
  final String? expiryMonth;
  final String? expiryYear;
  final String? bankName;
  final String? accountNumberMasked;
  final bool isDefault;

  PaymentMethodData({
    required this.id,
    required this.type,
    required this.provider,
    required this.lastFour,
    this.expiryMonth,
    this.expiryYear,
    this.bankName,
    this.accountNumberMasked,
    this.isDefault = false,
  });

  factory PaymentMethodData.fromJson(Map<String, dynamic> json) {
    return PaymentMethodData(
      id: json['id'],
      type: json['type'],
      provider: json['provider'],
      lastFour: json['last_four'],
      expiryMonth: json['expiry_month'],
      expiryYear: json['expiry_year'],
      bankName: json['bank_name'],
      accountNumberMasked: json['account_number_masked'],
      isDefault: json['is_default'] ?? false,
    );
  }

  String get displayName {
    if (type == 'card') return '$provider ending in $lastFour';
    return '$bankName •••• $lastFour';
  }

  String get subtitle {
    if (type == 'card') return 'Expires $expiryMonth/$expiryYear';
    return accountNumberMasked ?? '•••• $lastFour';
  }
}

class AddressData {
  final int id;
  final String label;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String country;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  AddressData({
    required this.id,
    required this.label,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    this.country = 'Nigeria',
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  factory AddressData.fromJson(Map<String, dynamic> json) {
    return AddressData(
      id: json['id'],
      label: json['label'],
      addressLine1: json['address_line1'],
      addressLine2: json['address_line2'],
      city: json['city'],
      state: json['state'],
      country: json['country'] ?? 'Nigeria',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isDefault: json['is_default'] ?? false,
    );
  }

  String get fullAddress {
    final parts = [addressLine1];
    if (addressLine2 != null && addressLine2!.isNotEmpty) {
      parts.add(addressLine2!);
    }
    parts.add('$city, $state');
    return parts.join(', ');
  }
}

class SavedLocationData {
  final int id;
  final String name;
  final String type;
  final String? code;
  final String? address;
  final double? latitude;
  final double? longitude;

  SavedLocationData({
    required this.id,
    required this.name,
    required this.type,
    this.code,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory SavedLocationData.fromJson(Map<String, dynamic> json) {
    return SavedLocationData(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      code: json['code'],
      address: json['address'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class LoginSessionData {
  final int id;
  final String? deviceName;
  final String? deviceType;
  final String? browser;
  final String? ipAddress;
  final String? location;
  final bool isCurrent;
  final DateTime? lastActiveAt;

  LoginSessionData({
    required this.id,
    this.deviceName,
    this.deviceType,
    this.browser,
    this.ipAddress,
    this.location,
    this.isCurrent = false,
    this.lastActiveAt,
  });

  factory LoginSessionData.fromJson(Map<String, dynamic> json) {
    return LoginSessionData(
      id: json['id'],
      deviceName: json['device_name'],
      deviceType: json['device_type'],
      browser: json['browser'],
      ipAddress: json['ip_address'],
      location: json['location'],
      isCurrent: json['is_current'] ?? false,
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.tryParse(json['last_active_at'])
          : null,
    );
  }

  String get deviceLabel => deviceName ?? deviceType ?? 'Unknown device';
}

class SavedAuthorizationData {
  final int id;
  final String authorizationCode;
  final String cardType;
  final String lastFour;
  final String? expMonth;
  final String? expYear;
  final String? bankName;

  SavedAuthorizationData({
    required this.id,
    required this.authorizationCode,
    required this.cardType,
    required this.lastFour,
    this.expMonth,
    this.expYear,
    this.bankName,
  });

  factory SavedAuthorizationData.fromJson(Map<String, dynamic> json) {
    return SavedAuthorizationData(
      id: json['id'],
      authorizationCode: json['authorization_code'],
      cardType: json['card_type'],
      lastFour: json['last_four'],
      expMonth: json['exp_month'],
      expYear: json['exp_year'],
      bankName: json['bank_name'],
    );
  }

  String get displayName => '$cardType ending in $lastFour';
  String get subtitle => 'Expires $expMonth/$expYear';
}
