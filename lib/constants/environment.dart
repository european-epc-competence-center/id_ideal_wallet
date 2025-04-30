class Env {
  static String get firebaseApiKey =>
      const String.fromEnvironment('FIREBASE_API_KEY');

  static String get firebaseAppIdAndroid =>
      const String.fromEnvironment('FIREBASE_APP_ID_ANDROID');

  static String get firebaseAppIdIos =>
      const String.fromEnvironment('FIREBASE_APP_ID_IOS');

  static String get firebaseSenderId =>
      const String.fromEnvironment('FIREBASE_SENDER_ID');

  static String get firebaseProjectId =>
      const String.fromEnvironment('FIREBASE_PROJECT_ID');

  static String get firebaseStorage =>
      const String.fromEnvironment('FIREBASE_STORAGE');
}
