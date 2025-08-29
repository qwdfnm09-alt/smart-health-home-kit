import 'dart:math';
import 'dart:typed_data';
import 'device_type.dart';

class DataParser {
  static Map<String, dynamic> parse(
      Uint8List data, {
        required DeviceType deviceType,
      }) {
    switch (deviceType) {
      case DeviceType.glucose:
        return _parseGlucose(data);
      case DeviceType.thermometer:
        return _parseThermometer(data);
      case DeviceType.bloodPressure:
        return _parseBloodPressure(data);
      default:
        return {
          "type": "unknown",
          "raw": data,
          "timestamp": DateTime.now().toIso8601String(),
        };
    }
  }

  // ---------- Glucose (Samico GL ----------
  // Notify formats:
  // - Info:      18 bytes, [0]=0x55, [2]=0x00
  // - Countdown: 6  bytes, [0]=0x55, [2]=0x02
  // - Reading:   12 bytes, [0]=0x55, [2]=0x03
  static Map<String, dynamic> _parseGlucose(Uint8List d) {
    if (d.isEmpty) {
      return {"type": "glucose_unknown", "raw": d};
    }
    if (d[0] != 0x55) {
      // مش إطار GLU معروف
      return {"type": "glucose_unknown", "raw": d};
    }

    final pktType = d.length > 2 ? d[2] : 0xFF;

    if (pktType == 0x00 && d.length >= 18) {
      // Info
      final battery = d[5]; // 0..100
      return {
        "type": "glucose_info",
        "battery": battery,
        "raw": d,
        "timestamp": DateTime.now().toIso8601String(),
      };
    }

    if (pktType == 0x02 && d.length >= 6) {
      // Countdown
      final seconds = d[4];
      return {
        "type": "glucose_countdown",
        "seconds": seconds,
        "raw": d,
        "timestamp": DateTime.now().toIso8601String(),
      };
    }

    if (pktType == 0x03 && d.length >= 12) {
      // Reading
      int yy = d[3];
      if (yy > 0x40) yy -= 0x40;
      final year = 2000 + yy;
      final month = d[4];
      final day = d[5];
      final hour = d[6];
      final minute = d[7];
      final second = d[8];

      // الجلوكوز على بايتين. الدوك بيقول 0x0000-0x0190 (0..400)
      // هنفترض High ثم Low (لو الرقم طلع مش منطقي بدّل الترتيب)
      int glucoseRaw = (d[10] << 8) | d[11];

      return {
        "device": "glucose",
        "type": "reading",
        "value": glucoseRaw, // غالباً mg/dL. لو محتاج mmol/L = mg/dL / 18.0
        "units": "mg/dL",
        "datetime": DateTime(year, month, day, hour, minute, second).toIso8601String(),
        "raw": d,
        "timestamp": DateTime.now().toIso8601String(),
      };
    }

    return {"type": "glucose_unknown", "raw": d};
  }

  // ---------- Thermometer (Service 0x1809, Char 0x2A1C) ----------
  // Byte0: flags
  // Temp value: IEEE-11073 32-bit FLOAT (Little Endian على الهواء):
  // [mantissa (3 bytes) little-endian][exponent (1 byte signed)]
  static Map<String, dynamic> _parseThermometer(Uint8List d) {
    if (d.length < 5) {
      return {"type": "thermo_unknown", "raw": d};
    }

    int offset = 0;
    final flags = d[offset];
    offset += 1;

    // قيمة الحرارة 4 بايت: mantissa(3 LE) ثم exponent(int8)
    if (d.length < offset + 4) {
      return {"type": "thermo_unknown", "raw": d};
    }

    final mantissa = (d[offset] | (d[offset + 1] << 8) | (d[offset + 2] << 16));
    final exponent = _toSigned8(d[offset + 3]);
    offset += 4;

    // mantissa قد يكون signed 24-bit
    final mantissaSigned = _toSigned24(mantissa);

    final tempValue = mantissaSigned * pow(10, exponent).toDouble();

    final isFahrenheit = (flags & 0x01) != 0;
    final hasTimeStamp = (flags & 0x02) != 0;
    final hasType = (flags & 0x04) != 0;

    DateTime? time;
    if (hasTimeStamp && d.length >= offset + 7) {
      final year = d[offset] | (d[offset + 1] << 8);
      final month = d[offset + 2];
      final day = d[offset + 3];
      final hour = d[offset + 4];
      final minute = d[offset + 5];
      final second = d[offset + 6];
      offset += 7;
      time = DateTime(year, month, day, hour, minute, second);
    }

    int? tempType;
    if (hasType && d.length >= offset + 1) {
      tempType = d[offset];
      offset += 1;
    }

    return {
      "device": "thermometer",
      "type": "reading",
      "value": isFahrenheit ? _fToC(tempValue) : tempValue, // نرجعه °C
      "unit": "°C",
      "raw_unit": isFahrenheit ? "°F" : "°C",
      "timestamp": DateTime.now().toIso8601String(),
      if (time != null) "measurement_time": time.toIso8601String(),
      if (tempType != null) "temperature_type_key": tempType,
      "raw": d,
    };
  }

  // ---------- Blood Pressure (B180, FFF0/FFF4) ----------
  // قياس نهائي: 12 بايت:
  // [0] Flag
  // [1..2] SYS (High,Low)
  // [3..4] DIA (High,Low)
  // [5..6] MAP (High,Low) (غالباً 0)
  // [7..8] Pulse (High,Low)
  // [9] User
  // [10] PAD
  // [11] Status
  //
  // Testing (النفخ): 2 بايت: [0]=0x20, [1]=Pressure
  //
  // Memory (عند طلب Transfer Memory): 15 بايت يبدأ بـ FD FD
  static Map<String, dynamic> _parseBloodPressure(Uint8List d) {
    if (d.isEmpty) return {"type": "bp_unknown", "raw": d};

    // Memory frame
    if (d.length == 15 && d[0] == 0xFD && d[1] == 0xFD) {
      final status = d[2];
      final user = d[3];
      final sys = d[4];
      final dia = d[5];
      final pul = d[6];
      final yy = 2000 + d[7]; // Year2: 19..99 -> 2019..2099
      final mm = d[8];
      final dd = d[9];
      final hh = d[10];
      final mi = d[11];
      // Byte12 هو دقائق؟ (الدوك بيقول 6 Bytes DateTime) فـ d[12] = second
      final ss = d[12];

      return {
        "type": "bp_memory",
        "systolic": sys,
        "diastolic": dia,
        "pulse": pul,
        "user": user,
        "status": status,
        "datetime": DateTime(yy, mm, dd, hh, mi, ss).toIso8601String(),
        "raw": d,
        "timestamp": DateTime.now().toIso8601String(),
      };
    }

    // Testing (pressure during measuring)
    if (d.length == 2 && d[0] == 0x20) {
      final pressure = d[1];
      return {
        "type": "bp_testing",
        "pressure": pressure,
        "unit": "mmHg",
        "raw": d,
        "timestamp": DateTime.now().toIso8601String(),
      };
    }

    // Final 12-byte frame
    if (d.length >= 12) {
      final flag = d[0];
      final sys = (d[1] << 8) | d[2];
      final dia = (d[3] << 8) | d[4];
      final map = (d[5] << 8) | d[6];
      final pulse = (d[7] << 8) | d[8];
      final user = d[9];
      final pad = d[10];
      final status = d[11];

      return {
        "device": "bp",
        "type": "reading",
        "flag": flag,
        "value": {
          "systolic": sys,
          "diastolic": dia,
          "pulse": pulse,
        },
        "map": map,
        "user": user,
        "pad": pad == 1,
        "status": status,
        "unit": "mmHg",
        "datetime": DateTime.now().toIso8601String(),
        "raw": d,
        "timestamp": DateTime.now().toIso8601String(),
      };
    }

    return {"type": "bp_unknown", "raw": d};
  }

  // --------- Helpers ----------
  static int _toSigned8(int v) => v & 0x80 != 0 ? v - 256 : v;
  static int _toSigned24(int v) => v & 0x800000 != 0 ? v - 0x1000000 : v;

  static double _fToC(double f) => (f - 32.0) * 5.0 / 9.0;
}
