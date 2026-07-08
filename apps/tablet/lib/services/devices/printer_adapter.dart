class PrintJob {
  const PrintJob({
    required this.jobId,
    required this.template,
    required this.data,
  });

  final String jobId;
  final Map<String, dynamic> template;
  final Map<String, dynamic> data;
}

class PrintResult {
  const PrintResult({required this.jobId, required this.status, this.message});

  final String jobId;
  final String status;
  final String? message;
}

class PrinterDevice {
  const PrinterDevice({required this.id, required this.name, this.address});

  final String id;
  final String name;
  final String? address;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'address': address};

  factory PrinterDevice.fromJson(Map<String, dynamic> json) => PrinterDevice(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? 'Printer',
    address: json['address']?.toString(),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PrinterDevice && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

enum PrinterConnectionStatus {
  disconnected,
  listing,
  connecting,
  connected,
  printing,
  error,
}

abstract interface class PrinterAdapter {
  Future<List<PrinterDevice>> discover();
  Future<void> connect(String deviceIdentifier);
  Future<void> disconnect();
  Future<bool> isConnected();
  Future<PrintResult> print(PrintJob job);
}
