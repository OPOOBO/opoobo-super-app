import 'package:flutter/material.dart';

enum ServiceState { installed, notInstalled, update }

class ServiceModule {
  final String id;
  final String name;
  final String short;
  final String description;
  final IconData icon;
  final Color tint;
  final String? badge;
  final String? lastUsed;
  final ServiceState state;
  final String? version;
  final String? storage;
  final String? href;

  const ServiceModule({
    required this.id,
    required this.name,
    required this.short,
    required this.description,
    required this.icon,
    required this.tint,
    this.badge,
    this.lastUsed,
    required this.state,
    this.version,
    this.storage,
    this.href,
  });
}
