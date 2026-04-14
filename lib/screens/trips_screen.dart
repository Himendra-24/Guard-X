import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/trip.dart';
import '../models/log.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';
import '../services/sos_service.dart';
import '../services/trip_monitor_service.dart';
import '../services/alert_service.dart';
import '../utils/helpers.dart';
import '../widgets/trip_timer_widget.dart';
import 'sos_alert_screen.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  Trip? _activeTrip;
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _durCtrl = TextEditingController();
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadActiveTrip();
  }

  void _loadActiveTrip() {
    final active = HiveService.trips.values
        .where((t) => t.isActive && !t.completed)
        .toList();
    if (active.isNotEmpty) {
      setState(() => _activeTrip = active.first);
    }
  }

  void _showAddTripSheet() {
    _fromCtrl.clear();
    _toCtrl.clear();
    _durCtrl.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C2026),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'New Trip',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'We\'ll monitor your journey and alert your secondary guardian if you don\'t respond.',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
              const SizedBox(height: 20),
              _tripField(_fromCtrl, 'From', Icons.my_location_rounded),
              const SizedBox(height: 12),
              _tripField(_toCtrl, 'Destination', Icons.location_on_rounded),
              const SizedBox(height: 12),
              _tripField(
                _durCtrl,
                'Duration (minutes)',
                Icons.timer_rounded,
                type: TextInputType.number,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5352),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    disabledBackgroundColor: Colors.grey[800],
                  ),
                  icon: _isLoadingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    _isLoadingLocation ? 'Getting Location...' : 'Start Trip',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onPressed: _isLoadingLocation ? null : () => _startTrip(ctx, setSheetState),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startTrip(BuildContext sheetCtx, StateSetter setSheetState) async {
    if (_fromCtrl.text.trim().isEmpty ||
        _toCtrl.text.trim().isEmpty ||
        _durCtrl.text.trim().isEmpty) return;

    setSheetState(() => _isLoadingLocation = true);

    // 1. Get Location
    Position? pos = await LocationService.getCurrentLocation();
    
    // 2. Share via SMS to Primary Contact
    final contacts = HiveService.contacts.values.toList();
    final primary = SOSService.getPrimaryContact(contacts);

    if (primary != null) {
      await LocationService.shareLocationViaSMS(
        primary,
        destination: _toCtrl.text.trim(),
        lat: pos?.latitude,
        lng: pos?.longitude,
      );
    }

    final trip = Trip(
      from: _fromCtrl.text.trim(),
      to: _toCtrl.text.trim(),
      duration: int.tryParse(_durCtrl.text.trim()) ?? 30,
      isActive: true,
      startTime: DateTime.now(),
    );

    await HiveService.trips.add(trip);
    await HiveService.addLog('Trip started: ${trip.from} → ${trip.to}');

    await NotificationService.show(
      '🗺️ Trip Started',
      'Heading to ${trip.to}. Stay safe!',
    );

    if (sheetCtx.mounted) Navigator.pop(sheetCtx);
    if (mounted) setState(() {
      _activeTrip = trip;
      _isLoadingLocation = false;
    });
  }

  Future<void> _markSafe() async {
    if (_activeTrip == null) return;
    
    // Cancel any active safety checks/alarms
    await TripMonitorService.cancel();

    _activeTrip!
      ..isActive = false
      ..completed = true;
    await _activeTrip!.save();

    await HiveService.addLog('Trip completed safely: ${_activeTrip!.to}');

    await NotificationService.show(
      '✅ Safe Arrival!',
      'You reached ${_activeTrip!.to} safely.',
    );

    if (mounted) {
      setState(() => _activeTrip = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip completed safely! 🎉'),
          backgroundColor: Color(0xFF60DAC4),
        ),
      );
    }
  }

  Future<void> _onTimeout() async {
    if (!mounted) return;

    await HiveService.addLog('Trip timeout — triggered safety engine');

    // Trigger 3-Stage Safety Automation
    TripMonitorService.startSafetyCheck(
      onStage1: () => _showSafetyDialog(),
      onStage2: () {
        // UI updates for stage 2 if needed (already alarm starts)
        setState(() {});
      },
      onStage3: () {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SOSAlertScreen()),
          );
        }
      },
    );
  }

  void _showSafetyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C2026),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5352)),
            SizedBox(width: 8),
            Text('Safety Check', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Your trip timer has expired. Are you safe?\n\nIf you don\'t respond within 30 seconds, an alarm will trigger.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF60DAC4),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await TripMonitorService.cancel();
              if (ctx.mounted) Navigator.pop(ctx);
              _markSafe();
            },
            child: const Text('I AM SAFE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _tripField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFFF5352), size: 20),
      ),
    );
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _durCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10141A),
      appBar: buildAppBar('Safety Trips'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_activeTrip != null) ...[
              const Text(
                'Current Journey',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _activeTripCard(),
              const SizedBox(height: 32),
            ],
            const Text(
              'Journey Logs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            ValueListenableBuilder(
              valueListenable: HiveService.trips.listenable(),
              builder: (ctx, Box<Trip> box, _) {
                final past = box.values
                    .where((t) => !t.isActive || t.completed)
                    .toList()
                    .reversed
                    .toList();

                if (past.isEmpty && _activeTrip == null) {
                  return buildEmptyState(
                    Icons.route_rounded,
                    'No journeys yet.\nStart a trip to begin monitoring.',
                  );
                } else if (past.isEmpty) {
                  return const SizedBox();
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: past.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _historyCard(past[i]),
                );
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: _activeTrip == null
          ? FloatingActionButton.extended(
              heroTag: 'trips_fab',
              backgroundColor: const Color(0xFFFF5352),
              onPressed: _showAddTripSheet,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Start New Journey',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _activeTripCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: TripMonitorService.currentStage >= 2 
            ? [const Color(0xFFFF5352), const Color(0xFF68000B)]
            : [const Color(0xFF1C2026), const Color(0xFF10141A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: TripMonitorService.currentStage >= 2 
            ? Colors.redAccent.withOpacity(0.5) 
            : Colors.white.withOpacity(0.08)
        ),
        boxShadow: [
          BoxShadow(
            color: (TripMonitorService.currentStage >= 2 ? Colors.red : Colors.black).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                TripMonitorService.currentStage >= 2 ? Icons.warning_rounded : Icons.navigation_rounded,
                color: TripMonitorService.currentStage >= 2 ? Colors.white : const Color(0xFFFF5352), 
                size: 20
              ),
              const SizedBox(width: 8),
              Text(
                TripMonitorService.currentStage >= 2 ? 'EMERGENCY ALERT' : 'LIVE MONITORING',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              _stageIndicator(),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _activeTrip!.from,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const Icon(Icons.arrow_downward_rounded, color: Colors.white38, size: 16),
          Text(
            _activeTrip!.to,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          TripTimerWidget(
            startTime: _activeTrip!.startTime ?? DateTime.now(),
            durationMinutes: _activeTrip!.duration,
            onTimeout: _onTimeout,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: TripMonitorService.currentStage >= 2 ? Colors.white : const Color(0xFF60DAC4),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text(
                'I HAVE ARRIVED SAFELY',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1),
              ),
              onPressed: _markSafe,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stageIndicator() {
    if (!TripMonitorService.isActive) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'STAGE ${TripMonitorService.currentStage}',
        style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _historyCard(Trip t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2026),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (t.completed ? const Color(0xFF60DAC4) : Colors.orange).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              t.completed ? Icons.check_circle_rounded : Icons.history_rounded,
              color: t.completed ? const Color(0xFF60DAC4) : Colors.white38,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'To: ${t.to}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  formatDateTime(t.startTime ?? DateTime.now()),
                  style: const TextStyle(fontSize: 11, color: Colors.white38),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 20),
            onPressed: () => t.delete(),
          ),
        ],
      ),
    );
  }
}