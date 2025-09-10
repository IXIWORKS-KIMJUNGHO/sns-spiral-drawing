import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nemonic_sdk/constants/n_battery_status.dart';
import 'package:nemonic_sdk/constants/n_cartridge_type.dart';
import 'package:nemonic_sdk/constants/n_print_quality.dart';
import 'package:nemonic_sdk/constants/n_printer_status.dart';
import 'package:nemonic_sdk/constants/n_result.dart';
import 'package:nemonic_sdk/constants/n_result_string.dart';
import 'package:nemonic_sdk/i_n_printer_controller.dart';
import 'package:nemonic_sdk/n_print_info.dart';
import 'package:nemonic_sdk/n_printer.dart';
import 'package:nemonic_sdk/n_printer_controller.dart';

import 'empty_app_bar.dart';
import 'select_printer_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<StatefulWidget> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> implements INPrinterController {
  String _imagePath = '';
  String _selectedPrinterName = 'No selected printer';
  String _connectTextValue = 'Connect';
  int _copies = 1;
  int _printQualityType = 0;
  bool _isLastPageCut = true;
  bool _isDither = true;

  String _getPrinterStatusValue = '';
  String _getCartridgeTypeValue = '';
  String _getPrinterNameValue = '';

  String _getBatteryLevelValue = '';
  String _getBatteryStatusValue = '';

  bool _enableConnectButton = true;
  bool _enablePrintButton = true;
  bool _enableSetTemplateButton = true;

  NPrinter _selectedPrinter = NPrinter();
  NPrinterController _printerController = NPrinterController(null);

  @override
  void initState() {
    super.initState();
    _printerController = NPrinterController(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSelectedPrinter();
    });
  }

  void _updateSelectedPrinter() async {
    _selectedPrinter = await SelectPrinterPageState.loadSelectedPrinter();
    String displayName =
        SelectPrinterPageState.getDisplayName(_selectedPrinter);
    setState(() {
      _selectedPrinterName = displayName;
    });
  }

  @override
  Widget build(BuildContext context) {
    _updateSelectedPrinter();
    return Scaffold(appBar: const EmptyAppBar(), body: _bodyWidget());
  }

  Widget _bodyWidget() {
    return Column(
      children: [_upperWidget(), _bottomWidget()],
    );
  }

  Widget _upperWidget() {
    return Row(
      children: [
        _selectedImage(),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: [_selectedPrinterWidget(), _connectPrinterWidget()],
        ))
      ],
    );
  }

  Widget _selectedImage() {
    return InkWell(
      onTap: _imagePicker,
      child: _image(),
    );
  }

  Widget _image() {
    Widget child;
    if (_imagePath.isEmpty) {
      child = Container(color: Colors.white);
    } else {
      child = Image.file(File(_imagePath), fit: BoxFit.contain);
    }

    return SizedBox(height: 200, width: 150, child: child);
  }

  Widget _selectedPrinterWidget() {
    return Column(
      children: [
        Text(_selectedPrinterName),
        ElevatedButton(
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40)),
            onPressed: _selectPrinter,
            child: const Text('Select printer'))
      ],
    );
  }

  Widget _connectPrinterWidget() {
    return Column(
      children: [_connectButton()],
    );
  }

  Widget _connectButton() {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 40)),
        onPressed: _enableConnectButton ? () => _connect() : null,
        child: Text(_connectTextValue));
  }

  Widget _bottomWidget() {
    return Expanded(
        child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(children: [
              _printWidget(),
              _templateWidget(),
              _printerInformationWidget(),
              _powerWidget(),
            ])));
  }

  Widget _printWidget() {
    TextField copies = TextField(
        decoration: const InputDecoration(
          border: UnderlineInputBorder(),
          labelText: '1',
          hintText: 'Copies',
        ),
        keyboardType: TextInputType.number,
        onChanged: (text) {
          setState(() {
            if (text.isEmpty) {
              _copies = 1;
            } else {
              _copies = int.parse(text);
            }
          });
        });

    Column print = Column(children: [
      ElevatedButton(
          // style: ElevatedButton.styleFrom(
          //     minimumSize: const Size(double.infinity, 40)),
          onPressed: _enablePrintButton ? () => _print() : null,
          child: const Text('Print'))
    ]);

    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [SizedBox(width: 150, child: copies), print],
      ),
      _printOptionWidget()
    ]);
  }

  Widget _printOptionWidget() {
    Widget printOptions = const SizedBox(
        width: double.infinity,
        child: Text('Print options',
            textAlign: TextAlign.start,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0)));

    return Column(
      children: [
        printOptions,
        _printQualityWidget(),
        _isLastPageCutWidget(),
        _isDitherWidget()
      ],
    );
  }

  Widget _printQualityWidget() {
    List printQualityNames = ['Low fast', 'Middle', 'High slow'];

    List<Widget> buttons = [];
    for (int i = 0; i < printQualityNames.length; i++) {
      var name = printQualityNames[i];
      buttons.add(SizedBox(
          width: 200,
          child: RadioListTile(
              title: Text(name),
              value: i,
              groupValue: _printQualityType,
              onChanged: (int? value) {
                setState(() {
                  _printQualityType = value!;
                });
              })));
    }

    return Column(mainAxisSize: MainAxisSize.max, children: buttons);
  }

  Widget _isLastPageCutWidget() {
    Switch lastPageCutSwitch = Switch(
        value: _isLastPageCut,
        onChanged: (value) {
          setState(() {
            _isLastPageCut = value;
          });
        });
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [const Text('Last page cut'), lastPageCutSwitch]);
  }

  Widget _isDitherWidget() {
    Switch lastPageCutSwitch = Switch(
        value: _isDither,
        onChanged: (value) {
          setState(() {
            _isDither = value;
          });
        });
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [const Text('Dither'), lastPageCutSwitch]);
  }

  Widget _templateWidget() {
    Widget template = const SizedBox(
        width: double.infinity,
        child: Text('Template',
            textAlign: TextAlign.start,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0)));

    ElevatedButton set = ElevatedButton(
        onPressed: _enableSetTemplateButton ? () => _setTemplate() : null,
        child: const Text('Set'));

    ElevatedButton delete =
        ElevatedButton(onPressed: _clearTemplate, child: const Text('Delete'));

    return Column(mainAxisAlignment: MainAxisAlignment.start, children: [
      template,
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [set, delete],
      )
    ]);
  }

  Widget _printerInformationWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(
            width: double.infinity,
            child: Text('Printer information',
                textAlign: TextAlign.start,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0))),
        _printerStatusWidget(),
        _cartridgetTypeWidget(),
        _printerNameWidget()
      ],
    );
  }

  Widget _printerStatusWidget() {
    ElevatedButton get =
        ElevatedButton(onPressed: _getPrinterStatus, child: const Text('Get'));

    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      const Text('Printer status'),
      Text(_getPrinterStatusValue),
      get
    ]);
  }

  Widget _cartridgetTypeWidget() {
    ElevatedButton get =
        ElevatedButton(onPressed: _getCartridgeType, child: const Text('Get'));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Cartridget type'),
        Text(_getCartridgeTypeValue),
        get
      ],
    );
  }

  Widget _printerNameWidget() {
    ElevatedButton get =
        ElevatedButton(onPressed: _getPrinterName, child: const Text('Get'));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [const Text('Printer name'), Text(_getPrinterNameValue), get],
    );
  }

  Widget _powerWidget() {
    return Column(mainAxisAlignment: MainAxisAlignment.start, children: [
      const SizedBox(
          width: double.infinity,
          child: Text('Power',
              textAlign: TextAlign.start,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0))),
      _batteryWidget()
    ]);
  }

  Widget _batteryWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [_batteryLevelWidget(), _batteryStatusWidget()],
    );
  }

  Widget _batteryLevelWidget() {
    ElevatedButton get =
        ElevatedButton(onPressed: _getBatteryLevel, child: const Text('Get'));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [const Text('Battery level'), Text(_getBatteryLevelValue), get],
    );
  }

  Widget _batteryStatusWidget() {
    ElevatedButton get =
        ElevatedButton(onPressed: _getBatteryStatus, child: const Text('Get'));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Battery status'),
        Text(_getBatteryStatusValue),
        get
      ],
    );
  }

  _imagePicker() async {
    final ImagePicker imagePicker = ImagePicker();
    final XFile? image =
        await imagePicker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  _selectPrinter() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const SelectPrinterPage()));
  }

  _connect() async {
    setState(() {
      _enableConnectButton = false;
    });

    if (_connectTextValue == 'Connect') {
      int result = await _printerController.connect(_selectedPrinter);
      if (result == NResult.ok.index) {
        setState(() {
          _connectTextValue = 'Disconnect';
          _showToast('Connected');
        });
      } else {
        _showToast('connect failed($result)');
      }
    } else {
      await _printerController.disconnect();
      setState(() {
        _connectTextValue = 'Connect';
        _showToast('Disconnected');
      });
    }

    setState(() {
      _enableConnectButton = true;
    });
  }

  _print() async {
    if (_imagePath.isEmpty) {
      _showToast('No selected image!');
      return;
    }

    setState(() {
      _enablePrintButton = false;
    });

    Uint8List image = await File(_imagePath).readAsBytes();
    NPrintQuality printQuality = NPrintQuality.lowFast;
    switch (_printQualityType) {
      case 0:
        printQuality = NPrintQuality.lowFast;
        break;
      case 1:
        printQuality = NPrintQuality.middle;
        break;
      case 2:
        printQuality = NPrintQuality.highSlow;
        break;
    }
    NPrintInfo printInfo = NPrintInfo(_selectedPrinter);
    printInfo
        .setPrintQuality(printQuality)
        .setImage(image)
        .setEnableLastPageCut(_isLastPageCut)
        .setEnableDither(_isDither)
        .setCopies(_copies);
    int result = await _printerController.print(printInfo);
    if (result == NResult.ok.code) {
      _showToast('Success');
    } else {
      String printerStatusContent = _getPrinterStatusContent(result);
      if (printerStatusContent.isNotEmpty) {
        _showToast(printerStatusContent);
      } else {
        _processErrorResult(result);
      }
    }

    setState(() {
      _enablePrintButton = true;
    });
  }

  _getPrinterStatus() async {
    int result = await _printerController.getPrinterStatus();
    if (result == NResult.ok.code) {
      setState(() {
        _getPrinterStatusValue = 'OK';
      });
      _showToast('Success');
    } else {
      String printerStatusContent = _getPrinterStatusContent(result);
      if (printerStatusContent.isNotEmpty) {
        setState(() {
          _getPrinterStatusValue = printerStatusContent;
        });
        _showToast(printerStatusContent);
      } else {
        String content = _processErrorResult(result);
        setState(() {
          _getPrinterStatusValue = content;
        });
      }
    }
  }

  _getCartridgeType() async {
    int result = await _printerController.getCartridgeType();
    if (result >= 0) {
      NCartridgeType type = NCartridgeType.getByCode(result);
      String content = '';
      switch (type) {
        case NCartridgeType.none:
          content = 'None';
          break;
        case NCartridgeType.white:
          content = 'White';
          break;
        case NCartridgeType.yellow:
          content = 'Yellow';
          break;
        case NCartridgeType.green:
          content = 'Green';
          break;
        case NCartridgeType.blue:
          content = 'Blue';
          break;
        case NCartridgeType.pink:
          content = 'Pink';
          break;
        case NCartridgeType.l1:
          content = 'L1';
          break;
        case NCartridgeType.l2:
          content = 'L2';
          break;
        case NCartridgeType.l3:
          content = 'L3';
          break;
        case NCartridgeType.l4:
          content = 'L4';
        case NCartridgeType.m1:
          content = 'm1';
        case NCartridgeType.m2:
          content = 'm2';
        case NCartridgeType.m3:
          content = 'm3';
        case NCartridgeType.m4:
          content = 'm4';
      }
      setState(() {
        _getCartridgeTypeValue = content;
      });
      _showToast(content);
    } else {
      String content = _processErrorResult(result);
      setState(() {
        _getCartridgeTypeValue = content;
      });
    }
  }

  _getPrinterName() async {
    NResultString resultString = await _printerController.getPrinterName();
    int result = resultString.getResult();
    String value = resultString.getValue();
    if (result == NResult.ok.code) {
      setState(() {
        _getPrinterNameValue = value;
      });
      _showToast('Success');
    } else {
      _processErrorResult(result);
    }
  }

  _setTemplate() async {
    setState(() {
      _enableSetTemplateButton = false;
    });

    Uint8List image = await File(_imagePath).readAsBytes();
    int result = await _printerController.setTemplate(image, true, true);
    if (result == NResult.ok.code) {
      _showToast('Success');
    } else {
      _processErrorResult(result);
    }

    setState(() {
      _enableSetTemplateButton = true;
    });
  }

  _clearTemplate() async {
    int result = await _printerController.clearTemplate();
    if (result == NResult.ok.code) {
      _showToast('Success');
    } else {
      _processErrorResult(result);
    }
  }

  _getBatteryLevel() async {
    int result = await _printerController.getBatteryLevel();
    if (result >= 0) {
      setState(() {
        _getBatteryLevelValue = result.toString();
      });
      _showToast('Success');
    } else {
      _processErrorResult(result);
    }
  }

  _getBatteryStatus() async {
    int result = await _printerController.getBatteryStatus();
    if (result >= 0) {
      setState(() {
        NBatteryStatus status = NBatteryStatus.getByCode(result);
        switch (status) {
          case NBatteryStatus.noCahrging:
            _getBatteryStatusValue = 'No charging';
            break;
          case NBatteryStatus.lowNoCahrging:
            _getBatteryStatusValue = 'Low & No charging';
            break;
          case NBatteryStatus.charging:
            _getBatteryStatusValue = 'Charging';
            break;
          case NBatteryStatus.lowCharging:
            _getBatteryStatusValue = 'Low & Charging';
            break;
          default:
            _getBatteryStatusValue = 'None';
            break;
        }
      });
      _showToast('Success');
    } else {
      _processErrorResult(result);
    }
  }

  @override
  void disconnected() {
    setState(() {
      _connectTextValue = 'Connect';
    });
  }

  @override
  void printProgress(int index, int total, int result) {}

  @override
  void printComplete(int result) {}

  String _getPrinterStatusContent(int status) {
    String result = '';
    if (status > 0) {
      NPrinterStatus printerStatus = NPrinterStatus.getByCode(status);
      switch (printerStatus) {
        case NPrinterStatus.outOfPaper:
          result = 'Out of paper';
          break;
        case NPrinterStatus.coverOpened:
          result = 'Cover opened';
          break;
        case NPrinterStatus.overheat:
          result = 'Overheat';
          break;
        case NPrinterStatus.paperJam:
          result = 'Paper jam';
          break;
        default:
          break;
      }
    }

    return result;
  }

  String _processErrorResult(int result) {
    NResult nResult = NResult.getByCode(result);
    String resultContent = nResult.toString();

    _showToast(resultContent);

    return resultContent;
  }

  void _showToast(String content) {
    Fluttertoast.showToast(msg: content, gravity: ToastGravity.BOTTOM);
  }
}
