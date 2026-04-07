import 'package:flutter/material.dart';

import '../config/theme_config.dart';

class SettingsBottomProxyPanel extends StatefulWidget {
  const SettingsBottomProxyPanel({
    super.key,
    required this.state,
    required this.onAction,
  });

  final Map<String, dynamic> state;
  final void Function(String action, Map<String, dynamic> payload) onAction;

  @override
  State<SettingsBottomProxyPanel> createState() =>
      _SettingsBottomProxyPanelState();
}

class _SettingsBottomProxyPanelState extends State<SettingsBottomProxyPanel> {
  bool _uppercase = false;

  @override
  Widget build(BuildContext context) {
    final mode = widget.state['bottomMode']?.toString() ?? 'idle';
    return Container(
      color: EarthyTheme.background,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 8),
          if (mode == 'slider') _buildSlider(),
          if (mode == 'network') _buildNetwork(),
          if (mode == 'keyboard') _buildKeyboard(),
          if (mode == 'numberPad') _buildNumberPad(),
          if (mode == 'confirm') _buildConfirm(),
          if (mode == 'idle') _buildPanelPicker(),
        ],
      ),
    );
  }

  Widget _header() {
    final title =
        widget.state['bottomTitle']?.toString() ?? 'Settings Controls';
    final helper =
        widget.state['bottomHelper']?.toString() ??
        'Select a settings panel from below.';
    return Row(
      children: [
        Icon(Icons.tune_rounded, color: EarthyTheme.wheat, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: EarthyTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                helper,
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

  Widget _buildPanelPicker() {
    return Expanded(
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: [
          _panelButton('Brightness', Icons.brightness_6_rounded, 'brightness'),
          _panelButton('Volume', Icons.volume_up_rounded, 'volume'),
          _panelButton('Network', Icons.wifi_rounded, 'network'),
          _panelButton('About', Icons.info_outline_rounded, 'about'),
          _panelButton('Quit', Icons.exit_to_app_rounded, 'quit'),
          _panelButton('Close', Icons.close_rounded, 'none'),
        ],
      ),
    );
  }

  Widget _panelButton(String label, IconData icon, String panel) {
    return ElevatedButton(
      onPressed: () {
        if (panel == 'none') {
          widget.onAction('closePanel', const {});
        } else {
          widget.onAction('selectPanel', {'panel': panel});
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: EarthyTheme.forestGreen,
        foregroundColor: Colors.white,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Icon(icon), const SizedBox(height: 4), Text(label)],
      ),
    );
  }

  Widget _buildSlider() {
    final value = (widget.state['sliderValue'] as num?)?.toDouble() ?? 50;
    final min = (widget.state['sliderMin'] as num?)?.toDouble() ?? 0;
    final max = (widget.state['sliderMax'] as num?)?.toDouble() ?? 100;
    final unit = widget.state['sliderUnit']?.toString() ?? '%';
    final saveLabel =
        widget.state['bottomPrimaryActionLabel']?.toString() ?? 'Save';

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected: ${value.round()}$unit',
            style: TextStyle(color: EarthyTheme.textSecondary),
          ),
          Slider(
            min: min,
            max: max,
            value: value.clamp(min, max),
            activeColor: EarthyTheme.wheat,
            onChanged: (next) {
              widget.onAction('sliderChanged', {'value': next});
            },
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => widget.onAction('closePanel', const {}),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => widget.onAction('saveSlider', const {}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EarthyTheme.clay,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(saveLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetwork() {
    final options =
        (widget.state['wifiNetworks'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];
    final selected = widget.state['selectedSsid']?.toString();
    return Expanded(
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: options.contains(selected) ? selected : null,
            dropdownColor: EarthyTheme.surface,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Wi-Fi Network'),
            items: options
                .map((ssid) => DropdownMenuItem(value: ssid, child: Text(ssid)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                widget.onAction('networkSelect', {'ssid': value});
              }
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => widget.onAction('networkScan', const {}),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Scan'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => widget.onAction('networkPassword', const {}),
                  icon: const Icon(Icons.keyboard_rounded),
                  label: const Text('Password'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => widget.onAction('networkConnect', const {}),
              style: ElevatedButton.styleFrom(
                backgroundColor: EarthyTheme.clay,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.wifi_rounded),
              label: const Text('Connect'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberPad() {
    const keys = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      'DONE',
      '0',
      'DEL',
    ];
    return Expanded(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.9,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: keys.length,
        itemBuilder: (context, index) {
          final key = keys[index];
          return ElevatedButton(
            onPressed: () {
              if (key == 'DONE') {
                widget.onAction('inputDone', const {});
              } else if (key == 'DEL') {
                widget.onAction('inputBackspace', const {});
              } else {
                widget.onAction('inputKey', {'value': key});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: key == 'DONE'
                  ? EarthyTheme.clay
                  : (key == 'DEL' ? EarthyTheme.bark : EarthyTheme.forestGreen),
              foregroundColor: Colors.white,
            ),
            child: Text(key),
          );
        },
      ),
    );
  }

  Widget _buildKeyboard() {
    final row1 = 'qwertyuiop'.split('');
    final row2 = 'asdfghjkl'.split('');
    final row3 = 'zxcvbnm'.split('');

    return Expanded(
      child: Column(
        children: [
          _keyRow(row1),
          const SizedBox(height: 6),
          _keyRow(row2),
          const SizedBox(height: 6),
          Row(
            children: [
              _wideKeyboardKey(
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
              Expanded(child: _keyRow(row3, compact: true)),
              const SizedBox(width: 6),
              _wideKeyboardKey(
                icon: Icons.backspace_rounded,
                onTap: () => widget.onAction('inputBackspace', const {}),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _wideKeyboardKey(
                label: '@',
                onTap: () => widget.onAction('inputKey', {'value': '@'}),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => widget.onAction('inputKey', {'value': ' '}),
                  child: const Text('SPACE'),
                ),
              ),
              const SizedBox(width: 6),
              _wideKeyboardKey(
                label: 'CLR',
                onTap: () => widget.onAction('inputClear', const {}),
              ),
              const SizedBox(width: 6),
              _wideKeyboardKey(
                label: 'DONE',
                color: EarthyTheme.clay,
                onTap: () => widget.onAction('inputDone', const {}),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _keyRow(List<String> keys, {bool compact = false}) {
    return Row(
      children: keys
          .map(
            (key) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: ElevatedButton(
                  onPressed: () {
                    final value = _uppercase ? key.toUpperCase() : key;
                    widget.onAction('inputKey', {'value': value});
                    if (_uppercase) {
                      setState(() {
                        _uppercase = false;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    _uppercase ? key.toUpperCase() : key,
                    style: TextStyle(fontSize: compact ? 12 : 14),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _wideKeyboardKey({
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
          padding: EdgeInsets.zero,
        ),
        child: icon != null ? Icon(icon, size: 18) : Text(label ?? ''),
      ),
    );
  }

  Widget _buildConfirm() {
    final label =
        widget.state['bottomPrimaryActionLabel']?.toString() ?? 'Confirm';
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => widget.onAction('quitCancel', const {}),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () => widget.onAction('quitConfirm', const {}),
            style: ElevatedButton.styleFrom(
              backgroundColor: EarthyTheme.terracotta,
              foregroundColor: Colors.white,
            ),
            child: Text(label),
          ),
        ),
      ],
    );
  }
}
