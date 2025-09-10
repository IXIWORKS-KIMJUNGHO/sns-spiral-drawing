enum NConnectState {
  disconnected(0),
  connecting(1),
  connected(2),
  disconnecting(3);

  const NConnectState(this.code);
  final int code;

  factory NConnectState.getByCode(int code) {
    return NConnectState.values.firstWhere((value) => value.code == code,
        orElse: () => NConnectState.disconnected);
  }

  factory NConnectState.fromDynamic(dynamic code) {
    if (code is NConnectState) {
      return code;
    } else if (code is int) {
      return NConnectState.getByCode(code);
    }

    return NConnectState.disconnected;
  }
}
