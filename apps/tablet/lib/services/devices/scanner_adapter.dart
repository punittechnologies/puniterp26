abstract interface class ScannerAdapter {
  Future<void> connect(String deviceIdentifier);
  Future<void> disconnect();
  Stream<String> scans();
}
