import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/log.dart';
import 'hive_service.dart';

class SyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static bool get isSynced => 
      HiveService.settings.get('has_synced', defaultValue: false);

  /// Performs a one-time sync of legacy logs from Firestore to Hive
  static Future<void> syncLegacyLogs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (isSynced) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('logs')
          .orderBy('timestamp', descending: true)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final event = data['event'] as String?;
        final ts = data['timestamp'] as Timestamp?;

        if (event != null && ts != null) {
          final log = AppLog(
            event: '[Synced] $event',
            timestamp: ts.toDate(),
          );
          await HiveService.logs.add(log);
        }
      }

      // Mark sync as completed locally
      await HiveService.settings.put('has_synced', true);
      debugPrint('Sync completed for ${snapshot.docs.length} logs.');
      
    } catch (e) {
      debugPrint('Sync Error: $e');
      rethrow;
    }
  }
}
