// ─────────────────────────────────────────────────────────────────
//  EcoVera — BLE Sensor Sync Screen
//  Scans for "EcoVera-Sensor" BLE device, connects, reads the
//  7 soil parameters and returns them to the analysis form.
// ─────────────────────────────────────────────────────────────────
//
//  NOTE: This screen uses plain dart:typed_data + a manual BLE
//  approach via flutter_blue_plus package.
//
//  Add to pubspec.yaml:
//    flutter_blue_plus: ^1.31.0
//    permission_handler: ^11.3.0
// ─────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ──────────────────────────────────────────────────────────────
//  SENSOR DATA MODEL
// ──────────────────────────────────────────────────────────────
class SensorReading {
  final double nitrogen;
  final double phosphorus;
  final double potassium;
  final double ph;
  final double temperature;
  final double humidity;
  final double moisture;
  final DateTime timestamp;

  const SensorReading({
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.ph,
    required this.temperature,
    required this.humidity,
    required this.moisture,
    required this.timestamp,
  });

  /// Parse from the JSON sent by the ESP32
  /// Format: {"n":45,"p":28,"k":62,"ph":6.5,"temp":26.3,"hum":65.2,"moist":38.0}
  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      nitrogen:    (json['n']     as num).toDouble(),
      phosphorus:  (json['p']     as num).toDouble(),
      potassium:   (json['k']     as num).toDouble(),
      ph:          (json['ph']    as num).toDouble(),
      temperature: (json['temp']  as num).toDouble(),
      humidity:    (json['hum']   as num).toDouble(),
      moisture:    (json['moist'] as num).toDouble(),
      timestamp:   DateTime.now(),
    );
  }

  Map<String, double> toFormMap() => {
    'nitrogen':    nitrogen,
    'phosphorus':  phosphorus,
    'potassium':   potassium,
    'ph':          ph,
    'temperature': temperature,
    'humidity':    humidity,
    'moisture':    moisture,
  };
}

// ──────────────────────────────────────────────────────────────
//  SENSOR SYNC SCREEN  (shown as a bottom sheet from AnalysisScreen)
// ──────────────────────────────────────────────────────────────
class SensorSyncScreen extends StatefulWidget {
  /// Called with sensor data when sync is successful
  final void Function(SensorReading reading) onDataReceived;

  const SensorSyncScreen({super.key, required this.onDataReceived});

  @override
  State<SensorSyncScreen> createState() => _SensorSyncScreenState();
}

class _SensorSyncScreenState extends State<SensorSyncScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────
  _SyncStatus _status = _SyncStatus.idle;
  String _statusMessage = 'Ready to scan for EcoVera sensor';
  SensorReading? _reading;
  String? _errorMessage;

  late AnimationController _pulseController;
  late Animation<double>    _pulseAnimation;

  // ── Simulated BLE state (replace with flutter_blue_plus in production) ──
  Timer? _simulationTimer;

  // ─────────────────────────────────────────────────────────
  static const _serviceUUID = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const _charUUID    = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _simulationTimer?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  //  SCAN & CONNECT  (simulation — swap with real BLE code)
  // ─────────────────────────────────────────────────────────
  Future<void> _startScan() async {
    setState(() {
      _status = _SyncStatus.scanning;
      _statusMessage = 'Scanning for EcoVera-Sensor…';
      _errorMessage = null;
      _reading = null;
    });

    // ── Simulate BLE scan (2s) → connect (1s) → read (1s) ──
    // In production: replace with flutter_blue_plus scan logic
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() {
      _status = _SyncStatus.connecting;
      _statusMessage = 'Found EcoVera-Sensor! Connecting…';
    });

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    setState(() {
      _status = _SyncStatus.reading;
      _statusMessage = 'Connected! Reading sensor values…';
    });

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    // ── Simulated JSON payload from ESP32 ──────────────────
    // In production this comes from pCharacteristic.lastValueStream
    final simulatedPayload = {
      'n':    _randomVal(20, 80),
      'p':    _randomVal(10, 60),
      'k':    _randomVal(15, 70),
      'ph':   double.parse((_randomVal(5.0, 8.5)).toStringAsFixed(1)),
      'temp': double.parse((_randomVal(18.0, 38.0)).toStringAsFixed(1)),
      'hum':  double.parse((_randomVal(40.0, 90.0)).toStringAsFixed(1)),
      'moist':double.parse((_randomVal(20.0, 70.0)).toStringAsFixed(1)),
    };

    final reading = SensorReading.fromJson(simulatedPayload);

    setState(() {
      _status = _SyncStatus.success;
      _statusMessage = 'All 7 parameters received!';
      _reading = reading;
    });

    _pulseController.stop();
  }

  double _randomVal(double min, double max) {
    final range = max - min;
    return min + (range * (DateTime.now().millisecondsSinceEpoch % 100) / 100.0);
  }

  void _useReading() {
    if (_reading != null) {
      widget.onDataReceived(_reading!);
      Navigator.of(context).pop();
    }
  }

  void _reset() {
    _pulseController.repeat(reverse: true);
    setState(() {
      _status = _SyncStatus.idle;
      _statusMessage = 'Ready to scan for EcoVera sensor';
      _reading = null;
      _errorMessage = null;
    });
  }

  // ─────────────────────────────────────────────────────────
  //  UI
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1F0F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A3A1A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.sensors, color: Color(0xFF4CAF50), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NPK Sensor Sync',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'EcoVera-Sensor • BLE',
                        style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Status indicator
              _buildStatusIndicator(),
              const SizedBox(height: 24),

              // Sensor readings grid (shown after success)
              if (_reading != null) ...[
                _buildReadingsGrid(_reading!),
                const SizedBox(height: 20),
              ],

              // Action buttons
              _buildActionButtons(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final Color color = switch (_status) {
      _SyncStatus.idle       => const Color(0xFF607D8B),
      _SyncStatus.scanning   => const Color(0xFF2196F3),
      _SyncStatus.connecting => const Color(0xFFFF9800),
      _SyncStatus.reading    => const Color(0xFF9C27B0),
      _SyncStatus.success    => const Color(0xFF4CAF50),
      _SyncStatus.error      => const Color(0xFFF44336),
    };

    final IconData icon = switch (_status) {
      _SyncStatus.idle       => Icons.bluetooth_searching,
      _SyncStatus.scanning   => Icons.radar,
      _SyncStatus.connecting => Icons.bluetooth_connected,
      _SyncStatus.reading    => Icons.download_rounded,
      _SyncStatus.success    => Icons.check_circle_rounded,
      _SyncStatus.error      => Icons.error_rounded,
    };

    final bool pulsing = _status != _SyncStatus.idle &&
                         _status != _SyncStatus.success &&
                         _status != _SyncStatus.error;

    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (ctx, child) => Transform.scale(
            scale: pulsing ? _pulseAnimation.value : 1.0,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _status.label,
                style: GoogleFonts.outfit(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _statusMessage,
                style: GoogleFonts.outfit(
                  color: Colors.white60,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReadingsGrid(SensorReading r) {
    final params = [
      ('N', r.nitrogen,    'mg/kg', const Color(0xFF4CAF50)),
      ('P', r.phosphorus,  'mg/kg', const Color(0xFF2196F3)),
      ('K', r.potassium,   'mg/kg', const Color(0xFFFF9800)),
      ('pH', r.ph,         '',      const Color(0xFF9C27B0)),
      ('Temp', r.temperature, '°C', const Color(0xFFF44336)),
      ('Humid', r.humidity,  '%',   const Color(0xFF00BCD4)),
      ('Moist', r.moisture,  '%',   const Color(0xFF8BC34A)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '  7 Parameters Received',
          style: GoogleFonts.outfit(
            color: Colors.white38,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.1,
          ),
          itemCount: params.length,
          itemBuilder: (ctx, i) {
            final (label, value, unit, color) = params[i];
            return Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                    style: GoogleFonts.outfit(
                      color: color, fontSize: 11, fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value.toStringAsFixed(label == 'pH' ? 1 : 0),
                    style: GoogleFonts.outfit(
                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    Text(unit, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 9)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_status == _SyncStatus.success && _reading != null) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _useReading,
              icon: const Icon(Icons.auto_fix_high_rounded),
              label: Text(
                'Use These Values & Predict',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _reset,
            child: Text('Scan Again', style: GoogleFonts.outfit(color: Colors.white38)),
          ),
        ],
      );
    }

    if (_status == _SyncStatus.idle || _status == _SyncStatus.error) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _startScan,
          icon: const Icon(Icons.bluetooth_searching),
          label: Text(
            'Scan for EcoVera-Sensor',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
    }

    // Scanning / connecting / reading — show loading
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: null,
        icon: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
        ),
        label: Text(
          'Please wait…',
          style: GoogleFonts.outfit(fontSize: 16, color: Colors.white54),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A2A1A),
          disabledBackgroundColor: const Color(0xFF1A2A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

// ── Sync status enum ─────────────────────────────────────────────
enum _SyncStatus {
  idle, scanning, connecting, reading, success, error;

  String get label => switch (this) {
    idle       => 'Not connected',
    scanning   => 'Scanning…',
    connecting => 'Connecting…',
    reading    => 'Reading…',
    success    => 'Sync Complete ✓',
    error      => 'Error',
  };
}

// ────────────────────────────────────────────────────────────────
//  HELPER: Show sensor sync bottom sheet from any screen
// ────────────────────────────────────────────────────────────────
Future<SensorReading?> showSensorSyncSheet(BuildContext context) async {
  SensorReading? result;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SensorSyncScreen(
      onDataReceived: (reading) => result = reading,
    ),
  );
  return result;
}
