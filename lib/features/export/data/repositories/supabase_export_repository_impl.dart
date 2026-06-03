import 'dart:io';

import 'package:beltech/features/export/data/services/csv_builder.dart';
import 'package:beltech/features/export/data/services/encrypted_export_service.dart';
import 'package:beltech/features/export/domain/entities/export_result.dart';
import 'package:beltech/features/export/domain/repositories/export_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseExportRepositoryImpl implements ExportRepository {
  SupabaseExportRepositoryImpl(
    this._client, {
    CsvBuilder csvBuilder = const CsvBuilder(),
  }) : _csvBuilder = csvBuilder;

  final SupabaseClient _client;
  final CsvBuilder _csvBuilder;

  @override
  Future<ExportResult> exportCsv({
    required ExportScope scope,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (kIsWeb) {
      throw Exception('CSV export is not supported on web builds.');
    }
    final userId = _requireUserId();
    final chunks = await _buildChunks(scope, userId,
        startDate: startDate, endDate: endDate);
    final sections = <String>[];
    var totalRows = 0;
    for (final chunk in chunks) {
      sections.add('## ${chunk.name}');
      sections.add(chunk.csv);
      totalRows += chunk.rows;
    }
    final content = sections.join('\n');
    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final dateTag = _dateTag(startDate: startDate, endDate: endDate);
    final file = File(
        '${dir.path}${Platform.pathSeparator}dart2_export${dateTag}_$stamp.csv');
    await file.writeAsString(content);
    return ExportResult(
        filePath: file.path, rowsExported: totalRows, scope: scope);
  }

  @override
  Future<ExportResult> exportEncryptedCsv({
    required ExportScope scope,
    required String password,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (kIsWeb) {
      throw Exception('Encrypted export is not supported on web builds.');
    }
    final userId = _requireUserId();
    final chunks = await _buildChunks(scope, userId,
        startDate: startDate, endDate: endDate);
    final sections = <String>[];
    var totalRows = 0;
    for (final chunk in chunks) {
      sections.add('## ${chunk.name}');
      sections.add(chunk.csv);
      totalRows += chunk.rows;
    }
    final content = sections.join('\n');
    const encryptedService = EncryptedExportService();
    final encrypted = encryptedService.encrypt(plainText: content, password: password);
    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final dateTag = _dateTag(startDate: startDate, endDate: endDate);
    final file = File(
        '${dir.path}${Platform.pathSeparator}dart2_export${dateTag}_$stamp.enc');
    await file.writeAsString(encrypted);
    return ExportResult(
      filePath: file.path,
      rowsExported: totalRows,
      scope: scope,
    );
  }

  @override
  Future<ExportResult> exportPdfStatement({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    throw Exception('PDF statement export is not supported in cloud mode.');
  }

  Future<List<_ExportChunk>> _buildChunks(
      ExportScope scope, String userId,
      {DateTime? startDate, DateTime? endDate}) async {
    final chunks = <_ExportChunk>[];
    if (scope == ExportScope.all || scope == ExportScope.expenses) {
      var query = _client
          .from('transactions')
          .select('id,title,category,amount,occurred_at,source')
          .eq('owner_id', userId);
      if (startDate != null) {
        query = query.gte('occurred_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('occurred_at', endDate.toIso8601String());
      }
      chunks.add(await _buildChunk(
        name: 'expenses',
        rows: await query.order('occurred_at', ascending: false),
        headers: const [
          'id',
          'title',
          'category',
          'amount',
          'occurred_at',
          'source'
        ],
      ));
    }
    if (scope == ExportScope.all || scope == ExportScope.incomes) {
      var query = _client
          .from('incomes')
          .select('id,title,amount,received_at,source')
          .eq('owner_id', userId);
      if (startDate != null) {
        query = query.gte('received_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('received_at', endDate.toIso8601String());
      }
      chunks.add(await _buildChunk(
        name: 'incomes',
        rows: await query.order('received_at', ascending: false),
        headers: const ['id', 'title', 'amount', 'received_at', 'source'],
      ));
    }
    if (scope == ExportScope.all || scope == ExportScope.tasks) {
      var query = _client
          .from('tasks')
          .select('id,title,description,completed,due_at,priority')
          .eq('owner_id', userId);
      if (startDate != null) {
        query = query.gte('due_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('due_at', endDate.toIso8601String());
      }
      chunks.add(await _buildChunk(
        name: 'tasks',
        rows: await query.order('id', ascending: false),
        headers: const [
          'id',
          'title',
          'description',
          'completed',
          'due_at',
          'priority'
        ],
      ));
    }
    if (scope == ExportScope.all || scope == ExportScope.events) {
      var query = _client
          .from('events')
          .select('id,title,start_at,end_at,note')
          .eq('owner_id', userId);
      if (startDate != null) {
        query = query.gte('start_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('start_at', endDate.toIso8601String());
      }
      chunks.add(await _buildChunk(
        name: 'events',
        rows: await query.order('start_at', ascending: false),
        headers: const ['id', 'title', 'start_at', 'end_at', 'note'],
      ));
    }
    if (scope == ExportScope.all || scope == ExportScope.budgets) {
      chunks.add(await _buildChunk(
        name: 'budgets',
        rows: await _client
            .from('budgets')
            .select('id,category,monthly_limit')
            .eq('owner_id', userId)
            .order('category'),
        headers: const ['id', 'category', 'monthly_limit'],
      ));
    }
    if (scope == ExportScope.all || scope == ExportScope.recurring) {
      chunks.add(await _buildChunk(
        name: 'recurring_templates',
        rows: await _client
            .from('recurring_templates')
            .select(
                'id,kind,title,description,category,amount,priority,cadence,next_run_at,enabled')
            .eq('owner_id', userId)
            .order('id', ascending: false),
        headers: const [
          'id',
          'kind',
          'title',
          'description',
          'category',
          'amount',
          'priority',
          'cadence',
          'next_run_at',
          'enabled'
        ],
      ));
    }
    return chunks;
  }

  String _dateTag({DateTime? startDate, DateTime? endDate}) {
    final parts = <String>[];
    if (startDate != null) {
      parts.add(
          '${startDate.year}${startDate.month.toString().padLeft(2, '0')}${startDate.day.toString().padLeft(2, '0')}');
    }
    if (endDate != null) {
      parts.add(
          '${endDate.year}${endDate.month.toString().padLeft(2, '0')}${endDate.day.toString().padLeft(2, '0')}');
    }
    if (parts.isEmpty) return '';
    return '_${parts.join('_to_')}';
  }

  Future<_ExportChunk> _buildChunk({
    required String name,
    required dynamic rows,
    required List<String> headers,
  }) async {
    final list = (rows as List).cast<Map<String, dynamic>>();
    final values = list
        .map((row) => headers.map((header) => row[header]).toList())
        .toList();
    return _ExportChunk(
      name: name,
      csv: _csvBuilder.build(headers: headers, rows: values),
      rows: list.length,
    );
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw Exception('Sign in is required.');
    }
    return userId;
  }
}

class _ExportChunk {
  const _ExportChunk({
    required this.name,
    required this.csv,
    required this.rows,
  });

  final String name;
  final String csv;
  final int rows;
}
