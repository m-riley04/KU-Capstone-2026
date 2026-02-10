import 'package:flutter/material.dart';
import '../config/screen_config.dart';
import '../config/theme_config.dart';
import '../widgets/control_button.dart';
import '../apps/base_app.dart';

/// Bottom screen widget with app launcher buttons and home button
class BottomScreen extends StatelessWidget {
  final Function(String) onAppSelected;
  final VoidCallback onHomePressed;
  final List<String> availableApps;
  final BaseApp currentApp;

  const BottomScreen({
    Key? key,
    required this.onAppSelected,
    required this.onHomePressed,
    required this.availableApps,
    required this.currentApp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if current app provides custom bottom screen content
    final customContent = currentApp.buildBottomScreenContent(context);
    if (customContent != null) {
      return Container(
        width: ScreenConfig.bottomScreenWidth,
        height: ScreenConfig.bottomScreenHeight,
        color: EarthyTheme.surface,
        child: Stack(
          children: [
            // custom content will take full space, but we want to be able to go home sometimes
            customContent,
            // optional back button at bottom using bool declared by app
            if (currentApp.showBackButtonWithCustomBottom)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 63,
                child: Container(
                  decoration: BoxDecoration(
                  color: EarthyTheme.bark, // Background color
                  borderRadius: BorderRadius.circular(4),
                   ),
                  child: IconButton(
                    icon: const Icon(Icons.home_rounded),
                    color: EarthyTheme.textSecondary,
                    onPressed: onHomePressed,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Default: show button grid
    return _buildDefaultButtonGrid(context);
  }

  Widget _buildDefaultButtonGrid(BuildContext context) {
    // Icon mapping for each app
    final Map<String, IconData> appIcons = {
      'Timer': Icons.access_time_rounded,
      'Weather': Icons.wb_sunny_rounded,
      'Media': Icons.music_note_rounded,
      'Notes': Icons.note_rounded,
      'Settings': Icons.settings_rounded,
    };

    // home always first settings always last
    final List<String> orderedApps = List<String>.from(availableApps);
    if (orderedApps.contains('Settings')) {
      orderedApps.remove('Settings');
      orderedApps.add('Settings');
    }
    final List<String> allButtons = ['Home', ...orderedApps];

    return Container(
      width: ScreenConfig.bottomScreenWidth,
      height: ScreenConfig.bottomScreenHeight,
      color: EarthyTheme.surface,
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.0, // square buttons
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          if (index >= allButtons.length) {
            return const SizedBox.shrink();
          }
          
          final appName = allButtons[index];
          
          // Home button is first (index 0)
          if (appName == 'Home') {
            return ControlButton(
              label: 'Home',
              icon: Icons.home_rounded,
              backgroundColor: EarthyTheme.bark,
              onPressed: onHomePressed,
            );
          }
          
          return ControlButton(
            label: appName,
            icon: appIcons[appName] ?? Icons.apps,
            backgroundColor: EarthyTheme.buttonColors[(index - 1) % EarthyTheme.buttonColors.length],
            onPressed: () {
              onAppSelected(appName);
            },
          );
        },
      ),
    );
  }
}
