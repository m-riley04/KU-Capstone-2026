export 'multi_window_stub.dart';

import 'multi_window_stub.dart';
import 'multi_window_stub.dart'
    if (dart.library.io) 'multi_window_desktop.dart' as impl;

PolypodMultiWindow createMultiWindow() => impl.createMultiWindowImpl();
