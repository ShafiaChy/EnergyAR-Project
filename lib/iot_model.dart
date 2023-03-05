import 'dart:convert';

class IoTHome {
  bool lightState;
  bool bulbState;
  bool fanState;
  int lightVolt;
  int bulbVolt;
  int fanVolt;
  double lightAmp;
  double bulbAmp;
  double fanAmp;

  IoTHome({
    required this.lightState,
    required this.bulbState,
    required this.fanState,
    required this.lightVolt,
    required this.bulbVolt,
    required this.fanVolt,
    required this.lightAmp,
    required this.bulbAmp,
    required this.fanAmp,
  });

  IoTHome copyWith({
    bool? lightState,
    bool? bulbState,
    bool? fanState,
    int? lightVolt,
    int? bulbVolt,
    int? fanVolt,
    double? lightAmp,
    double? bulbAmp,
    double? fanAmp,
  }) {
    return IoTHome(
      lightState: lightState ?? this.lightState,
      bulbState: bulbState ?? this.bulbState,
      fanState: fanState ?? this.fanState,
      lightVolt: lightVolt ?? this.lightVolt,
      bulbVolt: bulbVolt ?? this.bulbVolt,
      fanVolt: fanVolt ?? this.fanVolt,
      lightAmp: lightAmp ?? this.lightAmp,
      bulbAmp: bulbAmp ?? this.bulbAmp,
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
      'v7': '',
      'v8': '',
    };
  }

  Map<String, dynamic> toMapLight(bool state) {
    return <String, dynamic>{
      'v0': state ? '1' : '0',
    };
  }

  Map<String, dynamic> toMapBulb(bool state) {
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
      'v1': bulbState,
      'v2': fanState,
      'v3': lightVolt,
      'v4': bulbVolt,
      'v5': fanVolt,
      'v6': lightAmp,
      'v7': bulbAmp,
      'v8': fanAmp,
    };
  }

  factory IoTHome.fromMap(Map<String, dynamic> map) {
    return IoTHome(
      lightState: map['v0'] as int == 1 ? true : false,
      bulbState: map['v1'] as int == 1 ? true : false,
      fanState: map['v2'] as int == 1 ? true : false,
      lightVolt: map['v3'] as int,
      bulbVolt: map['v4'] as int,
      fanVolt: map['v5'] as int,
      lightAmp: map['v6'] as double,
      bulbAmp: map['v7'] as double,
      fanAmp: map['v8'] as double,
    );
  }

  String toJson() => json.encode(toMap());

  factory IoTHome.fromJson(String source) => IoTHome.fromMap(json.decode(source) as Map<String, dynamic>);

  double lightWatt() => lightVolt * lightAmp * 0.9;
  double bulbWatt() => bulbVolt * bulbAmp * 0.9;
  double fanWatt() => fanVolt * fanAmp * 0.9;

  @override
  String toString() {
    return 'Home(v0: $lightState, v1: $bulbState, v2: $fanState, v3: $lightVolt, v4: $bulbVolt, v5: $fanVolt, v6: $lightAmp, v7: $bulbAmp, v8: $fanAmp)';
  }

  @override
  bool operator ==(covariant IoTHome other) {
    if (identical(this, other)) return true;

    return other.lightState == lightState &&
        other.bulbState == bulbState &&
        other.fanState == fanState &&
        other.lightVolt == lightVolt &&
        other.bulbVolt == bulbVolt &&
        other.fanVolt == fanVolt &&
        other.lightAmp == lightAmp &&
        other.bulbAmp == bulbAmp &&
        other.fanAmp == fanAmp;
  }

  @override
  int get hashCode {
    return lightState.hashCode ^
        bulbState.hashCode ^
        fanState.hashCode ^
        lightVolt.hashCode ^
        bulbVolt.hashCode ^
        fanVolt.hashCode ^
        lightAmp.hashCode ^
        bulbAmp.hashCode ^
        fanAmp.hashCode;
  }
}
