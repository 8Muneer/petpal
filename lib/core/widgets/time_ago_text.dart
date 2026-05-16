import 'dart:async';
import 'package:flutter/material.dart';

/// Displays a Hebrew relative-time string ("עכשיו", "לפני 5 דק׳", etc.)
/// and automatically refreshes every minute so the label stays accurate.
class TimeAgoText extends StatefulWidget {
  final DateTime? createdAt;
  final TextStyle? style;

  const TimeAgoText({super.key, required this.createdAt, this.style});

  @override
  State<TimeAgoText> createState() => _TimeAgoTextState();
}

class _TimeAgoTextState extends State<TimeAgoText> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Refresh every 60 seconds so the label stays current.
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _label {
    final createdAt = widget.createdAt;
    if (createdAt == null) return '';
    final now = DateTime.now();
    // Guard against server clock being slightly ahead of the client.
    if (createdAt.isAfter(now)) return 'עכשיו';
    final diff = now.difference(createdAt);
    if (diff.inSeconds < 60) return 'עכשיו';
    if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דק׳';
    if (diff.inHours < 24) return 'לפני ${diff.inHours} שעות';
    if (diff.inDays < 7) return 'לפני ${diff.inDays} ימים';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Text(_label, style: widget.style);
  }
}
