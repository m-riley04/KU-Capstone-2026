import 'dart:io';
import 'dart:convert';

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
  final TextEditingController _userIdController = TextEditingController();
  bool _isLoadingUserId = true;
  bool _isSavingUserId = false;
  String _userIdStatus = '';

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

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
          _buildUserIdSetting(),
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

  Widget _buildUserIdSetting() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: EarthyTheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline_rounded, color: EarthyTheme.textSecondary),
                const SizedBox(width: 15),
                Text(
                  'Notification User ID',
                  style: TextStyle(
                    fontSize: 16,
                    color: EarthyTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _userIdController,
              enabled: !_isLoadingUserId && !_isSavingUserId,
              style: TextStyle(color: EarthyTheme.textPrimary),
              decoration: InputDecoration(
                hintText: _isLoadingUserId ? 'Loading...' : 'Enter user id',
                hintStyle: TextStyle(color: EarthyTheme.textSecondary),
                filled: true,
                fillColor: EarthyTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: EarthyTheme.textSecondary.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: EarthyTheme.textSecondary.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: EarthyTheme.clay),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: (_isLoadingUserId || _isSavingUserId) ? null : _saveUserId,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EarthyTheme.clay,
                    foregroundColor: Colors.white,
                  ),
                  icon: _isSavingUserId
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_isSavingUserId ? 'Saving...' : 'Save User ID'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _userIdStatus,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: EarthyTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadUserId() async {
    try {
      final settingsFile = File(_notificationSettingsPath());
      if (await settingsFile.exists()) {
        final raw = await settingsFile.readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final savedUserId = decoded['user_id']?.toString() ?? '';
          if (mounted) {
            _userIdController.text = savedUserId;
          }
        }
      }
      if (mounted) {
        setState(() {
          _isLoadingUserId = false;
          _userIdStatus = 'Loaded from notification settings file.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUserId = false;
          _userIdStatus = 'Could not load user id.';
        });
      }
    }
  }

  Future<void> _saveUserId() async {
    final userId = _userIdController.text.trim();

    setState(() {
      _isSavingUserId = true;
      _userIdStatus = '';
    });

    try {
      final settingsFile = File(_notificationSettingsPath());
      await settingsFile.parent.create(recursive: true);

      String previousUserId = '';
      if (await settingsFile.exists()) {
        try {
          final existingRaw = await settingsFile.readAsString();
          final existingDecoded = jsonDecode(existingRaw);
          if (existingDecoded is Map<String, dynamic>) {
            previousUserId = existingDecoded['user_id']?.toString().trim() ?? '';
          }
        } catch (_) {
          previousUserId = '';
        }
      }

      final hasChanged = previousUserId != userId;
      if (hasChanged) {
        await settingsFile.writeAsString(
          const JsonEncoder.withIndent('  ').convert({'user_id': ''}),
        );
        await _clearNotificationStateFiles();
      }

      final payload = <String, dynamic>{
        'user_id': userId,
      };

      await settingsFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(payload),
      );

      if (mounted) {
        setState(() {
          _userIdStatus = hasChanged
              ? 'User ID updated. Cleared previous notification state.'
              : 'User ID saved.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userIdStatus = 'Failed to save user id.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingUserId = false;
        });
      }
    }
  }

  Future<void> _clearNotificationStateFiles() async {
    final currentNotificationFile = File(_currentNotificationPath());
    await currentNotificationFile.parent.create(recursive: true);
    await currentNotificationFile.writeAsString('{}');

    final pollerStateFile = File(_notificationPollStatePath());
    if (await pollerStateFile.exists()) {
      await pollerStateFile.delete();
    }
  }

  String _notificationSettingsPath() {
    final currentDir = Directory.current.path;
    final settingsPath = '$currentDir${Platform.pathSeparator}..${Platform.pathSeparator}notif${Platform.pathSeparator}notification_settings.json';
    return File(settingsPath).absolute.path;
  }

  String _currentNotificationPath() {
    final currentDir = Directory.current.path;
    final notifPath = '$currentDir${Platform.pathSeparator}..${Platform.pathSeparator}notif${Platform.pathSeparator}current_notification.json';
    return File(notifPath).absolute.path;
  }

  String _notificationPollStatePath() {
    final currentDir = Directory.current.path;
    final statePath = '$currentDir${Platform.pathSeparator}..${Platform.pathSeparator}notif${Platform.pathSeparator}.notification_poll_state.json';
    return File(statePath).absolute.path;
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
