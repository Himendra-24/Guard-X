import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/hive_service.dart';
import '../models/log.dart';
import '../utils/helpers.dart';

class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({super.key});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen>
    with TickerProviderStateMixin {
  // States: setup → waiting → ringing → inCall
  _CallState _state = _CallState.setup;

  String _callerName = 'Dad';
  String _callerLabel = 'Mobile';
  int _delaySeconds = 5;

  Timer? _ringTimer;
  Timer? _callTimer;
  int _callSeconds = 0;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
  }

  void _startSequence() {
    setState(() => _state = _CallState.waiting);
    
    _ringTimer = Timer(Duration(seconds: _delaySeconds), () {
      if (mounted) {
        setState(() => _state = _CallState.ringing);
        _pulseCtrl.repeat(reverse: true);
        _slideCtrl.forward();
        _startRingVibration();
      }
    });
  }

  Timer? _vibrationTimer;
  void _startRingVibration() {
    _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_state == _CallState.ringing) {
        HapticFeedback.heavyImpact();
      } else {
        _vibrationTimer?.cancel();
      }
    });
  }

  void _acceptCall() {
    HapticFeedback.lightImpact();
    _vibrationTimer?.cancel();
    setState(() => _state = _CallState.inCall);
    _pulseCtrl.stop();

    HiveService.addLog('Fake Call activated — "$_callerName"');

    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callSeconds++);
    });
  }

  void _rejectCall() => Navigator.pop(context);
  void _endCall() => Navigator.pop(context);

  @override
  void dispose() {
    _ringTimer?.cancel();
    _callTimer?.cancel();
    _vibrationTimer?.cancel();
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  String get _callDuration {
    final m = (_callSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_callSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10141A),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: _state == _CallState.setup 
            ? null 
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A1D23), Color(0xFF0D0F12)],
              ),
        ),
        child: SafeArea(
          child: _state == _CallState.setup
              ? _buildSetupView()
              : _state == _CallState.waiting
                  ? _buildWaitingView()
                  : _state == _CallState.ringing
                      ? _buildRingingView()
                      : _buildInCallView(),
        ),
      ),
    );
  }

  // ── Setup View ────────────────────────────────
  Widget _buildSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFFFB3AE)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Fake Call Setup',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Configure an incoming call to help you exit uncomfortable situations safely.',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 40),

          _setupField('Caller Name', _callerName, (v) => setState(() => _callerName = v), Icons.person_rounded),
          const SizedBox(height: 20),
          _setupField('Label (e.g. Mobile)', _callerLabel, (v) => setState(() => _callerLabel = v), Icons.label_rounded),
          const SizedBox(height: 32),

          const Text('Delay before ring', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [2, 3, 5, 10].map((s) => _delayChip(s)).toList(),
          ),

          const SizedBox(height: 60),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5352),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _startSequence,
              child: const Text('SCHEDULE CALL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _setupField(String label, String value, Function(String) onChanged, IconData icon) {
    return TextField(
      onChanged: onChanged,
      controller: TextEditingController(text: value)..selection = TextSelection.collapsed(offset: value.length),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFFF5352), size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
      ),
    );
  }

  Widget _delayChip(int s) {
    final isSelected = _delaySeconds == s;
    return GestureDetector(
      onTap: () => setState(() => _delaySeconds = s),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF5352) : Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${s}s',
          style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ── Waiting View ──────────────────────────────
  Widget _buildWaitingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFFFF5352)),
          ),
          const SizedBox(height: 32),
          Text(
            'Scheduling incoming call...\nStarting in $_delaySeconds seconds',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 48),
          TextButton(
            onPressed: () => setState(() => _state = _CallState.setup),
            child: const Text('Cancel Request', style: TextStyle(color: Color(0xFFFFB3AE))),
          ),
        ],
      ),
    );
  }

  // ── Ringing View ──────────────────────────────
  Widget _buildRingingView() {
    return Column(
      children: [
        const Spacer(flex: 2),
        ScaleTransition(
          scale: _pulseAnim,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF262A31),
              border: Border.all(color: const Color(0xFF60DAC4).withOpacity(0.4), width: 3),
              boxShadow: [
                BoxShadow(color: const Color(0xFF60DAC4).withOpacity(0.2), blurRadius: 40, spreadRadius: 10),
              ],
            ),
            child: Center(
              child: Text(
                _callerName.isNotEmpty ? _callerName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          _callerName,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phone_rounded, color: Color(0xFF60DAC4), size: 16),
            const SizedBox(width: 8),
            Text(
              'Incoming Call • $_callerLabel',
              style: const TextStyle(color: Color(0xFF60DAC4), fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const Spacer(flex: 3),
        SlideTransition(
          position: _slideAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _callButton(icon: Icons.call_end_rounded, color: const Color(0xFFFF5352), label: 'Decline', onTap: _rejectCall),
                _callButton(icon: Icons.call_rounded, color: const Color(0xFF4CAF50), label: 'Accept', onTap: _acceptCall),
              ],
            ),
          ),
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  // ── In-Call View ──────────────────────────────
  Widget _buildInCallView() {
    return Column(
      children: [
        const Spacer(flex: 2),
        Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF262A31)),
          child: Center(
            child: Text(
              _callerName.isNotEmpty ? _callerName[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _callerName,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          _callDuration,
          style: const TextStyle(color: Color(0xFF60DAC4), fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 2),
        ),
        const Spacer(flex: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _smallAction(Icons.volume_up_rounded, 'Speaker'),
            _smallAction(Icons.mic_off_rounded, 'Mute'),
            _smallAction(Icons.dialpad_rounded, 'Keypad'),
          ],
        ),
        const SizedBox(height: 48),
        GestureDetector(
          onTap: _endCall,
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFF5352),
              boxShadow: [BoxShadow(color: Color(0xFFFF5352), blurRadius: 20, spreadRadius: 2)],
            ),
            child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 10),
        const Text('End Call', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 50),
      ],
    );
  }

  Widget _callButton({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle, 
              color: color,
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _smallAction(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)),
          child: Icon(icon, color: Colors.white70, size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}

enum _CallState { setup, waiting, ringing, inCall }
