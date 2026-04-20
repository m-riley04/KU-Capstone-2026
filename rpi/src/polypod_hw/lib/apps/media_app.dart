import 'dart:async';

import 'package:flutter/material.dart';
import 'base_app.dart';
import '../config/theme_config.dart';
import '../controllers/bluetooth_media_bridge_service.dart';
import '../services/bluetooth_media_service.dart';

class MediaApp extends BaseApp {
  const MediaApp({super.key});

  @override
  String get appName => 'Media';

  @override
  State<MediaApp> createState() => _MediaAppState();
}

class _MediaAppState extends State<MediaApp> {
  final BluetoothMediaBridgeService _bridgeService = BluetoothMediaBridgeService();
  final BluetoothMediaService _mediaService = BluetoothMediaService();
  BluetoothMediaState _mediaState = BluetoothMediaState.disconnected();
  Timer? _pollTimer;
  bool _isBusy = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _bridgeService.start();
    _refreshState();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _refreshState(showErrors: false);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _bridgeService.stop();
    super.dispose();
  }

  Future<void> _refreshState({bool showErrors = true}) async {
    try {
      final updatedState = await _mediaService.fetchState();
      if (!mounted) return;

      setState(() {
        _mediaState = updatedState;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _mediaState = BluetoothMediaState.disconnected();
        if (showErrors) {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        }
      });
    }
  }

  Future<void> _runCommand(Future<void> Function() command) async {
    if (_isBusy) return;

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      await command();
      await _refreshState(showErrors: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String nowPlayingTitle = _mediaState.title.isNotEmpty
        ? _mediaState.title
        : (_mediaState.connected ? 'Unknown Track' : 'No Bluetooth Media');

    final String nowPlayingSubtitle = _mediaState.artist.isNotEmpty
        ? _mediaState.artist
        : (_mediaState.connected ? 'Unknown Artist' : 'Pair a phone to begin');

    final bool controlsEnabled = _mediaState.connected && !_isBusy;

    return Container(
      color: EarthyTheme.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: EarthyTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _mediaState.connected
                    ? Icons.bluetooth_audio_rounded
                    : Icons.bluetooth_disabled_rounded,
                size: 100,
                color: EarthyTheme.terracotta,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              _mediaState.connected ? 'Now Playing' : 'Bluetooth Media',
              style: TextStyle(
                fontSize: 14,
                color: EarthyTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              nowPlayingTitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: EarthyTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              nowPlayingSubtitle,
              style: TextStyle(
                fontSize: 15,
                color: EarthyTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_errorMessage != null && _errorMessage!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 12,
                  color: EarthyTheme.terracotta,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded, size: 40),
                  color: EarthyTheme.textSecondary,
                  onPressed: controlsEnabled
                      ? () => _runCommand(_mediaService.previous)
                      : null,
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: Icon(
                    _mediaState.isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_filled_rounded,
                    size: 60,
                  ),
                  color: EarthyTheme.sage,
                  onPressed: controlsEnabled
                      ? () => _runCommand(
                            _mediaState.isPlaying
                                ? _mediaService.pause
                                : _mediaService.play,
                          )
                      : null,
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded, size: 40),
                  color: EarthyTheme.textSecondary,
                  onPressed: controlsEnabled
                      ? () => _runCommand(_mediaService.next)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _isBusy ? null : _refreshState,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
