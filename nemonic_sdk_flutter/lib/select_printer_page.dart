import 'package:flutter/material.dart';
import 'package:nemonic_sdk/constants/n_printer_type.dart';
import 'package:nemonic_sdk/i_n_printer_scan_controller.dart';
import 'package:nemonic_sdk/n_printer.dart';
import 'package:nemonic_sdk/n_printer_scan_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'empty_app_bar.dart';

class SelectPrinterPage extends StatefulWidget {
  const SelectPrinterPage({super.key});

  @override
  State<StatefulWidget> createState() => SelectPrinterPageState();
}

class SelectPrinterPageState extends State<SelectPrinterPage>
    implements INPrinterScanController {
  static const String prefSelectedPrinterName = 'prefSelectedPrinterName';
  static const String prefSelectedPrinterMacAddress =
      'prefSelectedPrinterMacAddress';
  static const String prefSelectedPrinterType = 'prefSelectedPrinterType';

  String _selectedPrinterValue = 'No selected printer';
  final List<String> _printersNamesValue = [];
  final List<NPrinter> _printers = [];

  NPrinterScanController? _printerScanController;

  SelectPrinterPageState() {
    _startScan();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSelectedPrinter();
    });
  }

  void _updateSelectedPrinter() async {
    NPrinter selectedPrinter = await loadSelectedPrinter();
    String displayName = getDisplayName(selectedPrinter);
    setState(() {
      _selectedPrinterValue = displayName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: const EmptyAppBar(), body: _bodyWidget());
  }

  @override
  void dispose() {
    _stopScan();
    super.dispose();
  }

  Widget _bodyWidget() {
    return Column(
      children: [_upperWidget(), _printersWidget(), _refreshWidget()],
    );
  }

  Widget _upperWidget() {
    ElevatedButton back =
        ElevatedButton(onPressed: _back, child: const Text('Back'));
    ElevatedButton unselect = ElevatedButton(
        onPressed: _unselectPrinter, child: const Text('Unselect'));

    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [back, Text(_selectedPrinterValue), unselect]);
  }

  Widget _printersWidget() {
    return Expanded(
        child: ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _printersNamesValue.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(_printersNamesValue[index]),
          // tileColor: _selectedPrinterIndex == index ? Colors.blue : null,
          onTap: () async {
            setState(() {
              _selectedPrinterValue = _printersNamesValue[index];
            });

            await saveSelectedPrinter(_printers[index]);
          },
        );
      },
    ));
  }

  Widget _refreshWidget() {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 40)),
        onPressed: _refresh,
        child: const Text('Refresh'));
  }

  _back() {
    _stopScan();
    Navigator.pop(context);
  }

  _unselectPrinter() async {
    setState(() {
      _selectedPrinterValue = 'No selected printer';
    });

    await deleteSelectedPrinter();
  }

  _startScan() {
    _printerScanController ??= NPrinterScanController(this);
    _printerScanController?.startScan();
  }

  _stopScan() {
    _printerScanController?.stopScan();
  }

  _refresh() {
    _printersNamesValue.clear();
    _printers.clear();
    _startScan();
  }

  @override
  void deviceFound(NPrinter printer) {
    setState(() {
      String printerName = getDisplayName(printer);
      _printersNamesValue.add(printerName);
      _printers.add(printer);
    });
  }

  static String getDisplayName(NPrinter printer) {
    if (printer.isEmpty()) {
      return 'No selected printer';
    }

    String name = printer.getName();
    String macAddress = printer.getMacAddress();
    return '$name($macAddress)';
  }

  static Future<void> saveSelectedPrinter(NPrinter printer) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (printer.isEmpty()) {
      prefs.remove(prefSelectedPrinterName);
      prefs.remove(prefSelectedPrinterMacAddress);
      prefs.remove(prefSelectedPrinterType);
      return;
    }

    String name = printer.getName();
    String macAddress = printer.getMacAddress();
    NPrinterType type = printer.getType();

    prefs.setString(prefSelectedPrinterName, name);
    prefs.setString(prefSelectedPrinterMacAddress, macAddress);
    prefs.setInt(prefSelectedPrinterType, type.code);
  }

  static Future<void> deleteSelectedPrinter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove(prefSelectedPrinterName);
    prefs.remove(prefSelectedPrinterMacAddress);
    prefs.remove(prefSelectedPrinterType);
  }

  static Future<NPrinter> loadSelectedPrinter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String name = prefs.getString(prefSelectedPrinterName) ?? '';
    String macAddress = prefs.getString(prefSelectedPrinterMacAddress) ?? '';
    NPrinterType type =
        NPrinterType.values[prefs.getInt(prefSelectedPrinterType) ?? 0];

    NPrinter printer = NPrinter();
    printer.setName(name);
    printer.setMacAddress(macAddress);
    printer.setType(type);

    return printer;
  }
}
