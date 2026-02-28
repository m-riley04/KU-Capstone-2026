import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'ipc_message.dart';

/// TCP client that runs inside the **bottom-window** process.
///
/// It connects to the top-window's [IpcServer] on `localhost:<port>`.
/// Incoming newline-delimited JSON messages are forwarded to [onMessage].
/// Use [send] to push a message to the server (the top window).
///
/// The client will automatically attempt to reconnect if the connection drops.
class IpcClient {
  IpcClient({
    this.host = '127.0.0.1',
    this.port = 9473,
    this.reconnectDelay = const Duration(seconds: 2),
  });

  final String host;
  final int port;
  final Duration reconnectDelay;

  Socket? _socket;
  bool _disposed = false;

  /// Called for every valid message received from the server.
  IpcMessageHandler? onMessage;

  final StreamController<bool> _connectedController =
      StreamController<bool>.broadcast();

  /// Emits `true` on connect, `false` on disconnect.
  Stream<bool> get onConnectionChanged => _connectedController.stream;

  /// Whether the client is currently connected to the server.
  bool get isConnected => _socket != null;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Initiate a connection to the server.  If the server is not yet available
  /// the client retries after [reconnectDelay].
  Future<void> connect() async {
    if (_disposed) return;

    try {
      _socket = await Socket.connect(host, port);
      _connectedController.add(true);
      if (kDebugMode) {
        print('[IpcClient] connected to $host:$port');
      }

      final buffer = StringBuffer();

      _socket!.cast<List<int>>().transform(utf8.decoder).listen(
        (data) {
          buffer.write(data);
          final content = buffer.toString();
          final lines = content.split('\n');

          for (int i = 0; i < lines.length - 1; i++) {
            final msg = IpcMessage.decode(lines[i]);
            if (msg != null) {
              onMessage?.call(msg);
            }
          }

          buffer.clear();
          buffer.write(lines.last);
        },
        onDone: () {
          _socket = null;
          _connectedController.add(false);
          if (kDebugMode) {
            print('[IpcClient] disconnected');
          }
          _scheduleReconnect();
        },
        onError: (_) {
          _socket = null;
          _connectedController.add(false);
          _scheduleReconnect();
        },
      );
    } catch (_) {
      _socket = null;
      _connectedController.add(false);
      if (kDebugMode) {
        print('[IpcClient] connection failed, retrying in '
            '${reconnectDelay.inSeconds}s …');
      }
      _scheduleReconnect();
    }
  }

  /// Close the connection and stop any reconnect attempts.
  Future<void> dispose() async {
    _disposed = true;
    await _socket?.close();
    _socket = null;
    await _connectedController.close();
  }

  // ---------------------------------------------------------------------------
  // Outgoing
  // ---------------------------------------------------------------------------

  /// Send [message] to the server.  Silently ignored when disconnected.
  void send(IpcMessage message) {
    if (_socket == null) return;
    try {
      _socket!.add(utf8.encode(message.encode()));
    } catch (_) {
      _socket = null;
      _scheduleReconnect();
    }
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  void _scheduleReconnect() {
    if (_disposed) return;
    Future.delayed(reconnectDelay, () {
      if (!_disposed && _socket == null) {
        connect();
      }
    });
  }
}
