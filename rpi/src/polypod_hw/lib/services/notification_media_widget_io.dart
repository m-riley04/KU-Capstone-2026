import 'dart:io';

import 'package:flutter/material.dart';

Widget buildNotificationMediaWidget(String media) {
  if (media.startsWith('http://') || media.startsWith('https://')) {
    return Image.network(
      media,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(Icons.error, color: Colors.red),
        );
      },
    );
  }

  if (media.isNotEmpty) {
    return Image.file(
      File(media),
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