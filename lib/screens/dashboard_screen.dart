import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../models/log.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../widgets/dashboard_card.dart';
import 'contacts_screen.dart';
import 'trips_screen.dart';
import 'notes_screen.dart';
import 'logs_screen.dart';
import 'sos_alert_screen.dart';
import 'fake_call_screen.dart';
import 'emergency_toolkit_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Long-press SOS progress
  bool _isSOSHolding = false;
  double _sosProgress = 0.0;
  Timer? _sosTimer;
  static const _sosHoldDuration = Duration(milliseconds: 1500);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.07).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _sosTimer?.cancel();
    super.dispose();
  }

  void _onSOSHoldStart() {
    setState(() {
      _isSOSHolding = true;
      _sosProgress = 0.0;
    });

    const tickInterval = Duration(milliseconds: 50);
    final totalTicks = _sosHoldDuration.inMilliseconds ~/ tickInterval.inMilliseconds;
    int currentTick = 0;

    _sosTimer = Timer.periodic(tickInterval, (timer) {
      currentTick++;
      if (mounted) {
        setState(() => _sosProgress = currentTick / totalTicks);
      }

      if (currentTick >= totalTicks) {
        timer.cancel();
        _triggerSOS();
      }
    });
  }

  void _onSOSHoldEnd() {
    _sosTimer?.cancel();
    if (mounted) {
      setState(() {
        _isSOSHolding = false;
        _sosProgress = 0.0;
      });
    }
  }

  Future<void> _triggerSOS() async {
    _sosTimer?.cancel();
    if (mounted) {
      setState(() {
        _isSOSHolding = false;
        _sosProgress = 0.0;
      });
    }

    HapticFeedback.heavyImpact();
    await HiveService.logs.add(
        AppLog(event: 'SOS triggered from dashboard', timestamp: DateTime.now()));
    await NotificationService.show(
        '🚨 SOS Activated', 'Emergency alert! Take immediate action.');
    if (mounted) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SOSAlertScreen()));
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }


  void _navigate(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) setState(() {}); // Rebuild to pick up name/data changes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10141A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_greeting()} 👋',
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 14)),
                      const SizedBox(height: 4),
                      ValueListenableBuilder<String>(
                        valueListenable: HiveService.userNameNotifier,
                        builder: (context, name, _) {
                          final displayName = name.isNotEmpty 
                              ? name.split(' ').first 
                              : 'Guardian';
                          return Text(displayName,
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white));
                        },
                      ),
                    ],
                  ),
                  _statusPill(),
                ],
              ),

              const SizedBox(height: 44),

              // ── SOS Button (Long Press with Progress) ──
              Center(
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, child) =>
                      Transform.scale(scale: _pulseAnim.value, child: child),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _ring(220, 0.12),
                      _ring(188, 0.20),
                      GestureDetector(
                        onLongPressStart: (_) => _onSOSHoldStart(),
                        onLongPressEnd: (_) => _onSOSHoldEnd(),
                        onLongPressCancel: () => _onSOSHoldEnd(),
                        child: SizedBox(
                          width: 156,
                          height: 156,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Progress ring
                              if (_isSOSHolding)
                                SizedBox(
                                  width: 156,
                                  height: 156,
                                  child: CircularProgressIndicator(
                                    value: _sosProgress,
                                    strokeWidth: 4,
                                    color: Colors.white,
                                    backgroundColor: Colors.white24,
                                  ),
                                ),
                              Container(
                                width: 146,
                                height: 146,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isSOSHolding
                                      ? const Color(0xFFFF2020)
                                      : const Color(0xFFFF5352),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF5352)
                                          .withOpacity(_isSOSHolding ? 0.7 : 0.4),
                                      blurRadius: _isSOSHolding ? 64 : 48,
                                      spreadRadius: _isSOSHolding ? 12 : 8,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isSOSHolding
                                          ? Icons.warning_rounded
                                          : Icons.emergency_share,
                                      color: Colors.white,
                                      size: 42,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _isSOSHolding ? 'HOLD' : 'SOS',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 3),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _isSOSHolding
                      ? 'Keep holding to activate...'
                      : 'Long press to activate SOS',
                  style: TextStyle(
                    color: _isSOSHolding ? Colors.orangeAccent : Colors.grey,
                    fontSize: 13,
                    fontWeight:
                        _isSOSHolding ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // ── Quick Access Grid ───────────────────
              const Text('Quick Access',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.15,
                children: [
                  DashboardCard(
                    title: 'Contacts',
                    subtitle: 'Emergency guardians',
                    icon: Icons.group_rounded,
                    onTap: () => _navigate(const ContactsScreen()),
                  ),
                  DashboardCard(
                    title: 'Trips',
                    subtitle: 'Track your journey',
                    icon: Icons.map_rounded,
                    iconColor: const Color(0xFF60DAC4),
                    onTap: () => _navigate(const TripsScreen()),
                  ),
                  DashboardCard(
                    title: 'Toolkit',
                    subtitle: 'Emergency tools',
                    icon: Icons.build_rounded,
                    iconColor: Colors.orangeAccent,
                    onTap: () => _navigate(const EmergencyToolkitScreen()),
                  ),
                  DashboardCard(
                    title: 'Fake Call',
                    subtitle: 'Safety escape tool',
                    icon: Icons.phone_callback_rounded,
                    iconColor: const Color(0xFF9C27B0),
                    onTap: () => _navigate(const FakeCallScreen()),
                  ),
                  DashboardCard(
                    title: 'Notes',
                    subtitle: 'Safety protocols',
                    icon: Icons.description_rounded,
                    iconColor: const Color(0xFFFFB3AE),
                    onTap: () => _navigate(const NotesScreen()),
                  ),
                  DashboardCard(
                    title: 'Logs',
                    subtitle: 'Activity history',
                    icon: Icons.history_rounded,
                    iconColor: const Color(0xFFA0CAFF),
                    onTap: () => _navigate(const LogsScreen()),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ring(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: const Color(0xFFFF5352).withOpacity(opacity), width: 1.5),
        ),
      );

  Widget _statusPill() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF60DAC4).withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: const Color(0xFF60DAC4).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFF60DAC4)),
            ),
            const SizedBox(width: 6),
            const Text('Protected',
                style: TextStyle(
                    color: Color(0xFF60DAC4),
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );
}