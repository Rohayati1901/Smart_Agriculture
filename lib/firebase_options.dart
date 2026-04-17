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
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAk5FPPzMy2VJKQvnTVjXkZs9IEL2PrLnc',
    appId: '1:122665005516:web:5ed85776bb991cfe186d69',
    messagingSenderId: '122665005516',
    projectId: 'smart-agriculture-sliyeg',
    authDomain: 'smart-agriculture-sliyeg.firebaseapp.com',
    databaseURL: 'https://smart-agriculture-sliyeg-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'smart-agriculture-sliyeg.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDYQC80Hr05PKLxWtGEMXtNxXec6HHDQB4',
    appId: '1:122665005516:android:4c702047cc2515aa186d69',
    messagingSenderId: '122665005516',
    projectId: 'smart-agriculture-sliyeg',
    databaseURL: 'https://smart-agriculture-sliyeg-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'smart-agriculture-sliyeg.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBw3FfsoisaN0zevJNNsw5Oo4svsei8y9I',
    appId: '1:122665005516:ios:7420fb4ba4a4485e186d69',
    messagingSenderId: '122665005516',
    projectId: 'smart-agriculture-sliyeg',
    databaseURL: 'https://smart-agriculture-sliyeg-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'smart-agriculture-sliyeg.firebasestorage.app',
    iosClientId: '122665005516-bquv5h9hohud4irabm9spas7qn9afhh4.apps.googleusercontent.com',
    iosBundleId: 'com.example.smartAgricultureSliyeg',
  );

  static const FirebaseOptions macos = ios;
  static const FirebaseOptions windows = web;
}
