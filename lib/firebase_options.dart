import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for QuantumLab.
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
      default:
        throw UnsupportedError('Unsupported platform: $defaultTargetPlatform');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC03kZbd0vv1_PS2Pfake2b5pfz-7QezLg',
    appId: '1:279897198801:web:61255ed00a27954e2435f0',
    messagingSenderId: '279897198801',
    projectId: 'quantum-lab-zf',
    authDomain: 'quantum-lab-zf.firebaseapp.com',
    storageBucket: 'quantum-lab-zf.firebasestorage.app',
    measurementId: 'G-KX5LN4D5SH',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB5Qr38tAoJF96wh0vZrFviASlonKBzWJw',
    appId: '1:279897198801:android:430bc4e0a06e78552435f0',
    messagingSenderId: '279897198801',
    projectId: 'quantum-lab-zf',
    storageBucket: 'quantum-lab-zf.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBh_VKZCjmwiZx2EJP0PoTa64H3ldO-FsU',
    appId: '1:279897198801:ios:af9b8e56c8204d8d2435f0',
    messagingSenderId: '279897198801',
    projectId: 'quantum-lab-zf',
    storageBucket: 'quantum-lab-zf.firebasestorage.app',
    iosBundleId: 'com.quantumlab.quantumlab',
  );
}
