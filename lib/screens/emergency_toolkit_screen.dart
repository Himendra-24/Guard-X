import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/hive_service.dart';
import '../services/alert_service.dart';
import '../services/sos_service.dart';
import '../utils/helpers.dart';
import 'fake_call_screen.dart';

class EmergencyToolkitScreen extends StatefulWidget {
  const EmergencyToolkitScreen({super.key});

  @override
  State<EmergencyToolkitScreen> createState() => _EmergencyToolkitScreenState();
}

class _EmergencyToolkitScreenState extends State<EmergencyToolkitScreen> {
  bool _isSirenOn = false;
  bool _isFlashlightOn = false;

  @override
  void dispose() {
    AlertService.stopSiren();
    super.dispose();
  }

  void _toggleSiren() async {
    setState(() => _isSirenOn = !_isSirenOn);
    if (_isSirenOn) {
      await AlertService.playSiren();
    } else {
      await AlertService.stopSiren();
    }
    HapticFeedback.mediumImpact();
  }

  void _toggleFlashlight() async {
    setState(() => _isFlashlightOn = !_isFlashlightOn);
    await AlertService.toggleFlashlight(_isFlashlightOn);
    HapticFeedback.lightImpact();
  }

  void _callPrimary() async {
    final contacts = HiveService.contacts.values.toList();
    final primary = SOSService.getPrimaryContact(contacts);
    if (primary != null) {
      await SOSService.callContact(primary);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No primary contact set!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10141A),
      appBar: buildAppBar('Emergency Toolkit'),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Emergency Tools',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use these tools in uncomfortable or dangerous situations to draw attention or escape.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            // New Emergency Kill Switch
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  AlertService.stopAll();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All Alerts Stopped 🔇'),
                      backgroundColor: Colors.blueGrey,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C2026),
                  foregroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                ),
                icon: const Icon(Icons.stop_circle_rounded),
                label: const Text(
                  'STOP ALL ALERTS',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
                childAspectRatio: 0.95,
                children: [
                  _toolkitCard(
                    title: 'Test Alarm',
                    subtitle: 'Verify sound & vibrate',
                    icon: Icons.notifications_active_rounded,
                    onTap: () {
                      AlertService.playAlarm();
                      AlertService.emergencyVibrate();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Testing Alarm & Vibration...'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    },
                    activeColor: const Color(0xFFFF5352),
                  ),
                  _toolkitCard(
                    title: 'Loud Siren',
                    subtitle: 'Draw immediate attention',
                    icon: _isSirenOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    isActive: _isSirenOn,
                    onTap: _toggleSiren,
                    activeColor: Colors.orangeAccent,
                  ),
                  _toolkitCard(
                    title: 'Flashlight',
                    subtitle: 'Emergency lighting',
                    icon: _isFlashlightOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                    isActive: _isFlashlightOn,
                    onTap: _toggleFlashlight,
                    activeColor: const Color(0xFFA0CAFF),
                  ),
                  _toolkitCard(
                    title: 'Fake Call',
                    subtitle: 'Reason to leave',
                    icon: Icons.phone_callback_rounded,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FakeCallScreen()),
                    ),
                    activeColor: const Color(0xFF9C27B0),
                  ),
                  _toolkitCard(
                    title: 'Call Primary',
                    subtitle: 'Quick guardian contact',
                    icon: Icons.contact_phone_rounded,
                    onTap: _callPrimary,
                    activeColor: const Color(0xFF60DAC4),
                  ),
                ],
              ),
            ),
            _safetyTip(),
          ],
        ),
      ),
    );
  }

  Widget _toolkitCard({
    required String title,
    required String subtitle,
    required IconData icon,
    bool isActive = false,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.15) : const Color(0xFF1C2026),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? activeColor.withOpacity(0.5) : Colors.white.withOpacity(0.05),
            width: 2,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: activeColor.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isActive ? activeColor : Colors.white10).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isActive ? activeColor : Colors.white54, size: 28),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _safetyTip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2026).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'TIP: Long-pressing the SOS button on the dashboard is the fastest way to alert everyone.',
              style: TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}
