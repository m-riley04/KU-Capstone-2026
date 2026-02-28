/// IPC (Inter-Process Communication) layer for the Polypod dual-window
/// architecture.
///
/// The top-window process runs an [IpcServer] and the bottom-window process
/// connects to it via an [IpcClient].  Messages are newline-delimited JSON
/// transmitted over a TCP socket on `localhost`.
///
/// See [IpcMessage] for the message catalogue.
library;

export 'ipc_message.dart';
export 'ipc_server.dart';
export 'ipc_client.dart';
