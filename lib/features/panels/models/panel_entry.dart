import 'package:flutter/material.dart';

class PanelEntry {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  final bool isHidden;

  const PanelEntry({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    this.isHidden = false,
  });
}

class PanelGroup {
  final String title;
  final IconData icon;
  final List<PanelEntry> items;
  final bool isHidden;

  const PanelGroup({
    required this.title,
    required this.icon,
    required this.items,
    this.isHidden = false,
  });
}

