import 'package:flutter/material.dart';
import 'base_app.dart';
import '../config/theme_config.dart';

class MediaApp extends BaseApp {
  const MediaApp({super.key});

  @override
  String get appName => 'Media';

  @override
  State<MediaApp> createState() => _MediaAppState();
}

class _MediaAppState extends State<MediaApp> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
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
                Icons.music_note_rounded,
                size: 100,
                color: EarthyTheme.terracotta,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Now Playing',
              style: TextStyle(
                fontSize: 14,
                color: EarthyTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Nature Sounds',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: EarthyTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.skip_previous_rounded, size: 40),
                  color: EarthyTheme.textSecondary,
                  onPressed: () {},
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                    size: 60,
                  ),
                  color: EarthyTheme.sage,
                  onPressed: () {
                    setState(() {
                      _isPlaying = !_isPlaying;
                    });
                  },
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: Icon(Icons.skip_next_rounded, size: 40),
                  color: EarthyTheme.textSecondary,
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
