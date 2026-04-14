import 'dart:async';
import 'package:flutter/material.dart';

class TripTimerWidget extends StatefulWidget {
  final DateTime startTime;
  final int durationMinutes;
  final VoidCallback onTimeout;

  const TripTimerWidget({
    super.key,
    required this.startTime,
    required this.durationMinutes,
    required this.onTimeout,
  });

  @override
  State<TripTimerWidget> createState() => _TripTimerWidgetState();
}

class _TripTimerWidgetState extends State<TripTimerWidget>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _timedOut = false;
  late AnimationController _blinkCtrl;

  @override
  void initState() {
    super.initState();
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _computeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _computeRemaining();
    });
  }

  void _computeRemaining() {
    final endTime =
        widget.startTime.add(Duration(minutes: widget.durationMinutes));
    final now = DateTime.now();

    if (now.isAfter(endTime)) {
      if (!_timedOut) {
        _timedOut = true;
        _timer?.cancel();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onTimeout();
        });
      }
      if (mounted) setState(() => _remaining = Duration.zero);
    } else {
      if (mounted) setState(() => _remaining = endTime.difference(now));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _blinkCtrl.dispose();
    super.dispose();
  }

  String _pad(int v) => v.toString().padLeft(2, '0');

  String get _formattedTime {
    final h = _remaining.inHours;
    final m = _remaining.inMinutes.remainder(60);
    final s = _remaining.inSeconds.remainder(60);
    if (h > 0) return '${_pad(h)}:${_pad(m)}:${_pad(s)}';
    return '${_pad(m)}:${_pad(s)}';
  }

  double get _progress {
    final totalSeconds = widget.durationMinutes * 60;
    if (totalSeconds == 0) return 1.0;
    final elapsed = totalSeconds - _remaining.inSeconds;
    return (elapsed / totalSeconds).clamp(0.0, 1.0);
  }

  Color get _timerColor {
    if (_progress >= 0.95) return const Color(0xFFFF5352);
    if (_progress >= 0.85) return Colors.orangeAccent;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                FadeTransition(
                  opacity: (_timedOut || _progress > 0.85)
                      ? _blinkCtrl
                      : const AlwaysStoppedAnimation(1.0),
                  child: Icon(
                    Icons.timer_rounded,
                    color: _timerColor.withOpacity(0.7),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Safety Window',
                  style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Text(
              '${widget.durationMinutes} min trip',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            color: _timerColor,
            fontSize: 64,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            height: 1,
            shadows: [
              if (_progress >= 0.85)
                Shadow(
                  color: _timerColor.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 0),
                ),
            ],
          ),
          child: Text(_formattedTime),
        ),
        const SizedBox(height: 20),
        Stack(
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(_timerColor),
                minHeight: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _progress >= 0.95 ? const Color(0xFFFF5352) : const Color(0xFF60DAC4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _timedOut 
                ? 'Time Expired — Safety check required' 
                : _progress >= 0.85
                  ? 'Approach trip deadline'
                  : 'Monitoring your safety window',
              style: TextStyle(
                color: _timedOut ? const Color(0xFFFF5352) : Colors.white38, 
                fontSize: 11, 
                fontWeight: FontWeight.w600
              ),
            ),
          ],
        ),
      ],
    );
  }
}