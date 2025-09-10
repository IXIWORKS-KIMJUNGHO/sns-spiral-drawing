enum NPrintQuality {
  lowFast(0),
  middle(1),
  highSlow(2);

  const NPrintQuality(this.code);
  final int code;

  factory NPrintQuality.getByCode(int code) {
    return NPrintQuality.values.firstWhere((value) => value.code == code,
        orElse: () => NPrintQuality.lowFast);
  }

  factory NPrintQuality.fromDynamic(dynamic code) {
    if (code is NPrintQuality) {
      return code;
    } else if (code is int) {
      return NPrintQuality.getByCode(code);
    }

    return NPrintQuality.lowFast;
  }
}
