import 'package:dart_2_0/features/export/domain/entities/export_result.dart';

abstract class ExportRepository {
  Future<ExportResult> exportCsv({
    required ExportScope scope,
  });
}
