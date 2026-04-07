import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'base_app.dart';
import '../config/theme_config.dart';

class SettingsAppBridge {
  void Function(String action, Map<String, dynamic> payload)? _actionHandler;
  void Function(Map<String, dynamic> state)? onStateChanged;
  Map<String, dynamic> _latestState = const {};

  Map<String, dynamic> get latestState => _latestState;

  void bindActionHandler(
    void Function(String action, Map<String, dynamic> payload) handler,
  ) {
    _actionHandler = handler;
  }

  void unbindActionHandler() {
    _actionHandler = null;
  }

  void sendAction(String action, [Map<String, dynamic> payload = const {}]) {
    _actionHandler?.call(action, payload);
  }

  void publishState(Map<String, dynamic> state) {
    _latestState = Map<String, dynamic>.from(state);
    onStateChanged?.call(_latestState);
  }
}

enum _BottomInputMode { idle, keyboard, numberPad, slider, network, confirm }

enum _SettingsPanel { none, brightness, volume, network, about, quit }

class _BottomInputController extends ChangeNotifier {
  _BottomInputMode mode = _BottomInputMode.idle;
  String title = 'Input';
  String helper = '';
  double sliderValue = 0;
  double sliderMin = 0;
  double sliderMax = 100;
  String sliderUnit = '%';
  String primaryActionLabel = 'Save';
  List<String> networkOptions = const [];
  String? selectedNetwork;

  VoidCallback? _onBackspace;
  VoidCallback? _onClear;
  void Function(String value)? _onKey;
  VoidCallback? _onDone;
  ValueChanged<double>? _onSliderChanged;
  VoidCallback? _onPrimaryAction;
  VoidCallback? _onSecondaryAction;
  VoidCallback? _onRefreshNetworks;
  ValueChanged<String>? _onSelectNetwork;
  VoidCallback? _onConnectNetwork;
  VoidCallback? _onEditNetworkPassword;

  void activate({
    required _BottomInputMode nextMode,
    required String nextTitle,
    required String nextHelper,
    required VoidCallback onBackspace,
    required VoidCallback onClear,
    required void Function(String value) onKey,
    required VoidCallback onDone,
  }) {
    mode = nextMode;
    title = nextTitle;
    helper = nextHelper;
    _onBackspace = onBackspace;
    _onClear = onClear;
    _onKey = onKey;
    _onDone = onDone;
    notifyListeners();
  }

  void deactivate() {
    mode = _BottomInputMode.idle;
    title = 'Input';
    helper = '';
    _onSliderChanged = null;
    _onPrimaryAction = null;
    _onSecondaryAction = null;
    _onRefreshNetworks = null;
    _onSelectNetwork = null;
    _onConnectNetwork = null;
    _onEditNetworkPassword = null;
    notifyListeners();
  }

  void activateSlider({
    required String nextTitle,
    required String nextHelper,
    required double initialValue,
    required double min,
    required double max,
    required String unit,
    required String primaryLabel,
    required ValueChanged<double> onChanged,
    required VoidCallback onPrimary,
    VoidCallback? onSecondary,
  }) {
    mode = _BottomInputMode.slider;
    title = nextTitle;
    helper = nextHelper;
    sliderValue = initialValue;
    sliderMin = min;
    sliderMax = max;
    sliderUnit = unit;
    primaryActionLabel = primaryLabel;
    _onSliderChanged = onChanged;
    _onPrimaryAction = onPrimary;
    _onSecondaryAction = onSecondary;
    notifyListeners();
  }

  void activateNetwork({
    required String nextTitle,
    required String nextHelper,
    required List<String> options,
    required String? selected,
    required VoidCallback onRefresh,
    required ValueChanged<String> onSelect,
    required VoidCallback onConnect,
    required VoidCallback onEditPassword,
  }) {
    mode = _BottomInputMode.network;
    title = nextTitle;
    helper = nextHelper;
    networkOptions = options;
    selectedNetwork = selected;
    _onRefreshNetworks = onRefresh;
    _onSelectNetwork = onSelect;
    _onConnectNetwork = onConnect;
    _onEditNetworkPassword = onEditPassword;
    notifyListeners();
  }

  void activateConfirm({
    required String nextTitle,
    required String nextHelper,
    required String confirmLabel,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
  }) {
    mode = _BottomInputMode.confirm;
    title = nextTitle;
    helper = nextHelper;
    primaryActionLabel = confirmLabel;
    _onPrimaryAction = onConfirm;
    _onSecondaryAction = onCancel;
    notifyListeners();
  }

  void addCharacter(String value) {
    _onKey?.call(value);
  }

  void backspace() {
    _onBackspace?.call();
  }

  void clear() {
    _onClear?.call();
  }

  void done() {
    _onDone?.call();
  }

  void updateSlider(double value) {
    sliderValue = value;
    _onSliderChanged?.call(value);
    notifyListeners();
  }

  void primaryAction() {
    _onPrimaryAction?.call();
  }

  void secondaryAction() {
    _onSecondaryAction?.call();
  }

  void refreshNetworks() {
    _onRefreshNetworks?.call();
  }

  void selectNetwork(String value) {
    selectedNetwork = value;
    _onSelectNetwork?.call(value);
    notifyListeners();
  }

  void connectNetwork() {
    _onConnectNetwork?.call();
  }

  void editNetworkPassword() {
    _onEditNetworkPassword?.call();
  }
}

class SettingsApp extends BaseApp {
  SettingsApp({super.key, this.bridge});

  final _BottomInputController _bottomInputController =
      _BottomInputController();
  final SettingsAppBridge? bridge;

  @override
  String get appName => 'Settings';

  @override
  Widget? buildBottomScreenContent(BuildContext context) {
    return _SettingsBottomInputPanel(controller: _bottomInputController);
  }

  @override
  State<SettingsApp> createState() => _SettingsAppState();
}

class _SettingsAppState extends State<SettingsApp> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _wifiPasswordController = TextEditingController();
  bool _isLoadingUserId = true;
  bool _isSavingUserId = false;
  String _userIdStatus = '';

  bool _isLoadingBrightness = true;
  bool _isLoadingVolume = true;
  bool _isLoadingNetwork = true;

  double _brightnessPercent = 75;
  double _volumePercent = 55;
  double _brightnessDraft = 75;
  double _volumeDraft = 55;
  String _networkIpAddress = 'Unknown';
  String _networkStatus = 'Not checked';
  List<String> _wifiNetworks = const [];
  String? _selectedSsid;
  String _brightnessStatus = '';
  String _volumeStatus = '';
  String _deviceHostname = 'Loading...';
  String _deviceOsName = 'Loading...';
  _SettingsPanel _activePanel = _SettingsPanel.none;

  TextEditingController? _activeBottomInput;
  VoidCallback? _activeBottomInputOnChange;
  VoidCallback? _activeBottomInputOnDone;
  String _lastBridgeStateHash = '';

  @override
  void initState() {
    super.initState();
    widget.bridge?.bindActionHandler(_handleBridgeAction);
    _loadUserId();
    _loadBrightness();
    _loadVolume();
    _refreshNetworkState();
    _loadDeviceInfo();
  }

  @override
  void dispose() {
    widget.bridge?.unbindActionHandler();
    widget._bottomInputController.deactivate();
    _userIdController.dispose();
    _wifiPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _emitBridgeState();
      }
    });
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: EarthyTheme.background,
          padding: const EdgeInsets.all(24),
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.settings_rounded,
                          size: 40,
                          color: EarthyTheme.clay,
                        ),
                        const SizedBox(width: 15),
                        Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: EarthyTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildUserIdSetting(),
                    _buildActiveTopPanel(),
                    _buildSettingItem(
                      'Display Brightness',
                      Icons.brightness_6_rounded,
                      subtitle: _isLoadingBrightness
                          ? 'Detecting current brightness...'
                          : 'Current: ${_brightnessPercent.round()}%',
                      onTap: _showBrightnessPanel,
                    ),
                    _buildSettingItem(
                      'Volume',
                      Icons.volume_up_rounded,
                      subtitle: _isLoadingVolume
                          ? 'Detecting current volume...'
                          : 'Current: ${_volumePercent.round()}%',
                      onTap: _showVolumePanel,
                    ),
                    _buildSettingItem(
                      'Network',
                      Icons.wifi_rounded,
                      subtitle: 'IP: $_networkIpAddress',
                      onTap: _showNetworkPanel,
                    ),
                    _buildSettingItem(
                      'About Device',
                      Icons.info_outline_rounded,
                      subtitle: 'System and runtime information',
                      onTap: _showAboutPanel,
                    ),
                    _buildSettingItem(
                      'Quit Polypod',
                      Icons.exit_to_app_rounded,
                      subtitle: 'Close the application safely',
                      onTap: _showQuitPanel,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _emitBridgeState() {
    final bridge = widget.bridge;
    if (bridge == null) {
      return;
    }

    final state = <String, dynamic>{
      'activePanel': _activePanel.name,
      'bottomMode': widget._bottomInputController.mode.name,
      'bottomTitle': widget._bottomInputController.title,
      'bottomHelper': widget._bottomInputController.helper,
      'bottomPrimaryActionLabel':
          widget._bottomInputController.primaryActionLabel,
      'brightnessPercent': _brightnessPercent,
      'brightnessDraft': _brightnessDraft,
      'brightnessStatus': _brightnessStatus,
      'volumePercent': _volumePercent,
      'volumeDraft': _volumeDraft,
      'volumeStatus': _volumeStatus,
      'sliderValue': widget._bottomInputController.sliderValue,
      'sliderMin': widget._bottomInputController.sliderMin,
      'sliderMax': widget._bottomInputController.sliderMax,
      'sliderUnit': widget._bottomInputController.sliderUnit,
      'networkIpAddress': _networkIpAddress,
      'networkStatus': _networkStatus,
      'wifiNetworks': _wifiNetworks,
      'selectedSsid': _selectedSsid,
      'passwordMasked': _wifiPasswordController.text.isEmpty
          ? '(not set)'
          : '*' * _wifiPasswordController.text.length,
      'deviceHostname': _deviceHostname,
      'deviceOsName': _deviceOsName,
    };

    final hash = jsonEncode(state);
    if (hash == _lastBridgeStateHash) {
      return;
    }

    _lastBridgeStateHash = hash;
    bridge.publishState(state);
  }

  void _handleBridgeAction(String action, Map<String, dynamic> payload) {
    switch (action) {
      case 'selectPanel':
        final panel = payload['panel']?.toString() ?? '';
        if (panel == 'brightness') {
          _showBrightnessPanel();
        } else if (panel == 'volume') {
          _showVolumePanel();
        } else if (panel == 'network') {
          _showNetworkPanel();
        } else if (panel == 'about') {
          _showAboutPanel();
        } else if (panel == 'quit') {
          _showQuitPanel();
        }
        return;
      case 'closePanel':
        _clearSelectionPanel();
        return;
      case 'sliderChanged':
        final value = (payload['value'] as num?)?.toDouble();
        if (value == null) {
          return;
        }
        if (_activePanel == _SettingsPanel.brightness) {
          setState(() {
            _brightnessDraft = value;
          });
        } else if (_activePanel == _SettingsPanel.volume) {
          setState(() {
            _volumeDraft = value;
          });
        }
        return;
      case 'saveSlider':
        if (_activePanel == _SettingsPanel.brightness) {
          _saveBrightnessFromBottom();
        } else if (_activePanel == _SettingsPanel.volume) {
          _saveVolumeFromBottom();
        }
        return;
      case 'networkSelect':
        final ssid = payload['ssid']?.toString();
        if (ssid != null && ssid.isNotEmpty) {
          setState(() {
            _selectedSsid = ssid;
          });
          _activateNetworkControls();
        }
        return;
      case 'networkScan':
        _refreshNetworkFromBottom();
        return;
      case 'networkConnect':
        _connectNetworkFromBottom();
        return;
      case 'networkPassword':
        _openWifiPasswordKeyboard();
        return;
      case 'inputKey':
        final value = payload['value']?.toString() ?? '';
        if (value.isNotEmpty) {
          _handleBottomInputKey(value);
        }
        return;
      case 'inputBackspace':
        _handleBottomInputBackspace();
        return;
      case 'inputClear':
        _handleBottomInputClear();
        return;
      case 'inputDone':
        _deactivateBottomInput();
        return;
      case 'quitConfirm':
        SystemNavigator.pop();
        exit(0);
        return;
      case 'quitCancel':
        _clearSelectionPanel();
        return;
    }
  }

  Widget _buildUserIdSetting() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: EarthyTheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  color: EarthyTheme.textSecondary,
                ),
                const SizedBox(width: 15),
                Text(
                  'Notification User ID',
                  style: TextStyle(
                    fontSize: 16,
                    color: EarthyTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _userIdController,
              readOnly: true,
              onTap: () {
                _activateBottomInput(
                  mode: _BottomInputMode.numberPad,
                  title: 'Notification User ID',
                  helper: 'Use the number pad below to enter your user ID.',
                  controller: _userIdController,
                );
              },
              enabled: !_isLoadingUserId && !_isSavingUserId,
              style: TextStyle(color: EarthyTheme.textPrimary),
              decoration: InputDecoration(
                hintText: _isLoadingUserId ? 'Loading...' : 'Enter user id',
                hintStyle: TextStyle(color: EarthyTheme.textSecondary),
                filled: true,
                fillColor: EarthyTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: EarthyTheme.textSecondary.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: EarthyTheme.textSecondary.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: EarthyTheme.clay),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: (_isLoadingUserId || _isSavingUserId)
                      ? null
                      : _saveUserId,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EarthyTheme.clay,
                    foregroundColor: Colors.white,
                  ),
                  icon: _isSavingUserId
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_isSavingUserId ? 'Saving...' : 'Save User ID'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: (_isLoadingUserId || _isSavingUserId)
                      ? null
                      : () {
                          _activateBottomInput(
                            mode: _BottomInputMode.numberPad,
                            title: 'Notification User ID',
                            helper:
                                'Use the number pad below to enter your user ID.',
                            controller: _userIdController,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EarthyTheme.moss,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.dialpad_rounded),
                  label: const Text('Numpad'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _userIdStatus,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: EarthyTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadUserId() async {
    try {
      final settingsFile = File(_notificationSettingsPath());
      if (await settingsFile.exists()) {
        final raw = await settingsFile.readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final savedUserId = decoded['user_id']?.toString() ?? '';
          if (mounted) {
            _userIdController.text = savedUserId;
          }
        }
      }
      if (mounted) {
        setState(() {
          _isLoadingUserId = false;
          _userIdStatus = 'Loaded from notification settings file.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUserId = false;
          _userIdStatus = 'Could not load user id.';
        });
      }
    }
  }

  Future<void> _loadBrightness() async {
    final data = await _readBrightnessPercent();
    if (!mounted) {
      return;
    }
    setState(() {
      _brightnessPercent = data ?? _brightnessPercent;
      _brightnessDraft = _brightnessPercent;
      _isLoadingBrightness = false;
    });
  }

  Future<void> _loadVolume() async {
    final data = await _readVolumePercent();
    if (!mounted) {
      return;
    }
    setState(() {
      _volumePercent = data ?? _volumePercent;
      _volumeDraft = _volumePercent;
      _isLoadingVolume = false;
    });
  }

  Future<void> _refreshNetworkState() async {
    final networkList = await _scanWifiNetworks();
    final ip = await _readIpAddress();
    if (!mounted) {
      return;
    }
    setState(() {
      _wifiNetworks = networkList;
      _selectedSsid = networkList.isEmpty
          ? null
          : (_selectedSsid ?? networkList.first);
      _networkIpAddress = ip;
      _networkStatus = networkList.isEmpty
          ? 'No nearby Wi-Fi networks found.'
          : 'Found ${networkList.length} network(s).';
      _isLoadingNetwork = false;
    });
  }

  Future<void> _loadDeviceInfo() async {
    final hostname = (await _runCommand(
      'hostname',
      const [],
    ))?.stdout?.toString().trim();
    String osName = 'Unknown Linux';
    try {
      final osRelease = File('/etc/os-release');
      if (await osRelease.exists()) {
        final content = await osRelease.readAsString();
        final match = RegExp(r'PRETTY_NAME="([^"]+)"').firstMatch(content);
        if (match != null) {
          osName = match.group(1) ?? osName;
        }
      }
    } catch (_) {
      osName = 'Unknown Linux';
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _deviceHostname = hostname?.isNotEmpty == true
          ? hostname!
          : 'Unavailable';
      _deviceOsName = osName;
    });
  }

  void _showBrightnessPanel() {
    _deactivateBottomInput();
    setState(() {
      _activePanel = _SettingsPanel.brightness;
      _brightnessDraft = _brightnessPercent;
      _brightnessStatus = '';
    });
    widget._bottomInputController.activateSlider(
      nextTitle: 'Display Brightness',
      nextHelper: 'Adjust, then save.',
      initialValue: _brightnessDraft,
      min: 1,
      max: 100,
      unit: '%',
      primaryLabel: 'Save Brightness',
      onChanged: (value) {
        setState(() {
          _brightnessDraft = value;
        });
      },
      onPrimary: _saveBrightnessFromBottom,
      onSecondary: _clearSelectionPanel,
    );
  }

  void _showVolumePanel() {
    _deactivateBottomInput();
    setState(() {
      _activePanel = _SettingsPanel.volume;
      _volumeDraft = _volumePercent;
      _volumeStatus = '';
    });
    widget._bottomInputController.activateSlider(
      nextTitle: 'Volume',
      nextHelper: 'Adjust, then save.',
      initialValue: _volumeDraft,
      min: 0,
      max: 100,
      unit: '%',
      primaryLabel: 'Save Volume',
      onChanged: (value) {
        setState(() {
          _volumeDraft = value;
        });
      },
      onPrimary: _saveVolumeFromBottom,
      onSecondary: _clearSelectionPanel,
    );
  }

  void _showNetworkPanel() {
    _deactivateBottomInput();
    setState(() {
      _activePanel = _SettingsPanel.network;
      _networkStatus = _isLoadingNetwork
          ? 'Loading network state...'
          : _networkStatus;
    });
    _activateNetworkControls();
  }

  void _showAboutPanel() {
    _deactivateBottomInput();
    setState(() {
      _activePanel = _SettingsPanel.about;
    });
    widget._bottomInputController.deactivate();
  }

  void _showQuitPanel() {
    _deactivateBottomInput();
    setState(() {
      _activePanel = _SettingsPanel.quit;
    });
    widget._bottomInputController.activateConfirm(
      nextTitle: 'Quit Polypod',
      nextHelper: 'Confirm to close the app.',
      confirmLabel: 'Quit Now',
      onConfirm: () {
        SystemNavigator.pop();
        exit(0);
      },
      onCancel: _clearSelectionPanel,
    );
  }

  void _clearSelectionPanel() {
    _deactivateBottomInput();
    setState(() {
      _activePanel = _SettingsPanel.none;
    });
    widget._bottomInputController.deactivate();
  }

  Future<void> _saveBrightnessFromBottom() async {
    final success = await _setBrightnessPercent(_brightnessDraft);
    if (!mounted) {
      return;
    }
    setState(() {
      if (success) {
        _brightnessPercent = _brightnessDraft;
      }
      _brightnessStatus = success
          ? 'Brightness updated to ${_brightnessPercent.round()}%.'
          : 'Unable to update brightness.';
    });
  }

  Future<void> _saveVolumeFromBottom() async {
    final success = await _setVolumePercent(_volumeDraft);
    if (!mounted) {
      return;
    }
    setState(() {
      if (success) {
        _volumePercent = _volumeDraft;
      }
      _volumeStatus = success
          ? 'Volume updated to ${_volumePercent.round()}%.'
          : 'Unable to update volume.';
    });
  }

  void _activateNetworkControls() {
    widget._bottomInputController.activateNetwork(
      nextTitle: 'Network Controls',
      nextHelper: 'Select Wi-Fi and connect using controls below.',
      options: _wifiNetworks,
      selected: _selectedSsid,
      onRefresh: _refreshNetworkFromBottom,
      onSelect: (value) {
        setState(() {
          _selectedSsid = value;
        });
      },
      onConnect: _connectNetworkFromBottom,
      onEditPassword: _openWifiPasswordKeyboard,
    );
  }

  Future<void> _refreshNetworkFromBottom() async {
    setState(() {
      _networkStatus = 'Scanning for nearby networks...';
    });
    await _refreshNetworkState();
    if (mounted) {
      _activateNetworkControls();
    }
  }

  Future<void> _connectNetworkFromBottom() async {
    final ssid = _selectedSsid;
    if (ssid == null || ssid.isEmpty) {
      setState(() {
        _networkStatus = 'Select a network first.';
      });
      return;
    }

    setState(() {
      _networkStatus = 'Connecting to $ssid...';
    });

    final success = await _connectToWifi(
      ssid: ssid,
      password: _wifiPasswordController.text,
    );
    final updatedIp = await _readIpAddress();
    if (!mounted) {
      return;
    }

    setState(() {
      _networkIpAddress = updatedIp;
      _networkStatus = success
          ? 'Connected to $ssid.'
          : 'Failed to connect to $ssid.';
    });
    _activateNetworkControls();
  }

  void _openWifiPasswordKeyboard() {
    _activateBottomInput(
      mode: _BottomInputMode.keyboard,
      title: 'Wi-Fi Password',
      helper: 'Enter password. DONE returns to network controls.',
      controller: _wifiPasswordController,
      onDone: () {
        if (_activePanel == _SettingsPanel.network) {
          _activateNetworkControls();
        }
      },
    );
  }

  Widget _buildActiveTopPanel() {
    if (_activePanel == _SettingsPanel.none) {
      return const SizedBox.shrink();
    }

    String title;
    Widget content;
    switch (_activePanel) {
      case _SettingsPanel.brightness:
        title = 'Brightness';
        content = Text(
          _brightnessStatus.isNotEmpty
              ? _brightnessStatus
              : 'Current: ${_brightnessPercent.round()}% | Pending: ${_brightnessDraft.round()}%',
          style: TextStyle(
            fontSize: 13,
            color: EarthyTheme.textSecondary,
            height: 1.35,
          ),
        );
        break;
      case _SettingsPanel.volume:
        title = 'Volume';
        content = Text(
          _volumeStatus.isNotEmpty
              ? _volumeStatus
              : 'Current: ${_volumePercent.round()}% | Pending: ${_volumeDraft.round()}%',
          style: TextStyle(
            fontSize: 13,
            color: EarthyTheme.textSecondary,
            height: 1.35,
          ),
        );
        break;
      case _SettingsPanel.network:
        final masked = _wifiPasswordController.text.isEmpty
            ? '(not set)'
            : '*' * _wifiPasswordController.text.length;
        title = 'Network';
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'IP: $_networkIpAddress',
              style: TextStyle(fontSize: 13, color: EarthyTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            _buildTopReadOnlyField('SSID', _selectedSsid ?? '(none selected)'),
            const SizedBox(height: 8),
            _buildTopReadOnlyField('Password', masked),
            const SizedBox(height: 8),
            Text(
              'Status: $_networkStatus',
              style: TextStyle(
                fontSize: 13,
                color: EarthyTheme.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        );
        break;
      case _SettingsPanel.about:
        title = 'About Device';
        content = Text(
          'Hostname: $_deviceHostname\n'
          'Operating System: $_deviceOsName\n'
          'IP Address: $_networkIpAddress\n'
          'App: Polypod Hardware UI',
          style: TextStyle(
            fontSize: 13,
            color: EarthyTheme.textSecondary,
            height: 1.35,
          ),
        );
        break;
      case _SettingsPanel.quit:
        title = 'Quit Polypod';
        content = Text(
          'Confirm quit to close the application.',
          style: TextStyle(
            fontSize: 13,
            color: EarthyTheme.textSecondary,
            height: 1.35,
          ),
        );
        break;
      case _SettingsPanel.none:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: EarthyTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: EarthyTheme.wheat.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: EarthyTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildTopReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: EarthyTheme.textSecondary),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: EarthyTheme.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: EarthyTheme.textSecondary.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            value,
            style: TextStyle(fontSize: 13, color: EarthyTheme.textPrimary),
          ),
        ),
      ],
    );
  }

  Future<void> _saveUserId() async {
    final userId = _userIdController.text.trim();

    setState(() {
      _isSavingUserId = true;
      _userIdStatus = '';
    });

    try {
      final settingsFile = File(_notificationSettingsPath());
      await settingsFile.parent.create(recursive: true);

      String previousUserId = '';
      if (await settingsFile.exists()) {
        try {
          final existingRaw = await settingsFile.readAsString();
          final existingDecoded = jsonDecode(existingRaw);
          if (existingDecoded is Map<String, dynamic>) {
            previousUserId =
                existingDecoded['user_id']?.toString().trim() ?? '';
          }
        } catch (_) {
          previousUserId = '';
        }
      }

      final hasChanged = previousUserId != userId;
      if (hasChanged) {
        await settingsFile.writeAsString(
          const JsonEncoder.withIndent('  ').convert({'user_id': ''}),
        );
        await _clearNotificationStateFiles();
      }

      final payload = <String, dynamic>{'user_id': userId};

      await settingsFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(payload),
      );

      if (mounted) {
        setState(() {
          _userIdStatus = hasChanged
              ? 'User ID updated. Cleared previous notification state.'
              : 'User ID saved.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userIdStatus = 'Failed to save user id.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingUserId = false;
        });
      }
    }
  }

  void _activateBottomInput({
    required _BottomInputMode mode,
    required String title,
    required String helper,
    required TextEditingController controller,
    VoidCallback? onChange,
    VoidCallback? onDone,
  }) {
    _activeBottomInput = controller;
    _activeBottomInputOnChange = onChange;
    _activeBottomInputOnDone = onDone;

    widget._bottomInputController.activate(
      nextMode: mode,
      nextTitle: title,
      nextHelper: helper,
      onBackspace: _handleBottomInputBackspace,
      onClear: _handleBottomInputClear,
      onKey: _handleBottomInputKey,
      onDone: () {
        _deactivateBottomInput();
      },
    );
  }

  void _deactivateBottomInput() {
    try {
      _activeBottomInputOnDone?.call();
    } catch (_) {
      // Ignore stale callback from a closed dialog.
    }
    _activeBottomInputOnDone = null;
    _activeBottomInputOnChange = null;
    _activeBottomInput = null;
    widget._bottomInputController.deactivate();
    setState(() {});
  }

  void _handleBottomInputKey(String value) {
    final target = _activeBottomInput;
    if (target == null) {
      return;
    }

    final selection = target.selection;
    final text = target.text;

    if (!selection.isValid || selection.start < 0 || selection.end < 0) {
      final updated = '$text$value';
      target.value = TextEditingValue(
        text: updated,
        selection: TextSelection.collapsed(offset: updated.length),
      );
    } else {
      final start = selection.start;
      final end = selection.end;
      final updated = text.replaceRange(start, end, value);
      target.value = TextEditingValue(
        text: updated,
        selection: TextSelection.collapsed(offset: start + value.length),
      );
    }

    _activeBottomInputOnChange?.call();
    setState(() {});
  }

  void _handleBottomInputBackspace() {
    final target = _activeBottomInput;
    if (target == null || target.text.isEmpty) {
      return;
    }

    final selection = target.selection;
    final text = target.text;

    if (!selection.isValid || selection.start <= 0 && selection.end <= 0) {
      final updated = text.substring(0, text.length - 1);
      target.value = TextEditingValue(
        text: updated,
        selection: TextSelection.collapsed(offset: updated.length),
      );
    } else if (selection.start != selection.end) {
      final start = selection.start;
      final end = selection.end;
      final updated = text.replaceRange(start, end, '');
      target.value = TextEditingValue(
        text: updated,
        selection: TextSelection.collapsed(offset: start),
      );
    } else {
      final cursor = selection.start;
      if (cursor <= 0) {
        return;
      }
      final updated = text.replaceRange(cursor - 1, cursor, '');
      target.value = TextEditingValue(
        text: updated,
        selection: TextSelection.collapsed(offset: cursor - 1),
      );
    }

    _activeBottomInputOnChange?.call();
    setState(() {});
  }

  void _handleBottomInputClear() {
    final target = _activeBottomInput;
    if (target == null) {
      return;
    }

    target.value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
    );
    _activeBottomInputOnChange?.call();
    setState(() {});
  }

  Future<ProcessResult?> _runCommand(
    String executable,
    List<String> arguments,
  ) async {
    try {
      return await Process.run(executable, arguments);
    } catch (_) {
      return null;
    }
  }

  Future<double?> _readBrightnessPercent() async {
    final current = await _runCommand('brightnessctl', ['g']);
    final maximum = await _runCommand('brightnessctl', ['m']);

    final currentText = current?.stdout?.toString().trim() ?? '';
    final maxText = maximum?.stdout?.toString().trim() ?? '';

    final currentValue = int.tryParse(currentText);
    final maxValue = int.tryParse(maxText);
    if (currentValue != null && maxValue != null && maxValue > 0) {
      return (currentValue / maxValue * 100).clamp(1, 100).toDouble();
    }

    return null;
  }

  Future<bool> _setBrightnessPercent(double percent) async {
    final result = await _runCommand('brightnessctl', [
      'set',
      '${percent.round()}%',
    ]);
    return result != null && result.exitCode == 0;
  }

  Future<double?> _readVolumePercent() async {
    final result = await _runCommand('amixer', ['get', 'Master']);
    final output = result?.stdout?.toString() ?? '';
    final match = RegExp(r'\[(\d{1,3})%\]').firstMatch(output);
    if (match == null) {
      return null;
    }
    final value = double.tryParse(match.group(1) ?? '');
    return value?.clamp(0, 100).toDouble();
  }

  Future<bool> _setVolumePercent(double percent) async {
    final result = await _runCommand('amixer', [
      'set',
      'Master',
      '${percent.round()}%',
    ]);
    return result != null && result.exitCode == 0;
  }

  Future<String> _readIpAddress() async {
    final result = await _runCommand('hostname', ['-I']);
    if (result == null || result.exitCode != 0) {
      return 'Unavailable';
    }
    final output = result.stdout?.toString().trim() ?? '';
    if (output.isEmpty) {
      return 'Unavailable';
    }
    return output.split(RegExp(r'\s+')).first;
  }

  Future<List<String>> _scanWifiNetworks() async {
    final result = await _runCommand('nmcli', [
      '-t',
      '-f',
      'SSID',
      'dev',
      'wifi',
      'list',
      '--rescan',
      'yes',
    ]);
    if (result == null || result.exitCode != 0) {
      return const [];
    }

    final lines =
        (result.stdout?.toString() ?? '')
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return lines;
  }

  Future<bool> _connectToWifi({
    required String ssid,
    required String password,
  }) async {
    final args = ['dev', 'wifi', 'connect', ssid];
    if (password.isNotEmpty) {
      args.addAll(['password', password]);
    }

    final result = await _runCommand('nmcli', args);
    return result != null && result.exitCode == 0;
  }

  Future<void> _clearNotificationStateFiles() async {
    final currentNotificationFile = File(_currentNotificationPath());
    await currentNotificationFile.parent.create(recursive: true);
    await currentNotificationFile.writeAsString('{}');

    final pollerStateFile = File(_notificationPollStatePath());
    if (await pollerStateFile.exists()) {
      await pollerStateFile.delete();
    }
  }

  String _notificationSettingsPath() {
    final currentDir = Directory.current.path;
    final settingsPath =
        '$currentDir${Platform.pathSeparator}..${Platform.pathSeparator}notif${Platform.pathSeparator}notification_settings.json';
    return File(settingsPath).absolute.path;
  }

  String _currentNotificationPath() {
    final currentDir = Directory.current.path;
    final notifPath =
        '$currentDir${Platform.pathSeparator}..${Platform.pathSeparator}notif${Platform.pathSeparator}current_notification.json';
    return File(notifPath).absolute.path;
  }

  String _notificationPollStatePath() {
    final currentDir = Directory.current.path;
    final statePath =
        '$currentDir${Platform.pathSeparator}..${Platform.pathSeparator}notif${Platform.pathSeparator}.notification_poll_state.json';
    return File(statePath).absolute.path;
  }

  Widget _buildSettingItem(
    String label,
    IconData icon, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Material(
        color: EarthyTheme.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Icon(icon, color: EarthyTheme.textSecondary),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          color: EarthyTheme.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: EarthyTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: EarthyTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsBottomInputPanel extends StatefulWidget {
  const _SettingsBottomInputPanel({required this.controller});

  final _BottomInputController controller;

  @override
  State<_SettingsBottomInputPanel> createState() =>
      _SettingsBottomInputPanelState();
}

class _SettingsBottomInputPanelState extends State<_SettingsBottomInputPanel> {
  bool _uppercase = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        if (widget.controller.mode == _BottomInputMode.idle) {
          return _buildIdlePanel();
        }
        if (widget.controller.mode == _BottomInputMode.numberPad) {
          return _buildNumberPad();
        }
        if (widget.controller.mode == _BottomInputMode.slider) {
          return _buildSliderPanel();
        }
        if (widget.controller.mode == _BottomInputMode.network) {
          return _buildNetworkPanel();
        }
        if (widget.controller.mode == _BottomInputMode.confirm) {
          return _buildConfirmPanel();
        }
        return _buildKeyboard();
      },
    );
  }

  Widget _buildIdlePanel() {
    return Container();
  }

  Widget _buildNumberPad() {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];
    return Container(
      color: EarthyTheme.background,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelHeader(),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.9,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                if (index < 9) {
                  return _buildInputKey(
                    label: keys[index],
                    onTap: () => widget.controller.addCharacter(keys[index]),
                  );
                }
                if (index == 9) {
                  return _buildInputKey(
                    label: keys[9],
                    onTap: () => widget.controller.addCharacter(keys[9]),
                  );
                }
                if (index == 10) {
                  return _buildInputKey(
                    label: 'DONE',
                    onTap: widget.controller.done,
                    color: EarthyTheme.clay,
                  );
                }
                return _buildInputKey(
                  label: 'DEL',
                  onTap: widget.controller.backspace,
                  color: EarthyTheme.bark,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboard() {
    final row1 = _characters('qwertyuiop');
    final row2 = _characters('asdfghjkl');
    final row3 = _characters('zxcvbnm');

    return Container(
      color: EarthyTheme.background,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 72),
      child: Column(
        children: [
          _buildPanelHeader(),
          const SizedBox(height: 6),
          _buildTextRow(row1),
          const SizedBox(height: 6),
          _buildTextRow(row2),
          const SizedBox(height: 6),
          Row(
            children: [
              _wideKey(
                icon: _uppercase
                    ? Icons.keyboard_capslock_rounded
                    : Icons.arrow_upward_rounded,
                onTap: () {
                  setState(() {
                    _uppercase = !_uppercase;
                  });
                },
              ),
              const SizedBox(width: 6),
              Expanded(child: _buildTextRow(row3, compact: true)),
              const SizedBox(width: 6),
              _wideKey(
                icon: Icons.backspace_rounded,
                onTap: widget.controller.backspace,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _wideKey(
                label: '@',
                onTap: () {
                  widget.controller.addCharacter('@');
                },
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildInputKey(
                  label: 'SPACE',
                  onTap: () => widget.controller.addCharacter(' '),
                ),
              ),
              const SizedBox(width: 6),
              _wideKey(label: 'CLR', onTap: widget.controller.clear),
              const SizedBox(width: 6),
              _wideKey(
                label: 'DONE',
                onTap: widget.controller.done,
                color: EarthyTheme.clay,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliderPanel() {
    return Container(
      color: EarthyTheme.background,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelHeader(),
          const SizedBox(height: 10),
          Text(
            'Selected: ${widget.controller.sliderValue.round()}${widget.controller.sliderUnit}',
            style: TextStyle(color: EarthyTheme.textSecondary, fontSize: 14),
          ),
          Slider(
            min: widget.controller.sliderMin,
            max: widget.controller.sliderMax,
            value: widget.controller.sliderValue.clamp(
              widget.controller.sliderMin,
              widget.controller.sliderMax,
            ),
            activeColor: EarthyTheme.wheat,
            onChanged: widget.controller.updateSlider,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.controller.secondaryAction,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: EarthyTheme.textSecondary.withValues(alpha: 0.4),
                    ),
                    foregroundColor: EarthyTheme.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.controller.primaryAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EarthyTheme.clay,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(widget.controller.primaryActionLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkPanel() {
    final hasOptions = widget.controller.networkOptions.isNotEmpty;
    final selected = widget.controller.selectedNetwork;

    return Container(
      color: EarthyTheme.background,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelHeader(),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: hasOptions ? selected : null,
            dropdownColor: EarthyTheme.surface,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Wi-Fi Network',
              labelStyle: TextStyle(color: EarthyTheme.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: EarthyTheme.textSecondary.withValues(alpha: 0.4),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: EarthyTheme.clay),
              ),
            ),
            items: widget.controller.networkOptions
                .map(
                  (network) => DropdownMenuItem<String>(
                    value: network,
                    child: Text(
                      network,
                      style: TextStyle(color: EarthyTheme.textPrimary),
                    ),
                  ),
                )
                .toList(),
            onChanged: hasOptions
                ? (value) {
                    if (value != null) {
                      widget.controller.selectNetwork(value);
                    }
                  }
                : null,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.controller.refreshNetworks,
                  icon: const Icon(Icons.refresh_rounded),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: EarthyTheme.textSecondary,
                    side: BorderSide(
                      color: EarthyTheme.textSecondary.withValues(alpha: 0.4),
                    ),
                  ),
                  label: const Text('Scan'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.controller.editNetworkPassword,
                  icon: const Icon(Icons.keyboard_rounded),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: EarthyTheme.textSecondary,
                    side: BorderSide(
                      color: EarthyTheme.textSecondary.withValues(alpha: 0.4),
                    ),
                  ),
                  label: const Text('Password'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.controller.connectNetwork,
              style: ElevatedButton.styleFrom(
                backgroundColor: EarthyTheme.clay,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.wifi_rounded),
              label: const Text('Connect'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmPanel() {
    return Container(
      color: EarthyTheme.background,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelHeader(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.controller.secondaryAction,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: EarthyTheme.textSecondary,
                    side: BorderSide(
                      color: EarthyTheme.textSecondary.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.controller.primaryAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EarthyTheme.terracotta,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(widget.controller.primaryActionLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPanelHeader() {
    return Row(
      children: [
        Icon(Icons.keyboard_rounded, color: EarthyTheme.wheat),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.controller.title,
                style: TextStyle(
                  color: EarthyTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (widget.controller.helper.isNotEmpty)
                Text(
                  widget.controller.helper,
                  style: TextStyle(
                    color: EarthyTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextRow(List<String> row, {bool compact = false}) {
    return Row(
      children: row
          .map(
            (key) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _buildInputKey(
                  label: _uppercase ? key.toUpperCase() : key,
                  onTap: () {
                    final output = _uppercase ? key.toUpperCase() : key;
                    widget.controller.addCharacter(output);
                    if (_uppercase) {
                      setState(() {
                        _uppercase = false;
                      });
                    }
                  },
                  fontSize: compact ? 12 : 14,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildInputKey({
    required String label,
    required VoidCallback onTap,
    Color? color,
    double fontSize = 16,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? EarthyTheme.forestGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _wideKey({
    String? label,
    IconData? icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return SizedBox(
      width: 70,
      height: 44,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? EarthyTheme.moss,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero,
        ),
        child: icon != null ? Icon(icon, size: 18) : Text(label ?? ''),
      ),
    );
  }

  List<String> _characters(String sequence) => sequence.split('');
}
