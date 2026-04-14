import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/contact.dart';
import '../models/log.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../services/sos_service.dart';
import '../services/alert_service.dart';
import 'fake_call_screen.dart';

class SOSAlertScreen extends StatefulWidget {
  const SOSAlertScreen({super.key});

  @override
  State<SOSAlertScreen> createState() => _SOSAlertScreenState();
}

class _SOSAlertScreenState extends State<SOSAlertScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  List<Contact> _contacts = [];

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _contacts = HiveService.contacts.values.toList();

    // Fire SOS notification
    NotificationService.showSOSTriggered();

    // Start alarm + vibration
    AlertService.playAlarm();
    AlertService.emergencyVibrate();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    AlertService.stopAlarm();
    super.dispose();
  }

  void _dismiss() {
    AlertService.stopAlarm();
    HiveService.logs.add(
        AppLog(event: 'SOS dismissed — Marked safe', timestamp: DateTime.now()));
    Navigator.pop(context);
  }

  Contact? get _primaryContact => SOSService.getPrimaryContact(_contacts);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF5352), Color(0xFF68000B)],
          ),
        ),
        child: SafeArea(
          child: SizedBox.expand(
            child: Stack(
              children: [
                // ── Ambient bg rings ─────────────────────
                Positioned(
                  top: -80,
                  right: -80,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -60,
                  left: -60,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.12),
                    ),
                  ),
                ),

                // ── Main Content ─────────────────────────
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      // Pulsing emergency icon
                      ScaleTransition(
                        scale: _pulseAnim,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.shade900.withOpacity(0.5),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.emergency_rounded,
                              size: 60, color: Colors.white),
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'EMERGENCY',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Take action now. Your contacts\nwill be notified.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white70, fontSize: 14, height: 1.5),
                      ),

                      const SizedBox(height: 32),

                      // ── Call Primary Contact ──────────────
                      if (_primaryContact != null)
                        _emergencyButton(
                          icon: Icons.call_rounded,
                          label: 'Call ${_primaryContact!.name}',
                          color: const Color(0xFF4CAF50),
                          onTap: () => SOSService.callContact(_primaryContact!),
                        ),

                      const SizedBox(height: 12),

                      // ── Send SMS to All ───────────────────
                      _emergencyButton(
                        icon: Icons.sms_rounded,
                        label: 'Send SOS SMS to All',
                        color: Colors.white,
                        textColor: const Color(0xFFFF5352),
                        onTap: () {
                          for (final c in _contacts) {
                            SOSService.sendSMS(
                              c,
                              '🚨 SOS! I may be in danger. This is an automated '
                              'alert from Guard-X Safety App. Please try to '
                              'reach me immediately.',
                            );
                          }
                          HiveService.addLog('SOS SMS sent to all contacts');
                        },
                      ),

                      const SizedBox(height: 12),

                      // ── Fake Call ─────────────────────────
                      _emergencyButton(
                        icon: Icons.phone_callback_rounded,
                        label: 'Fake Call — Escape',
                        color: const Color(0xFF9C27B0),
                        onTap: () {
                          AlertService.stopAlarm();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const FakeCallScreen()),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // ── Contact List ──────────────────────
                      if (_contacts.isEmpty)
                        _noContactsCard()
                      else
                        ..._contacts.take(3).map((c) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildContactRow(c),
                            )),

                      const SizedBox(height: 32),

                      // ── I'm Safe / Cancel ──────────────────
                      GestureDetector(
                        onTap: _dismiss,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white38, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.shield_rounded,
                                  color: Colors.white, size: 28),
                              SizedBox(height: 6),
                              Text(
                                'I AM SAFE — CANCEL',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emergencyButton({
    required IconData icon,
    required String label,
    required Color color,
    Color textColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 6,
        ),
        icon: Icon(icon, size: 24),
        label: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildContactRow(Contact c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFFF5352),
            child: Text(
              c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(c.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10141A),
                              fontSize: 14),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (c.isPrimary)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.star_rounded,
                            color: Color(0xFFFF5352), size: 16),
                      ),
                  ],
                ),
                Text(c.phone,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => SOSService.callContact(c),
            icon: const Icon(Icons.call_rounded,
                color: Color(0xFFFF5352), size: 26),
            tooltip: 'Call ${c.name}',
          ),
        ],
      ),
    );
  }

  Widget _noContactsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.white70),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No emergency contacts added yet.\nPlease add contacts from the Contacts section.',
              style: TextStyle(
                  color: Colors.white70, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}