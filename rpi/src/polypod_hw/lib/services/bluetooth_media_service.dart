import 'dart:convert';

import 'package:http/http.dart' as http;

class BluetoothMediaState {
  const BluetoothMediaState({
    required this.connected,
    required this.isPlaying,
    required this.status,
    required this.title,
    required this.artist,
    required this.album,
    required this.player,
  });

  final bool connected;
  final bool isPlaying;
  final String status;
  final String title;
  final String artist;
  final String album;
  final String? player;

  factory BluetoothMediaState.fromJson(Map<String, dynamic> json) {
    return BluetoothMediaState(
      connected: json['connected'] == true,
      isPlaying: json['is_playing'] == true,
      status: (json['status'] as String? ?? 'disconnected').trim(),
      title: (json['title'] as String? ?? '').trim(),
      artist: (json['artist'] as String? ?? '').trim(),
      album: (json['album'] as String? ?? '').trim(),
      player: json['player'] as String?,
    );
  }

  factory BluetoothMediaState.disconnected() {
    return const BluetoothMediaState(
      connected: false,
      isPlaying: false,
      status: 'disconnected',
      title: '',
      artist: '',
      album: '',
      player: null,
    );
  }
}

class BluetoothMediaService {
  BluetoothMediaService({
    String baseUrl = 'http://127.0.0.1:8765',
    http.Client? client,
  }) : _baseUri = Uri.parse(baseUrl),
       _client = client ?? http.Client();

  final Uri _baseUri;
  final http.Client _client;

  Future<BluetoothMediaState> fetchState() async {
    final response = await _client
        .get(_baseUri.resolve('/state'))
        .timeout(const Duration(milliseconds: 1500));

    if (response.statusCode != 200) {
      throw Exception('Bridge returned ${response.statusCode} for /state');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected /state response payload');
    }

    return BluetoothMediaState.fromJson(decoded);
  }

  Future<void> play() => _post('/play');

  Future<void> pause() => _post('/pause');

  Future<void> next() => _post('/next');

  Future<void> previous() => _post('/previous');

  Future<void> _post(String endpoint) async {
    final response = await _client
        .post(_baseUri.resolve(endpoint))
        .timeout(const Duration(milliseconds: 1500));

    if (response.statusCode >= 400) {
      String errorMessage = 'Bridge command failed: ${response.statusCode}';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['error'] is String) {
          errorMessage = decoded['error'] as String;
        }
      } catch (_) {
        // Keep fallback error message if JSON parsing fails.
      }

      throw Exception(errorMessage);
    }
  }
}
