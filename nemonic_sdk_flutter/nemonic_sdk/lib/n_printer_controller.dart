import 'dart:io';

import 'package:flutter/services.dart';
import 'package:nemonic_sdk/constants/n_result.dart';

import '../n_printer.dart';
import 'constants/n_printer_type.dart';
import 'constants/n_result_string.dart';
import 'i_n_printer_controller.dart';
import 'n_print_info.dart';

class NPrinterController {
  final _channel = const MethodChannel('nemonic_sdk');
  late INPrinterController? _callback;

  NPrinterController(INPrinterController? callback) {
    _callback = callback;
  }

  Future<int> getDefaultConnectDelay() async {
    dynamic dResult = await _channel.invokeMethod('getDefaultConnectDelay');
    int result = dResult as int;

    return result;
  }

  Future<int> getConnectDelay() async {
    dynamic dResult = await _channel.invokeMethod('getConnectDelay');
    int result = dResult as int;

    return result;
  }

  Future<void> setConnectDelay(int msec) async {
    Map<String, Object> map = {'msec': msec};

    await _channel.invokeMethod('setConnectDelay', map);
  }

  Future<int> getDefaultDisconnectDelay() async {
    dynamic dResult = await _channel.invokeMethod('getDefaultDisconnectDelay');
    int result = dResult as int;

    return result;
  }

  Future<int> getDisconnectDelay() async {
    dynamic dResult = await _channel.invokeMethod('getDisconnectDelay');
    int result = dResult as int;

    return result;
  }

  Future<void> setDisconnectDelay(int msec) async {
    Map<String, Object> map = {'msec': msec};

    await _channel.invokeMethod('setDisconnectDelay', map);
  }

  Future<int> connect(NPrinter printer) async {
    Map<String, Object> map = {
      'name': printer.getName(),
      'macAddress': printer.getMacAddress(),
      'type': printer.getType().code
    };

    dynamic dResult = await _channel.invokeMethod('connect', map);
    int result = dResult as int;

    if (result != NResult.ok.code) {
      return result;
    }

    _channel.setMethodCallHandler((call) async {
      String method = call.method;
      switch (method) {
        case 'disconnected':
          _callback?.disconnected();
          break;
        case 'printProgress':
          if (call.arguments is! Map<Object?, Object?>) {
            return;
          }

          Map<Object?, Object?> printProgressMap =
              call.arguments as Map<Object?, Object?>;
          int index = printProgressMap['index'] as int;
          int total = printProgressMap['total'] as int;
          int result = printProgressMap['result'] as int;

          _callback?.printProgress(index, total, result);
          break;
        case 'printComplete':
          if (call.arguments is! Map<Object?, Object?>) {
            return;
          }

          Map<Object?, Object?> printProgressMap =
              call.arguments as Map<Object?, Object?>;
          int result = printProgressMap['result'] as int;

          _callback?.printComplete(result);
          break;
      }
    });

    return result;
  }

  Future<void> disconnect() async {
    await _channel.invokeMethod('disconnect');
    _channel.setMethodCallHandler(null);
  }

  Future<int> getConnectState() async {
    dynamic dResult = await _channel.invokeMethod('getConnectState');
    int result = dResult as int;

    return result;
  }

  Future<void> cancel() async {
    await _channel.invokeMethod('cancel');
  }

  Future<void> setPrintTimeout(bool enableAuto, int manualTime) async {
    Map<String, Object> map = {
      'enableAuto': enableAuto,
      'manualTime': manualTime
    };
    await _channel.invokeMethod('setPrintTimeout', map);
  }

  Future<int> print(NPrintInfo printInfo) async {
    NPrinter printer = printInfo.getPrinter();
    Map<String, Object> map = {
      'printerName': printer.getName(),
      'printerMacAddress': printer.getMacAddress(),
      'printerType': printer.getType().code,
      'printQuality': printInfo.getPrintQuality().code,
      'images': printInfo.getImages(),
      'copies': printInfo.getCopies(),
      'isLastPageCut': printInfo.isLastPageCutEnable(),
      'enableDither': printInfo.isEnableDither(),
      'isCheckPrinterStatus': printInfo.isCheckPrinterStatus(),
      'isCheckCartridgeType': printInfo.isCheckCartridgeType(),
      'isCheckPower': printInfo.isCheckPower()
    };

    dynamic dResult = await _channel.invokeMethod('print', map);
    int result = dResult as int;

    return result;
  }

  Future<int> setTemplate(
      Uint8List image, bool withPrint, bool enableDither) async {
    Map<String, Object> map = {
      'image': image,
      'withPrint': withPrint,
      'enableDither': enableDither
    };

    dynamic dResult = await _channel.invokeMethod('setTemplate', map);
    int result = dResult as int;

    return result;
  }

  Future<int> clearTemplate() async {
    dynamic dResult = await _channel.invokeMethod('clearTemplate');
    int result = dResult as int;

    return result;
  }

  Future<int> getPrinterStatus() async {
    dynamic dResult = await _channel.invokeMethod('getPrinterStatus');
    int result = dResult as int;

    return result;
  }

  Future<int> getCartridgeType() async {
    dynamic dResult = await _channel.invokeMethod('getCartridgeType');
    int result = dResult as int;

    return result;
  }

  Future<NResultString> getPrinterName() async {
    dynamic dResult = await _channel.invokeMethod('getPrinterName');
    Map<Object?, Object?> map = dResult as Map<Object?, Object?>;
    int result = map['result'] as int;
    String value = map['value'] as String;

    return NResultString(result, value);
  }

  Future<int> getBatteryLevel() async {
    dynamic dResult = await _channel.invokeMethod('getBatteryLevel');
    int result = dResult as int;

    return result;
  }

  Future<int> getBatteryStatus() async {
    dynamic dResult = await _channel.invokeMethod('getBatteryStatus');
    int result = dResult as int;

    return result;
  }
}
