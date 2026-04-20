import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'base_app.dart';
import '../config/theme_config.dart';
import '../services/notification_settings_store.dart';

class SettingsApp extends BaseApp {
  const SettingsApp({
    super.key,
    this.onRequestResetConfirmation,
    this.onResetToSetup,
    this.showBottomResetConfirmation = false,
  });

  final VoidCallback? onRequestResetConfirmation;
  final Future<void> Function()? onResetToSetup;
  final bool showBottomResetConfirmation;

  @override
  String get appName => 'Settings';

  @override
  Widget? buildBottomScreenContent(BuildContext context) {
    if (!showBottomResetConfirmation) {
      return null;
    }
    return SettingsBottomScreenContent(onResetToSetup: onResetToSetup);
  }

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
      child: SingleChildScrollView(
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
            GestureDetector(
              onTap: widget.onRequestResetConfirmation,
              child: _buildSettingItem(
                'Reset Device To Setup QR',
                Icons.restart_alt_rounded,
              ),
            ),
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
      final savedUserId = await loadNotificationUserId();
      if (mounted) {
        _userIdController.text = savedUserId;
      }
      if (mounted) {
        setState(() {
          _isLoadingUserId = false;
          _userIdStatus = 'Loaded saved user ID.';
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
      final previousUserId = (await loadNotificationUserId()).trim();

      final hasChanged = previousUserId != userId;
      if (hasChanged) {
        await clearNotificationState();
      }

      await saveNotificationUserId(userId);

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

class SettingsBottomScreenContent extends StatefulWidget {
  const SettingsBottomScreenContent({
    super.key,
    this.onResetToSetup,
  });

  final Future<void> Function()? onResetToSetup;

  @override
  State<SettingsBottomScreenContent> createState() =>
      _SettingsBottomScreenContentState();
}

class _SettingsBottomScreenContentState extends State<SettingsBottomScreenContent> {
  bool _isResetting = false;

  Future<void> _confirmAndReset() async {
    setState(() {
      _isResetting = true;
    });

    try {
      await widget.onResetToSetup?.call();
    } finally {
      setState(() {
        _isResetting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EarthyTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Settings',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: EarthyTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Reset confirmation is shown on this bottom screen.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: EarthyTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _isResetting ? null : _confirmAndReset,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: _isResetting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.qr_code_rounded),
            label: Text(_isResetting ? 'Resetting...' : 'Reset To Setup'),
          ),
        ],
      ),
    );
  }
}
