class NResultString {
  int _result = 0;
  String _value = '';

  NResultString(int result, String value) {
    _result = result;
    _value = value;
  }

  int getResult() {
    return _result;
  }

  void setResult(int result) {
    _result = result;
  }

  String getValue() {
    return _value;
  }

  void setValue(String value) {
    _value = value;
  }
}
