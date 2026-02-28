/// IPC network configuration constants.
///
/// The port can be overridden at runtime via the `POLYPOD_IPC_PORT`
/// environment variable.
class IpcConfig {
  IpcConfig._();

  /// Default TCP port used for top ↔ bottom window communication.
  static const int defaultPort = 9473;

  /// Resolve the port, preferring the environment variable if set.
  static int get port {
    final env = const String.fromEnvironment('POLYPOD_IPC_PORT');
    if (env.isNotEmpty) {
      final parsed = int.tryParse(env);
      if (parsed != null && parsed > 0 && parsed < 65536) return parsed;
    }
    return defaultPort;
  }
}
