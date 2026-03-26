class ThermometerReading {
  final double temperature; // °C أو °F
  final String unit;        // "°C" أو "°F"
  final DateTime datetime;  // وقت القياس
  final String source;      // اسم الجهاز
  final Map<String, dynamic>? raw; // البيانات الخام للديباج

  ThermometerReading({
    required this.temperature,
    required this.unit,
    required this.datetime,
    required this.source,
    this.raw,
  });

  factory ThermometerReading.fromMap(Map<String, dynamic> map) {
    final dynamic maybeValue = map['temperature'] ?? map['value'];
    final double temp = (maybeValue is num)
        ? maybeValue.toDouble()
        : double.tryParse('${maybeValue ?? 0}') ?? 0.0;

    final String unit = (map['unit'] ?? "°C").toString();

    DateTime datetime;
    final dtStr = map['datetime'] ?? map['timestamp'] ?? map['datetime_iso'];
    if (dtStr is String) {
      datetime = DateTime.tryParse(dtStr) ?? DateTime.now();
    } else {
      datetime = DateTime.now();
    }

    final source = (map['device'] ?? map['source'] ?? 'thermometer').toString();

    return ThermometerReading(
      temperature: temp,
      unit: unit,
      datetime: datetime,
      source: source,
      raw: Map<String, dynamic>.from(map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'unit': unit,
      'datetime': datetime.toIso8601String(),
      'source': source,
    };
  }
}
