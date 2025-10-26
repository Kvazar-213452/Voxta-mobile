class Settings {
  final bool darkMode;
  final bool browserNotifications;
  final bool doNotDisturb;
  final String language;
  final int pasw;
  final bool readReceipts;
  final bool onlineStatus;

  Settings({
    required this.darkMode,
    required this.browserNotifications,
    required this.doNotDisturb,
    required this.language,
    required this.readReceipts,
    required this.onlineStatus,
    required this.pasw,
  });

  Map<String, dynamic> toMap() {
    return {
      'darkMode': darkMode ? 1 : 0,
      'browserNotifications': browserNotifications ? 1 : 0,
      'doNotDisturb': doNotDisturb ? 1 : 0,
      'language': language,
      'readReceipts': readReceipts ? 1 : 0,
      'onlineStatus': onlineStatus ? 1 : 0,
      'pasw': pasw,
    };
  }

  static Settings fromMap(Map<String, dynamic> map) {
    return Settings(
      darkMode: map['darkMode'] == 1,
      browserNotifications: map['browserNotifications'] == 1,
      doNotDisturb: map['doNotDisturb'] == 1,
      language: map['language'],
      readReceipts: map['readReceipts'] == 1,
      onlineStatus: map['onlineStatus'] == 1,
      pasw: map['pasw'] ?? 0,
    );
  }
}
