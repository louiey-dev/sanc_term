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

  static Thingy53Telemetry? parseByteArray(Uint8List data) {
    final p = Uint8List.fromList(data);
    myUtils.log('parseByteArray received ${p.length} bytes');

    if (p.length >= 6 && p[0] == 0xA5 && p[1] == 0x5A) {
      return parseNusData(p);
    } else if (p.length >= 62) {
      return parse62ByteTelemetry(p, 0);
    } else if (p.length >= 52) {
      return parse52ByteTelemetry(p, 0);
    } else {
      myUtils.err(
        "Payload too short or magic word not matched: ${p.length} bytes",
      );
      return null;
    }
  }

  /// Parses the updated 62-byte binary telemetry payload structure:
  /// - 8 bytes: Light (red, green, blue, ir as uint16_t big-endian)
  /// - 12 bytes: Environment (temp, press, hum as float32 little-endian)
  /// - 4 bytes: Gas resistance (gas_resistance as uint32_t big-endian)
  /// - 36 bytes: Motion (accX/Y/Z, gyroX/Y/Z, magX/Y/Z as float32 little-endian)
  /// - 2 bytes: Battery voltage (batt_mv as uint16_t big-endian)
  static Thingy53Telemetry parse62ByteTelemetry(Uint8List p, int offset) {
    final bd = ByteData.sublistView(p, offset, offset + 62);

    final lightRed = bd.getUint16(0, Endian.big);
    final lightGreen = bd.getUint16(2, Endian.big);
    final lightBlue = bd.getUint16(4, Endian.big);
    final lightIr = bd.getUint16(6, Endian.big);

    final temperature = bd.getFloat32(8, Endian.little);
    final pressure = bd.getFloat32(12, Endian.little);
    final humidity = bd.getFloat32(16, Endian.little);
    final gasResistance = bd.getUint32(20, Endian.big).toDouble();

    final accelX = bd.getFloat32(24, Endian.little);
    final accelY = bd.getFloat32(28, Endian.little);
    final accelZ = bd.getFloat32(32, Endian.little);

    final gyroX = bd.getFloat32(36, Endian.little);
    final gyroY = bd.getFloat32(40, Endian.little);
    final gyroZ = bd.getFloat32(44, Endian.little);

    final magX = bd.getFloat32(48, Endian.little);
    final magY = bd.getFloat32(52, Endian.little);
    final magZ = bd.getFloat32(56, Endian.little);

    final batteryMillivolts = bd.getUint16(60, Endian.big);

    final telemetry = Thingy53Telemetry(
      lightRed: lightRed,
      lightGreen: lightGreen,
      lightBlue: lightBlue,
      lightIr: lightIr,
      temperature: temperature,
      pressure: pressure,
      humidity: humidity,
      gasResistance: gasResistance,
      accelX: accelX,
      accelY: accelY,
      accelZ: accelZ,
      gyroX: gyroX,
      gyroY: gyroY,
      gyroZ: gyroZ,
      magX: magX,
      magY: magY,
      magZ: magZ,
      batteryMillivolts: batteryMillivolts,
      rawOutput: p
          .sublist(offset, offset + 62)
          .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(' '),
    );

    myUtils.log('Parsed 62-byte binary telemetry payload: $telemetry');
    return telemetry;
  }

  /// Parses the 52-byte binary telemetry payload structure:
  /// - 8 bytes: Light (red, green, blue, ir as uint16_t big-endian)
  /// - 6 bytes: Environment (temp val1/val2, press val1/val2, hum val1/val2 as int8_t)
  /// - 36 bytes: Motion (accX/Y/Z, gyroX/Y/Z, magX/Y/Z as float32 little-endian)
  /// - 2 bytes: Battery voltage (batt_mv as uint16_t big-endian)
  static Thingy53Telemetry parse52ByteTelemetry(Uint8List p, int offset) {
    final bd = ByteData.sublistView(p, offset, offset + 52);

    final lightRed = bd.getUint16(0, Endian.big);
    final lightGreen = bd.getUint16(2, Endian.big);
    final lightBlue = bd.getUint16(4, Endian.big);
    final lightIr = bd.getUint16(6, Endian.big);

    double parse2BVal(int v1, int v2) {
      final frac = v2 / 100.0;
      if (v1 < 0 || (v1 == 0 && v2 < 0)) {
        return v1 - frac.abs();
      }
      return v1 + frac;
    }

    final tempVal1 = bd.getInt8(8);
    final tempVal2 = bd.getInt8(9);
    final temperature = parse2BVal(tempVal1, tempVal2);

    final pressVal1 = bd.getInt8(10);
    final pressVal2 = bd.getInt8(11);
    final pressure = parse2BVal(pressVal1, pressVal2);

    final humVal1 = bd.getInt8(12);
    final humVal2 = bd.getInt8(13);
    final humidity = parse2BVal(humVal1, humVal2);

    final accelX = bd.getFloat32(14, Endian.little);
    final accelY = bd.getFloat32(18, Endian.little);
    final accelZ = bd.getFloat32(22, Endian.little);

    final gyroX = bd.getFloat32(26, Endian.little);
    final gyroY = bd.getFloat32(30, Endian.little);
    final gyroZ = bd.getFloat32(34, Endian.little);

    final magX = bd.getFloat32(38, Endian.little);
    final magY = bd.getFloat32(42, Endian.little);
    final magZ = bd.getFloat32(46, Endian.little);

    final batteryMillivolts = bd.getUint16(50, Endian.big);

    final telemetry = Thingy53Telemetry(
      lightRed: lightRed,
      lightGreen: lightGreen,
      lightBlue: lightBlue,
      lightIr: lightIr,
      temperature: temperature,
      pressure: pressure,
      humidity: humidity,
      accelX: accelX,
      accelY: accelY,
      accelZ: accelZ,
      gyroX: gyroX,
      gyroY: gyroY,
      gyroZ: gyroZ,
      magX: magX,
      magY: magY,
      magZ: magZ,
      batteryMillivolts: batteryMillivolts,
      rawOutput: p
          .sublist(offset, offset + 52)
          .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(' '),
    );

    myUtils.log('Parsed 52-byte binary telemetry payload: $telemetry');
    return telemetry;
  }

  static Thingy53Telemetry? parseNusData(Uint8List p) {
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
      return null;
    }

    switch (msgId) {
      case MsgId.msgResVer:
        if (p.length >= 6 + msgLen) {
          final version = utf8.decode(
            Uint8List.sublistView(p, 6, 6 + msgLen),
            allowMalformed: true,
          );
          myUtils.log('received version info, $version');
        }
        return null;
      case MsgId.msgResStats:
        return null;
      case MsgId.msgPktPayload:
        // Handle 62-byte payload structure (header: 6 bytes + payload: 62 bytes = 68 bytes total, or msgLen == 62)
        if (msgLen == 62 || p.length >= 68 || (p.length >= 6 && p.length - 6 >= 62)) {
          return parse62ByteTelemetry(p, 6);
        }

        // Handle 52-byte payload structure (header: 6 bytes + payload: 52 bytes = 58 bytes total)
        if (msgLen == 52 || (p.length >= 58 && p.length < 68)) {
          return parse52ByteTelemetry(p, 6);
        }

        // Legacy format fallback:
        // 4-byte sensor parsing (2B val1 + 2B val2 = 4B) requires 6 + 8 + 48 = 62 bytes total
        // 2-byte sensor parsing requires 6 + 8 + 24 = 38 bytes total
        if (p.length < 38) {
          myUtils.err(
            'msgPktPayload too short: ${p.length} bytes, expected at least 38',
          );
          return null;
        }

        int parseInt16(int offset) {
          final raw = (p[offset] << 8) | p[offset + 1];
          return raw > 32767 ? raw - 65536 : raw;
        }

        int parseUint16(int offset) {
          return (p[offset] << 8) | p[offset + 1];
        }

        double parseSensorValue4B(int offset, {double scale = 1000.0}) {
          final val1 = parseInt16(offset);
          final val2 = parseInt16(offset + 2);
          final frac = val2 / scale;
          return val1 >= 0 ? (val1 + frac) : (val1 - frac.abs());
        }

        final bool is4ByteFormat = p.length >= 62;

        double parseSensor(int offset4B, int offset2B) {
          if (is4ByteFormat) {
            return parseSensorValue4B(offset4B);
          } else {
            final rawB1 = p[offset2B];
            final rawB2 = p[offset2B + 1];
            final val1 = rawB1 > 127 ? rawB1 - 256 : rawB1;
            final val2 = rawB2 > 127 ? rawB2 - 256 : rawB2;
            return val1 + (val2 / 100.0);
          }
        }

        final int? batMv = is4ByteFormat
            ? (p.length >= 64 ? parseUint16(62) : null)
            : (p.length >= 40 ? parseUint16(38) : null);

        final telemetry = Thingy53Telemetry(
          lightRed: parseUint16(6),
          lightGreen: parseUint16(8),
          lightBlue: parseUint16(10),
          lightIr: parseUint16(12),
          temperature: parseSensor(14, 14),
          pressure: parseSensor(18, 16),
          humidity: parseSensor(22, 18),
          accelX: parseSensor(26, 20),
          accelY: parseSensor(30, 22),
          accelZ: parseSensor(34, 24),
          gyroX: parseSensor(38, 26),
          gyroY: parseSensor(42, 28),
          gyroZ: parseSensor(46, 30),
          magX: parseSensor(50, 32),
          magY: parseSensor(54, 34),
          magZ: parseSensor(58, 36),
          batteryMillivolts: batMv,
          rawOutput: p
              .take(p.length)
              .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
              .join(' '),
        );

        myUtils.log('Parsed legacy 16-sensor binary payload: $telemetry');
        return telemetry;
      case MsgId.msgPktCborSensor:
        return null;
      case MsgId.msgPktCborStats:
        return null;
      case MsgId.msgPktCborCpu:
        return null;
      default:
        return null;
    }
  }
}

extension Thingy53TelemetryX on Thingy53Telemetry {
  /// Formats the parsed Thingy:53 telemetry into a map suitable for SSE telemetry broadcasting.
  Map<String, dynamic> toTelemetryMap() {
    return {
      'temp_c': temperature,
      'humidity_pct': humidity,
      'pressure_hpa': pressure,
      'gas_res_ohm': gasResistance,
      'light_red': lightRed,
      'light_green': lightGreen,
      'light_blue': lightBlue,
      'light_ir': lightIr,
      'accel_x': accelX,
      'accel_y': accelY,
      'accel_z': accelZ,
      'gyro_x': gyroX,
      'gyro_y': gyroY,
      'gyro_z': gyroZ,
      'mag_x': magX,
      'mag_y': magY,
      'mag_z': magZ,
      'battery_mv': batteryMillivolts,
    };
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
  msgPktPayload(0x1A),
  msgSetSensorLog(0x1B),
  msgResSensorLog(0x1C),
  msgPktCborSensor(0x1D),
  msgPktCborStats(0x1E),
  msgPktCborCpu(0x1F),
  msgMax(0x1D);

  final int value;
  const MsgId(this.value);

  static MsgId? fromValue(int val) {
    for (final type in MsgId.values) {
      if (type.value == val) return type;
    }
    return null;
  }
}
