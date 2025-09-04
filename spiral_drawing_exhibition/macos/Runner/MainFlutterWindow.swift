import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow, NSWindowDelegate {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    
    // 1:1 비율로 초기 크기 설정 (1000x1000)
    let squareSize: CGFloat = 1000
    let windowFrame = NSRect(x: self.frame.origin.x, 
                             y: self.frame.origin.y, 
                             width: squareSize, 
                             height: squareSize)
    
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    
    // 윈도우 설정
    self.delegate = self
    self.styleMask.insert(.resizable)
    self.contentAspectRatio = NSSize(width: 1.0, height: 1.0) // 1:1 비율 강제
    self.minSize = NSSize(width: 800, height: 800) // 최소 크기
    self.maxSize = NSSize(width: 1400, height: 1400) // 최대 크기

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
  
  // 윈도우 크기 조절 시 1:1 비율 유지
  func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
    // 가로와 세로 중 더 작은 값을 사용하여 정사각형 유지
    let size = min(frameSize.width, frameSize.height)
    return NSSize(width: size, height: size)
  }
}
