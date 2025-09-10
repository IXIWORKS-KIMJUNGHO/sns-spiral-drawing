enum NPrinterType {
  none(0),
  nemonic(1),
  nemonicLabel(2),
  nemonicMini(3),
  nemonicMip201(4);

  const NPrinterType(this.code);
  final int code;

  factory NPrinterType.getByCode(int code) {
    return NPrinterType.values.firstWhere((value) => value.code == code,
        orElse: () => NPrinterType.none);
  }

  factory NPrinterType.fromDynamic(dynamic code) {
    if (code is NPrinterType) {
      return code;
    } else if (code is int) {
      return NPrinterType.getByCode(code);
    }

    return NPrinterType.none;
  }
}
