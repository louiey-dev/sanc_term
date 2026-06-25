// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'serial_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SerialConfig {

 String get port; int get baudRate; SerialEncoding get encoding; NewLine get newLine;
/// Create a copy of SerialConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SerialConfigCopyWith<SerialConfig> get copyWith => _$SerialConfigCopyWithImpl<SerialConfig>(this as SerialConfig, _$identity);

  /// Serializes this SerialConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SerialConfig&&(identical(other.port, port) || other.port == port)&&(identical(other.baudRate, baudRate) || other.baudRate == baudRate)&&(identical(other.encoding, encoding) || other.encoding == encoding)&&(identical(other.newLine, newLine) || other.newLine == newLine));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,port,baudRate,encoding,newLine);

@override
String toString() {
  return 'SerialConfig(port: $port, baudRate: $baudRate, encoding: $encoding, newLine: $newLine)';
}


}

/// @nodoc
abstract mixin class $SerialConfigCopyWith<$Res>  {
  factory $SerialConfigCopyWith(SerialConfig value, $Res Function(SerialConfig) _then) = _$SerialConfigCopyWithImpl;
@useResult
$Res call({
 String port, int baudRate, SerialEncoding encoding, NewLine newLine
});




}
/// @nodoc
class _$SerialConfigCopyWithImpl<$Res>
    implements $SerialConfigCopyWith<$Res> {
  _$SerialConfigCopyWithImpl(this._self, this._then);

  final SerialConfig _self;
  final $Res Function(SerialConfig) _then;

/// Create a copy of SerialConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? port = null,Object? baudRate = null,Object? encoding = null,Object? newLine = null,}) {
  return _then(_self.copyWith(
port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as String,baudRate: null == baudRate ? _self.baudRate : baudRate // ignore: cast_nullable_to_non_nullable
as int,encoding: null == encoding ? _self.encoding : encoding // ignore: cast_nullable_to_non_nullable
as SerialEncoding,newLine: null == newLine ? _self.newLine : newLine // ignore: cast_nullable_to_non_nullable
as NewLine,
  ));
}

}


/// Adds pattern-matching-related methods to [SerialConfig].
extension SerialConfigPatterns on SerialConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SerialConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SerialConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SerialConfig value)  $default,){
final _that = this;
switch (_that) {
case _SerialConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SerialConfig value)?  $default,){
final _that = this;
switch (_that) {
case _SerialConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String port,  int baudRate,  SerialEncoding encoding,  NewLine newLine)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SerialConfig() when $default != null:
return $default(_that.port,_that.baudRate,_that.encoding,_that.newLine);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String port,  int baudRate,  SerialEncoding encoding,  NewLine newLine)  $default,) {final _that = this;
switch (_that) {
case _SerialConfig():
return $default(_that.port,_that.baudRate,_that.encoding,_that.newLine);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String port,  int baudRate,  SerialEncoding encoding,  NewLine newLine)?  $default,) {final _that = this;
switch (_that) {
case _SerialConfig() when $default != null:
return $default(_that.port,_that.baudRate,_that.encoding,_that.newLine);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SerialConfig implements SerialConfig {
  const _SerialConfig({this.port = '', this.baudRate = 115200, this.encoding = SerialEncoding.utf8, this.newLine = NewLine.none});
  factory _SerialConfig.fromJson(Map<String, dynamic> json) => _$SerialConfigFromJson(json);

@override@JsonKey() final  String port;
@override@JsonKey() final  int baudRate;
@override@JsonKey() final  SerialEncoding encoding;
@override@JsonKey() final  NewLine newLine;

/// Create a copy of SerialConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SerialConfigCopyWith<_SerialConfig> get copyWith => __$SerialConfigCopyWithImpl<_SerialConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SerialConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SerialConfig&&(identical(other.port, port) || other.port == port)&&(identical(other.baudRate, baudRate) || other.baudRate == baudRate)&&(identical(other.encoding, encoding) || other.encoding == encoding)&&(identical(other.newLine, newLine) || other.newLine == newLine));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,port,baudRate,encoding,newLine);

@override
String toString() {
  return 'SerialConfig(port: $port, baudRate: $baudRate, encoding: $encoding, newLine: $newLine)';
}


}

/// @nodoc
abstract mixin class _$SerialConfigCopyWith<$Res> implements $SerialConfigCopyWith<$Res> {
  factory _$SerialConfigCopyWith(_SerialConfig value, $Res Function(_SerialConfig) _then) = __$SerialConfigCopyWithImpl;
@override @useResult
$Res call({
 String port, int baudRate, SerialEncoding encoding, NewLine newLine
});




}
/// @nodoc
class __$SerialConfigCopyWithImpl<$Res>
    implements _$SerialConfigCopyWith<$Res> {
  __$SerialConfigCopyWithImpl(this._self, this._then);

  final _SerialConfig _self;
  final $Res Function(_SerialConfig) _then;

/// Create a copy of SerialConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? port = null,Object? baudRate = null,Object? encoding = null,Object? newLine = null,}) {
  return _then(_SerialConfig(
port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as String,baudRate: null == baudRate ? _self.baudRate : baudRate // ignore: cast_nullable_to_non_nullable
as int,encoding: null == encoding ? _self.encoding : encoding // ignore: cast_nullable_to_non_nullable
as SerialEncoding,newLine: null == newLine ? _self.newLine : newLine // ignore: cast_nullable_to_non_nullable
as NewLine,
  ));
}


}

// dart format on
