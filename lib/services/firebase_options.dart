import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'PUT-YOUR-OWN-API-KEY',
    appId: 'PUT-YOUR-OWN-API-ID',
    messagingSenderId: '841100323234',
    projectId: 'meal-planner-61809',
    authDomain: 'meal-planner-61809.firebaseapp.com',
    storageBucket: 'meal-planner-61809.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'PUT-YOUR-OWN-API-KEY',
    appId: 'PUT-YOUR-OWN-API-KEY',
    messagingSenderId: '841100323234',
    projectId: 'meal-planner-61809',
    storageBucket: 'meal-planner-61809.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'PUT-YOUR-OWN-API-KEY',
    appId: 'PUT-YOUR-OWN-API-KEY',
    messagingSenderId: '841100323234',
    projectId: 'meal-planner-61809',
    storageBucket: 'meal-planner-61809.appspot.com',
    iosBundleId: 'com.example.mealPlanner',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'PUT-YOUR-OWN-API-KEY',
    appId: 'PUT-YOUR-OWN-API-KEY',
    messagingSenderId: '841100323234',
    projectId: 'meal-planner-61809',
    storageBucket: 'meal-planner-61809.appspot.com',
    iosBundleId: 'com.example.mealPlanner',
  );
}
