import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    self.minSize = NSSize(width: 800, height: 600)
    let visibleSize = self.screen?.visibleFrame.size ?? NSScreen.main?.visibleFrame.size
    let preferredSize = NSSize(
      width: min(1280, visibleSize?.width ?? 1280),
      height: min(800, visibleSize?.height ?? 800)
    )
    self.setContentSize(preferredSize)
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
