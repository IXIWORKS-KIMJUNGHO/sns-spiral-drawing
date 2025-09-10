enum NCartridgeType {
  none(-1),
  white(0),
  yellow(1),
  green(2),
  blue(3),
  pink(7),
  l1(13),
  l2(12),
  l3(10),
  l4(6),
  m1(101),
  m2(102),
  m3(103),
  m4(104);

  const NCartridgeType(this.code);
  final int code;

  factory NCartridgeType.getByCode(int code) {
    return NCartridgeType.values.firstWhere((value) => value.code == code,
        orElse: () => NCartridgeType.none);
  }

  factory NCartridgeType.fromDynamic(dynamic code) {
    if (code is NCartridgeType) {
      return code;
    } else if (code is int) {
      return NCartridgeType.getByCode(code);
    }

    return NCartridgeType.none;
  }

  factory NCartridgeType.fromPrinterName(String name) {
    String typeName = '';

    List<String> values = name.split('_');
    if (values.length >= 2) {
      typeName = values[values.length - 1];
    }

    switch (typeName) {
      case 'W':
      case 'w':
        return NCartridgeType.white;
      case 'Y':
      case 'y':
        return NCartridgeType.yellow;
      case 'G':
      case 'g':
        return NCartridgeType.green;
      case 'B':
      case 'b':
        return NCartridgeType.blue;
      case 'P':
      case 'p':
        return NCartridgeType.pink;
      case 'L1':
      case 'l1':
        return NCartridgeType.l1;
      case 'L2':
      case 'l2':
        return NCartridgeType.l2;
      case 'L3':
      case 'l3':
        return NCartridgeType.l3;
      case 'L4':
      case 'l4':
        return NCartridgeType.l4;
      case 'M1':
      case 'm1':
        return NCartridgeType.m1;
      case 'M2':
      case 'm2':
        return NCartridgeType.m2;
      case 'M3':
      case 'm3':
        return NCartridgeType.m3;
      case 'M4':
      case 'm4':
        return NCartridgeType.m4;
      default:
        return NCartridgeType.none;
    }
  }

  static String stringNameOf(NCartridgeType type, bool isMini) {
    switch (type) {
      case NCartridgeType.white:
        return 'W';
      case NCartridgeType.yellow:
        return 'Y';
      case NCartridgeType.green:
        return 'G';
      case NCartridgeType.blue:
        return 'B';
      case NCartridgeType.pink:
        return 'P';
      case NCartridgeType.l1:
        if (isMini) {
          return 'm1';
        }
        return 'L1';
      case NCartridgeType.l2:
        if (isMini) {
          return 'm2';
        }
        return 'L2';
      case NCartridgeType.l3:
        if (isMini) {
          return 'm3';
        }
        return 'L3';
      case NCartridgeType.l4:
        if (isMini) {
          return 'm4';
        }
        return 'L4';
      case NCartridgeType.m1:
        return 'm1';
      case NCartridgeType.m2:
        return 'm2';
      case NCartridgeType.m3:
        return 'm3';
      case NCartridgeType.m4:
        return 'm4';
      default:
        return '';
    }
  }
}
