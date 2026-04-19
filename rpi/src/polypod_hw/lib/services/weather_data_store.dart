import 'package:flutter/foundation.dart';

import '../models/notification_models.dart';

class WeatherSnapshot {
  final String temperature;
  final String condition;
  final String location;
  final String iconUrl;
  final DateTime? updatedAt;

  const WeatherSnapshot({
    required this.temperature,
    required this.condition,
    required this.location,
    required this.iconUrl,
    required this.updatedAt,
  });

  factory WeatherSnapshot.initial() {
    return const WeatherSnapshot(
      temperature: '--\u00b0F',
      condition: 'Waiting for weather update',
      location: 'Local',
      iconUrl: '',
      updatedAt: null,
    );
  }
}

class WeatherDataStore extends ChangeNotifier {
  WeatherDataStore._();

  static final WeatherDataStore instance = WeatherDataStore._();

  WeatherSnapshot _snapshot = WeatherSnapshot.initial();

  WeatherSnapshot get snapshot => _snapshot;

  void updateFromNotification(NotificationData notification) {
    final parsed = _parseWeatherInfo(notification.info);
    final location = _parseLocation(notification.headline);
    final updatedAt = DateTime.tryParse(notification.timestamp);

    _snapshot = WeatherSnapshot(
      temperature: parsed.$1,
      condition: parsed.$2,
      location: location,
      iconUrl: notification.media,
      updatedAt: updatedAt,
    );

    notifyListeners();
  }

  (String, String) _parseWeatherInfo(String info) {
    final trimmed = info.trim();
    final match = RegExp(r'^(-?\d+(?:\.\d+)?)\s*\u00b0\s*F\s*,\s*(.+)$', caseSensitive: false)
        .firstMatch(trimmed);
    if (match == null) {
      if (trimmed.isEmpty) {
        return ('--\u00b0F', 'No weather details available');
      }
      return ('--\u00b0F', trimmed);
    }

    final temp = '${match.group(1)}\u00b0F';
    final condition = (match.group(2) ?? '').trim().replaceFirst(RegExp(r'\.$'), '');
    return (temp, condition.isEmpty ? 'Unknown conditions' : condition);
  }

  String _parseLocation(String headline) {
    const prefix = 'Weather Update:';
    if (!headline.startsWith(prefix)) {
      return 'Local';
    }

    final location = headline.substring(prefix.length).trim();
    return location.isEmpty ? 'Local' : location;
  }
}