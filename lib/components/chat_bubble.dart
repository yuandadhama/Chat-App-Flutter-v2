import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isSender;
  final dynamic timestamp; // Firestore Timestamp or DateTime

  const ChatBubble({
    super.key,
    Key? keys,
    required this.message,
    required this.isSender,
    this.timestamp,
  });

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    DateTime dateTime;
    if (ts is Timestamp) {
      dateTime = ts.toDate();
    } else if (ts is DateTime) {
      dateTime = ts;
    } else {
      // try parse
      try {
        dateTime = DateTime.parse(ts.toString());
      } catch (_) {
        return '';
      }
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final difference = today.difference(msgDate).inDays;

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hour = twoDigits(dateTime.hour);
    final minute = twoDigits(dateTime.minute);
    final timeStr = '$hour:$minute';

    // Determine day label
    String dayLabel = '';
    if (difference == 0) {
      // Today - just show time
      dayLabel = timeStr;
    } else if (difference == 1) {
      // Yesterday
      dayLabel = 'Yesterday $timeStr';
    } else if (difference > 1 && difference <= 6) {
      // Within a week - show day name
      const List<String> dayNames = [
        'Sunday',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday'
      ];
      final dayName = dayNames[dateTime.weekday % 7];
      dayLabel = '$dayName $timeStr';
    } else {
      // Older - show full date
      dayLabel =
          '${dateTime.year}-${twoDigits(dateTime.month)}-${twoDigits(dateTime.day)} $timeStr';
    }

    return dayLabel;
  }

  @override
  Widget build(BuildContext context) {
    final tsText = _formatTimestamp(timestamp);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Material(
        borderRadius: BorderRadius.circular(15),
        color: isSender ? Colors.green : Colors.grey.shade400,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            crossAxisAlignment:
                isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: TextStyle(
                  color: isSender ? Colors.white : Colors.black,
                ),
              ),
              if (tsText.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  tsText,
                  style: TextStyle(
                    color: isSender ? Colors.white70 : Colors.black87,
                    fontSize: 11,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
