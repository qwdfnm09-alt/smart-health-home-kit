import 'package:flutter_test/flutter_test.dart';
import 'package:smart_health_home_kit/utils/constants.dart';

void main() {
  test('Health data type constants stay stable', () {
    expect(DataTypes.bp, 'bloodPressure');
    expect(DataTypes.glucose, 'glucose');
    expect(DataTypes.temp, 'temp');
  });
}
