// RILEY ANDERSON
// 02/17/2026
// this file contains the functions for how each api and local notification shall be displayed
// also has a function for interpreting new configs sent by polywork api

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../config/theme_config.dart';
import '../config/screen_config.dart';

/// Configuration for notification display
class NotificationConfig {
  final Size mediaSize;
  final double headlineSize;
  final double infoSize;

  NotificationConfig({
    required this.mediaSize,
    required this.headlineSize,
    required this.infoSize,
  });

  factory NotificationConfig.fromJson(Map<String, dynamic> json) {
    final mediaSizeList = json['media_size'] as List;
    return NotificationConfig(
      mediaSize: Size(
        (mediaSizeList[0] as num).toDouble(),
        (mediaSizeList[1] as num).toDouble(),
      ),
      headlineSize: (json['headline_size'] as num).toDouble(),
      infoSize: (json['info_size'] as num).toDouble(),
    );
  }
}

/// Notification data model
class NotificationData {
  final String timestamp;
  final String media;
  final String headline;
  final String info;
  final String seemore;
  final String fromSource;
  final NotificationConfig config;

  NotificationData({
    required this.timestamp,
    required this.media,
    required this.headline,
    required this.info,
    required this.seemore,
    required this.fromSource,
    required this.config,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    final notificationData = json['notification'] as Map<String, dynamic>;
    final configData = json['config'] as Map<String, dynamic>;

    return NotificationData(
      timestamp: notificationData['timestamp'] ?? '',
      media: notificationData['media'] ?? '',
      headline: notificationData['headline'] ?? '',
      info: notificationData['info'] ?? '',
      seemore: notificationData['seemore'] ?? '',
      fromSource: json['from_source'] ?? '',
      config: NotificationConfig.fromJson(configData),
    );
  }
}

/// Parse notification from JSON file
Future<NotificationData?> parseNotificationFromFile(String filePath) async {
  try {
    final file = File(filePath);
    if (!await file.exists()) {
      return null;
    }

    final contents = await file.readAsString();
    final json = jsonDecode(contents) as Map<String, dynamic>;
    
    return NotificationData.fromJson(json);
  } catch (e) {
    print('Error parsing notification: $e');
    return null;
  }
}

/// Widget that displays a notification with custom configuration
class NotificationWidget extends StatelessWidget {
  final NotificationData notification;
  final VoidCallback? onSeeMore;

  const NotificationWidget({
    Key? key,
    required this.notification,
    this.onSeeMore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ScreenConfig.topScreenWidth,
      height: ScreenConfig.topScreenHeight,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: EarthyTheme.forestGreen,
        border: Border.all(color: EarthyTheme.wheat, width: 3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Source label
          if (notification.fromSource.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                notification.fromSource.toUpperCase(),
                style: TextStyle(
                  color: EarthyTheme.wheat,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          
          // Media (if present)
          if (notification.media.isNotEmpty &&
              notification.config.mediaSize.width > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Container(
                  width: notification.config.mediaSize.width,
                  height: notification.config.mediaSize.height,
                  decoration: BoxDecoration(
                    color: EarthyTheme.surface,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: EarthyTheme.bark, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: _buildMediaWidget(),
                  ),
                ),
              ),
            ),

          // Headline
          if (notification.headline.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                notification.headline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: EarthyTheme.textPrimary,
                  fontSize: notification.config.headlineSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // Info
          if (notification.info.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                notification.info,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: EarthyTheme.textSecondary,
                  fontSize: notification.config.infoSize,
                ),
              ),
            ),

          // See More button
          if (notification.seemore.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ElevatedButton(
                onPressed: onSeeMore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EarthyTheme.terracotta,
                  foregroundColor: EarthyTheme.textPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('See More', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaWidget() {
    // Check if media is a URL or local path
    if (notification.media.startsWith('http://') ||
        notification.media.startsWith('https://')) {
      return Image.network(
        notification.media,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.error, color: Colors.red),
          );
        },
      );
    } else if (notification.media.isNotEmpty) {
      return Image.file(
        File(notification.media),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.error, color: Colors.red),
          );
        },
      );
    }
    return Container();
  }
}
