import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'base_app.dart';
import '../config/theme_config.dart';

class SettingsApp extends BaseApp {
  const SettingsApp({super.key});

  @override
  String get appName => 'Settings';

  @override
  State<SettingsApp> createState() => _SettingsAppState();
}

class _SettingsAppState extends State<SettingsApp> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: EarthyTheme.background,
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings_rounded,
                size: 40,
                color: EarthyTheme.clay,
              ),
              const SizedBox(width: 15),
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: EarthyTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _buildSettingItem('Display Brightness', Icons.brightness_6_rounded),
          _buildSettingItem('Volume', Icons.volume_up_rounded),
          _buildSettingItem('Network', Icons.wifi_rounded),
          _buildSettingItem('About Device', Icons.info_outline_rounded),
          GestureDetector(
            onTap: () => _confirmQuit(context),
            child: _buildSettingItem('Quit Polypod', Icons.exit_to_app_rounded),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmQuit(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EarthyTheme.surface,
        title: Text('Quit Polypod?', style: TextStyle(color: EarthyTheme.textPrimary)),
        content: Text('Are you sure you want to quit?', style: TextStyle(color: EarthyTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: EarthyTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Quit', style: TextStyle(color: EarthyTheme.clay)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      SystemNavigator.pop();
      exit(0);
    }
  }

  Widget _buildSettingItem(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: EarthyTheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: EarthyTheme.textSecondary),
            const SizedBox(width: 15),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: EarthyTheme.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: EarthyTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
