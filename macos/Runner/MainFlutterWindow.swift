import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    // Premium masaüstü deneyimi: pencere küçük/çerçeveli "dış uygulama" gibi
    // durmasın. Açılışta görünür ekran alanının büyük kısmını kaplayan,
    // ortalanmış ve makul bir alt sınırı olan büyütülebilir bir pencere ver.
    if let screen = self.screen ?? NSScreen.main {
      let visible = screen.visibleFrame
      let targetWidth = max(1100.0, visible.width * 0.9)
      let targetHeight = max(720.0, visible.height * 0.9)
      let width = min(targetWidth, visible.width)
      let height = min(targetHeight, visible.height)
      let originX = visible.origin.x + (visible.width - width) / 2.0
      let originY = visible.origin.y + (visible.height - height) / 2.0
      let frame = NSRect(x: originX, y: originY, width: width, height: height)
      self.setFrame(frame, display: true)
    }
    // Pencere içeriğinin asla aşırı sıkışmaması için alt sınır.
    self.minSize = NSSize(width: 960, height: 640)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
    self.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }
}
