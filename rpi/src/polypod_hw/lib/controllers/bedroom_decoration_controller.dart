import 'dart:convert';
import 'package:flutter/services.dart';

class DecorationZone {
  final String id;
  final int tileX;
  final int tileY;
  final int tileWidth;
  final int tileHeight;
  final List<String> allowedTypes;
  final int maxAccumulated;

  const DecorationZone({
    required this.id,
    required this.tileX,
    required this.tileY,
    required this.tileWidth,
    required this.tileHeight,
    required this.allowedTypes,
    required this.maxAccumulated,
  });

  /// Pixel position (assuming 16px tiles)
  int get pixelX => tileX * 16;
  int get pixelY => tileY * 16;
  int get pixelWidth => tileWidth * 16;
  int get pixelHeight => tileHeight * 16;

  factory DecorationZone.fromJson(Map<String, dynamic> json) {
    return DecorationZone(
      id: json['id'] as String,
      tileX: json['tile_x'] as int,
      tileY: json['tile_y'] as int,
      tileWidth: json['tile_width'] as int,
      tileHeight: json['tile_height'] as int,
      allowedTypes: List<String>.from(json['allowed_types'] as List),
      maxAccumulated: json['max_accumulated'] as int? ?? 1,
    );
  }
}

class DecorationItem {
  final String zoneId;
  final String decorationType;
  final String teamName;
  final String genre; // 'mcb' or 'nhl'
  final int stackOrder; // For ordering within a zone

  const DecorationItem({
    required this.zoneId,
    required this.decorationType,
    required this.teamName,
    required this.genre,
    required this.stackOrder,
  });

  /// Asset path to the decoration image
  String get assetPath => 'assets/br/$genre/$teamName.png';
}

class BedroomDecorationController {
  final Map<String, DecorationZone> _zones = {};
  final Map<String, List<DecorationItem>> _zoneDecorations = {};

  bool _isInitialized = false;

  BedroomDecorationController();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final configJson = await rootBundle
          .loadString('assets/br/bedroom_decor_config.json');
      final config = jsonDecode(configJson) as Map<String, dynamic>;
      final bedroomConfig = config['bedroom'] as Map<String, dynamic>;
      final zones = bedroomConfig['decoration_zones'] as List;

      for (final zoneJson in zones) {
        final zone = DecorationZone.fromJson(zoneJson as Map<String, dynamic>);
        _zones[zone.id] = zone;
        _zoneDecorations[zone.id] = [];
      }

      _isInitialized = true;
    } catch (_) {
      _zones.clear();
      _zoneDecorations.clear();
      _isInitialized = false;
    }
  }

  bool get isInitialized => _isInitialized;

  /// Add a decoration item to a zone
  /// Returns true if added, false if zone is full or type not allowed
  bool addDecorationToZone({
    required String zoneId,
    required String decorationType,
    required String teamName,
    required String genre,
  }) {
    final zone = _zones[zoneId];
    if (zone == null) return false;

    // Check if decoration type is allowed
    if (!zone.allowedTypes.contains(decorationType)) {
      return false;
    }

    // Check if zone is at max capacity
    final items = _zoneDecorations[zoneId] ?? [];
    if (items.length >= zone.maxAccumulated) {
      return false;
    }

    final item = DecorationItem(
      zoneId: zoneId,
      decorationType: decorationType,
      teamName: teamName,
      genre: genre,
      stackOrder: items.length,
    );

    items.add(item);
    return true;
  }

  /// Find the best available zone for a decoration type
  /// Returns zone ID or null if no zones available
  String? findAvailableZoneForType(String decorationType) {
    for (final zone in _zones.values) {
      if (!zone.allowedTypes.contains(decorationType)) continue;

      final items = _zoneDecorations[zone.id] ?? [];
      if (items.length < zone.maxAccumulated) {
        return zone.id;
      }
    }
    return null;
  }

  /// Add a decoration to the first available zone of its type
  bool addDecoration({
    required String decorationType,
    required String teamName,
    required String genre,
  }) {
    final zoneId = findAvailableZoneForType(decorationType);
    if (zoneId == null) return false;

    return addDecorationToZone(
      zoneId: zoneId,
      decorationType: decorationType,
      teamName: teamName,
      genre: genre,
    );
  }

  /// Get all decoration items across all zones
  List<DecorationItem> getAllDecorations() {
    final all = <DecorationItem>[];
    for (final items in _zoneDecorations.values) {
      all.addAll(items);
    }
    return all;
  }

  /// Get decoration items for a specific zone
  List<DecorationItem> getDecorationsInZone(String zoneId) {
    return _zoneDecorations[zoneId] ?? [];
  }

  /// Get zone info
  DecorationZone? getZone(String zoneId) {
    return _zones[zoneId];
  }

  /// Clear all decorations
  void clearAllDecorations() {
    for (final items in _zoneDecorations.values) {
      items.clear();
    }
  }

  /// Clear decorations in a specific zone
  void clearZone(String zoneId) {
    _zoneDecorations[zoneId]?.clear();
  }

  /// Remove decoration by index from a zone
  bool removeDecorationFromZone(String zoneId, int index) {
    final items = _zoneDecorations[zoneId];
    if (items == null || index < 0 || index >= items.length) {
      return false;
    }
    items.removeAt(index);
    return true;
  }
}
