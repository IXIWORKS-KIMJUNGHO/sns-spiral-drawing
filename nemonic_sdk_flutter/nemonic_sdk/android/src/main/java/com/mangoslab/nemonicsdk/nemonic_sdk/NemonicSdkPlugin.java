package com.mangoslab.nemonicsdk.nemonic_sdk;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Log;

import androidx.annotation.NonNull;

import com.mangoslab.nemonicsdk.NPrinter;
import com.mangoslab.nemonicsdk.NPrintInfo;
import com.mangoslab.nemonicsdk.constants.NPrinterType;
import com.mangoslab.nemonicsdk.constants.NPrintQuality;
import com.mangoslab.nemonicsdk.constants.NResultString;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMethodCodec;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/** NemonicSdkPlugin */
public class NemonicSdkPlugin implements FlutterPlugin, MethodCallHandler {
  private static final String TAG = "NemonicSdkPlugin";

  /// The MethodChannel that will the communication between Flutter and native
  /// Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine
  /// and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;

  private NemonicSdkScanController scanController;
  private NemonicSdkController controller;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    BinaryMessenger messenger = flutterPluginBinding.getBinaryMessenger();
    BinaryMessenger.TaskQueue taskQueue = messenger.makeBackgroundTaskQueue();
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "nemonic_sdk");
    channel.setMethodCallHandler(this);

    scanController = new NemonicSdkScanController(channel, flutterPluginBinding.getApplicationContext());
    controller = new NemonicSdkController(channel, flutterPluginBinding.getApplicationContext());
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    String method = call.method;

    switch (method) {
      case "startScan":
        int startScanResult = scanController.startScan();
        result.success(startScanResult);
        break;
      case "stopScan":
        scanController.stopScan();
        result.success(true);
        break;
      case "getDefaultConnectDelay":
        int defaultConnectDelayResult = controller.getDefaultConnectDelay();
        result.success(defaultConnectDelayResult);
        break;
      case "getConnectDelay":
        int connectDelayResult = controller.getConnectDelay();
        result.success(connectDelayResult);
        break;
      case "setConnectDelay":
        int connectDelay = call.argument("msec");
        controller.setConnectDelay(connectDelay);
        result.success(null);
        break;
      case "connect":
        NPrinter connectPrinter = getPrinterArgument(call);
        int connectResult = controller.connect(connectPrinter);
        result.success(connectResult);
        break;
      case "disconnect":
        controller.disconnect();
        result.success(null);
        break;
      case "getConnectState":
        int connectStateResult = controller.getConnectState();
        result.success(connectStateResult);
        break;
      case "cancel":
        controller.cancel();
        result.success(null);
        break;
      case "setPrintTimeout":
        boolean enableAuto = call.argument("enableAuto");
        int manualTimeout = call.argument("manualTime");
        controller.setPrintTimeout(enableAuto, manualTimeout);
        result.success(null);
        break;
      case "print":
        NPrintInfo printInfo = getPrintInfoArgument(call);
        int printResult = controller.print(printInfo);
        result.success(printResult);
        break;
      case "setTemplate":
        byte[] bTemplateImage = call.argument("image");
        Bitmap templateImage = BitmapFactory.decodeByteArray(bTemplateImage, 0, bTemplateImage.length);
        boolean withPrint = call.argument("withPrint");
        boolean enableDither = call.argument("enableDither");
        int setTemplateResult = controller.setTemplate(templateImage, withPrint, enableDither);
        result.success(setTemplateResult);
        break;
      case "clearTemplate":
        int clearTemplateResult = controller.clearTemplate();
        result.success(clearTemplateResult);
        break;
      case "getPrinterStatus":
        int getPrinterStatusResult = controller.getPrinterStatus();
        result.success(getPrinterStatusResult);
        break;
      case "getCartridgeType":
        int getCartridgeTypeResult = controller.getCartridgeType();
        result.success(getCartridgeTypeResult);
        break;
      case "getPrinterName":
        NResultString getPrinterNameResult = controller.getPrinterName();
        Map<String, Object> mapGetPrinterNameResult = new HashMap<>();
        mapGetPrinterNameResult.put("result", getPrinterNameResult.getResult());
        mapGetPrinterNameResult.put("value", getPrinterNameResult.getValue());
        result.success(mapGetPrinterNameResult);
        break;
      case "getBatteryLevel":
        int getBatteryLevelResult = controller.getBatteryLevel();
        result.success(getBatteryLevelResult);
        break;
      case "getBatteryStatus":
        int getBatteryStatusResult = controller.getBatteryStatus();
        result.success(getBatteryStatusResult);
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  private NPrinter getPrinterArgument(MethodCall call) {
    if (call == null) {
      Log.d(TAG, "getPrinterArgument call is null");
    }
    String name = call.argument("name");
    String macAddress = call.argument("macAddress");
    int iType = call.argument("type");
    NPrinterType type = NPrinterType.valueOf(iType);

    Log.d(TAG, String.format("getPrinterArgument name = %s", name));
    Log.d(TAG, String.format("getPrinterArgument macAddress = %s", macAddress));
    Log.d(TAG, String.format("getPrinterArgument type = %d", iType));

    NPrinter result = new NPrinter();
    result.setName(name);
    result.setMacAddress(macAddress);
    result.setType(type);

    return result;
  }

  private NPrintInfo getPrintInfoArgument(@NonNull MethodCall call) {
    String printerName = call.argument("printerName");
    String printerMacAddress = call.argument("printerMacAddress");
    int iPrinterType = call.argument("printerType");
    NPrinterType printerType = NPrinterType.valueOf(iPrinterType);
    NPrinter printer = new NPrinter(printerType, printerName, printerMacAddress);

    int iPrintQuality = call.argument("printQuality");
    NPrintQuality printQuality = NPrintQuality.valueOf(iPrintQuality);

    List<byte[]> bImages = call.argument("images");
    List<Bitmap> images = new ArrayList<>();
    for (int i = 0; i < bImages.size(); i++) {
      byte[] bImage = bImages.get(i);
      Bitmap image = BitmapFactory.decodeByteArray(bImage, 0, bImage.length);
      images.add(image);
    }

    int copies = call.argument("copies");
    boolean isLastPageCut = call.argument("isLastPageCut");
    boolean enableDither = call.argument("enableDither");
    boolean isCheckPrinterStatus = call.argument("isCheckPrinterStatus");
    boolean isCheckCartridgeType = call.argument("isCheckCartridgeType");
    boolean isCheckPower = call.argument("isCheckPower");

    NPrintInfo printInfo = new NPrintInfo(printer, images);
    printInfo.setPrintQuality(printQuality)
        .setCopies(copies)
        .setEnableLastPageCut(isLastPageCut)
        .setEnableDither(enableDither)
        .setEnableCheckPrinterStatus(isCheckPrinterStatus)
        .setEnableCheckCartridgeType(isCheckCartridgeType)
        .setEnableCheckPower(isCheckPower);

    return printInfo;
  }
}
