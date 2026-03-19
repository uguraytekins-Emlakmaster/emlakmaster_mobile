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
    appId: '1:572835725773:web:93531b623c67ce9392c484',
    messagingSenderId: '572835725773',
    projectId: 'emlak-master',
    authDomain: 'emlak-master.firebaseapp.com',
    storageBucket: 'emlak-master.firebasestorage.app',
    measurementId: 'G-JN9PX6QL6V',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDKdLUjaSD3aOcswit93mCcoz_VrO3HgWY',
    appId: '1:572835725773:ios:9cc83a12d81b6aa392c484',
    messagingSenderId: '572835725773',
    projectId: 'emlak-master',
    storageBucket: 'emlak-master.firebasestorage.app',
    iosClientId: '572835725773-8s71g3li2ful895gppeb6bvlbck09hkd.apps.googleusercontent.com',
    iosBundleId: 'com.example.emlakmasterMobile',
  );

  /// macOS: Aynı proje; GoogleService-Info.plist ile uyumlu.

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAsQl8NkdQ22MiX2Xx5IxgNzYixrj2EqbQ',
    appId: '1:572835725773:android:27252e78a15a8fda92c484',
    messagingSenderId: '572835725773',
    projectId: 'emlak-master',
    storageBucket: 'emlak-master.firebasestorage.app',
  );

  /// Android: Aynı Firebase projesi. Tam yapılandırma için: flutterfire configure

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDKdLUjaSD3aOcswit93mCcoz_VrO3HgWY',
    appId: '1:572835725773:ios:9cc83a12d81b6aa392c484',
    messagingSenderId: '572835725773',
    projectId: 'emlak-master',
    storageBucket: 'emlak-master.firebasestorage.app',
    iosClientId: '572835725773-8s71g3li2ful895gppeb6bvlbck09hkd.apps.googleusercontent.com',
    iosBundleId: 'com.example.emlakmasterMobile',
  );

  /// iOS: Aynı Firebase projesi. Tam yapılandırma için: flutterfire configure
}