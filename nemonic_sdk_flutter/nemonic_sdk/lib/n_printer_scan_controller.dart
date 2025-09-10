import 'package:flutter/services.dart';
import 'package:nemonic_sdk/constants/n_result.dart';

import 'constants/n_printer_type.dart';
import 'i_n_printer_scan_controller.dart';
import 'n_printer.dart';

class NPrinterScanController {
  final _channel = const MethodChannel('nemonic_sdk');
  late INPrinterScanController _callback;

  NPrinterScanController(INPrinterScanController callback) {
    _callback = callback;
  }

  Future<int> startScan() async {
    dynamic dResult = await _channel.invokeMethod('startScan');
    int result = dResult as int;

    if (result != NResult.ok.code) {
      return result;
    }

    _channel.setMethodCallHandler((call) async {
      if (call.method != 'deviceFound' ||
          call.arguments is! Map<Object?, Object?>) {
        return;
      }

      Map<Object?, Object?> map = call.arguments as Map<Object?, Object?>;
      String name = map['name'].toString();
      String macAddress = map['macAddress'].toString();
      int type = map['type'] as int;
      NPrinter printer = NPrinter();
      printer.setName(name);
      printer.setMacAddress(macAddress);
      printer.setType(NPrinterType.values[type]);

      _callback.deviceFound(printer);
    });

    return result;
  }

  Future stopScan() async {
    await _channel.invokeMethod('stopScan');
    _channel.setMethodCallHandler(null);
  }
}
