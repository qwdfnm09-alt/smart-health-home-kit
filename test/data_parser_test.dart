import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_health_home_kit/utils/data_parser.dart';
import 'package:smart_health_home_kit/utils/device_type.dart';

void main() {
  group('DataParser Robust Unit Tests', () {
    
    // 🩺 اختبارات ضغط الدم (Blood Pressure)
    group('Blood Pressure Parsing', () {
      test('Normal values: 120/80, Pulse 72', () {
        final rawData = Uint8List.fromList([
          0x00, 0x00, 120, 0x00, 80, 0x00, 0x00, 0x00, 72, 0x00, 0x00, 0x00
        ]);
        final result = DataParser.parse(rawData, deviceType: DeviceType.bloodPressure);
        expect(result['systolic'], 120);
        expect(result['diastolic'], 80);
        expect(result['pulse'], 72);
      });

      test('High values: 180/110, Pulse 105', () {
        // 180 = 0xB4, 110 = 0x6E, 105 = 0x69
        final rawData = Uint8List.fromList([
          0x00, 0x00, 0xB4, 0x00, 0x6E, 0x00, 0x00, 0x00, 0x69, 0x00, 0x00, 0x00
        ]);
        final result = DataParser.parse(rawData, deviceType: DeviceType.bloodPressure);
        expect(result['systolic'], 180);
        expect(result['diastolic'], 110);
        expect(result['pulse'], 105);
      });

      test('Large bit values (e.g. Systolic 300)', () {
        // 300 = 0x12C -> data[2]=0x2C, data[3]=0x01
        final rawData = Uint8List.fromList([
          0x00, 0x00, 0x2C, 0x01, 80, 0x00, 0x00, 0x00, 72, 0x00, 0x00, 0x00
        ]);
        final result = DataParser.parse(rawData, deviceType: DeviceType.bloodPressure);
        expect(result['systolic'], 300);
      });

      test('Invalid data length (11 bytes)', () {
        final rawData = Uint8List(11);
        final result = DataParser.parse(rawData, deviceType: DeviceType.bloodPressure);
        expect(result['healthData'], isNull);
      });
    });

    // 🍬 اختبارات السكر (Glucose)
    group('Glucose Parsing', () {
      test('Normal fasting: 95 mg/dL', () {
        final rawData = Uint8List.fromList([
          0x55, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 95, 0x00, 0x00
        ]);
        final result = DataParser.parse(rawData, deviceType: DeviceType.glucose);
        expect(result['glucose'], 95.0);
        expect(result['unit'], 'mg/dL');
      });

      test('High post-meal: 250 mg/dL', () {
        // 250 = 0xFA
        final rawData = Uint8List.fromList([
          0x55, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFA, 0x00, 0x00
        ]);
        final result = DataParser.parse(rawData, deviceType: DeviceType.glucose);
        expect(result['glucose'], 250.0);
      });

      test('Invalid header (not 0x55)', () {
        final rawData = Uint8List.fromList([
          0xAA, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 100, 0x00, 0x00
        ]);
        final result = DataParser.parse(rawData, deviceType: DeviceType.glucose);
        expect(result.containsKey('glucose'), isFalse);
      });
    });

    // 🌡 اختبارات الحرارة (Thermometer)
    group('Thermometer Parsing', () {
      test('Normal Body Temp: 37.0°C', () {
        // 370 = 0x0172 -> [0x72, 0x01, 0x00], Exp -1
        final rawData = Uint8List.fromList([0x00, 0x72, 0x01, 0x00, 0xFF]);
        final result = DataParser.parse(rawData, deviceType: DeviceType.thermometer);
        expect(result['temperature'], closeTo(37.0, 0.01));
        expect(result['unit'], '°C');
      });

      test('High Fever: 40.5°C', () {
        // 405 = 0x0195 -> [0x95, 0x01, 0x00], Exp -1
        final rawData = Uint8List.fromList([0x00, 0x95, 0x01, 0x00, 0xFF]);
        final result = DataParser.parse(rawData, deviceType: DeviceType.thermometer);
        expect(result['temperature'], closeTo(40.5, 0.01));
      });

      test('Fahrenheit test: 98.6°F', () {
        // 986 = 0x03DA -> [0xDA, 0x03, 0x00], Exp -1, Flag 0x01
        final rawData = Uint8List.fromList([0x01, 0xDA, 0x03, 0x00, 0xFF]);
        final result = DataParser.parse(rawData, deviceType: DeviceType.thermometer);
        expect(result['temperature'], closeTo(98.6, 0.01));
        expect(result['unit'], '°F');
      });

      test('Low ambient temp: 15.25°C', () {
        // 1525 = 0x05F5 -> [0xF5, 0x05, 0x00], Exp -2
        final rawData = Uint8List.fromList([0x00, 0xF5, 0x05, 0x00, 0xFE]);
        final result = DataParser.parse(rawData, deviceType: DeviceType.thermometer);
        expect(result['temperature'], closeTo(15.25, 0.01));
      });
    });

    // ❓ اختبار الحالات المجهولة (Edge Cases)
    group('Edge Cases', () {
      test('Null device type', () {
        final rawData = Uint8List.fromList([0x01, 0x02]);
        final result = DataParser.parse(rawData);
        expect(result['type'], DeviceType.unknown);
      });

      test('Empty data list', () {
        final rawData = Uint8List(0);
        final result = DataParser.parse(rawData, deviceType: DeviceType.thermometer);
        expect(result.containsKey('temperature'), isFalse);
      });
    });
  });
}
