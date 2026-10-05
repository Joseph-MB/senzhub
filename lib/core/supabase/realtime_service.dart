import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// RealtimeService handles channel creation, postgres_changes event listening,
/// and safe cleanup for realtime updates across SENZHUB screens.
class RealtimeService {
  final SupabaseClient _client = SupabaseService.client;

  /// Subscribes to new INSERT events on `device_readings` for a specific [deviceId].
  RealtimeChannel subscribeToReadings({
    required String deviceId,
    required void Function(Map<String, dynamic> newReading) onNewReading,
  }) {
    final channelName = 'realtime:readings:$deviceId:${DateTime.now().millisecondsSinceEpoch}';
    final channel = _client.channel(channelName);

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'device_readings',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'device_id',
        value: deviceId,
      ),
      callback: (payload) {
        if (payload.newRecord.isNotEmpty) {
          onNewReading(payload.newRecord);
        }
      },
    ).subscribe();

    return channel;
  }

  /// Subscribes to new INSERT events on `alerts`.
  RealtimeChannel subscribeToAlerts({
    required void Function(Map<String, dynamic> newAlert) onNewAlert,
  }) {
    final channelName = 'realtime:alerts:${DateTime.now().millisecondsSinceEpoch}';
    final channel = _client.channel(channelName);

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'alerts',
      callback: (payload) {
        if (payload.newRecord.isNotEmpty) {
          onNewAlert(payload.newRecord);
        }
      },
    ).subscribe();

    return channel;
  }

  /// Subscribes to UPDATE events on `devices`.
  RealtimeChannel subscribeToDevices({
    required void Function(Map<String, dynamic> updatedDevice) onDeviceUpdate,
  }) {
    final channelName = 'realtime:devices:${DateTime.now().millisecondsSinceEpoch}';
    final channel = _client.channel(channelName);

    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'devices',
      callback: (payload) {
        if (payload.newRecord.isNotEmpty) {
          onDeviceUpdate(payload.newRecord);
        }
      },
    ).subscribe();

    return channel;
  }

  /// Subscribes to updates on a specific `device_commands` row by [commandId].
  RealtimeChannel subscribeToCommand({
    required String commandId,
    required void Function(Map<String, dynamic> updatedCommand) onCommandUpdate,
  }) {
    final channelName = 'realtime:command:$commandId:${DateTime.now().millisecondsSinceEpoch}';
    final channel = _client.channel(channelName);

    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'device_commands',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: commandId,
      ),
      callback: (payload) {
        if (payload.newRecord.isNotEmpty) {
          onCommandUpdate(payload.newRecord);
        }
      },
    ).subscribe();

    return channel;
  }


  /// Safely unsubscribes and removes the [channel].
  Future<void> unsubscribe(RealtimeChannel? channel) async {
    if (channel != null) {
      await _client.removeChannel(channel);
    }
  }
}
