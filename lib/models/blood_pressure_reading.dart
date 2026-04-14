class BloodPressureReading {
  final int systolic;   // الضغط الانقباضي (أعلى قيمة)
  final int diastolic;  // الضغط الانبساطي (أقل قيمة)
  final int pulse;      // معدل النبض
  final DateTime datetime;
  final String source;  // اسم الجهاز
  final Map<String, dynamic>? raw; // البيانات الخام للديباج

  BloodPressureReading({
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.datetime,
    required this.source,
    this.raw,
  });

  factory BloodPressureReading.fromMap(Map<String, dynamic> map) {
    final int sys = (map['systolic'] ?? map['sys'] ?? 0) as int;
    final int dia = (map['diastolic'] ?? map['dia'] ?? 0) as int;
    final int pulse = (map['pulse'] ?? map['heartRate'] ?? 0) as int;

    DateTime datetime;
    final dtStr = map['datetime'] ?? map['timestamp'] ?? map['datetime_iso'];
    if (dtStr is String) {
      datetime = DateTime.tryParse(dtStr) ?? DateTime.now();
    } else {
      datetime = DateTime.now();
    }

    final source = (map['device'] ?? map['source'] ?? 'bloodPressure').toString();

    return BloodPressureReading(
      systolic: sys,
      diastolic: dia,
      pulse: pulse,
      datetime: datetime,
      source: source,
      raw: Map<String, dynamic>.from(map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'systolic': systolic,
      'diastolic': diastolic,
      'pulse': pulse,
      'datetime': datetime.toIso8601String(),
      'source': source,
    };
  }
}
