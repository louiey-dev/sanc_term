// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'thingy53_parser.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Thingy53Telemetry {

 double? get temperature; double? get humidity; double? get pressure; double? get gasResistance;// Accelerometer (BMI270 or ADXL362)
 double? get accelX; double? get accelY; double? get accelZ;// Gyroscope (BMI270)
 double? get gyroX; double? get gyroY; double? get gyroZ;// Magnetometer (BMM150)
 double? get magX; double? get magY; double? get magZ;// Ambient Light / Colour (BH1749)
 int? get lightRed; int? get lightGreen; int? get lightBlue; int? get lightIr;// Battery Voltage in millivolts
 int? get batteryMillivolts;// Raw output data
 String? get rawOutput;
/// Create a copy of Thingy53Telemetry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Thingy53TelemetryCopyWith<Thingy53Telemetry> get copyWith => _$Thingy53TelemetryCopyWithImpl<Thingy53Telemetry>(this as Thingy53Telemetry, _$identity);

  /// Serializes this Thingy53Telemetry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Thingy53Telemetry&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.humidity, humidity) || other.humidity == humidity)&&(identical(other.pressure, pressure) || other.pressure == pressure)&&(identical(other.gasResistance, gasResistance) || other.gasResistance == gasResistance)&&(identical(other.accelX, accelX) || other.accelX == accelX)&&(identical(other.accelY, accelY) || other.accelY == accelY)&&(identical(other.accelZ, accelZ) || other.accelZ == accelZ)&&(identical(other.gyroX, gyroX) || other.gyroX == gyroX)&&(identical(other.gyroY, gyroY) || other.gyroY == gyroY)&&(identical(other.gyroZ, gyroZ) || other.gyroZ == gyroZ)&&(identical(other.magX, magX) || other.magX == magX)&&(identical(other.magY, magY) || other.magY == magY)&&(identical(other.magZ, magZ) || other.magZ == magZ)&&(identical(other.lightRed, lightRed) || other.lightRed == lightRed)&&(identical(other.lightGreen, lightGreen) || other.lightGreen == lightGreen)&&(identical(other.lightBlue, lightBlue) || other.lightBlue == lightBlue)&&(identical(other.lightIr, lightIr) || other.lightIr == lightIr)&&(identical(other.batteryMillivolts, batteryMillivolts) || other.batteryMillivolts == batteryMillivolts)&&(identical(other.rawOutput, rawOutput) || other.rawOutput == rawOutput));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,temperature,humidity,pressure,gasResistance,accelX,accelY,accelZ,gyroX,gyroY,gyroZ,magX,magY,magZ,lightRed,lightGreen,lightBlue,lightIr,batteryMillivolts,rawOutput]);

@override
String toString() {
  return 'Thingy53Telemetry(temperature: $temperature, humidity: $humidity, pressure: $pressure, gasResistance: $gasResistance, accelX: $accelX, accelY: $accelY, accelZ: $accelZ, gyroX: $gyroX, gyroY: $gyroY, gyroZ: $gyroZ, magX: $magX, magY: $magY, magZ: $magZ, lightRed: $lightRed, lightGreen: $lightGreen, lightBlue: $lightBlue, lightIr: $lightIr, batteryMillivolts: $batteryMillivolts, rawOutput: $rawOutput)';
}


}

/// @nodoc
abstract mixin class $Thingy53TelemetryCopyWith<$Res>  {
  factory $Thingy53TelemetryCopyWith(Thingy53Telemetry value, $Res Function(Thingy53Telemetry) _then) = _$Thingy53TelemetryCopyWithImpl;
@useResult
$Res call({
 double? temperature, double? humidity, double? pressure, double? gasResistance, double? accelX, double? accelY, double? accelZ, double? gyroX, double? gyroY, double? gyroZ, double? magX, double? magY, double? magZ, int? lightRed, int? lightGreen, int? lightBlue, int? lightIr, int? batteryMillivolts, String? rawOutput
});




}
/// @nodoc
class _$Thingy53TelemetryCopyWithImpl<$Res>
    implements $Thingy53TelemetryCopyWith<$Res> {
  _$Thingy53TelemetryCopyWithImpl(this._self, this._then);

  final Thingy53Telemetry _self;
  final $Res Function(Thingy53Telemetry) _then;

/// Create a copy of Thingy53Telemetry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? temperature = freezed,Object? humidity = freezed,Object? pressure = freezed,Object? gasResistance = freezed,Object? accelX = freezed,Object? accelY = freezed,Object? accelZ = freezed,Object? gyroX = freezed,Object? gyroY = freezed,Object? gyroZ = freezed,Object? magX = freezed,Object? magY = freezed,Object? magZ = freezed,Object? lightRed = freezed,Object? lightGreen = freezed,Object? lightBlue = freezed,Object? lightIr = freezed,Object? batteryMillivolts = freezed,Object? rawOutput = freezed,}) {
  return _then(_self.copyWith(
temperature: freezed == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double?,humidity: freezed == humidity ? _self.humidity : humidity // ignore: cast_nullable_to_non_nullable
as double?,pressure: freezed == pressure ? _self.pressure : pressure // ignore: cast_nullable_to_non_nullable
as double?,gasResistance: freezed == gasResistance ? _self.gasResistance : gasResistance // ignore: cast_nullable_to_non_nullable
as double?,accelX: freezed == accelX ? _self.accelX : accelX // ignore: cast_nullable_to_non_nullable
as double?,accelY: freezed == accelY ? _self.accelY : accelY // ignore: cast_nullable_to_non_nullable
as double?,accelZ: freezed == accelZ ? _self.accelZ : accelZ // ignore: cast_nullable_to_non_nullable
as double?,gyroX: freezed == gyroX ? _self.gyroX : gyroX // ignore: cast_nullable_to_non_nullable
as double?,gyroY: freezed == gyroY ? _self.gyroY : gyroY // ignore: cast_nullable_to_non_nullable
as double?,gyroZ: freezed == gyroZ ? _self.gyroZ : gyroZ // ignore: cast_nullable_to_non_nullable
as double?,magX: freezed == magX ? _self.magX : magX // ignore: cast_nullable_to_non_nullable
as double?,magY: freezed == magY ? _self.magY : magY // ignore: cast_nullable_to_non_nullable
as double?,magZ: freezed == magZ ? _self.magZ : magZ // ignore: cast_nullable_to_non_nullable
as double?,lightRed: freezed == lightRed ? _self.lightRed : lightRed // ignore: cast_nullable_to_non_nullable
as int?,lightGreen: freezed == lightGreen ? _self.lightGreen : lightGreen // ignore: cast_nullable_to_non_nullable
as int?,lightBlue: freezed == lightBlue ? _self.lightBlue : lightBlue // ignore: cast_nullable_to_non_nullable
as int?,lightIr: freezed == lightIr ? _self.lightIr : lightIr // ignore: cast_nullable_to_non_nullable
as int?,batteryMillivolts: freezed == batteryMillivolts ? _self.batteryMillivolts : batteryMillivolts // ignore: cast_nullable_to_non_nullable
as int?,rawOutput: freezed == rawOutput ? _self.rawOutput : rawOutput // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Thingy53Telemetry].
extension Thingy53TelemetryPatterns on Thingy53Telemetry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Thingy53Telemetry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Thingy53Telemetry() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Thingy53Telemetry value)  $default,){
final _that = this;
switch (_that) {
case _Thingy53Telemetry():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Thingy53Telemetry value)?  $default,){
final _that = this;
switch (_that) {
case _Thingy53Telemetry() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double? temperature,  double? humidity,  double? pressure,  double? gasResistance,  double? accelX,  double? accelY,  double? accelZ,  double? gyroX,  double? gyroY,  double? gyroZ,  double? magX,  double? magY,  double? magZ,  int? lightRed,  int? lightGreen,  int? lightBlue,  int? lightIr,  int? batteryMillivolts,  String? rawOutput)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Thingy53Telemetry() when $default != null:
return $default(_that.temperature,_that.humidity,_that.pressure,_that.gasResistance,_that.accelX,_that.accelY,_that.accelZ,_that.gyroX,_that.gyroY,_that.gyroZ,_that.magX,_that.magY,_that.magZ,_that.lightRed,_that.lightGreen,_that.lightBlue,_that.lightIr,_that.batteryMillivolts,_that.rawOutput);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double? temperature,  double? humidity,  double? pressure,  double? gasResistance,  double? accelX,  double? accelY,  double? accelZ,  double? gyroX,  double? gyroY,  double? gyroZ,  double? magX,  double? magY,  double? magZ,  int? lightRed,  int? lightGreen,  int? lightBlue,  int? lightIr,  int? batteryMillivolts,  String? rawOutput)  $default,) {final _that = this;
switch (_that) {
case _Thingy53Telemetry():
return $default(_that.temperature,_that.humidity,_that.pressure,_that.gasResistance,_that.accelX,_that.accelY,_that.accelZ,_that.gyroX,_that.gyroY,_that.gyroZ,_that.magX,_that.magY,_that.magZ,_that.lightRed,_that.lightGreen,_that.lightBlue,_that.lightIr,_that.batteryMillivolts,_that.rawOutput);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double? temperature,  double? humidity,  double? pressure,  double? gasResistance,  double? accelX,  double? accelY,  double? accelZ,  double? gyroX,  double? gyroY,  double? gyroZ,  double? magX,  double? magY,  double? magZ,  int? lightRed,  int? lightGreen,  int? lightBlue,  int? lightIr,  int? batteryMillivolts,  String? rawOutput)?  $default,) {final _that = this;
switch (_that) {
case _Thingy53Telemetry() when $default != null:
return $default(_that.temperature,_that.humidity,_that.pressure,_that.gasResistance,_that.accelX,_that.accelY,_that.accelZ,_that.gyroX,_that.gyroY,_that.gyroZ,_that.magX,_that.magY,_that.magZ,_that.lightRed,_that.lightGreen,_that.lightBlue,_that.lightIr,_that.batteryMillivolts,_that.rawOutput);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Thingy53Telemetry implements Thingy53Telemetry {
  const _Thingy53Telemetry({this.temperature, this.humidity, this.pressure, this.gasResistance, this.accelX, this.accelY, this.accelZ, this.gyroX, this.gyroY, this.gyroZ, this.magX, this.magY, this.magZ, this.lightRed, this.lightGreen, this.lightBlue, this.lightIr, this.batteryMillivolts, this.rawOutput});
  factory _Thingy53Telemetry.fromJson(Map<String, dynamic> json) => _$Thingy53TelemetryFromJson(json);

@override final  double? temperature;
@override final  double? humidity;
@override final  double? pressure;
@override final  double? gasResistance;
// Accelerometer (BMI270 or ADXL362)
@override final  double? accelX;
@override final  double? accelY;
@override final  double? accelZ;
// Gyroscope (BMI270)
@override final  double? gyroX;
@override final  double? gyroY;
@override final  double? gyroZ;
// Magnetometer (BMM150)
@override final  double? magX;
@override final  double? magY;
@override final  double? magZ;
// Ambient Light / Colour (BH1749)
@override final  int? lightRed;
@override final  int? lightGreen;
@override final  int? lightBlue;
@override final  int? lightIr;
// Battery Voltage in millivolts
@override final  int? batteryMillivolts;
// Raw output data
@override final  String? rawOutput;

/// Create a copy of Thingy53Telemetry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Thingy53TelemetryCopyWith<_Thingy53Telemetry> get copyWith => __$Thingy53TelemetryCopyWithImpl<_Thingy53Telemetry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Thingy53TelemetryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Thingy53Telemetry&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.humidity, humidity) || other.humidity == humidity)&&(identical(other.pressure, pressure) || other.pressure == pressure)&&(identical(other.gasResistance, gasResistance) || other.gasResistance == gasResistance)&&(identical(other.accelX, accelX) || other.accelX == accelX)&&(identical(other.accelY, accelY) || other.accelY == accelY)&&(identical(other.accelZ, accelZ) || other.accelZ == accelZ)&&(identical(other.gyroX, gyroX) || other.gyroX == gyroX)&&(identical(other.gyroY, gyroY) || other.gyroY == gyroY)&&(identical(other.gyroZ, gyroZ) || other.gyroZ == gyroZ)&&(identical(other.magX, magX) || other.magX == magX)&&(identical(other.magY, magY) || other.magY == magY)&&(identical(other.magZ, magZ) || other.magZ == magZ)&&(identical(other.lightRed, lightRed) || other.lightRed == lightRed)&&(identical(other.lightGreen, lightGreen) || other.lightGreen == lightGreen)&&(identical(other.lightBlue, lightBlue) || other.lightBlue == lightBlue)&&(identical(other.lightIr, lightIr) || other.lightIr == lightIr)&&(identical(other.batteryMillivolts, batteryMillivolts) || other.batteryMillivolts == batteryMillivolts)&&(identical(other.rawOutput, rawOutput) || other.rawOutput == rawOutput));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,temperature,humidity,pressure,gasResistance,accelX,accelY,accelZ,gyroX,gyroY,gyroZ,magX,magY,magZ,lightRed,lightGreen,lightBlue,lightIr,batteryMillivolts,rawOutput]);

@override
String toString() {
  return 'Thingy53Telemetry(temperature: $temperature, humidity: $humidity, pressure: $pressure, gasResistance: $gasResistance, accelX: $accelX, accelY: $accelY, accelZ: $accelZ, gyroX: $gyroX, gyroY: $gyroY, gyroZ: $gyroZ, magX: $magX, magY: $magY, magZ: $magZ, lightRed: $lightRed, lightGreen: $lightGreen, lightBlue: $lightBlue, lightIr: $lightIr, batteryMillivolts: $batteryMillivolts, rawOutput: $rawOutput)';
}


}

/// @nodoc
abstract mixin class _$Thingy53TelemetryCopyWith<$Res> implements $Thingy53TelemetryCopyWith<$Res> {
  factory _$Thingy53TelemetryCopyWith(_Thingy53Telemetry value, $Res Function(_Thingy53Telemetry) _then) = __$Thingy53TelemetryCopyWithImpl;
@override @useResult
$Res call({
 double? temperature, double? humidity, double? pressure, double? gasResistance, double? accelX, double? accelY, double? accelZ, double? gyroX, double? gyroY, double? gyroZ, double? magX, double? magY, double? magZ, int? lightRed, int? lightGreen, int? lightBlue, int? lightIr, int? batteryMillivolts, String? rawOutput
});




}
/// @nodoc
class __$Thingy53TelemetryCopyWithImpl<$Res>
    implements _$Thingy53TelemetryCopyWith<$Res> {
  __$Thingy53TelemetryCopyWithImpl(this._self, this._then);

  final _Thingy53Telemetry _self;
  final $Res Function(_Thingy53Telemetry) _then;

/// Create a copy of Thingy53Telemetry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? temperature = freezed,Object? humidity = freezed,Object? pressure = freezed,Object? gasResistance = freezed,Object? accelX = freezed,Object? accelY = freezed,Object? accelZ = freezed,Object? gyroX = freezed,Object? gyroY = freezed,Object? gyroZ = freezed,Object? magX = freezed,Object? magY = freezed,Object? magZ = freezed,Object? lightRed = freezed,Object? lightGreen = freezed,Object? lightBlue = freezed,Object? lightIr = freezed,Object? batteryMillivolts = freezed,Object? rawOutput = freezed,}) {
  return _then(_Thingy53Telemetry(
temperature: freezed == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double?,humidity: freezed == humidity ? _self.humidity : humidity // ignore: cast_nullable_to_non_nullable
as double?,pressure: freezed == pressure ? _self.pressure : pressure // ignore: cast_nullable_to_non_nullable
as double?,gasResistance: freezed == gasResistance ? _self.gasResistance : gasResistance // ignore: cast_nullable_to_non_nullable
as double?,accelX: freezed == accelX ? _self.accelX : accelX // ignore: cast_nullable_to_non_nullable
as double?,accelY: freezed == accelY ? _self.accelY : accelY // ignore: cast_nullable_to_non_nullable
as double?,accelZ: freezed == accelZ ? _self.accelZ : accelZ // ignore: cast_nullable_to_non_nullable
as double?,gyroX: freezed == gyroX ? _self.gyroX : gyroX // ignore: cast_nullable_to_non_nullable
as double?,gyroY: freezed == gyroY ? _self.gyroY : gyroY // ignore: cast_nullable_to_non_nullable
as double?,gyroZ: freezed == gyroZ ? _self.gyroZ : gyroZ // ignore: cast_nullable_to_non_nullable
as double?,magX: freezed == magX ? _self.magX : magX // ignore: cast_nullable_to_non_nullable
as double?,magY: freezed == magY ? _self.magY : magY // ignore: cast_nullable_to_non_nullable
as double?,magZ: freezed == magZ ? _self.magZ : magZ // ignore: cast_nullable_to_non_nullable
as double?,lightRed: freezed == lightRed ? _self.lightRed : lightRed // ignore: cast_nullable_to_non_nullable
as int?,lightGreen: freezed == lightGreen ? _self.lightGreen : lightGreen // ignore: cast_nullable_to_non_nullable
as int?,lightBlue: freezed == lightBlue ? _self.lightBlue : lightBlue // ignore: cast_nullable_to_non_nullable
as int?,lightIr: freezed == lightIr ? _self.lightIr : lightIr // ignore: cast_nullable_to_non_nullable
as int?,batteryMillivolts: freezed == batteryMillivolts ? _self.batteryMillivolts : batteryMillivolts // ignore: cast_nullable_to_non_nullable
as int?,rawOutput: freezed == rawOutput ? _self.rawOutput : rawOutput // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
