import 'dart:convert';
import 'dart:typed_data';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/my_utils.dart';

part 'thingy53_parser.freezed.dart';
part 'thingy53_parser.g.dart';

@freezed
abstract class Thingy53Telemetry with _$Thingy53Telemetry {
  const factory Thingy53Telemetry({
    double? temperature,
    double? humidity,
    double? pressure,
    double? gasResistance,
    // Accelerometer (BMI270 or ADXL362)
    double? accelX,
    double? accelY,
    double? accelZ,
    // Gyroscope (BMI270)
    double? gyroX,
    double? gyroY,
    double? gyroZ,
    // Magnetometer (BMM150)
    double? magX,
    double? magY,
    double? magZ,
    // Ambient Light / Colour (BH1749)
    int? lightRed,
    int? lightGreen,
    int? lightBlue,
    int? lightIr,
    // Battery Voltage in millivolts
    int? batteryMillivolts,
    // Raw output data
    String? rawOutput,
  }) = _Thingy53Telemetry;

  factory Thingy53Telemetry.fromJson(Map<String, dynamic> json) =>
      _$Thingy53TelemetryFromJson(json);
}

class Thingy53Parser {
  /// Parses raw BLE notifier payloads (bytes) from NUS TX.
  /// Decodes the payload as a string and extracts telemetry fields.
  static Thingy53Telemetry parse(Uint8List data) {
    final text = utf8.decode(data, allowMalformed: true).trim();

    // 1. Try parsing JSON format
    if (text.startsWith('{') && text.endsWith('}')) {
      try {
        final decoded = json.decode(text) as Map<String, dynamic>;
        return Thingy53Telemetry.fromJson(decoded).copyWith(rawOutput: text);
      } on Exception catch (_, e) {
        // Fallback to text parsing
        myUtils.err(e.toString());
      }
    }

    // 2. Try parsing plain text format
    return parseText(text);
  }

  /// Parses textual output from sensors or shells.
  static Thingy53Telemetry parseText(String text) {
    double? temp;
    double? hum;
    double? press;
    double? gas;
    double? ax, ay, az;
    double? gx, gy, gz;
    double? mx, my, mz;
    int? r, g, b, ir;
    int? bat;

    // Matches temperature (e.g. "temperature: 23.50 C", "temp=23.5")
    final tempMatch = RegExp(
      r'(?:temperature|temp)[:\s=]+\s*([\d.-]+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (tempMatch != null) temp = double.tryParse(tempMatch.group(1) ?? '');

    // Matches humidity (e.g. "humidity: 45.2 %", "hum=45.2")
    final humMatch = RegExp(
      r'(?:humidity|hum)[:\s=]+\s*([\d.-]+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (humMatch != null) hum = double.tryParse(humMatch.group(1) ?? '');

    // Matches pressure (e.g. "pressure: 1013.25 hPa", "press=1013.25")
    final pressMatch = RegExp(
      r'(?:pressure|press)[:\s=]+\s*([\d.-]+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (pressMatch != null) press = double.tryParse(pressMatch.group(1) ?? '');

    // Matches gas resistance (e.g. "gas: 50000 ohm", "gas_resistance=50000")
    final gasMatch = RegExp(
      r'(?:gas|gas_resistance|gas_res)[:\s=]+\s*([\d.-]+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (gasMatch != null) gas = double.tryParse(gasMatch.group(1) ?? '');

    // Matches accelerometer: x, y, z
    final accelMatch = RegExp(
      r'(?:accel|bmi270|adxl362)[^\n]*?x[:\s=]+\s*([\d.-]+)[^\n]*?y[:\s=]+\s*([\d.-]+)[^\n]*?z[:\s=]+\s*([\d.-]+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (accelMatch != null) {
      ax = double.tryParse(accelMatch.group(1) ?? '');
      ay = double.tryParse(accelMatch.group(2) ?? '');
      az = double.tryParse(accelMatch.group(3) ?? '');
    }

    // Matches gyroscope: x, y, z
    final gyroMatch = RegExp(
      r'(?:gyro|gyroscope)[^\n]*?x[:\s=]+\s*([\d.-]+)[^\n]*?y[:\s=]+\s*([\d.-]+)[^\n]*?z[:\s=]+\s*([\d.-]+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (gyroMatch != null) {
      gx = double.tryParse(gyroMatch.group(1) ?? '');
      gy = double.tryParse(gyroMatch.group(2) ?? '');
      gz = double.tryParse(gyroMatch.group(3) ?? '');
    }

    // Matches magnetometer: x, y, z
    final magMatch = RegExp(
      r'(?:mag|magnetometer|bmm150)[^\n]*?x[:\s=]+\s*([\d.-]+)[^\n]*?y[:\s=]+\s*([\d.-]+)[^\n]*?z[:\s=]+\s*([\d.-]+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (magMatch != null) {
      mx = double.tryParse(magMatch.group(1) ?? '');
      my = double.tryParse(magMatch.group(2) ?? '');
      mz = double.tryParse(magMatch.group(3) ?? '');
    }

    // Matches ambient light/color (BH1749): r, g, b, ir
    final colorMatch = RegExp(
      r'(?:color|light|bh1749)[^\n]*?r[:\s=]+\s*(\d+)[^\n]*?g[:\s=]+\s*(\d+)[^\n]*?b[:\s=]+\s*(\d+)(?:[^\n]*?ir[:\s=]+\s*(\d+))?',
      caseSensitive: false,
    ).firstMatch(text);
    if (colorMatch != null) {
      r = int.tryParse(colorMatch.group(1) ?? '');
      g = int.tryParse(colorMatch.group(2) ?? '');
      b = int.tryParse(colorMatch.group(3) ?? '');
      if (colorMatch.groupCount >= 4) {
        ir = int.tryParse(colorMatch.group(4) ?? '');
      }
    }

    // Matches battery voltage: e.g. "battery: 3700 mV", "r_mv: 3700"
    final batMatch = RegExp(
      r'(?:battery|bat|bat_mv|r_mv)[:\s=]+\s*(\d+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (batMatch != null) {
      bat = int.tryParse(batMatch.group(1) ?? '');
    }

    return Thingy53Telemetry(
      temperature: temp,
      humidity: hum,
      pressure: press,
      gasResistance: gas,
      accelX: ax,
      accelY: ay,
      accelZ: az,
      gyroX: gx,
      gyroY: gy,
      gyroZ: gz,
      magX: mx,
      magY: my,
      magZ: mz,
      lightRed: r,
      lightGreen: g,
      lightBlue: b,
      lightIr: ir,
      batteryMillivolts: bat,
      rawOutput: text,
    );
  }

  static parseByteArray(Uint8List data) {
    final p = Uint8List.fromList(data);
    myUtils.log('parseByteArray received ${p.length} bytes');
    final hexBytes = p
        .take(4)
        .map((b) => '0x${b.toRadixString(16).padLeft(2, '0').toUpperCase()}')
        .join(', ');
    myUtils.log(hexBytes);

    if (p[0] == 0xA5 && p[1] == 0x5A) {
      parseNusData(p);
    } else {
      myUtils.err("Magic word not matched");
    }
  }

  static parseNusData(Uint8List p) {
    final len = p[2];
    final msgCount = p[3];
    final msgIdRaw = p[4];
    final msgLen = p[5];

    myUtils.log(
      'parseNusData received $len bytes, count $msgCount, id $msgIdRaw, len $msgLen',
    );

    final msgId = MsgId.fromValue(msgIdRaw);
    if (msgId == null) {
      myUtils.err('invalid msg id, $msgIdRaw');
      return;
    }

    switch (msgId) {
      case MsgId.msgResVer:
        final version = utf8.decode(
          Uint8List.sublistView(p, 6, 6 + msgLen),
          allowMalformed: true,
        );
        myUtils.log('received version info, $version');
        break;
      case MsgId.msgResStats:
        // TODO: Implement statistics parser
        break;
      default:
        break;
    }
  }
}

enum MsgId {
  msgGetVer(0x10),
  msgResVer(0x11),
  msgGetStats(0x12),
  msgResStats(0x13),
  msgSetSensorInit(0x14),
  msgResSensorInit(0x15),
  msgSetTelemetry(0x16),
  msgResTelemetry(0x17),
  msgSetSmDuration(0x18),
  msgResSmDuration(0x19),
  msgMax(0x1A);

  final int value;
  const MsgId(this.value);

  static MsgId? fromValue(int val) {
    for (final type in MsgId.values) {
      if (type.value == val) return type;
    }
    return null;
  }
}
