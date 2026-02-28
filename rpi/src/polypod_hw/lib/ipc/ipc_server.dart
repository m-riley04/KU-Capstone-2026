import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'ipc_message.dart';

/// TCP server that runs inside the **top-window** process.
///
/// It listens on `localhost:<port>` and accepts connections from the
/// bottom-window process.  Incoming newline-delimited JSON messages are
/// parsed and forwarded to [onMessage].  Use [broadcast] to push a
/// message to every connected client (i.e. the bottom window).
class IpcServer {
  IpcServer({this.port = 9473});

  final int port;

  ServerSocket? _server;
  final List<Socket> _clients = [];

  /// Called for every valid message received from a client.
  IpcMessageHandler? onMessage;

  final StreamController<bool> _connectedController =
      StreamController<bool>.broadcast();

  /// Emits `true` when a client connects, `false` when one disconnects.
  Stream<bool> get onConnectionChanged => _connectedController.stream;

  /// Whether at least one client is currently connected.
  bool get hasClients => _clients.isNotEmpty;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Bind the server socket and start accepting connections.
  ///
  /// If the port is still held by a stale process (e.g. a zombie from a
  /// previous run), we attempt to free it with `fuser -k` and retry once.
  Future<void> start() async {
    try {
      _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
    } on SocketException {
      // Port likely held by a stale process — try to reclaim it.
      if (kDebugMode) {
        print('[IpcServer] port $port busy, attempting to free it…');
      }
      try {
        await Process.run('fuser', ['-k', '$port/tcp']);
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 500));
      _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
    }
    _server!.listen(_handleConnection);
    if (kDebugMode) {
      print('[IpcServer] listening on 127.0.0.1:$port');
    }
  }

  /// Close all client connections and the server socket.
  Future<void> dispose() async {
    for (final client in List.of(_clients)) {
      try {
        await client.close();
      } catch (_) {}
    }
    _clients.clear();
    await _server?.close();
    _server = null;
    await _connectedController.close();
  }

  // ---------------------------------------------------------------------------
  // Outgoing
  // ---------------------------------------------------------------------------

  /// Send [message] to every connected client.
  void broadcast(IpcMessage message) {
    final encoded = utf8.encode(message.encode());
    for (final client in List.of(_clients)) {
      try {
        client.add(encoded);
      } catch (_) {
        _clients.remove(client);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  void _handleConnection(Socket client) {
    _clients.add(client);
    _connectedController.add(true);
    if (kDebugMode) {
      print('[IpcServer] client connected '
          '(${client.remoteAddress.address}:${client.remotePort})');
    }

    final buffer = StringBuffer();

    client.cast<List<int>>().transform(utf8.decoder).listen(
      (data) {
        buffer.write(data);
        final content = buffer.toString();
        final lines = content.split('\n');

        // Process every complete line (all but the last fragment).
        for (int i = 0; i < lines.length - 1; i++) {
          final msg = IpcMessage.decode(lines[i]);
          if (msg != null) {
            onMessage?.call(msg);
          }
        }

        // Keep any incomplete trailing fragment.
        buffer.clear();
        buffer.write(lines.last);
      },
      onDone: () {
        _clients.remove(client);
        _connectedController.add(false);
        if (kDebugMode) {
          print('[IpcServer] client disconnected');
        }
      },
      onError: (_) {
        _clients.remove(client);
        _connectedController.add(false);
      },
    );
  }
}
