import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/database/local_database.dart';
import '../../dispatch/data/dispatch_repository.dart';
import '../../inventory/data/inventory_repository.dart';
import '../../weighing/data/production_repository.dart';

class ReportRepository {
  const ReportRepository({required this.database, this.apiClient});

  final LocalDatabase database;
  final ApiClient? apiClient;

  ProductionRepository get production =>
      ProductionRepository(database: database, apiClient: apiClient);

  InventoryRepository get inventory => InventoryRepository(database);

  DispatchRepository get dispatch => DispatchRepository(database);

  Future<File?> downloadReport(String report, String format) async {
    final client = apiClient;
    if (client == null) return null;
    final response = await client.downloadBytes(
      '/reports/$report',
      query: {'format': format},
    );
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      p.join(
        directory.path,
        '${report}_report_${DateTime.now().millisecondsSinceEpoch}.$format',
      ),
    );
    await file.writeAsBytes(response.data ?? const []);

    return file;
  }
}
