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
    iosBundleId: 'com.uguraytekin.emlakmastermobile',
  );

  /// macOS: Runner `PRODUCT_BUNDLE_IDENTIFIER` ve `macos/Runner/GoogleService-Info.plist` ile aynı olmalı.

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAsQl8NkdQ22MiX2Xx5IxgNzYixrj2EqbQ',
    // com.axioncrm.mobile uygulamasının Firebase App ID'si (google-services.json ile eşleşmeli).
    appId: '1:572835725773:android:ea905ae6d6d0eb4592c484',
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
    iosBundleId: 'com.uguraytekin.emlakmastermobile',
  );

  /// iOS: Runner `PRODUCT_BUNDLE_IDENTIFIER` ve `ios/Runner/GoogleService-Info.plist` ile aynı olmalı.
}