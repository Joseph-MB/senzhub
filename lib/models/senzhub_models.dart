enum SafetyLevel { safe, warning, danger }
enum ValveState { open, closed, safetyLock }
enum ValveAction { open, close }
enum DeviceStatus { online, offline }
enum PowerSource { ac, battery }
enum AlertSeverity { info, warning, danger, critical }

class ValveCommandRecord {
  const ValveCommandRecord({
    required this.id,
    required this.deviceId,
    required this.command,
    required this.status,
    this.failureReason,
    this.requestedAt,
    this.executedAt,
    this.acknowledgedAt,
  });

  final String id;
  final String deviceId;
  final String command;
  final String status;
  final String? failureReason;
  final DateTime? requestedAt;
  final DateTime? executedAt;
  final DateTime? acknowledgedAt;
}


class OnboardingSlide {
  const OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badge,
  });

  final String title;
  final String subtitle;
  final String icon;
  final String badge;
}

class AlertItem {
  const AlertItem({
    required this.title,
    required this.message,
    required this.severity,
    required this.timestamp,
    required this.gasLevel,
    required this.action,
  });

  final String title;
  final String message;
  final AlertSeverity severity;
  final String timestamp;
  final int gasLevel;
  final String action;
}

class DeviceRecord {
  const DeviceRecord({
    required this.id,
    required this.serialNumber,
    required this.status,
    required this.location,
    required this.lastCommunication,
    required this.gasStatus,
    required this.valveState,
    required this.battery,
    required this.gsmSignalCsq,
    required this.gsmSignalQuality,
    required this.powerSource,
  });

  final String id;
  final String serialNumber;
  final DeviceStatus status;
  final String location;
  final String lastCommunication;
  final String gasStatus;
  final ValveState valveState;
  final int? battery;
  final int gsmSignalCsq;
  final String gsmSignalQuality;
  final PowerSource? powerSource;
}

class DiagnosticItem {
  const DiagnosticItem({
    required this.name,
    required this.status,
    required this.lastChecked,
    required this.message,
  });

  final String name;
  final String status;
  final String lastChecked;
  final String message;
}

class BookingItem {
  const BookingItem({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final String value;
  final String detail;
}

class SystemSnapshot {
  const SystemSnapshot({
    required this.gasLevelPpm,
    required this.warningThreshold,
    required this.dangerThreshold,
    required this.gasStatus,
    required this.valveState,
    required this.battery,
    required this.gsmSignalCsq,
    required this.gsmSignalQuality,
    required this.systemOnline,
    required this.powerSource,
    required this.latestAlert,
    required this.deviceId,
    required this.location,
  });

  final int gasLevelPpm;
  final int warningThreshold;
  final int dangerThreshold;
  final SafetyLevel gasStatus;
  final ValveState valveState;
  final int? battery;
  final int gsmSignalCsq;
  final String gsmSignalQuality;
  final bool systemOnline;
  final PowerSource? powerSource;
  final AlertItem latestAlert;
  final String deviceId;
  final String location;
}

class SdgTarget {
  const SdgTarget({
    required this.number,
    required this.text,
  });

  final String number;
  final String text;
}

class SdgGoal {
  const SdgGoal({
    required this.number,
    required this.name,
    required this.icon,
    required this.summary,
    required this.purpose,
    required this.contribution,
    required this.targets,
    required this.senzhubRelation,
  });

  final String number;
  final String name;
  final String icon;
  final String summary;
  final String purpose;
  final String contribution;
  final List<SdgTarget> targets;
  final String? senzhubRelation;
}
