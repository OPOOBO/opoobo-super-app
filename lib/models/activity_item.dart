import 'package:flutter/material.dart';

enum ActivityKind { trips, orders, payments, deliveries, purchases }

enum ActivityStatus { completed, ongoing, pending }

class ActivityItem {
  final String id;
  final String title;
  final String meta;
  final String amount;
  final String time;
  final String day;
  final ActivityKind kind;
  final IconData icon;
  final Color tint;
  final ActivityStatus status;

  const ActivityItem({
    required this.id,
    required this.title,
    required this.meta,
    required this.amount,
    required this.time,
    required this.day,
    required this.kind,
    required this.icon,
    required this.tint,
    required this.status,
  });
}
