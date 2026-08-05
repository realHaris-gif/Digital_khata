import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'google_auth_client.dart';

class GoogleDriveBackupService {
  final _supabase = Supabase.instance.client;

  // Pass clientId specifically for web platforms to resolve the Assertion error
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '680279637522-ugr6l0tk1f2bi1c970vf1kum7dk6aj64.apps.googleusercontent.com' : null,
    scopes: [
      drive.DriveApi.driveFileScope,
    ],
  );

  Future<void> backupToGoogleDrive() async {
    try {
      // 1. Try signing in silently first (ideal for web and returning users)
      GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      
      // If silent sign-in fails, prompt the interactive sign-in
      googleUser ??= await _googleSignIn.signIn();
      
      if (googleUser == null) return; // User canceled login

      final authHeaders = await googleUser.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      // 2. Fetch user's data from Supabase
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final accounts = await _supabase.from('accounts').select().eq('user_id', userId);
      final suppliers = await _supabase.from('suppliers').select().eq('user_id', userId);
      final invoices = await _supabase.from('invoices').select().eq('user_id', userId);

      // 3. Construct local JSON backup file
      final backupData = {
        'exported_at': DateTime.now().toIso8601String(),
        'accounts': accounts,
        'suppliers': suppliers,
        'invoices': invoices,
      };

      // Handle path provider safely across Web and Mobile platforms
      if (kIsWeb) {
        final bytes = utf8.encode(jsonEncode(backupData));
        
        final driveFile = drive.File()
          ..name = 'Digital_Khata_Backup_${DateTime.now().toIso8601String().substring(0, 10)}.json'
          ..description = 'Automated cloud backup from Digital Khata';

        await driveApi.files.create(
          driveFile,
          uploadMedia: drive.Media(
            Stream.value(bytes),
            bytes.length,
          ),
        );
        return;
      }

      // Mobile file path logic
      final directory = await getTemporaryDirectory();
      final localFile = File('${directory.path}/digital_khata_backup.json');
      await localFile.writeAsString(jsonEncode(backupData));

      final driveFile = drive.File()
        ..name = 'Digital_Khata_Backup_${DateTime.now().toIso8601String().substring(0, 10)}.json'
        ..description = 'Automated cloud backup from Digital Khata';

      await driveApi.files.create(
        driveFile,
        uploadMedia: drive.Media(localFile.openRead(), localFile.lengthSync()),
      );
    } catch (e) {
      throw Exception('Google Drive backup failed: $e');
    }
  }
}