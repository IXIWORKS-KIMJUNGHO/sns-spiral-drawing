import Flutter
import NemonicSdk

class NemonicSdkController: NSObject {
    private var channel: FlutterMethodChannel
    private var printerController: NPrinterController!

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
        printerController = NPrinterController(self)
    }

    public func getDefaultConnectDelay() -> UInt32 {
        return printerController.getDefaultConnectDelay()
    }

    public func getConnectDelay() -> UInt32 {
        return printerController.getConnectDelay()
    }

    public func setConnectDelay(_ msec: UInt32) {
        return printerController.setConnectDelay(msec)
    }

    public func connect(_ printer: NPrinter, queueLabel: String? = nil) -> Int {
        return printerController.connect(printer, queueLabel: queueLabel)
    }

    public func disconnect() {
        printerController.disconnect()
    }

    public func getConnectState() -> Int {
        return printerController.getConnectState()
    }

    public func cancel() {
        printerController.cancel()
    }

    public func setPrintTimeout(_ enableAuto: Bool, _ manualTime: Int) {
        printerController.setPrintTimeout(enableAuto, manualTime)
    }

    public func print(_ printInfo: NPrintInfo) -> Int {
        return printerController.print(printInfo)
    }

    public func setTemplate(_ image: UIImage, withPrint: Bool, enableDither: Bool) -> Int {
        return printerController.setTemplate(image, withPrint: withPrint, enableDither: enableDither)
    }

    public func clearTemplate() -> Int {
        printerController.clearTemplate()
    }

    public func getPrinterStatus() -> Int {
        return printerController.getPrinterStatus()
    }

    public func getCartridgeType() -> Int {
        return printerController.getCartridgeType()
    }

    public func getPrinterName() -> NResultString {
        return printerController.getPrinterName()
    }

    public func getBatteryLevel() -> Int {
        return printerController.getBatteryLevel()
    }

    public func getBatteryStatus() -> Int {
        return printerController.getBatteryStatus()
    }
}

extension NemonicSdkController: NPrinterControllerDelegate {
    public func disconnected() {
        DispatchQueue.main.async {
            self.channel.invokeMethod("disconnected", arguments: nil)
        }
    }

    public func printProgress(index: Int, total: Int, result: Int) {
        let data: [String: Any] = [
            "index": index,
            "total": total,
            "result": result
        ]

        DispatchQueue.main.async {
            self.channel.invokeMethod("printProgress", arguments: data)
        }
    }

    public func printComplete(result: Int) {
        let data: [String: Any] = [
            "result": result
        ]

        DispatchQueue.main.async {
            self.channel.invokeMethod("printComplete", arguments: data)
        }
    }
}