import '../constants/n_cartridge_type.dart';
import '../constants/n_printer_type.dart';

class NPrinter {
  String _name = '';
  String _macAddress = '';
  NPrinterType _type = NPrinterType.none;

  bool isEmpty() {
    return _name.isEmpty || _macAddress.isEmpty;
  }

  void reset() {
    _name = '';
    _macAddress = '';
    _type = NPrinterType.none;
  }

  String getName() {
    return _name;
  }

  void setName(String name) {
    _name = name;
  }

  static bool checkName(NPrinterType type, String name) {
    name = name.trim();
    RegExp regex;
    switch (type) {
      case NPrinterType.nemonicMip201:
        regex = RegExp('^[A-Za-z0-9]{4,13}_([WYBRPG]|[L][1-4])\$');
        break;
      case NPrinterType.nemonic:
      case NPrinterType.nemonicLabel:
      case NPrinterType.nemonicMini:
      default:
        regex = RegExp('[A-Za-z0-9]{4,12}_([WYBRPG]|[Lm][1-4])\$');
    }

    return regex.hasMatch(name);
  }

  String getMacAddress() {
    return _macAddress;
  }

  void setMacAddress(String macAddress) {
    _macAddress = macAddress;
  }

  NPrinterType getType() {
    if (_name.isEmpty) {
      return NPrinterType.none;
    }

    if (_type != NPrinterType.none) {
      return _type;
    } else {
      if (isMini()) {
        return NPrinterType.nemonicMini;
      } else if (isLabel()) {
        return NPrinterType.nemonicLabel;
      } else {
        return NPrinterType.nemonic;
      }
    }
  }

  void setType(NPrinterType type) {
    if (type != NPrinterType.nemonicMip201) {
      _type = NPrinterType.none;
    } else {
      _type = type;
    }
  }

  bool isLabel() {
    String typeName = _getCartridgeTypeName();
    return typeName == 'L1' ||
        typeName == 'L2' ||
        typeName == 'L3' ||
        typeName == 'L4';
  }

  bool isMini() {
    String typeName = _getCartridgeTypeName();
    return typeName == 'm1' ||
        typeName == 'm2' ||
        typeName == 'm3' ||
        typeName == 'm4';
  }

  String _getCartridgeTypeName() {
    String result = '';

    List<String> values = _name.split('_');
    if (values.length >= 2) {
      result = values[values.length - 1];
    }

    return result;
  }

  String getNameWithoutCartridgeTypeName() {
    String result = '';

    List<String> values = _name.split('_');
    if (values.length >= 2) {
      for (int i = 0; i < values.length - 1; i++) {
        if (i == 0) {
          result = values[i];
        } else {
          result += '_${values[i]}';
        }
      }
    }

    return result;
  }

  bool isSupportedBattery() {
    switch (_type) {
      case NPrinterType.nemonicMini:
      case NPrinterType.nemonicMip201:
        return true;
      default:
        return false;
    }
  }

  bool isSupportedPassword() {
    switch (_type) {
      case NPrinterType.nemonic:
      case NPrinterType.nemonicLabel:
      case NPrinterType.nemonicMini:
        return true;
      default:
        return false;
    }
  }

  bool setCartridgeType(NCartridgeType type) {
    String nameWithoutType = getNameWithoutCartridgeTypeName();
    if (nameWithoutType.isEmpty) {
      return false;
    }

    String typeName = NCartridgeType.stringNameOf(type, isMini());
    String name = '${nameWithoutType}_$typeName';
    setName(name);
    return true;
  }

  NCartridgeType getCartridgeType() {
    return NCartridgeType.fromPrinterName(_name);
  }

  @override
  bool operator ==(Object other) {
    if (other is! NPrinter) return false;

    return other.getMacAddress() == _macAddress;
  }
}
