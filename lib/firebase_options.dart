// Firebase configuration for Sinkly (project "gen-lang-client-0756551794"), generated from
// android/app/google-services.json and ios/Runner/GoogleService-Info.plist.
// These values identify the app to Firebase; they are not secrets.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Sinkly has no web build.');
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => throw UnsupportedError('Firebase is set up for Android and iOS only.'),
    };
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCyzDhMKc2INst6qcmwlNLh5jVeO7p89Eo',
    appId: '1:851013537296:android:c878d846de6d9347454495',
    messagingSenderId: '851013537296',
    projectId: 'gen-lang-client-0756551794',
    storageBucket: 'gen-lang-client-0756551794.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAnwXF_-G50Owtho738WlOY1UeIaYJFe-k',
    appId: '1:851013537296:ios:333307e9f5d85970454495',
    messagingSenderId: '851013537296',
    projectId: 'gen-lang-client-0756551794',
    storageBucket: 'gen-lang-client-0756551794.firebasestorage.app',
    iosBundleId: 'com.sinkly.app',
  );
}
