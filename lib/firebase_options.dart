import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Firebase options (web, macOS, Android, iOS — aynı proje emlak-master).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    if (defaultTargetPlatform == TargetPlatform.macOS) return macos;
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    if (defaultTargetPlatform == TargetPlatform.iOS) return ios;
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB068ls9KsjaHHESdkKNeqL8tnN4alDXXQ',
    authDomain: 'emlak-master.firebaseapp.com',
    projectId: 'emlak-master',
    storageBucket: 'emlak-master.firebasestorage.app',
    messagingSenderId: '572835725773',
    appId: '1:572835725773:web:93531b623c67ce9392c484',
    measurementId: 'G-JN9PX6QL6V',
  );

  /// macOS: Aynı proje; GoogleService-Info.plist ile uyumlu.
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB068ls9KsjaHHESdkKNeqL8tnN4alDXXQ',
    authDomain: 'emlak-master.firebaseapp.com',
    projectId: 'emlak-master',
    storageBucket: 'emlak-master.firebasestorage.app',
    messagingSenderId: '572835725773',
    appId: '1:572835725773:web:93531b623c67ce9392c484',
    measurementId: 'G-JN9PX6QL6V',
  );

  /// Android: Aynı Firebase projesi. Tam yapılandırma için: flutterfire configure
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB068ls9KsjaHHESdkKNeqL8tnN4alDXXQ',
    authDomain: 'emlak-master.firebaseapp.com',
    projectId: 'emlak-master',
    storageBucket: 'emlak-master.firebasestorage.app',
    messagingSenderId: '572835725773',
    appId: '1:572835725773:web:93531b623c67ce9392c484',
  );

  /// iOS: Aynı Firebase projesi. Tam yapılandırma için: flutterfire configure
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB068ls9KsjaHHESdkKNeqL8tnN4alDXXQ',
    authDomain: 'emlak-master.firebaseapp.com',
    projectId: 'emlak-master',
    storageBucket: 'emlak-master.firebasestorage.app',
    messagingSenderId: '572835725773',
    appId: '1:572835725773:web:93531b623c67ce9392c484',
    iosBundleId: 'com.example.emlakmasterMobile',
  );
}

