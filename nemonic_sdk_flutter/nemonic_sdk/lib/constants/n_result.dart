enum NResult {
  ok(0),
  timeout(-64),
  canceled(-65),
  batteryLow(-70),
  batteryNeedCharge(-71),
  batteryLowOrNoCharge(-72),
  paperNotMatched(-80),
  needUpdateFirmware(-90),
  bluetoothUnsupported(-100),
  bluetoothDisabled(-101),
  bluetoothNoPermission(-102),
  bluetoothResetting(-103),
  canceledOrBluetoothDisabled(-104),
  bluetoothUnknown(-105),
  locationNoPermission(-110),
  locationDisabled(-111),
  scanFailed(-200),
  noSelectedPrinter(-300),
  notConnected(-301),
  alreadyConnected(-302),
  notFound(-303),
  notConnectable(-304),
  socketError(-305),
  connectError(-306),
  connectFailed(-307),
  sessionError(-308),
  connectServiceNotFound(-309),
  connectUnsupportedMode(-310),
  ioReceiveError(-400),
  ioSendError(-401),
  sendFailed(-402),
  unknown(-500),
  invalidParameter(-501),
  notMatchedPrinterType(-502),
  noCallback(-503),
  notMatchedCommandResultFormat(-504),
  invalidPrinterName(-505),
  invalidPrinterResult(-506),
  printerResultFailed(-507),
  unsupportedDevice(-508);

  const NResult(this.code);
  final int code;

  factory NResult.getByCode(int code) {
    return NResult.values.firstWhere((value) => value.code == code,
        orElse: () => NResult.unknown);
  }

  factory NResult.fromDynamic(dynamic code) {
    if (code is NResult) {
      return code;
    } else if (code is int) {
      return NResult.getByCode(code);
    }

    return NResult.unknown;
  }
}
