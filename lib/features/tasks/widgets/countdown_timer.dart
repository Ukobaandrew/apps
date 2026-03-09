import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime endTime;
  final TextStyle? style;

  const CountdownTimer({super.key, required this.endTime, this.style});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer; // nullable to avoid late initialization error
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final remaining = widget.endTime.difference(now);

    if (remaining.isNegative) {
      _remaining = Duration.zero;
      _timer?.cancel(); // safe call
    } else {
      setState(() {
        _remaining = remaining;
      });
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _remaining.inSeconds > 0
          ? 'Ends in ${_formatDuration(_remaining)}'
          : 'Ended',
      style: widget.style ??
          const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel(); // safe cancellation
    super.dispose();
  }
}
