import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_service.dart';
import '../models/senzhub_models.dart';

class DeviceRepository {
  SupabaseClient get _client => SupabaseService.client;

  // ─── Devices list ─────────────────────────────────────────────────────────

  /// Returns all devices accessible to the authenticated user (RLS-enforced).
  Future<List<DeviceRecord>> getDevices() async {
    final res = await _client
        .from('devices')
        .select()
        .order('created_at', ascending: true);

    return res.map<DeviceRecord>(_rowToDeviceRecord).toList();
  }

  // ─── Valve Control ────────────────────────────────────────────────────────

  /// Fetches the current physical/db [ValveState] for [deviceId].
  Future<ValveState> getValveStatus(String deviceId) async {
    final res = await _client
        .from('devices')
        .select('valve_status')
        .eq('id', deviceId)
        .maybeSingle();

    if (res == null) return ValveState.closed;
    final statusStr = (res['valve_status'] as String?)?.toUpperCase() ?? 'CLOSED';
    if (statusStr == 'OPEN') return ValveState.open;
    if (statusStr == 'SAFETY_LOCK') return ValveState.safetyLock;
    return ValveState.closed;
  }

  /// Fetches whether the user has a valve PIN configured.
  Future<bool> getValvePinStatus() async {
    final response = await _client.functions.invoke(
      'get-valve-pin-status',
    );
    final status = response.status;
    final data = response.data is Map ? Map<String, dynamic>.from(response.data) : <String, dynamic>{};
    if (status < 200 || status >= 300) {
      final err = data['error'] as String? ?? 'Failed to get PIN status';
      throw Exception(err);
    }
    return data['has_pin'] == true;
  }

  /// Sets the user's valve PIN via secure Edge Function.
  Future<void> setValvePin(String pin) async {
    final response = await _client.functions.invoke(
      'set-valve-pin',
      body: {'pin': pin},
    );
    final status = response.status;
    if (status < 200 || status >= 300) {
      final err = (response.data is Map ? response.data['error'] : null) ?? 'Failed to set PIN';
      throw Exception(err);
    }
  }

  /// Verifies the user's valve PIN via secure Edge Function.
  Future<void> verifyValvePin(String pin) async {
    final response = await _client.functions.invoke(
      'verify-valve-pin',
      body: {'pin': pin},
    );
    final status = response.status;
    final data = response.data is Map ? Map<String, dynamic>.from(response.data) : <String, dynamic>{};
    if (status < 200 || status >= 300) {
      final err = data['error'] as String? ?? 'Failed to verify PIN';
      throw Exception(err);
    }
  }

  /// Resets the user's valve PIN using a secure recovery session.
  Future<void> resetValvePin(String newPin) async {
    final response = await _client.functions.invoke(
      'reset-valve-pin',
      body: {'pin': newPin},
    );
    final status = response.status;
    final data = response.data is Map ? Map<String, dynamic>.from(response.data) : <String, dynamic>{};
    if (status < 200 || status >= 300) {
      final err = data['error'] as String? ?? 'Failed to reset PIN';
      throw Exception(err);
    }
  }

  /// Requests a secure OTP challenge for a valve operation (e.g. OPEN).
  Future<Map<String, dynamic>> requestValveOtp(String deviceId, ValveAction action) async {
    final actionStr = action == ValveAction.open ? 'OPEN' : 'CLOSE';
    final response = await _client.functions.invoke(
      'request-valve-otp',
      body: {
        'device_id': deviceId,
        'action': actionStr,
      },
    );
    final status = response.status;
    final data = response.data is Map ? Map<String, dynamic>.from(response.data) : <String, dynamic>{};
    if (status < 200 || status >= 300) {
      final err = data['error'] as String? ?? 'Failed to request OTP (HTTP $status)';
      throw Exception(err);
    }
    return data;
  }

  /// Submits a valve control command via the secure Edge Function `send-valve-command`.
  /// Requires [pin], and for OPEN actions, requires [otp].
  /// Returns structured map containing `command_id` and initial status ('PENDING').
  Future<Map<String, dynamic>> submitValveCommand(
    String deviceId,
    ValveAction action, {
    String? reason,
    required String pin,
    String? otp,
  }) async {
    final actionStr = action == ValveAction.open ? 'OPEN' : 'CLOSE';
    final response = await _client.functions.invoke(
      'send-valve-command',
      body: {
        'device_id': deviceId,
        'action': actionStr,
        'reason': reason ?? 'Manual user command',
        'pin': pin,
        // ignore: use_null_aware_elements
        if (otp != null) 'otp': otp,
      },
    );

    final status = response.status;
    final data = response.data is Map ? Map<String, dynamic>.from(response.data) : <String, dynamic>{};

    if (status < 200 || status >= 300) {
      final err = data['error'] as String? ?? 'Command request failed (HTTP $status)';
      throw Exception(err);
    }

    return data;
  }

  /// Fetches details for a specific [commandId].
  Future<ValveCommandRecord?> getValveCommand(String commandId) async {
    final res = await _client
        .from('device_commands')
        .select()
        .eq('id', commandId)
        .maybeSingle();

    if (res == null) return null;

    return ValveCommandRecord(
      id: res['id'] as String,
      deviceId: res['device_id'] as String,
      command: res['command'] as String? ?? '',
      status: res['status'] as String? ?? 'PENDING',
      failureReason: res['failure_reason'] as String?,
      requestedAt: res['requested_at'] != null ? DateTime.tryParse(res['requested_at']) : null,
      executedAt: res['executed_at'] != null ? DateTime.tryParse(res['executed_at']) : null,
      acknowledgedAt: res['acknowledged_at'] != null ? DateTime.tryParse(res['acknowledged_at']) : null,
    );
  }


  // ─── Alerts list ──────────────────────────────────────────────────────────

  /// Returns all alerts accessible to the authenticated user (RLS-enforced).
  /// Joins device details (`serial_number`, `device_name`) and orders newest first (`created_at descending`).
  Future<List<AlertItem>> getAlerts() async {
    final res = await _client
        .from('alerts')
        .select('*, devices(serial_number, device_name)')
        .order('created_at', ascending: false)
        .limit(50);

    return res.map<AlertItem>(_rowToAlertItem).toList();
  }

  // ─── Dashboard snapshot ───────────────────────────────────────────────────

  Future<SystemSnapshot?> getDashboardSnapshot() async {
    if (!SupabaseService.isInitialized) return null;

    final devicesRes = await _client.from('devices').select().limit(1);
    if (devicesRes.isEmpty) return null;

    final device = devicesRes.first;
    final String deviceId = device['id'];

    final readingsRes = await _client
        .from('device_readings')
        .select()
        .eq('device_id', deviceId)
        .order('recorded_at', ascending: false)
        .limit(1);

    final Map<String, dynamic>? reading =
        readingsRes.isNotEmpty ? readingsRes.first : null;

    final gasStatusStr =
        (device['gas_status'] as String?)?.toUpperCase() ?? 'SAFE';
    final valveStatusStr =
        (device['valve_status'] as String?)?.toUpperCase() ?? 'OPEN';
    final powerSourceStr =
        (device['power_source'] as String?)?.toUpperCase() ?? 'AC';
    final deviceStatusStr =
        (device['device_status'] as String?)?.toUpperCase() ?? 'OFFLINE';

    SafetyLevel safetyLevel;
    if (gasStatusStr == 'DANGER') {
      safetyLevel = SafetyLevel.danger;
    } else if (gasStatusStr == 'WARNING') {
      safetyLevel = SafetyLevel.warning;
    } else {
      safetyLevel = SafetyLevel.safe;
    }

    final ValveState valveState =
        valveStatusStr == 'CLOSED' ? ValveState.closed : ValveState.open;

    const stubAlert = AlertItem(
      title: 'System Active',
      message: 'Monitoring started successfully.',
      severity: AlertSeverity.info,
      timestamp: 'Just now',
      gasLevel: 0,
      action: 'Dismiss',
    );

    return SystemSnapshot(
      gasLevelPpm: reading?['gas_level_ppm'] as int? ?? 0,
      warningThreshold: device['warning_threshold_ppm'] as int? ?? 3200,
      dangerThreshold: device['danger_threshold_ppm'] as int? ?? 3700,
      gasStatus: safetyLevel,
      valveState: valveState,
      battery: device['battery_percentage'] as int?,
      gsmSignalCsq: device['gsm_signal'] as int? ?? 20,
      gsmSignalQuality: 'Good',
      systemOnline: deviceStatusStr == 'ONLINE',
      powerSource: powerSourceStr == 'BATTERY' ? PowerSource.battery : (powerSourceStr == 'AC' ? PowerSource.ac : null),
      latestAlert: stubAlert,
      deviceId: device['serial_number'] as String? ?? deviceId,
      location: 'Main Location',
    );
  }

  // ─── Monitoring snapshot ──────────────────────────────────────────────────

  /// Returns a [MonitoringData] combining the device state and recent readings.
  /// Returns null if the user has no accessible device.
  Future<MonitoringData?> getMonitoringSnapshot([String? deviceIdParam]) async {
    // Fetch first accessible device or specific device
    final devicesQuery = _client.from('devices').select();
    final devicesRes = await (deviceIdParam != null 
        ? devicesQuery.eq('id', deviceIdParam).limit(1) 
        : devicesQuery.limit(1));
    
    if (devicesRes.isEmpty) return null;

    final device = devicesRes.first;
    final String deviceId = device['id'];

    // Fetch latest reading for live values
    final latestReadingRes = await _client
        .from('device_readings')
        .select()
        .eq('device_id', deviceId)
        .order('recorded_at', ascending: false)
        .limit(1);

    // Fetch recent readings for the trend chart (up to 20 rows)
    final recentReadingsRes = await _client
        .from('device_readings')
        .select('gas_level_ppm, recorded_at')
        .eq('device_id', deviceId)
        .order('recorded_at', ascending: true)
        .limit(20);

    final Map<String, dynamic>? latestReading =
        latestReadingRes.isNotEmpty ? latestReadingRes.first : null;

    final trendValues = recentReadingsRes
        .map<double>((r) => (r['gas_level_ppm'] as int).toDouble())
        .toList();

    // Map device state enums
    final gasStatusStr =
        (device['gas_status'] as String?)?.toUpperCase() ?? 'SAFE';
    final valveStatusStr =
        (device['valve_status'] as String?)?.toUpperCase() ?? 'OPEN';
    final powerSourceStr =
        (device['power_source'] as String?)?.toUpperCase() ?? 'AC';
    final deviceStatusStr =
        (device['device_status'] as String?)?.toUpperCase() ?? 'OFFLINE';

    SafetyLevel safetyLevel;
    if (gasStatusStr == 'DANGER') {
      safetyLevel = SafetyLevel.danger;
    } else if (gasStatusStr == 'WARNING') {
      safetyLevel = SafetyLevel.warning;
    } else {
      safetyLevel = SafetyLevel.safe;
    }

    final ValveState valveState =
        valveStatusStr == 'CLOSED' ? ValveState.closed : ValveState.open;

    // Latest reading timestamp
    final String latestReadingAt = latestReading?['recorded_at'] != null
        ? _formatTimestamp(latestReading!['recorded_at'] as String)
        : 'Never';

    return MonitoringData(
      gasLevelPpm: latestReading?['gas_level_ppm'] as int? ?? 0,
      warningThreshold: device['warning_threshold_ppm'] as int? ?? 3200,
      dangerThreshold: device['danger_threshold_ppm'] as int? ?? 3700,
      gasStatus: safetyLevel,
      valveState: valveState,
      battery: device['battery_percentage'] as int?,
      gsmSignalCsq: device['gsm_signal'] as int? ?? 0,
      systemOnline: deviceStatusStr == 'ONLINE',
      powerSource: powerSourceStr == 'BATTERY' ? PowerSource.battery : (powerSourceStr == 'AC' ? PowerSource.ac : null),
      trendValues: trendValues,
      latestReadingAt: latestReadingAt,
      deviceId: device['serial_number'] as String? ?? deviceId,
    );
  }

  // ─── Private helpers ─────────────────────────────────────────────────────

  AlertItem _rowToAlertItem(Map<String, dynamic> row) {
    final severityStr = (row['severity'] as String?)?.toUpperCase() ?? 'INFO';
    AlertSeverity severity;
    switch (severityStr) {
      case 'WARNING':
        severity = AlertSeverity.warning;
        break;
      case 'DANGER':
        severity = AlertSeverity.danger;
        break;
      case 'CRITICAL':
        severity = AlertSeverity.critical;
        break;
      case 'INFO':
      default:
        severity = AlertSeverity.info;
        break;
    }

    final alertType = row['alert_type'] as String? ?? 'ALERT';
    final title = _formatAlertType(alertType);

    final deviceMap = row['devices'] as Map<String, dynamic>?;
    final deviceName = deviceMap?['device_name'] as String? ??
        deviceMap?['serial_number'] as String?;

    final message = row['message'] as String? ?? '';
    final fullMessage = deviceName != null && deviceName.isNotEmpty
        ? '[$deviceName] $message'
        : message;

    final isAck = row['is_acknowledged'] as bool? ?? false;
    final action = isAck ? 'Acknowledged' : 'Active';

    final createdAtStr = row['created_at'] != null
        ? _formatTimestamp(row['created_at'] as String)
        : 'Unknown time';

    return AlertItem(
      title: title,
      message: fullMessage,
      severity: severity,
      timestamp: createdAtStr,
      gasLevel: row['gas_level_ppm'] as int? ?? 0,
      action: action,
    );
  }

  String _formatAlertType(String type) {
    return type
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  DeviceRecord _rowToDeviceRecord(Map<String, dynamic> row) {
    final gasStatusStr =
        (row['gas_status'] as String?)?.toUpperCase() ?? 'SAFE';
    final valveStatusStr =
        (row['valve_status'] as String?)?.toUpperCase() ?? 'OPEN';
    final powerSourceStr =
        (row['power_source'] as String?)?.toUpperCase() ?? 'AC';
    final deviceStatusStr =
        (row['device_status'] as String?)?.toUpperCase() ?? 'OFFLINE';

    final ValveState valveState =
        valveStatusStr == 'CLOSED' ? ValveState.closed : ValveState.open;

    final String lastComm = row['last_communication_at'] != null
        ? _formatTimestamp(row['last_communication_at'] as String)
        : 'Never';

    return DeviceRecord(
      id: row['id'] as String,
      serialNumber: row['serial_number'] as String,
      status: deviceStatusStr == 'ONLINE'
          ? DeviceStatus.online
          : DeviceStatus.offline,
      location: row['device_name'] as String? ?? 'Unknown device',
      lastCommunication: lastComm,
      gasStatus: gasStatusStr,
      valveState: valveState,
      battery: row['battery_percentage'] as int?,
      gsmSignalCsq: row['gsm_signal'] as int? ?? 0,
      gsmSignalQuality: _gsmQuality(row['gsm_signal'] as int? ?? 0),
      powerSource: powerSourceStr == 'BATTERY' ? PowerSource.battery : (powerSourceStr == 'AC' ? PowerSource.ac : null),
    );
  }

  String _gsmQuality(int csq) {
    if (csq >= 20) return 'Good';
    if (csq >= 12) return 'Fair';
    return 'Weak';
  }

  String _formatTimestamp(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return '${diff.inSeconds} sec ago';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hr ago';
      return '${diff.inDays} days ago';
    } catch (_) {
      return 'Unknown';
    }
  }
}

// ─── MonitoringData DTO ───────────────────────────────────────────────────────

/// Holds all data needed by MonitorScreen.
class MonitoringData {
  const MonitoringData({
    required this.gasLevelPpm,
    required this.warningThreshold,
    required this.dangerThreshold,
    required this.gasStatus,
    required this.valveState,
    required this.battery,
    required this.gsmSignalCsq,
    required this.systemOnline,
    required this.powerSource,
    required this.trendValues,
    required this.latestReadingAt,
    required this.deviceId,
  });

  final int gasLevelPpm;
  final int warningThreshold;
  final int dangerThreshold;
  final SafetyLevel gasStatus;
  final ValveState valveState;
  final int? battery;
  final int gsmSignalCsq;
  final bool systemOnline;
  final PowerSource? powerSource;
  /// Ordered list of gas_level_ppm doubles for the trend chart.
  final List<double> trendValues;
  final String latestReadingAt;
  final String deviceId;

  bool get hasReadings => trendValues.isNotEmpty;
}
