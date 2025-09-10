enum NPrinterStatus {
  none(-1),
  ok(0),
  outOfPaper(2),
  coverOpened(4),
  overheat(8),
  paperJam(16);

  const NPrinterStatus(this.code);
  final int code;

  factory NPrinterStatus.getByCode(int code) {
    return NPrinterStatus.values.firstWhere((value) => value.code == code,
        orElse: () => NPrinterStatus.none);
  }

  factory NPrinterStatus.fromDynamic(dynamic code) {
    if (code is NPrinterStatus) {
      return code;
    } else if (code is int) {
      return NPrinterStatus.getByCode(code);
    }

    return NPrinterStatus.none;
  }
}
