import 'dart:math';
import 'dart:typed_data';

import 'constants/n_print_quality.dart';
import 'n_printer.dart';

class NPrintInfo {
  NPrinter _printer = NPrinter();

  NPrintQuality _quality = NPrintQuality.lowFast;

  List<Uint8List> _images = [];
  int _copies = 1;
  bool _isLastPageCut = true;
  bool _enableDither = true;

  bool _isCheckPrinterStatus = true;
  bool _isCheckCartridgeType = true;
  bool _isCheckPower = true;

  NPrintInfo(NPrinter printer) {
    _printer = printer;
  }

  bool isEmpty() {
    return _images.isEmpty;
  }

  NPrintInfo setPrinter(NPrinter printer) {
    _printer = printer;

    return this;
  }

  NPrinter getPrinter() {
    return _printer;
  }

  NPrintInfo setPrintQuality(NPrintQuality quality) {
    _quality = quality;

    return this;
  }

  NPrintQuality getPrintQuality() {
    return _quality;
  }

  NPrintInfo setImage(Uint8List image) {
    if (_images.isNotEmpty) {
      _images.clear();
    }
    _images.add(image);

    return this;
  }

  Uint8List? getImage() {
    if (_images.isEmpty) {
      return null;
    } else {
      return _images[0];
    }
  }

  NPrintInfo setImages(List<Uint8List> images) {
    if (_images.isNotEmpty) {
      _images.clear();
    }
    _images = images;

    return this;
  }

  List<Uint8List> getImages() {
    return _images;
  }

  NPrintInfo setCopies(int copies) {
    copies = max(copies, 1);
    copies = min(copies, 255);
    _copies = copies;

    return this;
  }

  int getCopies() {
    return _copies;
  }

  NPrintInfo setEnableLastPageCut(bool enable) {
    _isLastPageCut = enable;

    return this;
  }

  bool isLastPageCutEnable() {
    return _isLastPageCut;
  }

  NPrintInfo setEnableDither(bool enable) {
    _enableDither = enable;

    return this;
  }

  bool isEnableDither() {
    return _enableDither;
  }

  NPrintInfo setEnableCheckPrinterStatus(bool enable) {
    _isCheckPrinterStatus = enable;

    return this;
  }

  bool isCheckPrinterStatus() {
    return _isCheckPrinterStatus;
  }

  NPrintInfo setEnableCheckCartridgeType(bool enable) {
    _isCheckCartridgeType = enable;

    return this;
  }

  bool isCheckCartridgeType() {
    return _isCheckCartridgeType;
  }

  NPrintInfo setEnableCheckPower(bool enable) {
    _isCheckPower = enable;

    return this;
  }

  bool isCheckPower() {
    return _isCheckPower;
  }
}
