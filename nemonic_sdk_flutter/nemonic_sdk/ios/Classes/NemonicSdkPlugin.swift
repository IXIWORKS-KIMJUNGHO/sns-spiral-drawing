import Flutter
import NemonicSdk
import UIKit

public class NemonicSdkPlugin: NSObject, FlutterPlugin {
  private let queueName: String = "com.mangoslab.queue"

  private let scanController: NemonicSdkScanController!
  private let controller: NemonicSdkController!

  private var printer = NPrinter()

  init(_ channel: FlutterMethodChannel) {
    scanController = NemonicSdkScanController(channel: channel)
    controller = NemonicSdkController(channel: channel)
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let taskQueue = registrar.messenger().makeBackgroundTaskQueue!()
    let channel = FlutterMethodChannel(name: "nemonic_sdk",
                                        binaryMessenger: registrar.messenger(),
                                        codec: FlutterStandardMethodCodec.sharedInstance(), 
                                        taskQueue: taskQueue)
    let instance = NemonicSdkPlugin(channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startScan":
      result(scanController.startScan())
    case "stopScan":
      scanController.stopScan()
      result(true)
    case "getDefaultConnectDelay":
      let defaultConnectDelayResult = controller.getDefaultConnectDelay()
      result(defaultConnectDelayResult)
    case "getConnectDelay":
      let connectDelayResult = controller.getConnectDelay()
      result(connectDelayResult)
    case "setConnectDelay":
      let connectDelay = getIntArgument(call, "msec")
      if connectDelay != nil {
        controller.setConnectDelay(UInt32(connectDelay!))
        result(nil)
      }
      else {
        result(NResult.invalidParameter.rawValue)
      }
    case "connect":
      let connectPrinter = getPrinterArgument(call)
      if connectPrinter == nil {
        result(NResult.invalidParameter.rawValue)
      }
      else {
        var connectPrinterType = connectPrinter!.getType()
        if (connectPrinterType == .nemonic || connectPrinterType == .nemonicLabel) {
          DispatchQueue.global().async() {
            let connectResult = self.connect(connectPrinter!)
            result(connectResult)
          }
        }
        else {
          let connectResult = connect(connectPrinter!)
          result(connectResult)
        }
      }
    case "disconnect":
      controller.disconnect()
      printer.reset()
      result(nil)
    case "getConnectState":
      let connectStateResult = controller.getConnectState()
      result(connectStateResult)
    case "cancel":
      controller.cancel()
      result(nil)
    case "setPrintTimeout":
      let enableAuto = getBoolArgument(call, "enableAuto")
      let manualTime = getIntArgument(call, "manualTime")
      if enableAuto != nil && manualTime != nil {
        controller.setPrintTimeout(enableAuto!, manualTime!)
      }
      result(nil)
    case "print":
      let printInfo = getPrintInfoArgument(call)
      if printInfo == nil {
        result(NResult.invalidParameter.rawValue)
      }
      else {
        DispatchQueue.global().async() {
          let printResult = self.controller.print(printInfo!)
          result(printResult)
        }
      }
    case "setTemplate":
      if let args = call.arguments as? [String: Any] {
        let bImage = args["image"] as? FlutterStandardTypedData
        if bImage == nil {
          result(NResult.invalidParameter.rawValue)
        }
        else {
          let image = UIImage(data: bImage!.data)
          if image == nil {
            result(NResult.invalidParameter.rawValue)
          }
          else {
            let withPrint = getBoolArgument(call, "withPrint")
            let enableDither = getBoolArgument(call, "enableDither")
            if withPrint == nil || enableDither == nil {
              result(NResult.invalidParameter.rawValue)
            } else {
              let printerType = printer.getType()
              if printerType == .nemonic || printerType == .nemonicLabel {
                DispatchQueue.global().async() {
                  let setTemplateResult = self.controller.setTemplate(image!, withPrint: withPrint!, enableDither: enableDither!)
                  result(setTemplateResult)
                }
              }
              else {
                let setTemplateResult = self.controller.setTemplate(image!, withPrint: withPrint!, enableDither: enableDither!)
                result(setTemplateResult)
              }
            }
          }
        }
      } else {
        result(NResult.invalidParameter.rawValue)
      }
    case "clearTemplate":
      let clearTemplateResult = controller.clearTemplate()
      result(clearTemplateResult)
    case "getPrinterStatus":
      let getPrinterStatusResult = controller.getPrinterStatus()
      result(getPrinterStatusResult)
    case "getCartridgeType":
      let getCartridgeTypeResult = controller.getCartridgeType()
      result(getCartridgeTypeResult)
    case "getPrinterName":
      let getPrinterNameResult = controller.getPrinterName()
      result(["result": getPrinterNameResult.getResult(), "value": getPrinterNameResult.getValue()])
    case "getBatteryLevel":
      let getBatteryLevelResult = controller.getBatteryLevel()
      result(getBatteryLevelResult)
    case "getBatteryStatus":
      let getBatteryStatusResult = controller.getBatteryStatus()
      result(getBatteryStatusResult)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func getStringArgument(_ call: FlutterMethodCall, _ name: String) -> String? {
    if let args = call.arguments as? [String: Any] {
      let result = args[name] as? String 
      return result
    }
    else {
      return nil
    }
  }

  private func getIntArgument(_ call: FlutterMethodCall, _ name: String) -> Int? {
    if let args = call.arguments as? [String: Any] {
      let result = args[name] as? Int 
      return result
    }
    else {
      return nil
    }
  }

  private func getBoolArgument(_ call: FlutterMethodCall, _ name: String) -> Bool? {
    if let args = call.arguments as? [String: Any] {
      let result = args[name] as? Bool 
      return result
    }
    else {
      return nil
    }
  }

  private func getByteArrayArgument(_ call: FlutterMethodCall, _ name: String) -> [UInt8]? {
    if let args = call.arguments as? [String: Any] {
      let result = args[name] as? FlutterStandardTypedData
      if result?.data == nil {
        return nil
      }
      else {
        return [UInt8](result!.data)
      }
    }
    else {
      return nil
    }
  }

  private func getPrinterArgument(_ call: FlutterMethodCall) -> NPrinter? {
    if let args = call.arguments as? [String: Any] {
      let name = args["name"] as? String ?? ""
      let macAddress = args["macAddress"] as? String ?? ""
      let type = NPrinterType(rawValue: args["type"] as? Int ?? NPrinterType.none.rawValue) ?? NPrinterType.none
      
      let printer = NPrinter()
      printer.setName(name)
      _ = printer.setMacAddress(macAddress)
      printer.setType(type)

      return printer 
    }
    else {
      return nil
    }
  }

  private func getPrintInfoArgument(_ call: FlutterMethodCall) -> NPrintInfo? {
    if let args = call.arguments as? [String: Any] {
      let printerName = args["printerName"] as? String ?? ""
      let printerMacAddress = args["printerMacAddress"] as? String ?? ""
      let printerType = NPrinterType(rawValue: args["printerType"] as? Int ?? NPrinterType.none.rawValue) ?? NPrinterType.none
      let printer = NPrinter()
      printer.setName(printerName)
        _ = printer.setMacAddress(printerMacAddress)
      printer.setType(printerType)

      let printQuality = NPrintQuality(rawValue: args["printQuality"] as? Int ?? NPrintQuality.lowFast.rawValue) ?? NPrintQuality.lowFast

      let bImages = args["images"] as? [FlutterStandardTypedData] ?? [FlutterStandardTypedData]()
      var images = [UIImage]()
      for bImage in bImages {
        let dImage = bImage.data
        let image = UIImage(data: dImage)
        if image == nil {
          return nil
        }
        images.append(image!)
      }

      let copies = args["copies"] as? Int ?? 1
      let isLastPageCut = args["isLastPageCut"] as? Bool ?? true
      let enableDither = args["enableDither"] as? Bool ?? true
      let isCheckPrinterStatus = args["isCheckPrinterStatus"] as? Bool ?? true
      let isCheckCartridgeType = args["isCheckCartridgeType"] as? Bool ?? true
      let isCheckPower = args["isCheckPower"] as? Bool ?? true

      let printInfo = NPrintInfo(printer: printer, images: images)
      _ = printInfo.setPrintQuality(printQuality)
          .setCopies(copies)
          .setEnableLastPageCut(isLastPageCut)
          .setEnableDither(enableDither)
          .setEnableCheckPrinterStatus(isCheckPrinterStatus)
          .setEnableCheckCartridgeType(isCheckCartridgeType)
          .setEnableCheckPower(isCheckPower)

      return printInfo
    }
    else {
      return nil
    }
  }

  private func connect(_ printer: NPrinter) -> Int {
    let result = self.controller.connect(printer, queueLabel: self.queueName)
    if result == NResult.ok.rawValue {
      self.printer = printer
    }

    return result
  }
}
