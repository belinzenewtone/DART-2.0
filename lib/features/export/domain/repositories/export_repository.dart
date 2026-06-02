import 'package:beltech/features/export/domain/entities/export_result.dart';

abstract class ExportRepository {
  Future<ExportResult> exportCsv({
    required ExportScope scope,
  });

  Future<ExportResult> exportEncryptedCsv({
    required ExportScope scope,
    required String password,
  });
}
