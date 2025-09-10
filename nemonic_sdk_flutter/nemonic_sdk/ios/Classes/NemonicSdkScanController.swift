import Flutter
import NemonicSdk

class NemonicSdkScanController: NSObject {
    private var channel: FlutterMethodChannel
    private var printerScanController: NPrinterScanController!

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
        printerScanController = NPrinterScanController(self)
    }

    public func startScan() -> Int {
        return printerScanController.startScan()
    }

    public func stopScan() {
        return printerScanController.stopScan()
    }
}

extension NemonicSdkScanController: NPrinterScanControllerDelegate {
    public func deviceFound(_ printer: NPrinter) {
        let data: [String: Any] = [
            "name": printer.getName(),
            "macAddress": printer.getMacAddress(),
            "type": printer.getType().rawValue
        ]

        channel.invokeMethod("deviceFound", arguments: data)
    }
}
