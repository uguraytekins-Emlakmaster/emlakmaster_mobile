import Cocoa
import FlutterMacOS
import GoogleSignIn

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

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  /// Google OAuth redirect — tek işleyici (çift handle oturumu bozar).
  override func application(_ application: NSApplication, open urls: [URL]) {
    var googleHandled = false
    for url in urls {
      if GIDSignIn.sharedInstance.handle(url) {
        googleHandled = true
      }
    }
    if !googleHandled {
      super.application(application, open: urls)
    }
    NSApp.activate(ignoringOtherApps: true)
  }
}
