import 'dart:convert';

/// Callback signature for handling incoming [IpcMessage]s.
typedef IpcMessageHandler = void Function(IpcMessage message);

/// A JSON-serialisable message exchanged between the top and bottom windows.
///
/// Messages are encoded as single-line JSON terminated by `\n` so that
/// they can be framed trivially over a TCP stream.
///
/// Direction conventions:
///   bottom → top : selectApp, home, timerSelection, timerStart, timerPause, timerReset
///   top → bottom : appChanged
class IpcMessage {
  const IpcMessage({required this.type, this.payload});

  final String type;
  final Map<String, dynamic>? payload;

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  factory IpcMessage.fromJson(Map<String, dynamic> json) {
    return IpcMessage(
      type: json['type'] as String,
      payload: json['payload'] != null
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        if (payload != null) 'payload': payload,
      };

  /// Encode to a newline-delimited JSON string ready for the wire.
  String encode() => '${jsonEncode(toJson())}\n';

  /// Decode a single line of text into an [IpcMessage], or `null` on failure.
  static IpcMessage? decode(String line) {
    try {
      final trimmed = line.trim();
      if (trimmed.isEmpty) return null;
      final json = jsonDecode(trimmed);
      if (json is Map<String, dynamic>) {
        return IpcMessage.fromJson(json);
      }
    } catch (_) {}
    return null;
  }

  // ---------------------------------------------------------------------------
  // Named constructors for every message type
  // ---------------------------------------------------------------------------

  /// Bottom → Top: user selected an app.
  factory IpcMessage.selectApp(String appName) => IpcMessage(
        type: 'selectApp',
        payload: {'appName': appName},
      );

  /// Bottom → Top: user pressed the home button.
  factory IpcMessage.home() => const IpcMessage(type: 'home');

  /// Bottom → Top: timer wheel values changed.
  factory IpcMessage.timerSelection({
    required int hours,
    required int minutes,
    required int seconds,
  }) =>
      IpcMessage(
        type: 'timerSelection',
        payload: {
          'hours': hours,
          'minutes': minutes,
          'seconds': seconds,
        },
      );

  /// Bottom → Top: start the timer.
  factory IpcMessage.timerStart() => const IpcMessage(type: 'timerStart');

  /// Bottom → Top: pause the timer.
  factory IpcMessage.timerPause() => const IpcMessage(type: 'timerPause');

  /// Bottom → Top: reset the timer.
  factory IpcMessage.timerReset() => const IpcMessage(type: 'timerReset');

  /// Top → Bottom: the currently-active app changed.
  factory IpcMessage.appChanged(String appKey) => IpcMessage(
        type: 'appChanged',
        payload: {'currentAppKey': appKey},
      );

  @override
  String toString() => 'IpcMessage($type, $payload)';
}
