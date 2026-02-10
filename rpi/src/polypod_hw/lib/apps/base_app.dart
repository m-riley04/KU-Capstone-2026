import 'package:flutter/material.dart';

/// base class for all top screen applications / animations
abstract class BaseApp extends StatefulWidget {
  const BaseApp({super.key});

  String get appName;

  /// apps can optionally provide custom content for the bottom screen
  Widget? buildBottomScreenContent(BuildContext context) => null;
  
  /// if bottom screen is customized, should there be a back button?
  /// default yes
  bool get showBackButtonWithCustomBottom => true;
}
