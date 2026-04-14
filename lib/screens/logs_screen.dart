import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/log.dart';
import '../services/hive_service.dart';
import '../utils/helpers.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  Map<String, dynamic> _getLogStyle(String event) {
    final e = event.toLowerCase();
    if (e.contains('sos')) {
      return {
        'icon': Icons.emergency_rounded,
        'color': const Color(0xFFFF5352),
        'label': 'SOS Alert',
      };
    }
    if (e.contains('completed') || e.contains('safely') || e.contains('safe')) {
      return {
        'icon': Icons.verified_rounded,
        'color': const Color(0xFF60DAC4),
        'label': 'Safe Check-in',
      };
    }
    if (e.contains('trip started') || e.contains('started')) {
      return {
        'icon': Icons.route_rounded,
        'color': const Color(0xFFA0CAFF),
        'label': 'Trip Started',
      };
    }
    if (e.contains('dismissed')) {
      return {
        'icon': Icons.check_circle_outline,
        'color': Colors.orange,
        'label': 'SOS Dismissed',
      };
    }
    return {
      'icon': Icons.info_outline_rounded,
      'color': Colors.grey,
      'label': 'Event',
    };
  }

  void _clearLogs(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C2026),
        title: const Text('Clear All Logs'),
        content: const Text(
          'This will permanently delete all activity logs.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await HiveService.logs.clear();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10141A),
      appBar: buildAppBar(
        'Activity Logs',
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded,
                color: Colors.redAccent),
            onPressed: () => _clearLogs(context),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: HiveService.logs.listenable(),
        builder: (ctx, Box<AppLog> box, _) {
          final logs = box.values.toList().reversed.toList();

          if (logs.isEmpty) {
            return buildEmptyState(
                Icons.history_rounded,
                'No activity yet.\nYour journey events will appear here.');
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              // Summary strip
              _summaryRow(logs),
              const SizedBox(height: 24),

              const Text('Timeline',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white38,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5)),
              const SizedBox(height: 14),

              // Timeline items
              ...List.generate(logs.length, (i) {
                final log = logs[i];
                final style = _getLogStyle(log.event);
                final isLast = i == logs.length - 1;
                return _timelineItem(log, style, isLast);
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryRow(List<AppLog> logs) {
    final sos = logs.where((l) => l.event.toLowerCase().contains('sos')).length;
    final trips =
        logs.where((l) => l.event.toLowerCase().contains('trip')).length;
    final safe =
        logs.where((l) => l.event.toLowerCase().contains('safely')).length;

    return Row(
      children: [
        _statChip('$sos', 'SOS', const Color(0xFFFF5352)),
        const SizedBox(width: 10),
        _statChip('$trips', 'Trips', const Color(0xFFA0CAFF)),
        const SizedBox(width: 10),
        _statChip('$safe', 'Safe', const Color(0xFF60DAC4)),
      ],
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 22)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _timelineItem(AppLog log, Map<String, dynamic> style, bool isLast) {
    final color = style['color'] as Color;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left side: icon + connector line
          SizedBox(
            width: 52,
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Icon(style['icon'] as IconData,
                      color: color, size: 20),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Right side: content card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2026),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(style['label'] as String,
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF262A31),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _formatLogTime(log.timestamp),
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(log.event,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.4)),
                    const SizedBox(height: 4),
                    Text(formatDateTime(log.timestamp),
                        style: const TextStyle(
                            color: Colors.white30, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLogTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}