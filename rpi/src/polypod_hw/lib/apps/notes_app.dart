import 'package:flutter/material.dart';
import 'base_app.dart';
import '../config/theme_config.dart';

class NotesApp extends BaseApp {
  const NotesApp({super.key});

  @override
  String get appName => 'Notes';

  @override
  State<NotesApp> createState() => _NotesAppState();
}

class _NotesAppState extends State<NotesApp> {
  final List<String> _notes = [
    'Meeting at 3 PM',
    'Buy groceries',
    'Call mom',
  ];

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
                Icons.note_rounded,
                size: 40,
                color: EarthyTheme.moss,
              ),
              const SizedBox(width: 15),
              Text(
                'Notes',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: EarthyTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Expanded(
            child: ListView.builder(
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: EarthyTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _notes[index],
                      style: TextStyle(
                        fontSize: 16,
                        color: EarthyTheme.textPrimary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
