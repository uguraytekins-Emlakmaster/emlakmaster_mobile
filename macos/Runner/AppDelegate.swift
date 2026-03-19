import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  /// Google Sign-In OAuth geri çağrısı (macOS).
  override func application(_ application: NSApplication, open urls: [URL]) {
    super.application(application, open: urls)
  }
}
