import 'dart:convert';

class IoTHome {
  bool lightState;
  bool freezeState;
  bool fanState;
  int acVolt;
  double lightAmp;
  double freezeAmp;
  double fanAmp;

  IoTHome({
    required this.lightState,
    required this.freezeState,
    required this.fanState,
    required this.acVolt,
    required this.lightAmp,
    required this.freezeAmp,
    required this.fanAmp,
  });

  IoTHome copyWith({
    bool? lightState,
    bool? freezeState,
    bool? fanState,
    int? acVolt,
    double? lightAmp,
    double? freezeAmp,
    double? fanAmp,
  }) {
    return IoTHome(
      lightState: lightState ?? this.lightState,
      freezeState: freezeState ?? this.freezeState,
      fanState: fanState ?? this.fanState,
      acVolt: acVolt ?? this.acVolt,
      lightAmp: lightAmp ?? this.lightAmp,
      freezeAmp: freezeAmp ?? this.freezeAmp,
      fanAmp: fanAmp ?? this.fanAmp,
    );
  }

  Map<String, String> toMapGet() {
    return <String, String>{
      'v0': '',
      'v1': '',
      'v2': '',
      'v3': '',
      'v4': '',
      'v5': '',
      'v6': '',
    };
  }

  Map<String, dynamic> toMapLight(bool state) {
    return <String, dynamic>{
      'v0': state ? '1' : '0',
    };
  }

  Map<String, dynamic> toMapFreeze(bool state) {
    return <String, dynamic>{
      'v1': state ? '1' : '0',
    };
  }

  Map<String, dynamic> toMapFan(bool state) {
    return <String, dynamic>{
      'v2': state ? '1' : '0',
    };
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'v0': lightState,
      'v1': freezeState,
      'v2': fanState,
      'v3': acVolt,
      'v4': lightAmp,
      'v5': freezeAmp,
      'v6': fanAmp,
    };
  }

  factory IoTHome.fromMap(Map<String, dynamic> map) {
    return IoTHome(
      lightState: map['v0'] as int == 1 ? true : false,
      freezeState: map['v1'] as int == 1 ? true : false,
      fanState: map['v2'] as int == 1 ? true : false,
      acVolt: map['v3'] as int,
      lightAmp: map['v4'] as double,
      freezeAmp: map['v5'] as double,
      fanAmp: map['v6'] as double,
    );
  }

  String toJson() => json.encode(toMap());

  factory IoTHome.fromJson(String source) => IoTHome.fromMap(json.decode(source) as Map<String, dynamic>);

  double lightWatt() => acVolt * lightAmp * 0.9;
  double freezeWatt() => acVolt * freezeAmp * 0.9;
  double fanWatt() => acVolt * fanAmp * 0.9;

  @override
  String toString() {
    return 'Home(v0: $lightState, v1: $freezeState, v2: $fanState, v3: $acVolt, v4: $lightAmp, v5: $freezeAmp, v6: $fanAmp)';
  }

  @override
  bool operator ==(covariant IoTHome other) {
    if (identical(this, other)) return true;

    return other.lightState == lightState &&
        other.freezeState == freezeState &&
        other.fanState == fanState &&
        other.acVolt == acVolt &&
        other.lightAmp == lightAmp &&
        other.freezeAmp == freezeAmp &&
        other.fanAmp == fanAmp;
  }

  @override
  int get hashCode {
    return lightState.hashCode ^
        freezeState.hashCode ^
        fanState.hashCode ^
        acVolt.hashCode ^
        lightAmp.hashCode ^
        freezeAmp.hashCode ^
        fanAmp.hashCode;
  }
}
