import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.regular)
    NSApp.activate(ignoringOtherApps: true)
    super.applicationDidFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Çıkış yapınca login'e dönerken ana pencere kapanırsa uygulama sonlanmasın.
    return false
  }

  /// Google Sign-In OAuth geri çağrısı (macOS).
  override func application(_ application: NSApplication, open urls: [URL]) {
    super.application(application, open: urls)
  }
}
