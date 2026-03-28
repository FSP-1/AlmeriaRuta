import 'dart:convert';

const Object _unset = Object();

class RechargeReminderSettings {
  final bool enabled;
  final String? monthlyExpiryDateIso; // yyyy-MM-dd
  final int hour;
  final int minute;

  const RechargeReminderSettings({
    required this.enabled,
    required this.monthlyExpiryDateIso,
    required this.hour,
    required this.minute,
  });

  const RechargeReminderSettings.defaults()
      : enabled = false,
        monthlyExpiryDateIso = null,
        hour = 20,
        minute = 0;

  RechargeReminderSettings copyWith({
    bool? enabled,
    Object? monthlyExpiryDateIso = _unset,
    int? hour,
    int? minute,
  }) {
    return RechargeReminderSettings(
      enabled: enabled ?? this.enabled,
      monthlyExpiryDateIso: identical(monthlyExpiryDateIso, _unset)
          ? this.monthlyExpiryDateIso
          : monthlyExpiryDateIso as String?,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'monthlyExpiryDateIso': monthlyExpiryDateIso,
        'hour': hour,
        'minute': minute,
      };

  factory RechargeReminderSettings.fromJson(Map<String, dynamic> json) {
    return RechargeReminderSettings(
      enabled: json['enabled'] == true,
      monthlyExpiryDateIso: json['monthlyExpiryDateIso']?.toString(),
      hour: (json['hour'] as num?)?.toInt() ?? 20,
      minute: (json['minute'] as num?)?.toInt() ?? 0,
    );
  }
}

class ArrivalAlertSettings {
  final bool enabled;
  final int leadMinutes;
  final String? lineId;
  final String? lineName;
  final String? stopId;
  final String? stopName;

  const ArrivalAlertSettings({
    required this.enabled,
    required this.leadMinutes,
    required this.lineId,
    required this.lineName,
    required this.stopId,
    required this.stopName,
  });

  const ArrivalAlertSettings.defaults()
      : enabled = false,
        leadMinutes = 5,
        lineId = null,
        lineName = null,
        stopId = null,
        stopName = null;

  ArrivalAlertSettings copyWith({
    bool? enabled,
    int? leadMinutes,
    Object? lineId = _unset,
    Object? lineName = _unset,
    Object? stopId = _unset,
    Object? stopName = _unset,
  }) {
    return ArrivalAlertSettings(
      enabled: enabled ?? this.enabled,
      leadMinutes: leadMinutes ?? this.leadMinutes,
      lineId: identical(lineId, _unset) ? this.lineId : lineId as String?,
      lineName: identical(lineName, _unset) ? this.lineName : lineName as String?,
      stopId: identical(stopId, _unset) ? this.stopId : stopId as String?,
      stopName: identical(stopName, _unset) ? this.stopName : stopName as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'leadMinutes': leadMinutes,
        'lineId': lineId,
        'lineName': lineName,
        'stopId': stopId,
        'stopName': stopName,
      };

  factory ArrivalAlertSettings.fromJson(Map<String, dynamic> json) {
    return ArrivalAlertSettings(
      enabled: json['enabled'] == true,
      leadMinutes: (json['leadMinutes'] as num?)?.toInt() ?? 5,
      lineId: json['lineId']?.toString(),
      lineName: json['lineName']?.toString(),
      stopId: json['stopId']?.toString(),
      stopName: json['stopName']?.toString(),
    );
  }
}

class NotificationSettings {
  final RechargeReminderSettings recharge;
  final ArrivalAlertSettings arrival;

  const NotificationSettings({
    required this.recharge,
    required this.arrival,
  });

  const NotificationSettings.defaults()
      : recharge = const RechargeReminderSettings.defaults(),
        arrival = const ArrivalAlertSettings.defaults();

  NotificationSettings copyWith({
    RechargeReminderSettings? recharge,
    ArrivalAlertSettings? arrival,
  }) {
    return NotificationSettings(
      recharge: recharge ?? this.recharge,
      arrival: arrival ?? this.arrival,
    );
  }

  Map<String, dynamic> toJson() => {
        'recharge': recharge.toJson(),
        'arrival': arrival.toJson(),
      };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      recharge: json['recharge'] is Map<String, dynamic>
          ? RechargeReminderSettings.fromJson(json['recharge'] as Map<String, dynamic>)
          : const RechargeReminderSettings.defaults(),
      arrival: json['arrival'] is Map<String, dynamic>
          ? ArrivalAlertSettings.fromJson(json['arrival'] as Map<String, dynamic>)
          : const ArrivalAlertSettings.defaults(),
    );
  }

  String toStorageString() => jsonEncode(toJson());

  factory NotificationSettings.fromStorageString(String raw) {
    try {
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) {
        return NotificationSettings.fromJson(json);
      }
    } catch (_) {}
    return const NotificationSettings.defaults();
  }
}
