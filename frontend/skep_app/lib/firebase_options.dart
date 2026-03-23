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
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for fuchsia - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: 'YOUR_WEB_MESSAGING_SENDER_ID',
    projectId: 'your-project-id',
    authDomain: 'your-project-id.firebaseapp.com',
    databaseURL: 'https://your-project-id.firebaseio.com',
    storageBucket: 'your-project-id.appspot.com',
    measurementId: 'YOUR_MEASUREMENT_ID',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_ANDROID_MESSAGING_SENDER_ID',
    projectId: 'your-project-id',
    databaseURL: 'https://your-project-id.firebaseio.com',
    storageBucket: 'your-project-id.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_iOS_API_KEY',
    appId: 'YOUR_iOS_APP_ID',
    messagingSenderId: 'YOUR_iOS_MESSAGING_SENDER_ID',
    projectId: 'your-project-id',
    databaseURL: 'https://your-project-id.firebaseio.com',
    storageBucket: 'your-project-id.appspot.com',
    iosBundleId: 'com.skep.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_macOS_API_KEY',
    appId: 'YOUR_macOS_APP_ID',
    messagingSenderId: 'YOUR_macOS_MESSAGING_SENDER_ID',
    projectId: 'your-project-id',
    databaseURL: 'https://your-project-id.firebaseio.com',
    storageBucket: 'your-project-id.appspot.com',
    iosBundleId: 'com.skep.app',
  );
}
