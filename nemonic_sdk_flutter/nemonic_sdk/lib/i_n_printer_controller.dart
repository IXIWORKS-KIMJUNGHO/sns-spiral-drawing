abstract interface class INPrinterController {
  void disconnected();
  void printProgress(int index, int total, int result);
  void printComplete(int result);
}
