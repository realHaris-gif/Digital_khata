import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlatformServices {
  final SupabaseClient _client = Supabase.instance.client;
  final LocalAuthentication _localAuth = LocalAuthentication();

  String get _userId => _client.auth.currentUser?.id ?? '';

  // ---------------------------------------------------------
  // MODULE 3: BIOMETRIC LOGIN SERVICE
  // ---------------------------------------------------------
  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Digital Khata',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      debugPrint('Biometric Auth Error: $e');
      return false;
    }
  }

  // ---------------------------------------------------------
  // MODULE 10: AUDIT LOG SERVICE
  // ---------------------------------------------------------
  Future<void> logAuditAction({
    required String action,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? details,
  }) async {
    if (_userId.isEmpty) return;
    try {
      await _client.from('audit_logs').insert({
        'user_id': _userId,
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'details': details != null ? jsonEncode(details) : null,
      });
    } catch (e) {
      debugPrint('Audit Log Error: $e');
    }
  }

  // ---------------------------------------------------------
  // MODULE 4: FCM PUSH NOTIFICATION TOKEN STORAGE
  // ---------------------------------------------------------
  Future<void> syncFcmTokenToSupabase(String token) async {
    if (_userId.isEmpty) return;
    try {
      await _client.from('user_fcm_tokens').upsert(
        {
          'user_id': _userId,
          'fcm_token': token,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id, fcm_token',
      );
    } catch (e) {
      debugPrint('FCM Sync Error: $e');
    }
  }

  // ---------------------------------------------------------
  // MODULE 6: EXPORTS (PDF & EXCEL GENERATOR)
  // ---------------------------------------------------------
  Future<void> exportDataToPdf({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Digital Khata - $title',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                headers: headers,
                data: rows,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.grey300),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey200),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/export_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: 'Exported PDF Report: $title');
  }

  Future<void> exportDataToExcel({
    required String sheetName,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    final excel = Excel.createExcel();
    final Sheet sheetObject = excel[sheetName];

    sheetObject.appendRow(headers.map((e) => TextCellValue(e)).toList());

    for (var row in rows) {
      sheetObject.appendRow(
        row.map((e) => TextCellValue(e.toString())).toList(),
      );
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${sheetName}_Export.xlsx');
      await file.writeAsBytes(fileBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Excel Report: $sheetName');
    }
  }
}