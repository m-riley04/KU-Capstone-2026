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
    return const Center(
      child: Icon(Icons.image_not_supported_outlined, color: Colors.white54),
    );
  }

  return Container();
}