enum NBatteryStatus {
  none(-1),
  noCahrging(0),
  lowNoCahrging(1),
  charging(2),
  lowCharging(3);

  const NBatteryStatus(this.code);
  final int code;

  factory NBatteryStatus.getByCode(int code) {
    return NBatteryStatus.values.firstWhere((value) => value.code == code,
        orElse: () => NBatteryStatus.none);
  }

  factory NBatteryStatus.fromDynamic(dynamic code) {
    if (code is NBatteryStatus) {
      return code;
    } else if (code is int) {
      return NBatteryStatus.getByCode(code);
    }

    return NBatteryStatus.none;
  }
}
