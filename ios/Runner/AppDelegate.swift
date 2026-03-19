import Flutter
import UIKit
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Duplicate FIRApp configure crash’ini önlemek için plugin kaydından önce guard kur.
    FirebaseConfigureGuardInstall()
    // Plist’ten tek seferlik configure (simulator’da nil apiKey decode crash’ını önlemek için).
    FirebaseConfigureFromPlistIfNeeded()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Plugin yüklendi; optionsFromFIROptions apiKey yamasını kur (Dart decode crash önlemi).
    FirebaseConfigureGuardInstallCorePluginPatch()
  }
}
