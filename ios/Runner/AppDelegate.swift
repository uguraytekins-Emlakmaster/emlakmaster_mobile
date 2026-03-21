import Flutter
import UIKit
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // FCM: APNs token zinciri için uzaktan bildirim kaydı (bildirim izni Dart tarafında istenir).
    // Bu çağrı, "no APNS Token" / FCM token gecikmesini azaltmaya yardımcı olur.
    application.registerForRemoteNotifications()
    // Firebase init Dart tarafında tek noktadan yönetiliyor.
    // Native guard/swizzle katmanı bazı cihazlarda core/not-initialized ürettiği için devre dışı.
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // flutter_contacts 1.x register aşamasında delegate.window!.rootViewController bekler;
    // UIScene ile window sahne tarafında kalır — nil olunca fatal error.
    synchronizeAppDelegateWindowForLegacyPlugins()
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  /// Eski plugin'ler için AppDelegate.window'u sahne penceresine bağla.
  private func synchronizeAppDelegateWindowForLegacyPlugins() {
    if window != nil { return }
    if #available(iOS 13.0, *) {
      for case let windowScene as UIWindowScene in UIApplication.shared.connectedScenes {
        if let w = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first {
          window = w
          return
        }
      }
    }
  }
}
