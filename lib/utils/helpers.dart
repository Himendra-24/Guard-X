import 'package:flutter/material.dart';

/// Shared AppBar used across all screens
PreferredSizeWidget buildAppBar(String title, {List<Widget>? actions}) {
  return AppBar(
    backgroundColor: const Color(0xFF10141A),
    elevation: 0,
    title: Text(
      title,
      style: const TextStyle(
        color: Color(0xFFFFB3AE),
        fontWeight: FontWeight.w800,
        fontSize: 18,
        letterSpacing: 1.2,
      ),
    ),
    leading: Builder(
      builder: (ctx) => IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Color(0xFFFFB3AE)),
        onPressed: () => Navigator.maybePop(ctx),
      ),
    ),
    actions: actions,
  );
}

/// Shared empty state widget
Widget buildEmptyState(IconData icon, String message) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 72, color: Colors.white12),
        const SizedBox(height: 16),
        Text(
          message,
          style: const TextStyle(
            color: Colors.white30,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

/// Format DateTime to readable string
String formatTime(DateTime t) {
  final now = DateTime.now();
  final diff = now.difference(t);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${t.day}/${t.month}/${t.year}';
}

/// Format full DateTime
String formatDateTime(DateTime t) {
  final hour = t.hour.toString().padLeft(2, '0');
  final min = t.minute.toString().padLeft(2, '0');
  return '${t.day}/${t.month}/${t.year}  $hour:$min';
}