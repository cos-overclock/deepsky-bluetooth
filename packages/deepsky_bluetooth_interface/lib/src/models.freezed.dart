// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReconnectPolicy {

 Duration get delay;
/// Create a copy of ReconnectPolicy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReconnectPolicyCopyWith<ReconnectPolicy> get copyWith => _$ReconnectPolicyCopyWithImpl<ReconnectPolicy>(this as ReconnectPolicy, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReconnectPolicy&&(identical(other.delay, delay) || other.delay == delay));
}


@override
int get hashCode => Object.hash(runtimeType,delay);

@override
String toString() {
  return 'ReconnectPolicy(delay: $delay)';
}


}

/// @nodoc
abstract mixin class $ReconnectPolicyCopyWith<$Res>  {
  factory $ReconnectPolicyCopyWith(ReconnectPolicy value, $Res Function(ReconnectPolicy) _then) = _$ReconnectPolicyCopyWithImpl;
@useResult
$Res call({
 Duration delay
});




}
/// @nodoc
class _$ReconnectPolicyCopyWithImpl<$Res>
    implements $ReconnectPolicyCopyWith<$Res> {
  _$ReconnectPolicyCopyWithImpl(this._self, this._then);

  final ReconnectPolicy _self;
  final $Res Function(ReconnectPolicy) _then;

/// Create a copy of ReconnectPolicy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? delay = null,}) {
  return _then(_self.copyWith(
delay: null == delay ? _self.delay : delay // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}

}


/// Adds pattern-matching-related methods to [ReconnectPolicy].
extension ReconnectPolicyPatterns on ReconnectPolicy {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReconnectPolicy value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReconnectPolicy() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReconnectPolicy value)  $default,){
final _that = this;
switch (_that) {
case _ReconnectPolicy():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReconnectPolicy value)?  $default,){
final _that = this;
switch (_that) {
case _ReconnectPolicy() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Duration delay)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReconnectPolicy() when $default != null:
return $default(_that.delay);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Duration delay)  $default,) {final _that = this;
switch (_that) {
case _ReconnectPolicy():
return $default(_that.delay);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Duration delay)?  $default,) {final _that = this;
switch (_that) {
case _ReconnectPolicy() when $default != null:
return $default(_that.delay);case _:
  return null;

}
}

}

/// @nodoc


class _ReconnectPolicy implements ReconnectPolicy {
  const _ReconnectPolicy({this.delay = const Duration(seconds: 5)});


@override@JsonKey() final  Duration delay;

/// Create a copy of ReconnectPolicy
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReconnectPolicyCopyWith<_ReconnectPolicy> get copyWith => __$ReconnectPolicyCopyWithImpl<_ReconnectPolicy>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReconnectPolicy&&(identical(other.delay, delay) || other.delay == delay));
}


@override
int get hashCode => Object.hash(runtimeType,delay);

@override
String toString() {
  return 'ReconnectPolicy(delay: $delay)';
}


}

/// @nodoc
abstract mixin class _$ReconnectPolicyCopyWith<$Res> implements $ReconnectPolicyCopyWith<$Res> {
  factory _$ReconnectPolicyCopyWith(_ReconnectPolicy value, $Res Function(_ReconnectPolicy) _then) = __$ReconnectPolicyCopyWithImpl;
@override @useResult
$Res call({
 Duration delay
});




}
/// @nodoc
class __$ReconnectPolicyCopyWithImpl<$Res>
    implements _$ReconnectPolicyCopyWith<$Res> {
  __$ReconnectPolicyCopyWithImpl(this._self, this._then);

  final _ReconnectPolicy _self;
  final $Res Function(_ReconnectPolicy) _then;

/// Create a copy of ReconnectPolicy
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? delay = null,}) {
  return _then(_ReconnectPolicy(
delay: null == delay ? _self.delay : delay // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}


}

/// @nodoc
mixin _$BleConnectionEvent {

 BleConnectionState get state; BleDisconnectReason? get reason;
/// Create a copy of BleConnectionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BleConnectionEventCopyWith<BleConnectionEvent> get copyWith => _$BleConnectionEventCopyWithImpl<BleConnectionEvent>(this as BleConnectionEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BleConnectionEvent&&(identical(other.state, state) || other.state == state)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,state,reason);

@override
String toString() {
  return 'BleConnectionEvent(state: $state, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $BleConnectionEventCopyWith<$Res>  {
  factory $BleConnectionEventCopyWith(BleConnectionEvent value, $Res Function(BleConnectionEvent) _then) = _$BleConnectionEventCopyWithImpl;
@useResult
$Res call({
 BleConnectionState state, BleDisconnectReason? reason
});




}
/// @nodoc
class _$BleConnectionEventCopyWithImpl<$Res>
    implements $BleConnectionEventCopyWith<$Res> {
  _$BleConnectionEventCopyWithImpl(this._self, this._then);

  final BleConnectionEvent _self;
  final $Res Function(BleConnectionEvent) _then;

/// Create a copy of BleConnectionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? state = null,Object? reason = freezed,}) {
  return _then(_self.copyWith(
state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as BleConnectionState,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as BleDisconnectReason?,
  ));
}

}


/// Adds pattern-matching-related methods to [BleConnectionEvent].
extension BleConnectionEventPatterns on BleConnectionEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BleConnectionEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BleConnectionEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BleConnectionEvent value)  $default,){
final _that = this;
switch (_that) {
case _BleConnectionEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BleConnectionEvent value)?  $default,){
final _that = this;
switch (_that) {
case _BleConnectionEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BleConnectionState state,  BleDisconnectReason? reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BleConnectionEvent() when $default != null:
return $default(_that.state,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BleConnectionState state,  BleDisconnectReason? reason)  $default,) {final _that = this;
switch (_that) {
case _BleConnectionEvent():
return $default(_that.state,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BleConnectionState state,  BleDisconnectReason? reason)?  $default,) {final _that = this;
switch (_that) {
case _BleConnectionEvent() when $default != null:
return $default(_that.state,_that.reason);case _:
  return null;

}
}

}

/// @nodoc


class _BleConnectionEvent implements BleConnectionEvent {
  const _BleConnectionEvent({required this.state, this.reason}): assert(state == BleConnectionState.disconnected ? reason != null : reason == null, 'Only disconnected events must have a reason.');


@override final  BleConnectionState state;
@override final  BleDisconnectReason? reason;

/// Create a copy of BleConnectionEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BleConnectionEventCopyWith<_BleConnectionEvent> get copyWith => __$BleConnectionEventCopyWithImpl<_BleConnectionEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BleConnectionEvent&&(identical(other.state, state) || other.state == state)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,state,reason);

@override
String toString() {
  return 'BleConnectionEvent(state: $state, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$BleConnectionEventCopyWith<$Res> implements $BleConnectionEventCopyWith<$Res> {
  factory _$BleConnectionEventCopyWith(_BleConnectionEvent value, $Res Function(_BleConnectionEvent) _then) = __$BleConnectionEventCopyWithImpl;
@override @useResult
$Res call({
 BleConnectionState state, BleDisconnectReason? reason
});




}
/// @nodoc
class __$BleConnectionEventCopyWithImpl<$Res>
    implements _$BleConnectionEventCopyWith<$Res> {
  __$BleConnectionEventCopyWithImpl(this._self, this._then);

  final _BleConnectionEvent _self;
  final $Res Function(_BleConnectionEvent) _then;

/// Create a copy of BleConnectionEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? state = null,Object? reason = freezed,}) {
  return _then(_BleConnectionEvent(
state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as BleConnectionState,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as BleDisconnectReason?,
  ));
}


}

/// @nodoc
mixin _$DeepskyScanFilterManufacturerData {

 int get manufacturerId; Uint8List get data;
/// Create a copy of DeepskyScanFilterManufacturerData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeepskyScanFilterManufacturerDataCopyWith<DeepskyScanFilterManufacturerData> get copyWith => _$DeepskyScanFilterManufacturerDataCopyWithImpl<DeepskyScanFilterManufacturerData>(this as DeepskyScanFilterManufacturerData, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeepskyScanFilterManufacturerData&&(identical(other.manufacturerId, manufacturerId) || other.manufacturerId == manufacturerId)&&const DeepCollectionEquality().equals(other.data, data));
}


@override
int get hashCode => Object.hash(runtimeType,manufacturerId,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'DeepskyScanFilterManufacturerData(manufacturerId: $manufacturerId, data: $data)';
}


}

/// @nodoc
abstract mixin class $DeepskyScanFilterManufacturerDataCopyWith<$Res>  {
  factory $DeepskyScanFilterManufacturerDataCopyWith(DeepskyScanFilterManufacturerData value, $Res Function(DeepskyScanFilterManufacturerData) _then) = _$DeepskyScanFilterManufacturerDataCopyWithImpl;
@useResult
$Res call({
 int manufacturerId, Uint8List data
});




}
/// @nodoc
class _$DeepskyScanFilterManufacturerDataCopyWithImpl<$Res>
    implements $DeepskyScanFilterManufacturerDataCopyWith<$Res> {
  _$DeepskyScanFilterManufacturerDataCopyWithImpl(this._self, this._then);

  final DeepskyScanFilterManufacturerData _self;
  final $Res Function(DeepskyScanFilterManufacturerData) _then;

/// Create a copy of DeepskyScanFilterManufacturerData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? manufacturerId = null,Object? data = null,}) {
  return _then(_self.copyWith(
manufacturerId: null == manufacturerId ? _self.manufacturerId : manufacturerId // ignore: cast_nullable_to_non_nullable
as int,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Uint8List,
  ));
}

}


/// Adds pattern-matching-related methods to [DeepskyScanFilterManufacturerData].
extension DeepskyScanFilterManufacturerDataPatterns on DeepskyScanFilterManufacturerData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeepskyScanFilterManufacturerData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeepskyScanFilterManufacturerData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeepskyScanFilterManufacturerData value)  $default,){
final _that = this;
switch (_that) {
case _DeepskyScanFilterManufacturerData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeepskyScanFilterManufacturerData value)?  $default,){
final _that = this;
switch (_that) {
case _DeepskyScanFilterManufacturerData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int manufacturerId,  Uint8List data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeepskyScanFilterManufacturerData() when $default != null:
return $default(_that.manufacturerId,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int manufacturerId,  Uint8List data)  $default,) {final _that = this;
switch (_that) {
case _DeepskyScanFilterManufacturerData():
return $default(_that.manufacturerId,_that.data);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int manufacturerId,  Uint8List data)?  $default,) {final _that = this;
switch (_that) {
case _DeepskyScanFilterManufacturerData() when $default != null:
return $default(_that.manufacturerId,_that.data);case _:
  return null;

}
}

}

/// @nodoc


class _DeepskyScanFilterManufacturerData implements DeepskyScanFilterManufacturerData {
  const _DeepskyScanFilterManufacturerData({required this.manufacturerId, required this.data});


@override final  int manufacturerId;
@override final  Uint8List data;

/// Create a copy of DeepskyScanFilterManufacturerData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeepskyScanFilterManufacturerDataCopyWith<_DeepskyScanFilterManufacturerData> get copyWith => __$DeepskyScanFilterManufacturerDataCopyWithImpl<_DeepskyScanFilterManufacturerData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeepskyScanFilterManufacturerData&&(identical(other.manufacturerId, manufacturerId) || other.manufacturerId == manufacturerId)&&const DeepCollectionEquality().equals(other.data, data));
}


@override
int get hashCode => Object.hash(runtimeType,manufacturerId,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'DeepskyScanFilterManufacturerData(manufacturerId: $manufacturerId, data: $data)';
}


}

/// @nodoc
abstract mixin class _$DeepskyScanFilterManufacturerDataCopyWith<$Res> implements $DeepskyScanFilterManufacturerDataCopyWith<$Res> {
  factory _$DeepskyScanFilterManufacturerDataCopyWith(_DeepskyScanFilterManufacturerData value, $Res Function(_DeepskyScanFilterManufacturerData) _then) = __$DeepskyScanFilterManufacturerDataCopyWithImpl;
@override @useResult
$Res call({
 int manufacturerId, Uint8List data
});




}
/// @nodoc
class __$DeepskyScanFilterManufacturerDataCopyWithImpl<$Res>
    implements _$DeepskyScanFilterManufacturerDataCopyWith<$Res> {
  __$DeepskyScanFilterManufacturerDataCopyWithImpl(this._self, this._then);

  final _DeepskyScanFilterManufacturerData _self;
  final $Res Function(_DeepskyScanFilterManufacturerData) _then;

/// Create a copy of DeepskyScanFilterManufacturerData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? manufacturerId = null,Object? data = null,}) {
  return _then(_DeepskyScanFilterManufacturerData(
manufacturerId: null == manufacturerId ? _self.manufacturerId : manufacturerId // ignore: cast_nullable_to_non_nullable
as int,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Uint8List,
  ));
}


}

/// @nodoc
mixin _$DeepskyScanFilterServiceData {

 DeepskyUuid get uuid; Uint8List get data;
/// Create a copy of DeepskyScanFilterServiceData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeepskyScanFilterServiceDataCopyWith<DeepskyScanFilterServiceData> get copyWith => _$DeepskyScanFilterServiceDataCopyWithImpl<DeepskyScanFilterServiceData>(this as DeepskyScanFilterServiceData, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeepskyScanFilterServiceData&&(identical(other.uuid, uuid) || other.uuid == uuid)&&const DeepCollectionEquality().equals(other.data, data));
}


@override
int get hashCode => Object.hash(runtimeType,uuid,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'DeepskyScanFilterServiceData(uuid: $uuid, data: $data)';
}


}

/// @nodoc
abstract mixin class $DeepskyScanFilterServiceDataCopyWith<$Res>  {
  factory $DeepskyScanFilterServiceDataCopyWith(DeepskyScanFilterServiceData value, $Res Function(DeepskyScanFilterServiceData) _then) = _$DeepskyScanFilterServiceDataCopyWithImpl;
@useResult
$Res call({
 DeepskyUuid uuid, Uint8List data
});


$DeepskyUuidCopyWith<$Res> get uuid;

}
/// @nodoc
class _$DeepskyScanFilterServiceDataCopyWithImpl<$Res>
    implements $DeepskyScanFilterServiceDataCopyWith<$Res> {
  _$DeepskyScanFilterServiceDataCopyWithImpl(this._self, this._then);

  final DeepskyScanFilterServiceData _self;
  final $Res Function(DeepskyScanFilterServiceData) _then;

/// Create a copy of DeepskyScanFilterServiceData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uuid = null,Object? data = null,}) {
  return _then(_self.copyWith(
uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as DeepskyUuid,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Uint8List,
  ));
}
/// Create a copy of DeepskyScanFilterServiceData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeepskyUuidCopyWith<$Res> get uuid {

  return $DeepskyUuidCopyWith<$Res>(_self.uuid, (value) {
    return _then(_self.copyWith(uuid: value));
  });
}
}


/// Adds pattern-matching-related methods to [DeepskyScanFilterServiceData].
extension DeepskyScanFilterServiceDataPatterns on DeepskyScanFilterServiceData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeepskyScanFilterServiceData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeepskyScanFilterServiceData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeepskyScanFilterServiceData value)  $default,){
final _that = this;
switch (_that) {
case _DeepskyScanFilterServiceData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeepskyScanFilterServiceData value)?  $default,){
final _that = this;
switch (_that) {
case _DeepskyScanFilterServiceData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DeepskyUuid uuid,  Uint8List data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeepskyScanFilterServiceData() when $default != null:
return $default(_that.uuid,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DeepskyUuid uuid,  Uint8List data)  $default,) {final _that = this;
switch (_that) {
case _DeepskyScanFilterServiceData():
return $default(_that.uuid,_that.data);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DeepskyUuid uuid,  Uint8List data)?  $default,) {final _that = this;
switch (_that) {
case _DeepskyScanFilterServiceData() when $default != null:
return $default(_that.uuid,_that.data);case _:
  return null;

}
}

}

/// @nodoc


class _DeepskyScanFilterServiceData implements DeepskyScanFilterServiceData {
  const _DeepskyScanFilterServiceData({required this.uuid, required this.data});


@override final  DeepskyUuid uuid;
@override final  Uint8List data;

/// Create a copy of DeepskyScanFilterServiceData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeepskyScanFilterServiceDataCopyWith<_DeepskyScanFilterServiceData> get copyWith => __$DeepskyScanFilterServiceDataCopyWithImpl<_DeepskyScanFilterServiceData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeepskyScanFilterServiceData&&(identical(other.uuid, uuid) || other.uuid == uuid)&&const DeepCollectionEquality().equals(other.data, data));
}


@override
int get hashCode => Object.hash(runtimeType,uuid,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'DeepskyScanFilterServiceData(uuid: $uuid, data: $data)';
}


}

/// @nodoc
abstract mixin class _$DeepskyScanFilterServiceDataCopyWith<$Res> implements $DeepskyScanFilterServiceDataCopyWith<$Res> {
  factory _$DeepskyScanFilterServiceDataCopyWith(_DeepskyScanFilterServiceData value, $Res Function(_DeepskyScanFilterServiceData) _then) = __$DeepskyScanFilterServiceDataCopyWithImpl;
@override @useResult
$Res call({
 DeepskyUuid uuid, Uint8List data
});


@override $DeepskyUuidCopyWith<$Res> get uuid;

}
/// @nodoc
class __$DeepskyScanFilterServiceDataCopyWithImpl<$Res>
    implements _$DeepskyScanFilterServiceDataCopyWith<$Res> {
  __$DeepskyScanFilterServiceDataCopyWithImpl(this._self, this._then);

  final _DeepskyScanFilterServiceData _self;
  final $Res Function(_DeepskyScanFilterServiceData) _then;

/// Create a copy of DeepskyScanFilterServiceData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uuid = null,Object? data = null,}) {
  return _then(_DeepskyScanFilterServiceData(
uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as DeepskyUuid,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Uint8List,
  ));
}

/// Create a copy of DeepskyScanFilterServiceData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeepskyUuidCopyWith<$Res> get uuid {

  return $DeepskyUuidCopyWith<$Res>(_self.uuid, (value) {
    return _then(_self.copyWith(uuid: value));
  });
}
}

/// @nodoc
mixin _$DeepskyScanFilter {

 List<DeepskyDeviceId> get deviceIds; List<String> get names; List<DeepskyScanFilterManufacturerData> get manufacturerData; List<DeepskyScanFilterServiceData> get serviceData; List<DeepskyUuid> get serviceUuids;
/// Create a copy of DeepskyScanFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeepskyScanFilterCopyWith<DeepskyScanFilter> get copyWith => _$DeepskyScanFilterCopyWithImpl<DeepskyScanFilter>(this as DeepskyScanFilter, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeepskyScanFilter&&const DeepCollectionEquality().equals(other.deviceIds, deviceIds)&&const DeepCollectionEquality().equals(other.names, names)&&const DeepCollectionEquality().equals(other.manufacturerData, manufacturerData)&&const DeepCollectionEquality().equals(other.serviceData, serviceData)&&const DeepCollectionEquality().equals(other.serviceUuids, serviceUuids));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(deviceIds),const DeepCollectionEquality().hash(names),const DeepCollectionEquality().hash(manufacturerData),const DeepCollectionEquality().hash(serviceData),const DeepCollectionEquality().hash(serviceUuids));

@override
String toString() {
  return 'DeepskyScanFilter(deviceIds: $deviceIds, names: $names, manufacturerData: $manufacturerData, serviceData: $serviceData, serviceUuids: $serviceUuids)';
}


}

/// @nodoc
abstract mixin class $DeepskyScanFilterCopyWith<$Res>  {
  factory $DeepskyScanFilterCopyWith(DeepskyScanFilter value, $Res Function(DeepskyScanFilter) _then) = _$DeepskyScanFilterCopyWithImpl;
@useResult
$Res call({
 List<DeepskyDeviceId> deviceIds, List<String> names, List<DeepskyScanFilterManufacturerData> manufacturerData, List<DeepskyScanFilterServiceData> serviceData, List<DeepskyUuid> serviceUuids
});




}
/// @nodoc
class _$DeepskyScanFilterCopyWithImpl<$Res>
    implements $DeepskyScanFilterCopyWith<$Res> {
  _$DeepskyScanFilterCopyWithImpl(this._self, this._then);

  final DeepskyScanFilter _self;
  final $Res Function(DeepskyScanFilter) _then;

/// Create a copy of DeepskyScanFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceIds = null,Object? names = null,Object? manufacturerData = null,Object? serviceData = null,Object? serviceUuids = null,}) {
  return _then(_self.copyWith(
deviceIds: null == deviceIds ? _self.deviceIds : deviceIds // ignore: cast_nullable_to_non_nullable
as List<DeepskyDeviceId>,names: null == names ? _self.names : names // ignore: cast_nullable_to_non_nullable
as List<String>,manufacturerData: null == manufacturerData ? _self.manufacturerData : manufacturerData // ignore: cast_nullable_to_non_nullable
as List<DeepskyScanFilterManufacturerData>,serviceData: null == serviceData ? _self.serviceData : serviceData // ignore: cast_nullable_to_non_nullable
as List<DeepskyScanFilterServiceData>,serviceUuids: null == serviceUuids ? _self.serviceUuids : serviceUuids // ignore: cast_nullable_to_non_nullable
as List<DeepskyUuid>,
  ));
}

}


/// Adds pattern-matching-related methods to [DeepskyScanFilter].
extension DeepskyScanFilterPatterns on DeepskyScanFilter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeepskyScanFilter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeepskyScanFilter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeepskyScanFilter value)  $default,){
final _that = this;
switch (_that) {
case _DeepskyScanFilter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeepskyScanFilter value)?  $default,){
final _that = this;
switch (_that) {
case _DeepskyScanFilter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<DeepskyDeviceId> deviceIds,  List<String> names,  List<DeepskyScanFilterManufacturerData> manufacturerData,  List<DeepskyScanFilterServiceData> serviceData,  List<DeepskyUuid> serviceUuids)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeepskyScanFilter() when $default != null:
return $default(_that.deviceIds,_that.names,_that.manufacturerData,_that.serviceData,_that.serviceUuids);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<DeepskyDeviceId> deviceIds,  List<String> names,  List<DeepskyScanFilterManufacturerData> manufacturerData,  List<DeepskyScanFilterServiceData> serviceData,  List<DeepskyUuid> serviceUuids)  $default,) {final _that = this;
switch (_that) {
case _DeepskyScanFilter():
return $default(_that.deviceIds,_that.names,_that.manufacturerData,_that.serviceData,_that.serviceUuids);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<DeepskyDeviceId> deviceIds,  List<String> names,  List<DeepskyScanFilterManufacturerData> manufacturerData,  List<DeepskyScanFilterServiceData> serviceData,  List<DeepskyUuid> serviceUuids)?  $default,) {final _that = this;
switch (_that) {
case _DeepskyScanFilter() when $default != null:
return $default(_that.deviceIds,_that.names,_that.manufacturerData,_that.serviceData,_that.serviceUuids);case _:
  return null;

}
}

}

/// @nodoc


class _DeepskyScanFilter implements DeepskyScanFilter {
  const _DeepskyScanFilter({final  List<DeepskyDeviceId> deviceIds = const <DeepskyDeviceId>[], final  List<String> names = const <String>[], final  List<DeepskyScanFilterManufacturerData> manufacturerData = const <DeepskyScanFilterManufacturerData>[], final  List<DeepskyScanFilterServiceData> serviceData = const <DeepskyScanFilterServiceData>[], final  List<DeepskyUuid> serviceUuids = const <DeepskyUuid>[]}): _deviceIds = deviceIds,_names = names,_manufacturerData = manufacturerData,_serviceData = serviceData,_serviceUuids = serviceUuids;


 final  List<DeepskyDeviceId> _deviceIds;
@override@JsonKey() List<DeepskyDeviceId> get deviceIds {
  if (_deviceIds is EqualUnmodifiableListView) return _deviceIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_deviceIds);
}

 final  List<String> _names;
@override@JsonKey() List<String> get names {
  if (_names is EqualUnmodifiableListView) return _names;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_names);
}

 final  List<DeepskyScanFilterManufacturerData> _manufacturerData;
@override@JsonKey() List<DeepskyScanFilterManufacturerData> get manufacturerData {
  if (_manufacturerData is EqualUnmodifiableListView) return _manufacturerData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_manufacturerData);
}

 final  List<DeepskyScanFilterServiceData> _serviceData;
@override@JsonKey() List<DeepskyScanFilterServiceData> get serviceData {
  if (_serviceData is EqualUnmodifiableListView) return _serviceData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_serviceData);
}

 final  List<DeepskyUuid> _serviceUuids;
@override@JsonKey() List<DeepskyUuid> get serviceUuids {
  if (_serviceUuids is EqualUnmodifiableListView) return _serviceUuids;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_serviceUuids);
}


/// Create a copy of DeepskyScanFilter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeepskyScanFilterCopyWith<_DeepskyScanFilter> get copyWith => __$DeepskyScanFilterCopyWithImpl<_DeepskyScanFilter>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeepskyScanFilter&&const DeepCollectionEquality().equals(other._deviceIds, _deviceIds)&&const DeepCollectionEquality().equals(other._names, _names)&&const DeepCollectionEquality().equals(other._manufacturerData, _manufacturerData)&&const DeepCollectionEquality().equals(other._serviceData, _serviceData)&&const DeepCollectionEquality().equals(other._serviceUuids, _serviceUuids));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_deviceIds),const DeepCollectionEquality().hash(_names),const DeepCollectionEquality().hash(_manufacturerData),const DeepCollectionEquality().hash(_serviceData),const DeepCollectionEquality().hash(_serviceUuids));

@override
String toString() {
  return 'DeepskyScanFilter(deviceIds: $deviceIds, names: $names, manufacturerData: $manufacturerData, serviceData: $serviceData, serviceUuids: $serviceUuids)';
}


}

/// @nodoc
abstract mixin class _$DeepskyScanFilterCopyWith<$Res> implements $DeepskyScanFilterCopyWith<$Res> {
  factory _$DeepskyScanFilterCopyWith(_DeepskyScanFilter value, $Res Function(_DeepskyScanFilter) _then) = __$DeepskyScanFilterCopyWithImpl;
@override @useResult
$Res call({
 List<DeepskyDeviceId> deviceIds, List<String> names, List<DeepskyScanFilterManufacturerData> manufacturerData, List<DeepskyScanFilterServiceData> serviceData, List<DeepskyUuid> serviceUuids
});




}
/// @nodoc
class __$DeepskyScanFilterCopyWithImpl<$Res>
    implements _$DeepskyScanFilterCopyWith<$Res> {
  __$DeepskyScanFilterCopyWithImpl(this._self, this._then);

  final _DeepskyScanFilter _self;
  final $Res Function(_DeepskyScanFilter) _then;

/// Create a copy of DeepskyScanFilter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceIds = null,Object? names = null,Object? manufacturerData = null,Object? serviceData = null,Object? serviceUuids = null,}) {
  return _then(_DeepskyScanFilter(
deviceIds: null == deviceIds ? _self._deviceIds : deviceIds // ignore: cast_nullable_to_non_nullable
as List<DeepskyDeviceId>,names: null == names ? _self._names : names // ignore: cast_nullable_to_non_nullable
as List<String>,manufacturerData: null == manufacturerData ? _self._manufacturerData : manufacturerData // ignore: cast_nullable_to_non_nullable
as List<DeepskyScanFilterManufacturerData>,serviceData: null == serviceData ? _self._serviceData : serviceData // ignore: cast_nullable_to_non_nullable
as List<DeepskyScanFilterServiceData>,serviceUuids: null == serviceUuids ? _self._serviceUuids : serviceUuids // ignore: cast_nullable_to_non_nullable
as List<DeepskyUuid>,
  ));
}


}

/// @nodoc
mixin _$DeepskyAndroidScanSetting {

 DeepskyAndroidScanMode get mode; DeepskyAndroidScanCallbackType get callbackType; bool get onlyLegacy; DeepskyAndroidScanMatchMode get matchMode; DeepskyAndroidScanNumOfMatch get numOfMatch; Duration get reportDelay; DeepskyAndroidScanPhy get phy;
/// Create a copy of DeepskyAndroidScanSetting
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeepskyAndroidScanSettingCopyWith<DeepskyAndroidScanSetting> get copyWith => _$DeepskyAndroidScanSettingCopyWithImpl<DeepskyAndroidScanSetting>(this as DeepskyAndroidScanSetting, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeepskyAndroidScanSetting&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.callbackType, callbackType) || other.callbackType == callbackType)&&(identical(other.onlyLegacy, onlyLegacy) || other.onlyLegacy == onlyLegacy)&&(identical(other.matchMode, matchMode) || other.matchMode == matchMode)&&(identical(other.numOfMatch, numOfMatch) || other.numOfMatch == numOfMatch)&&(identical(other.reportDelay, reportDelay) || other.reportDelay == reportDelay)&&(identical(other.phy, phy) || other.phy == phy));
}


@override
int get hashCode => Object.hash(runtimeType,mode,callbackType,onlyLegacy,matchMode,numOfMatch,reportDelay,phy);

@override
String toString() {
  return 'DeepskyAndroidScanSetting(mode: $mode, callbackType: $callbackType, onlyLegacy: $onlyLegacy, matchMode: $matchMode, numOfMatch: $numOfMatch, reportDelay: $reportDelay, phy: $phy)';
}


}

/// @nodoc
abstract mixin class $DeepskyAndroidScanSettingCopyWith<$Res>  {
  factory $DeepskyAndroidScanSettingCopyWith(DeepskyAndroidScanSetting value, $Res Function(DeepskyAndroidScanSetting) _then) = _$DeepskyAndroidScanSettingCopyWithImpl;
@useResult
$Res call({
 DeepskyAndroidScanMode mode, DeepskyAndroidScanCallbackType callbackType, bool onlyLegacy, DeepskyAndroidScanMatchMode matchMode, DeepskyAndroidScanNumOfMatch numOfMatch, Duration reportDelay, DeepskyAndroidScanPhy phy
});




}
/// @nodoc
class _$DeepskyAndroidScanSettingCopyWithImpl<$Res>
    implements $DeepskyAndroidScanSettingCopyWith<$Res> {
  _$DeepskyAndroidScanSettingCopyWithImpl(this._self, this._then);

  final DeepskyAndroidScanSetting _self;
  final $Res Function(DeepskyAndroidScanSetting) _then;

/// Create a copy of DeepskyAndroidScanSetting
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mode = null,Object? callbackType = null,Object? onlyLegacy = null,Object? matchMode = null,Object? numOfMatch = null,Object? reportDelay = null,Object? phy = null,}) {
  return _then(_self.copyWith(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as DeepskyAndroidScanMode,callbackType: null == callbackType ? _self.callbackType : callbackType // ignore: cast_nullable_to_non_nullable
as DeepskyAndroidScanCallbackType,onlyLegacy: null == onlyLegacy ? _self.onlyLegacy : onlyLegacy // ignore: cast_nullable_to_non_nullable
as bool,matchMode: null == matchMode ? _self.matchMode : matchMode // ignore: cast_nullable_to_non_nullable
as DeepskyAndroidScanMatchMode,numOfMatch: null == numOfMatch ? _self.numOfMatch : numOfMatch // ignore: cast_nullable_to_non_nullable
as DeepskyAndroidScanNumOfMatch,reportDelay: null == reportDelay ? _self.reportDelay : reportDelay // ignore: cast_nullable_to_non_nullable
as Duration,phy: null == phy ? _self.phy : phy // ignore: cast_nullable_to_non_nullable
as DeepskyAndroidScanPhy,
  ));
}

}


/// Adds pattern-matching-related methods to [DeepskyAndroidScanSetting].
extension DeepskyAndroidScanSettingPatterns on DeepskyAndroidScanSetting {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeepskyAndroidScanSetting value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeepskyAndroidScanSetting() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeepskyAndroidScanSetting value)  $default,){
final _that = this;
switch (_that) {
case _DeepskyAndroidScanSetting():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeepskyAndroidScanSetting value)?  $default,){
final _that = this;
switch (_that) {
case _DeepskyAndroidScanSetting() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DeepskyAndroidScanMode mode,  DeepskyAndroidScanCallbackType callbackType,  bool onlyLegacy,  DeepskyAndroidScanMatchMode matchMode,  DeepskyAndroidScanNumOfMatch numOfMatch,  Duration reportDelay,  DeepskyAndroidScanPhy phy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeepskyAndroidScanSetting() when $default != null:
return $default(_that.mode,_that.callbackType,_that.onlyLegacy,_that.matchMode,_that.numOfMatch,_that.reportDelay,_that.phy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DeepskyAndroidScanMode mode,  DeepskyAndroidScanCallbackType callbackType,  bool onlyLegacy,  DeepskyAndroidScanMatchMode matchMode,  DeepskyAndroidScanNumOfMatch numOfMatch,  Duration reportDelay,  DeepskyAndroidScanPhy phy)  $default,) {final _that = this;
switch (_that) {
case _DeepskyAndroidScanSetting():
return $default(_that.mode,_that.callbackType,_that.onlyLegacy,_that.matchMode,_that.numOfMatch,_that.reportDelay,_that.phy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DeepskyAndroidScanMode mode,  DeepskyAndroidScanCallbackType callbackType,  bool onlyLegacy,  DeepskyAndroidScanMatchMode matchMode,  DeepskyAndroidScanNumOfMatch numOfMatch,  Duration reportDelay,  DeepskyAndroidScanPhy phy)?  $default,) {final _that = this;
switch (_that) {
case _DeepskyAndroidScanSetting() when $default != null:
return $default(_that.mode,_that.callbackType,_that.onlyLegacy,_that.matchMode,_that.numOfMatch,_that.reportDelay,_that.phy);case _:
  return null;

}
}

}

/// @nodoc


class _DeepskyAndroidScanSetting implements DeepskyAndroidScanSetting {
  const _DeepskyAndroidScanSetting({this.mode = DeepskyAndroidScanMode.lowLatency, this.callbackType = DeepskyAndroidScanCallbackType.allMatches, this.onlyLegacy = true, this.matchMode = DeepskyAndroidScanMatchMode.aggressive, this.numOfMatch = DeepskyAndroidScanNumOfMatch.maxAdvertisement, this.reportDelay = Duration.zero, this.phy = DeepskyAndroidScanPhy.allSupported});


@override@JsonKey() final  DeepskyAndroidScanMode mode;
@override@JsonKey() final  DeepskyAndroidScanCallbackType callbackType;
@override@JsonKey() final  bool onlyLegacy;
@override@JsonKey() final  DeepskyAndroidScanMatchMode matchMode;
@override@JsonKey() final  DeepskyAndroidScanNumOfMatch numOfMatch;
@override@JsonKey() final  Duration reportDelay;
@override@JsonKey() final  DeepskyAndroidScanPhy phy;

/// Create a copy of DeepskyAndroidScanSetting
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeepskyAndroidScanSettingCopyWith<_DeepskyAndroidScanSetting> get copyWith => __$DeepskyAndroidScanSettingCopyWithImpl<_DeepskyAndroidScanSetting>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeepskyAndroidScanSetting&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.callbackType, callbackType) || other.callbackType == callbackType)&&(identical(other.onlyLegacy, onlyLegacy) || other.onlyLegacy == onlyLegacy)&&(identical(other.matchMode, matchMode) || other.matchMode == matchMode)&&(identical(other.numOfMatch, numOfMatch) || other.numOfMatch == numOfMatch)&&(identical(other.reportDelay, reportDelay) || other.reportDelay == reportDelay)&&(identical(other.phy, phy) || other.phy == phy));
}


@override
int get hashCode => Object.hash(runtimeType,mode,callbackType,onlyLegacy,matchMode,numOfMatch,reportDelay,phy);

@override
String toString() {
  return 'DeepskyAndroidScanSetting(mode: $mode, callbackType: $callbackType, onlyLegacy: $onlyLegacy, matchMode: $matchMode, numOfMatch: $numOfMatch, reportDelay: $reportDelay, phy: $phy)';
}


}

/// @nodoc
abstract mixin class _$DeepskyAndroidScanSettingCopyWith<$Res> implements $DeepskyAndroidScanSettingCopyWith<$Res> {
  factory _$DeepskyAndroidScanSettingCopyWith(_DeepskyAndroidScanSetting value, $Res Function(_DeepskyAndroidScanSetting) _then) = __$DeepskyAndroidScanSettingCopyWithImpl;
@override @useResult
$Res call({
 DeepskyAndroidScanMode mode, DeepskyAndroidScanCallbackType callbackType, bool onlyLegacy, DeepskyAndroidScanMatchMode matchMode, DeepskyAndroidScanNumOfMatch numOfMatch, Duration reportDelay, DeepskyAndroidScanPhy phy
});




}
/// @nodoc
class __$DeepskyAndroidScanSettingCopyWithImpl<$Res>
    implements _$DeepskyAndroidScanSettingCopyWith<$Res> {
  __$DeepskyAndroidScanSettingCopyWithImpl(this._self, this._then);

  final _DeepskyAndroidScanSetting _self;
  final $Res Function(_DeepskyAndroidScanSetting) _then;

/// Create a copy of DeepskyAndroidScanSetting
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mode = null,Object? callbackType = null,Object? onlyLegacy = null,Object? matchMode = null,Object? numOfMatch = null,Object? reportDelay = null,Object? phy = null,}) {
  return _then(_DeepskyAndroidScanSetting(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as DeepskyAndroidScanMode,callbackType: null == callbackType ? _self.callbackType : callbackType // ignore: cast_nullable_to_non_nullable
as DeepskyAndroidScanCallbackType,onlyLegacy: null == onlyLegacy ? _self.onlyLegacy : onlyLegacy // ignore: cast_nullable_to_non_nullable
as bool,matchMode: null == matchMode ? _self.matchMode : matchMode // ignore: cast_nullable_to_non_nullable
as DeepskyAndroidScanMatchMode,numOfMatch: null == numOfMatch ? _self.numOfMatch : numOfMatch // ignore: cast_nullable_to_non_nullable
as DeepskyAndroidScanNumOfMatch,reportDelay: null == reportDelay ? _self.reportDelay : reportDelay // ignore: cast_nullable_to_non_nullable
as Duration,phy: null == phy ? _self.phy : phy // ignore: cast_nullable_to_non_nullable
as DeepskyAndroidScanPhy,
  ));
}


}

/// @nodoc
mixin _$DeepskyDarwinScanSetting {

 bool get allowDuplicates; List<DeepskyUuid> get solicitedServiceUuids;
/// Create a copy of DeepskyDarwinScanSetting
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeepskyDarwinScanSettingCopyWith<DeepskyDarwinScanSetting> get copyWith => _$DeepskyDarwinScanSettingCopyWithImpl<DeepskyDarwinScanSetting>(this as DeepskyDarwinScanSetting, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeepskyDarwinScanSetting&&(identical(other.allowDuplicates, allowDuplicates) || other.allowDuplicates == allowDuplicates)&&const DeepCollectionEquality().equals(other.solicitedServiceUuids, solicitedServiceUuids));
}


@override
int get hashCode => Object.hash(runtimeType,allowDuplicates,const DeepCollectionEquality().hash(solicitedServiceUuids));

@override
String toString() {
  return 'DeepskyDarwinScanSetting(allowDuplicates: $allowDuplicates, solicitedServiceUuids: $solicitedServiceUuids)';
}


}

/// @nodoc
abstract mixin class $DeepskyDarwinScanSettingCopyWith<$Res>  {
  factory $DeepskyDarwinScanSettingCopyWith(DeepskyDarwinScanSetting value, $Res Function(DeepskyDarwinScanSetting) _then) = _$DeepskyDarwinScanSettingCopyWithImpl;
@useResult
$Res call({
 bool allowDuplicates, List<DeepskyUuid> solicitedServiceUuids
});




}
/// @nodoc
class _$DeepskyDarwinScanSettingCopyWithImpl<$Res>
    implements $DeepskyDarwinScanSettingCopyWith<$Res> {
  _$DeepskyDarwinScanSettingCopyWithImpl(this._self, this._then);

  final DeepskyDarwinScanSetting _self;
  final $Res Function(DeepskyDarwinScanSetting) _then;

/// Create a copy of DeepskyDarwinScanSetting
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? allowDuplicates = null,Object? solicitedServiceUuids = null,}) {
  return _then(_self.copyWith(
allowDuplicates: null == allowDuplicates ? _self.allowDuplicates : allowDuplicates // ignore: cast_nullable_to_non_nullable
as bool,solicitedServiceUuids: null == solicitedServiceUuids ? _self.solicitedServiceUuids : solicitedServiceUuids // ignore: cast_nullable_to_non_nullable
as List<DeepskyUuid>,
  ));
}

}


/// Adds pattern-matching-related methods to [DeepskyDarwinScanSetting].
extension DeepskyDarwinScanSettingPatterns on DeepskyDarwinScanSetting {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeepskyDarwinScanSetting value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeepskyDarwinScanSetting() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeepskyDarwinScanSetting value)  $default,){
final _that = this;
switch (_that) {
case _DeepskyDarwinScanSetting():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeepskyDarwinScanSetting value)?  $default,){
final _that = this;
switch (_that) {
case _DeepskyDarwinScanSetting() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool allowDuplicates,  List<DeepskyUuid> solicitedServiceUuids)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeepskyDarwinScanSetting() when $default != null:
return $default(_that.allowDuplicates,_that.solicitedServiceUuids);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool allowDuplicates,  List<DeepskyUuid> solicitedServiceUuids)  $default,) {final _that = this;
switch (_that) {
case _DeepskyDarwinScanSetting():
return $default(_that.allowDuplicates,_that.solicitedServiceUuids);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool allowDuplicates,  List<DeepskyUuid> solicitedServiceUuids)?  $default,) {final _that = this;
switch (_that) {
case _DeepskyDarwinScanSetting() when $default != null:
return $default(_that.allowDuplicates,_that.solicitedServiceUuids);case _:
  return null;

}
}

}

/// @nodoc


class _DeepskyDarwinScanSetting implements DeepskyDarwinScanSetting {
  const _DeepskyDarwinScanSetting({this.allowDuplicates = false, final  List<DeepskyUuid> solicitedServiceUuids = const <DeepskyUuid>[]}): _solicitedServiceUuids = solicitedServiceUuids;


@override@JsonKey() final  bool allowDuplicates;
 final  List<DeepskyUuid> _solicitedServiceUuids;
@override@JsonKey() List<DeepskyUuid> get solicitedServiceUuids {
  if (_solicitedServiceUuids is EqualUnmodifiableListView) return _solicitedServiceUuids;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_solicitedServiceUuids);
}


/// Create a copy of DeepskyDarwinScanSetting
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeepskyDarwinScanSettingCopyWith<_DeepskyDarwinScanSetting> get copyWith => __$DeepskyDarwinScanSettingCopyWithImpl<_DeepskyDarwinScanSetting>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeepskyDarwinScanSetting&&(identical(other.allowDuplicates, allowDuplicates) || other.allowDuplicates == allowDuplicates)&&const DeepCollectionEquality().equals(other._solicitedServiceUuids, _solicitedServiceUuids));
}


@override
int get hashCode => Object.hash(runtimeType,allowDuplicates,const DeepCollectionEquality().hash(_solicitedServiceUuids));

@override
String toString() {
  return 'DeepskyDarwinScanSetting(allowDuplicates: $allowDuplicates, solicitedServiceUuids: $solicitedServiceUuids)';
}


}

/// @nodoc
abstract mixin class _$DeepskyDarwinScanSettingCopyWith<$Res> implements $DeepskyDarwinScanSettingCopyWith<$Res> {
  factory _$DeepskyDarwinScanSettingCopyWith(_DeepskyDarwinScanSetting value, $Res Function(_DeepskyDarwinScanSetting) _then) = __$DeepskyDarwinScanSettingCopyWithImpl;
@override @useResult
$Res call({
 bool allowDuplicates, List<DeepskyUuid> solicitedServiceUuids
});




}
/// @nodoc
class __$DeepskyDarwinScanSettingCopyWithImpl<$Res>
    implements _$DeepskyDarwinScanSettingCopyWith<$Res> {
  __$DeepskyDarwinScanSettingCopyWithImpl(this._self, this._then);

  final _DeepskyDarwinScanSetting _self;
  final $Res Function(_DeepskyDarwinScanSetting) _then;

/// Create a copy of DeepskyDarwinScanSetting
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? allowDuplicates = null,Object? solicitedServiceUuids = null,}) {
  return _then(_DeepskyDarwinScanSetting(
allowDuplicates: null == allowDuplicates ? _self.allowDuplicates : allowDuplicates // ignore: cast_nullable_to_non_nullable
as bool,solicitedServiceUuids: null == solicitedServiceUuids ? _self._solicitedServiceUuids : solicitedServiceUuids // ignore: cast_nullable_to_non_nullable
as List<DeepskyUuid>,
  ));
}


}

/// @nodoc
mixin _$DeepskyScanOptions {

 DeepskyAndroidScanSetting get android; DeepskyDarwinScanSetting get darwin;
/// Create a copy of DeepskyScanOptions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeepskyScanOptionsCopyWith<DeepskyScanOptions> get copyWith => _$DeepskyScanOptionsCopyWithImpl<DeepskyScanOptions>(this as DeepskyScanOptions, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeepskyScanOptions&&(identical(other.android, android) || other.android == android)&&(identical(other.darwin, darwin) || other.darwin == darwin));
}


@override
int get hashCode => Object.hash(runtimeType,android,darwin);

@override
String toString() {
  return 'DeepskyScanOptions(android: $android, darwin: $darwin)';
}


}

/// @nodoc
abstract mixin class $DeepskyScanOptionsCopyWith<$Res>  {
  factory $DeepskyScanOptionsCopyWith(DeepskyScanOptions value, $Res Function(DeepskyScanOptions) _then) = _$DeepskyScanOptionsCopyWithImpl;
@useResult
$Res call({
 DeepskyAndroidScanSetting android, DeepskyDarwinScanSetting darwin
});


$DeepskyAndroidScanSettingCopyWith<$Res> get android;$DeepskyDarwinScanSettingCopyWith<$Res> get darwin;

}
/// @nodoc
class _$DeepskyScanOptionsCopyWithImpl<$Res>
    implements $DeepskyScanOptionsCopyWith<$Res> {
  _$DeepskyScanOptionsCopyWithImpl(this._self, this._then);

  final DeepskyScanOptions _self;
  final $Res Function(DeepskyScanOptions) _then;

/// Create a copy of DeepskyScanOptions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? android = null,Object? darwin = null,}) {
  return _then(_self.copyWith(
android: null == android ? _self.android : android // ignore: cast_nullable_to_non_nullable
as DeepskyAndroidScanSetting,darwin: null == darwin ? _self.darwin : darwin // ignore: cast_nullable_to_non_nullable
as DeepskyDarwinScanSetting,
  ));
}
/// Create a copy of DeepskyScanOptions
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeepskyAndroidScanSettingCopyWith<$Res> get android {

  return $DeepskyAndroidScanSettingCopyWith<$Res>(_self.android, (value) {
    return _then(_self.copyWith(android: value));
  });
}/// Create a copy of DeepskyScanOptions
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeepskyDarwinScanSettingCopyWith<$Res> get darwin {

  return $DeepskyDarwinScanSettingCopyWith<$Res>(_self.darwin, (value) {
    return _then(_self.copyWith(darwin: value));
  });
}
}


/// Adds pattern-matching-related methods to [DeepskyScanOptions].
extension DeepskyScanOptionsPatterns on DeepskyScanOptions {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeepskyScanOptions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeepskyScanOptions() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeepskyScanOptions value)  $default,){
final _that = this;
switch (_that) {
case _DeepskyScanOptions():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeepskyScanOptions value)?  $default,){
final _that = this;
switch (_that) {
case _DeepskyScanOptions() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DeepskyAndroidScanSetting android,  DeepskyDarwinScanSetting darwin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeepskyScanOptions() when $default != null:
return $default(_that.android,_that.darwin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DeepskyAndroidScanSetting android,  DeepskyDarwinScanSetting darwin)  $default,) {final _that = this;
switch (_that) {
case _DeepskyScanOptions():
return $default(_that.android,_that.darwin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DeepskyAndroidScanSetting android,  DeepskyDarwinScanSetting darwin)?  $default,) {final _that = this;
switch (_that) {
case _DeepskyScanOptions() when $default != null:
return $default(_that.android,_that.darwin);case _:
  return null;

}
}

}

/// @nodoc


class _DeepskyScanOptions implements DeepskyScanOptions {
  const _DeepskyScanOptions({this.android = const DeepskyAndroidScanSetting(), this.darwin = const DeepskyDarwinScanSetting()});


@override@JsonKey() final  DeepskyAndroidScanSetting android;
@override@JsonKey() final  DeepskyDarwinScanSetting darwin;

/// Create a copy of DeepskyScanOptions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeepskyScanOptionsCopyWith<_DeepskyScanOptions> get copyWith => __$DeepskyScanOptionsCopyWithImpl<_DeepskyScanOptions>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeepskyScanOptions&&(identical(other.android, android) || other.android == android)&&(identical(other.darwin, darwin) || other.darwin == darwin));
}


@override
int get hashCode => Object.hash(runtimeType,android,darwin);

@override
String toString() {
  return 'DeepskyScanOptions(android: $android, darwin: $darwin)';
}


}

/// @nodoc
abstract mixin class _$DeepskyScanOptionsCopyWith<$Res> implements $DeepskyScanOptionsCopyWith<$Res> {
  factory _$DeepskyScanOptionsCopyWith(_DeepskyScanOptions value, $Res Function(_DeepskyScanOptions) _then) = __$DeepskyScanOptionsCopyWithImpl;
@override @useResult
$Res call({
 DeepskyAndroidScanSetting android, DeepskyDarwinScanSetting darwin
});


@override $DeepskyAndroidScanSettingCopyWith<$Res> get android;@override $DeepskyDarwinScanSettingCopyWith<$Res> get darwin;

}
/// @nodoc
class __$DeepskyScanOptionsCopyWithImpl<$Res>
    implements _$DeepskyScanOptionsCopyWith<$Res> {
  __$DeepskyScanOptionsCopyWithImpl(this._self, this._then);

  final _DeepskyScanOptions _self;
  final $Res Function(_DeepskyScanOptions) _then;

/// Create a copy of DeepskyScanOptions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? android = null,Object? darwin = null,}) {
  return _then(_DeepskyScanOptions(
android: null == android ? _self.android : android // ignore: cast_nullable_to_non_nullable
as DeepskyAndroidScanSetting,darwin: null == darwin ? _self.darwin : darwin // ignore: cast_nullable_to_non_nullable
as DeepskyDarwinScanSetting,
  ));
}

/// Create a copy of DeepskyScanOptions
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeepskyAndroidScanSettingCopyWith<$Res> get android {

  return $DeepskyAndroidScanSettingCopyWith<$Res>(_self.android, (value) {
    return _then(_self.copyWith(android: value));
  });
}/// Create a copy of DeepskyScanOptions
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeepskyDarwinScanSettingCopyWith<$Res> get darwin {

  return $DeepskyDarwinScanSettingCopyWith<$Res>(_self.darwin, (value) {
    return _then(_self.copyWith(darwin: value));
  });
}
}

/// @nodoc
mixin _$BleScanResult {

 DeepskyDeviceId get deviceId; int get rssi; List<DeepskyUuid> get serviceUuids; String? get name; Uint8List? get manufacturerData; Uint8List? get raw;
/// Create a copy of BleScanResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BleScanResultCopyWith<BleScanResult> get copyWith => _$BleScanResultCopyWithImpl<BleScanResult>(this as BleScanResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BleScanResult&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.rssi, rssi) || other.rssi == rssi)&&const DeepCollectionEquality().equals(other.serviceUuids, serviceUuids)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.manufacturerData, manufacturerData)&&const DeepCollectionEquality().equals(other.raw, raw));
}


@override
int get hashCode => Object.hash(runtimeType,deviceId,rssi,const DeepCollectionEquality().hash(serviceUuids),name,const DeepCollectionEquality().hash(manufacturerData),const DeepCollectionEquality().hash(raw));

@override
String toString() {
  return 'BleScanResult(deviceId: $deviceId, rssi: $rssi, serviceUuids: $serviceUuids, name: $name, manufacturerData: $manufacturerData, raw: $raw)';
}


}

/// @nodoc
abstract mixin class $BleScanResultCopyWith<$Res>  {
  factory $BleScanResultCopyWith(BleScanResult value, $Res Function(BleScanResult) _then) = _$BleScanResultCopyWithImpl;
@useResult
$Res call({
 DeepskyDeviceId deviceId, int rssi, List<DeepskyUuid> serviceUuids, String? name, Uint8List? manufacturerData, Uint8List? raw
});


$DeepskyDeviceIdCopyWith<$Res> get deviceId;

}
/// @nodoc
class _$BleScanResultCopyWithImpl<$Res>
    implements $BleScanResultCopyWith<$Res> {
  _$BleScanResultCopyWithImpl(this._self, this._then);

  final BleScanResult _self;
  final $Res Function(BleScanResult) _then;

/// Create a copy of BleScanResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceId = null,Object? rssi = null,Object? serviceUuids = null,Object? name = freezed,Object? manufacturerData = freezed,Object? raw = freezed,}) {
  return _then(_self.copyWith(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as DeepskyDeviceId,rssi: null == rssi ? _self.rssi : rssi // ignore: cast_nullable_to_non_nullable
as int,serviceUuids: null == serviceUuids ? _self.serviceUuids : serviceUuids // ignore: cast_nullable_to_non_nullable
as List<DeepskyUuid>,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,manufacturerData: freezed == manufacturerData ? _self.manufacturerData : manufacturerData // ignore: cast_nullable_to_non_nullable
as Uint8List?,raw: freezed == raw ? _self.raw : raw // ignore: cast_nullable_to_non_nullable
as Uint8List?,
  ));
}
/// Create a copy of BleScanResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeepskyDeviceIdCopyWith<$Res> get deviceId {

  return $DeepskyDeviceIdCopyWith<$Res>(_self.deviceId, (value) {
    return _then(_self.copyWith(deviceId: value));
  });
}
}


/// Adds pattern-matching-related methods to [BleScanResult].
extension BleScanResultPatterns on BleScanResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BleScanResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BleScanResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BleScanResult value)  $default,){
final _that = this;
switch (_that) {
case _BleScanResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BleScanResult value)?  $default,){
final _that = this;
switch (_that) {
case _BleScanResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DeepskyDeviceId deviceId,  int rssi,  List<DeepskyUuid> serviceUuids,  String? name,  Uint8List? manufacturerData,  Uint8List? raw)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BleScanResult() when $default != null:
return $default(_that.deviceId,_that.rssi,_that.serviceUuids,_that.name,_that.manufacturerData,_that.raw);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DeepskyDeviceId deviceId,  int rssi,  List<DeepskyUuid> serviceUuids,  String? name,  Uint8List? manufacturerData,  Uint8List? raw)  $default,) {final _that = this;
switch (_that) {
case _BleScanResult():
return $default(_that.deviceId,_that.rssi,_that.serviceUuids,_that.name,_that.manufacturerData,_that.raw);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DeepskyDeviceId deviceId,  int rssi,  List<DeepskyUuid> serviceUuids,  String? name,  Uint8List? manufacturerData,  Uint8List? raw)?  $default,) {final _that = this;
switch (_that) {
case _BleScanResult() when $default != null:
return $default(_that.deviceId,_that.rssi,_that.serviceUuids,_that.name,_that.manufacturerData,_that.raw);case _:
  return null;

}
}

}

/// @nodoc


class _BleScanResult implements BleScanResult {
  const _BleScanResult({required this.deviceId, required this.rssi, required final  List<DeepskyUuid> serviceUuids, this.name, this.manufacturerData, this.raw}): _serviceUuids = serviceUuids;


@override final  DeepskyDeviceId deviceId;
@override final  int rssi;
 final  List<DeepskyUuid> _serviceUuids;
@override List<DeepskyUuid> get serviceUuids {
  if (_serviceUuids is EqualUnmodifiableListView) return _serviceUuids;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_serviceUuids);
}

@override final  String? name;
@override final  Uint8List? manufacturerData;
@override final  Uint8List? raw;

/// Create a copy of BleScanResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BleScanResultCopyWith<_BleScanResult> get copyWith => __$BleScanResultCopyWithImpl<_BleScanResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BleScanResult&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.rssi, rssi) || other.rssi == rssi)&&const DeepCollectionEquality().equals(other._serviceUuids, _serviceUuids)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.manufacturerData, manufacturerData)&&const DeepCollectionEquality().equals(other.raw, raw));
}


@override
int get hashCode => Object.hash(runtimeType,deviceId,rssi,const DeepCollectionEquality().hash(_serviceUuids),name,const DeepCollectionEquality().hash(manufacturerData),const DeepCollectionEquality().hash(raw));

@override
String toString() {
  return 'BleScanResult(deviceId: $deviceId, rssi: $rssi, serviceUuids: $serviceUuids, name: $name, manufacturerData: $manufacturerData, raw: $raw)';
}


}

/// @nodoc
abstract mixin class _$BleScanResultCopyWith<$Res> implements $BleScanResultCopyWith<$Res> {
  factory _$BleScanResultCopyWith(_BleScanResult value, $Res Function(_BleScanResult) _then) = __$BleScanResultCopyWithImpl;
@override @useResult
$Res call({
 DeepskyDeviceId deviceId, int rssi, List<DeepskyUuid> serviceUuids, String? name, Uint8List? manufacturerData, Uint8List? raw
});


@override $DeepskyDeviceIdCopyWith<$Res> get deviceId;

}
/// @nodoc
class __$BleScanResultCopyWithImpl<$Res>
    implements _$BleScanResultCopyWith<$Res> {
  __$BleScanResultCopyWithImpl(this._self, this._then);

  final _BleScanResult _self;
  final $Res Function(_BleScanResult) _then;

/// Create a copy of BleScanResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceId = null,Object? rssi = null,Object? serviceUuids = null,Object? name = freezed,Object? manufacturerData = freezed,Object? raw = freezed,}) {
  return _then(_BleScanResult(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as DeepskyDeviceId,rssi: null == rssi ? _self.rssi : rssi // ignore: cast_nullable_to_non_nullable
as int,serviceUuids: null == serviceUuids ? _self._serviceUuids : serviceUuids // ignore: cast_nullable_to_non_nullable
as List<DeepskyUuid>,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,manufacturerData: freezed == manufacturerData ? _self.manufacturerData : manufacturerData // ignore: cast_nullable_to_non_nullable
as Uint8List?,raw: freezed == raw ? _self.raw : raw // ignore: cast_nullable_to_non_nullable
as Uint8List?,
  ));
}

/// Create a copy of BleScanResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeepskyDeviceIdCopyWith<$Res> get deviceId {

  return $DeepskyDeviceIdCopyWith<$Res>(_self.deviceId, (value) {
    return _then(_self.copyWith(deviceId: value));
  });
}
}

/// @nodoc
mixin _$BleCharacteristicProperties {

 bool get broadcast; bool get read; bool get writeWithoutResponse; bool get writeWithResponse; bool get notify; bool get indicate; bool get authenticatedSignedWrites; bool get extendedProperties;
/// Create a copy of BleCharacteristicProperties
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BleCharacteristicPropertiesCopyWith<BleCharacteristicProperties> get copyWith => _$BleCharacteristicPropertiesCopyWithImpl<BleCharacteristicProperties>(this as BleCharacteristicProperties, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BleCharacteristicProperties&&(identical(other.broadcast, broadcast) || other.broadcast == broadcast)&&(identical(other.read, read) || other.read == read)&&(identical(other.writeWithoutResponse, writeWithoutResponse) || other.writeWithoutResponse == writeWithoutResponse)&&(identical(other.writeWithResponse, writeWithResponse) || other.writeWithResponse == writeWithResponse)&&(identical(other.notify, notify) || other.notify == notify)&&(identical(other.indicate, indicate) || other.indicate == indicate)&&(identical(other.authenticatedSignedWrites, authenticatedSignedWrites) || other.authenticatedSignedWrites == authenticatedSignedWrites)&&(identical(other.extendedProperties, extendedProperties) || other.extendedProperties == extendedProperties));
}


@override
int get hashCode => Object.hash(runtimeType,broadcast,read,writeWithoutResponse,writeWithResponse,notify,indicate,authenticatedSignedWrites,extendedProperties);

@override
String toString() {
  return 'BleCharacteristicProperties(broadcast: $broadcast, read: $read, writeWithoutResponse: $writeWithoutResponse, writeWithResponse: $writeWithResponse, notify: $notify, indicate: $indicate, authenticatedSignedWrites: $authenticatedSignedWrites, extendedProperties: $extendedProperties)';
}


}

/// @nodoc
abstract mixin class $BleCharacteristicPropertiesCopyWith<$Res>  {
  factory $BleCharacteristicPropertiesCopyWith(BleCharacteristicProperties value, $Res Function(BleCharacteristicProperties) _then) = _$BleCharacteristicPropertiesCopyWithImpl;
@useResult
$Res call({
 bool broadcast, bool read, bool writeWithoutResponse, bool writeWithResponse, bool notify, bool indicate, bool authenticatedSignedWrites, bool extendedProperties
});




}
/// @nodoc
class _$BleCharacteristicPropertiesCopyWithImpl<$Res>
    implements $BleCharacteristicPropertiesCopyWith<$Res> {
  _$BleCharacteristicPropertiesCopyWithImpl(this._self, this._then);

  final BleCharacteristicProperties _self;
  final $Res Function(BleCharacteristicProperties) _then;

/// Create a copy of BleCharacteristicProperties
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? broadcast = null,Object? read = null,Object? writeWithoutResponse = null,Object? writeWithResponse = null,Object? notify = null,Object? indicate = null,Object? authenticatedSignedWrites = null,Object? extendedProperties = null,}) {
  return _then(_self.copyWith(
broadcast: null == broadcast ? _self.broadcast : broadcast // ignore: cast_nullable_to_non_nullable
as bool,read: null == read ? _self.read : read // ignore: cast_nullable_to_non_nullable
as bool,writeWithoutResponse: null == writeWithoutResponse ? _self.writeWithoutResponse : writeWithoutResponse // ignore: cast_nullable_to_non_nullable
as bool,writeWithResponse: null == writeWithResponse ? _self.writeWithResponse : writeWithResponse // ignore: cast_nullable_to_non_nullable
as bool,notify: null == notify ? _self.notify : notify // ignore: cast_nullable_to_non_nullable
as bool,indicate: null == indicate ? _self.indicate : indicate // ignore: cast_nullable_to_non_nullable
as bool,authenticatedSignedWrites: null == authenticatedSignedWrites ? _self.authenticatedSignedWrites : authenticatedSignedWrites // ignore: cast_nullable_to_non_nullable
as bool,extendedProperties: null == extendedProperties ? _self.extendedProperties : extendedProperties // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [BleCharacteristicProperties].
extension BleCharacteristicPropertiesPatterns on BleCharacteristicProperties {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BleCharacteristicProperties value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BleCharacteristicProperties() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BleCharacteristicProperties value)  $default,){
final _that = this;
switch (_that) {
case _BleCharacteristicProperties():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BleCharacteristicProperties value)?  $default,){
final _that = this;
switch (_that) {
case _BleCharacteristicProperties() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool broadcast,  bool read,  bool writeWithoutResponse,  bool writeWithResponse,  bool notify,  bool indicate,  bool authenticatedSignedWrites,  bool extendedProperties)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BleCharacteristicProperties() when $default != null:
return $default(_that.broadcast,_that.read,_that.writeWithoutResponse,_that.writeWithResponse,_that.notify,_that.indicate,_that.authenticatedSignedWrites,_that.extendedProperties);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool broadcast,  bool read,  bool writeWithoutResponse,  bool writeWithResponse,  bool notify,  bool indicate,  bool authenticatedSignedWrites,  bool extendedProperties)  $default,) {final _that = this;
switch (_that) {
case _BleCharacteristicProperties():
return $default(_that.broadcast,_that.read,_that.writeWithoutResponse,_that.writeWithResponse,_that.notify,_that.indicate,_that.authenticatedSignedWrites,_that.extendedProperties);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool broadcast,  bool read,  bool writeWithoutResponse,  bool writeWithResponse,  bool notify,  bool indicate,  bool authenticatedSignedWrites,  bool extendedProperties)?  $default,) {final _that = this;
switch (_that) {
case _BleCharacteristicProperties() when $default != null:
return $default(_that.broadcast,_that.read,_that.writeWithoutResponse,_that.writeWithResponse,_that.notify,_that.indicate,_that.authenticatedSignedWrites,_that.extendedProperties);case _:
  return null;

}
}

}

/// @nodoc


class _BleCharacteristicProperties implements BleCharacteristicProperties {
  const _BleCharacteristicProperties({this.broadcast = false, this.read = false, this.writeWithoutResponse = false, this.writeWithResponse = false, this.notify = false, this.indicate = false, this.authenticatedSignedWrites = false, this.extendedProperties = false});


@override@JsonKey() final  bool broadcast;
@override@JsonKey() final  bool read;
@override@JsonKey() final  bool writeWithoutResponse;
@override@JsonKey() final  bool writeWithResponse;
@override@JsonKey() final  bool notify;
@override@JsonKey() final  bool indicate;
@override@JsonKey() final  bool authenticatedSignedWrites;
@override@JsonKey() final  bool extendedProperties;

/// Create a copy of BleCharacteristicProperties
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BleCharacteristicPropertiesCopyWith<_BleCharacteristicProperties> get copyWith => __$BleCharacteristicPropertiesCopyWithImpl<_BleCharacteristicProperties>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BleCharacteristicProperties&&(identical(other.broadcast, broadcast) || other.broadcast == broadcast)&&(identical(other.read, read) || other.read == read)&&(identical(other.writeWithoutResponse, writeWithoutResponse) || other.writeWithoutResponse == writeWithoutResponse)&&(identical(other.writeWithResponse, writeWithResponse) || other.writeWithResponse == writeWithResponse)&&(identical(other.notify, notify) || other.notify == notify)&&(identical(other.indicate, indicate) || other.indicate == indicate)&&(identical(other.authenticatedSignedWrites, authenticatedSignedWrites) || other.authenticatedSignedWrites == authenticatedSignedWrites)&&(identical(other.extendedProperties, extendedProperties) || other.extendedProperties == extendedProperties));
}


@override
int get hashCode => Object.hash(runtimeType,broadcast,read,writeWithoutResponse,writeWithResponse,notify,indicate,authenticatedSignedWrites,extendedProperties);

@override
String toString() {
  return 'BleCharacteristicProperties(broadcast: $broadcast, read: $read, writeWithoutResponse: $writeWithoutResponse, writeWithResponse: $writeWithResponse, notify: $notify, indicate: $indicate, authenticatedSignedWrites: $authenticatedSignedWrites, extendedProperties: $extendedProperties)';
}


}

/// @nodoc
abstract mixin class _$BleCharacteristicPropertiesCopyWith<$Res> implements $BleCharacteristicPropertiesCopyWith<$Res> {
  factory _$BleCharacteristicPropertiesCopyWith(_BleCharacteristicProperties value, $Res Function(_BleCharacteristicProperties) _then) = __$BleCharacteristicPropertiesCopyWithImpl;
@override @useResult
$Res call({
 bool broadcast, bool read, bool writeWithoutResponse, bool writeWithResponse, bool notify, bool indicate, bool authenticatedSignedWrites, bool extendedProperties
});




}
/// @nodoc
class __$BleCharacteristicPropertiesCopyWithImpl<$Res>
    implements _$BleCharacteristicPropertiesCopyWith<$Res> {
  __$BleCharacteristicPropertiesCopyWithImpl(this._self, this._then);

  final _BleCharacteristicProperties _self;
  final $Res Function(_BleCharacteristicProperties) _then;

/// Create a copy of BleCharacteristicProperties
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? broadcast = null,Object? read = null,Object? writeWithoutResponse = null,Object? writeWithResponse = null,Object? notify = null,Object? indicate = null,Object? authenticatedSignedWrites = null,Object? extendedProperties = null,}) {
  return _then(_BleCharacteristicProperties(
broadcast: null == broadcast ? _self.broadcast : broadcast // ignore: cast_nullable_to_non_nullable
as bool,read: null == read ? _self.read : read // ignore: cast_nullable_to_non_nullable
as bool,writeWithoutResponse: null == writeWithoutResponse ? _self.writeWithoutResponse : writeWithoutResponse // ignore: cast_nullable_to_non_nullable
as bool,writeWithResponse: null == writeWithResponse ? _self.writeWithResponse : writeWithResponse // ignore: cast_nullable_to_non_nullable
as bool,notify: null == notify ? _self.notify : notify // ignore: cast_nullable_to_non_nullable
as bool,indicate: null == indicate ? _self.indicate : indicate // ignore: cast_nullable_to_non_nullable
as bool,authenticatedSignedWrites: null == authenticatedSignedWrites ? _self.authenticatedSignedWrites : authenticatedSignedWrites // ignore: cast_nullable_to_non_nullable
as bool,extendedProperties: null == extendedProperties ? _self.extendedProperties : extendedProperties // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$BleServiceInfo {

 int get handle; DeepskyUuid get uuid; List<BleCharacteristicInfo> get characteristics;
/// Create a copy of BleServiceInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BleServiceInfoCopyWith<BleServiceInfo> get copyWith => _$BleServiceInfoCopyWithImpl<BleServiceInfo>(this as BleServiceInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BleServiceInfo&&(identical(other.handle, handle) || other.handle == handle)&&(identical(other.uuid, uuid) || other.uuid == uuid)&&const DeepCollectionEquality().equals(other.characteristics, characteristics));
}


@override
int get hashCode => Object.hash(runtimeType,handle,uuid,const DeepCollectionEquality().hash(characteristics));

@override
String toString() {
  return 'BleServiceInfo(handle: $handle, uuid: $uuid, characteristics: $characteristics)';
}


}

/// @nodoc
abstract mixin class $BleServiceInfoCopyWith<$Res>  {
  factory $BleServiceInfoCopyWith(BleServiceInfo value, $Res Function(BleServiceInfo) _then) = _$BleServiceInfoCopyWithImpl;
@useResult
$Res call({
 int handle, DeepskyUuid uuid, List<BleCharacteristicInfo> characteristics
});


$DeepskyUuidCopyWith<$Res> get uuid;

}
/// @nodoc
class _$BleServiceInfoCopyWithImpl<$Res>
    implements $BleServiceInfoCopyWith<$Res> {
  _$BleServiceInfoCopyWithImpl(this._self, this._then);

  final BleServiceInfo _self;
  final $Res Function(BleServiceInfo) _then;

/// Create a copy of BleServiceInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? handle = null,Object? uuid = null,Object? characteristics = null,}) {
  return _then(_self.copyWith(
handle: null == handle ? _self.handle : handle // ignore: cast_nullable_to_non_nullable
as int,uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as DeepskyUuid,characteristics: null == characteristics ? _self.characteristics : characteristics // ignore: cast_nullable_to_non_nullable
as List<BleCharacteristicInfo>,
  ));
}
/// Create a copy of BleServiceInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeepskyUuidCopyWith<$Res> get uuid {

  return $DeepskyUuidCopyWith<$Res>(_self.uuid, (value) {
    return _then(_self.copyWith(uuid: value));
  });
}
}


/// Adds pattern-matching-related methods to [BleServiceInfo].
extension BleServiceInfoPatterns on BleServiceInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BleServiceInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BleServiceInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BleServiceInfo value)  $default,){
final _that = this;
switch (_that) {
case _BleServiceInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BleServiceInfo value)?  $default,){
final _that = this;
switch (_that) {
case _BleServiceInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int handle,  DeepskyUuid uuid,  List<BleCharacteristicInfo> characteristics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BleServiceInfo() when $default != null:
return $default(_that.handle,_that.uuid,_that.characteristics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int handle,  DeepskyUuid uuid,  List<BleCharacteristicInfo> characteristics)  $default,) {final _that = this;
switch (_that) {
case _BleServiceInfo():
return $default(_that.handle,_that.uuid,_that.characteristics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int handle,  DeepskyUuid uuid,  List<BleCharacteristicInfo> characteristics)?  $default,) {final _that = this;
switch (_that) {
case _BleServiceInfo() when $default != null:
return $default(_that.handle,_that.uuid,_that.characteristics);case _:
  return null;

}
}

}

/// @nodoc


class _BleServiceInfo implements BleServiceInfo {
  const _BleServiceInfo({required this.handle, required this.uuid, final  List<BleCharacteristicInfo> characteristics = const <BleCharacteristicInfo>[]}): assert(handle >= 0, 'handle must be non-negative'),_characteristics = characteristics;


@override final  int handle;
@override final  DeepskyUuid uuid;
 final  List<BleCharacteristicInfo> _characteristics;
@override@JsonKey() List<BleCharacteristicInfo> get characteristics {
  if (_characteristics is EqualUnmodifiableListView) return _characteristics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_characteristics);
}


/// Create a copy of BleServiceInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BleServiceInfoCopyWith<_BleServiceInfo> get copyWith => __$BleServiceInfoCopyWithImpl<_BleServiceInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BleServiceInfo&&(identical(other.handle, handle) || other.handle == handle)&&(identical(other.uuid, uuid) || other.uuid == uuid)&&const DeepCollectionEquality().equals(other._characteristics, _characteristics));
}


@override
int get hashCode => Object.hash(runtimeType,handle,uuid,const DeepCollectionEquality().hash(_characteristics));

@override
String toString() {
  return 'BleServiceInfo(handle: $handle, uuid: $uuid, characteristics: $characteristics)';
}


}

/// @nodoc
abstract mixin class _$BleServiceInfoCopyWith<$Res> implements $BleServiceInfoCopyWith<$Res> {
  factory _$BleServiceInfoCopyWith(_BleServiceInfo value, $Res Function(_BleServiceInfo) _then) = __$BleServiceInfoCopyWithImpl;
@override @useResult
$Res call({
 int handle, DeepskyUuid uuid, List<BleCharacteristicInfo> characteristics
});


@override $DeepskyUuidCopyWith<$Res> get uuid;

}
/// @nodoc
class __$BleServiceInfoCopyWithImpl<$Res>
    implements _$BleServiceInfoCopyWith<$Res> {
  __$BleServiceInfoCopyWithImpl(this._self, this._then);

  final _BleServiceInfo _self;
  final $Res Function(_BleServiceInfo) _then;

/// Create a copy of BleServiceInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? handle = null,Object? uuid = null,Object? characteristics = null,}) {
  return _then(_BleServiceInfo(
handle: null == handle ? _self.handle : handle // ignore: cast_nullable_to_non_nullable
as int,uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as DeepskyUuid,characteristics: null == characteristics ? _self._characteristics : characteristics // ignore: cast_nullable_to_non_nullable
as List<BleCharacteristicInfo>,
  ));
}

/// Create a copy of BleServiceInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeepskyUuidCopyWith<$Res> get uuid {

  return $DeepskyUuidCopyWith<$Res>(_self.uuid, (value) {
    return _then(_self.copyWith(uuid: value));
  });
}
}

/// @nodoc
mixin _$BleCharacteristicInfo {

 int get handle; int get serviceHandle; DeepskyUuid get uuid; BleCharacteristicProperties get properties; List<BleDescriptorInfo> get descriptors;
/// Create a copy of BleCharacteristicInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BleCharacteristicInfoCopyWith<BleCharacteristicInfo> get copyWith => _$BleCharacteristicInfoCopyWithImpl<BleCharacteristicInfo>(this as BleCharacteristicInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BleCharacteristicInfo&&(identical(other.handle, handle) || other.handle == handle)&&(identical(other.serviceHandle, serviceHandle) || other.serviceHandle == serviceHandle)&&(identical(other.uuid, uuid) || other.uuid == uuid)&&(identical(other.properties, properties) || other.properties == properties)&&const DeepCollectionEquality().equals(other.descriptors, descriptors));
}


@override
int get hashCode => Object.hash(runtimeType,handle,serviceHandle,uuid,properties,const DeepCollectionEquality().hash(descriptors));

@override
String toString() {
  return 'BleCharacteristicInfo(handle: $handle, serviceHandle: $serviceHandle, uuid: $uuid, properties: $properties, descriptors: $descriptors)';
}


}

/// @nodoc
abstract mixin class $BleCharacteristicInfoCopyWith<$Res>  {
  factory $BleCharacteristicInfoCopyWith(BleCharacteristicInfo value, $Res Function(BleCharacteristicInfo) _then) = _$BleCharacteristicInfoCopyWithImpl;
@useResult
$Res call({
 int handle, int serviceHandle, DeepskyUuid uuid, BleCharacteristicProperties properties, List<BleDescriptorInfo> descriptors
});


$DeepskyUuidCopyWith<$Res> get uuid;$BleCharacteristicPropertiesCopyWith<$Res> get properties;

}
/// @nodoc
class _$BleCharacteristicInfoCopyWithImpl<$Res>
    implements $BleCharacteristicInfoCopyWith<$Res> {
  _$BleCharacteristicInfoCopyWithImpl(this._self, this._then);

  final BleCharacteristicInfo _self;
  final $Res Function(BleCharacteristicInfo) _then;

/// Create a copy of BleCharacteristicInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? handle = null,Object? serviceHandle = null,Object? uuid = null,Object? properties = null,Object? descriptors = null,}) {
  return _then(_self.copyWith(
handle: null == handle ? _self.handle : handle // ignore: cast_nullable_to_non_nullable
as int,serviceHandle: null == serviceHandle ? _self.serviceHandle : serviceHandle // ignore: cast_nullable_to_non_nullable
as int,uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as DeepskyUuid,properties: null == properties ? _self.properties : properties // ignore: cast_nullable_to_non_nullable
as BleCharacteristicProperties,descriptors: null == descriptors ? _self.descriptors : descriptors // ignore: cast_nullable_to_non_nullable
as List<BleDescriptorInfo>,
  ));
}
/// Create a copy of BleCharacteristicInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeepskyUuidCopyWith<$Res> get uuid {

  return $DeepskyUuidCopyWith<$Res>(_self.uuid, (value) {
    return _then(_self.copyWith(uuid: value));
  });
}/// Create a copy of BleCharacteristicInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BleCharacteristicPropertiesCopyWith<$Res> get properties {

  return $BleCharacteristicPropertiesCopyWith<$Res>(_self.properties, (value) {
    return _then(_self.copyWith(properties: value));
  });
}
}


/// Adds pattern-matching-related methods to [BleCharacteristicInfo].
extension BleCharacteristicInfoPatterns on BleCharacteristicInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BleCharacteristicInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BleCharacteristicInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BleCharacteristicInfo value)  $default,){
final _that = this;
switch (_that) {
case _BleCharacteristicInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BleCharacteristicInfo value)?  $default,){
final _that = this;
switch (_that) {
case _BleCharacteristicInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int handle,  int serviceHandle,  DeepskyUuid uuid,  BleCharacteristicProperties properties,  List<BleDescriptorInfo> descriptors)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BleCharacteristicInfo() when $default != null:
return $default(_that.handle,_that.serviceHandle,_that.uuid,_that.properties,_that.descriptors);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int handle,  int serviceHandle,  DeepskyUuid uuid,  BleCharacteristicProperties properties,  List<BleDescriptorInfo> descriptors)  $default,) {final _that = this;
switch (_that) {
case _BleCharacteristicInfo():
return $default(_that.handle,_that.serviceHandle,_that.uuid,_that.properties,_that.descriptors);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int handle,  int serviceHandle,  DeepskyUuid uuid,  BleCharacteristicProperties properties,  List<BleDescriptorInfo> descriptors)?  $default,) {final _that = this;
switch (_that) {
case _BleCharacteristicInfo() when $default != null:
return $default(_that.handle,_that.serviceHandle,_that.uuid,_that.properties,_that.descriptors);case _:
  return null;

}
}

}

/// @nodoc


class _BleCharacteristicInfo implements BleCharacteristicInfo {
  const _BleCharacteristicInfo({required this.handle, required this.serviceHandle, required this.uuid, required this.properties, final  List<BleDescriptorInfo> descriptors = const <BleDescriptorInfo>[]}): assert(handle >= 0, 'handle must be non-negative'),assert(serviceHandle >= 0, 'serviceHandle must be non-negative'),_descriptors = descriptors;


@override final  int handle;
@override final  int serviceHandle;
@override final  DeepskyUuid uuid;
@override final  BleCharacteristicProperties properties;
 final  List<BleDescriptorInfo> _descriptors;
@override@JsonKey() List<BleDescriptorInfo> get descriptors {
  if (_descriptors is EqualUnmodifiableListView) return _descriptors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_descriptors);
}


/// Create a copy of BleCharacteristicInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BleCharacteristicInfoCopyWith<_BleCharacteristicInfo> get copyWith => __$BleCharacteristicInfoCopyWithImpl<_BleCharacteristicInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BleCharacteristicInfo&&(identical(other.handle, handle) || other.handle == handle)&&(identical(other.serviceHandle, serviceHandle) || other.serviceHandle == serviceHandle)&&(identical(other.uuid, uuid) || other.uuid == uuid)&&(identical(other.properties, properties) || other.properties == properties)&&const DeepCollectionEquality().equals(other._descriptors, _descriptors));
}


@override
int get hashCode => Object.hash(runtimeType,handle,serviceHandle,uuid,properties,const DeepCollectionEquality().hash(_descriptors));

@override
String toString() {
  return 'BleCharacteristicInfo(handle: $handle, serviceHandle: $serviceHandle, uuid: $uuid, properties: $properties, descriptors: $descriptors)';
}


}

/// @nodoc
abstract mixin class _$BleCharacteristicInfoCopyWith<$Res> implements $BleCharacteristicInfoCopyWith<$Res> {
  factory _$BleCharacteristicInfoCopyWith(_BleCharacteristicInfo value, $Res Function(_BleCharacteristicInfo) _then) = __$BleCharacteristicInfoCopyWithImpl;
@override @useResult
$Res call({
 int handle, int serviceHandle, DeepskyUuid uuid, BleCharacteristicProperties properties, List<BleDescriptorInfo> descriptors
});


@override $DeepskyUuidCopyWith<$Res> get uuid;@override $BleCharacteristicPropertiesCopyWith<$Res> get properties;

}
/// @nodoc
class __$BleCharacteristicInfoCopyWithImpl<$Res>
    implements _$BleCharacteristicInfoCopyWith<$Res> {
  __$BleCharacteristicInfoCopyWithImpl(this._self, this._then);

  final _BleCharacteristicInfo _self;
  final $Res Function(_BleCharacteristicInfo) _then;

/// Create a copy of BleCharacteristicInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? handle = null,Object? serviceHandle = null,Object? uuid = null,Object? properties = null,Object? descriptors = null,}) {
  return _then(_BleCharacteristicInfo(
handle: null == handle ? _self.handle : handle // ignore: cast_nullable_to_non_nullable
as int,serviceHandle: null == serviceHandle ? _self.serviceHandle : serviceHandle // ignore: cast_nullable_to_non_nullable
as int,uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as DeepskyUuid,properties: null == properties ? _self.properties : properties // ignore: cast_nullable_to_non_nullable
as BleCharacteristicProperties,descriptors: null == descriptors ? _self._descriptors : descriptors // ignore: cast_nullable_to_non_nullable
as List<BleDescriptorInfo>,
  ));
}

/// Create a copy of BleCharacteristicInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeepskyUuidCopyWith<$Res> get uuid {

  return $DeepskyUuidCopyWith<$Res>(_self.uuid, (value) {
    return _then(_self.copyWith(uuid: value));
  });
}/// Create a copy of BleCharacteristicInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BleCharacteristicPropertiesCopyWith<$Res> get properties {

  return $BleCharacteristicPropertiesCopyWith<$Res>(_self.properties, (value) {
    return _then(_self.copyWith(properties: value));
  });
}
}

/// @nodoc
mixin _$BleDescriptorInfo {

 int get handle; DeepskyUuid get uuid;
/// Create a copy of BleDescriptorInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BleDescriptorInfoCopyWith<BleDescriptorInfo> get copyWith => _$BleDescriptorInfoCopyWithImpl<BleDescriptorInfo>(this as BleDescriptorInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BleDescriptorInfo&&(identical(other.handle, handle) || other.handle == handle)&&(identical(other.uuid, uuid) || other.uuid == uuid));
}


@override
int get hashCode => Object.hash(runtimeType,handle,uuid);

@override
String toString() {
  return 'BleDescriptorInfo(handle: $handle, uuid: $uuid)';
}


}

/// @nodoc
abstract mixin class $BleDescriptorInfoCopyWith<$Res>  {
  factory $BleDescriptorInfoCopyWith(BleDescriptorInfo value, $Res Function(BleDescriptorInfo) _then) = _$BleDescriptorInfoCopyWithImpl;
@useResult
$Res call({
 int handle, DeepskyUuid uuid
});


$DeepskyUuidCopyWith<$Res> get uuid;

}
/// @nodoc
class _$BleDescriptorInfoCopyWithImpl<$Res>
    implements $BleDescriptorInfoCopyWith<$Res> {
  _$BleDescriptorInfoCopyWithImpl(this._self, this._then);

  final BleDescriptorInfo _self;
  final $Res Function(BleDescriptorInfo) _then;

/// Create a copy of BleDescriptorInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? handle = null,Object? uuid = null,}) {
  return _then(_self.copyWith(
handle: null == handle ? _self.handle : handle // ignore: cast_nullable_to_non_nullable
as int,uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as DeepskyUuid,
  ));
}
/// Create a copy of BleDescriptorInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeepskyUuidCopyWith<$Res> get uuid {

  return $DeepskyUuidCopyWith<$Res>(_self.uuid, (value) {
    return _then(_self.copyWith(uuid: value));
  });
}
}


/// Adds pattern-matching-related methods to [BleDescriptorInfo].
extension BleDescriptorInfoPatterns on BleDescriptorInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BleDescriptorInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BleDescriptorInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BleDescriptorInfo value)  $default,){
final _that = this;
switch (_that) {
case _BleDescriptorInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BleDescriptorInfo value)?  $default,){
final _that = this;
switch (_that) {
case _BleDescriptorInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int handle,  DeepskyUuid uuid)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BleDescriptorInfo() when $default != null:
return $default(_that.handle,_that.uuid);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int handle,  DeepskyUuid uuid)  $default,) {final _that = this;
switch (_that) {
case _BleDescriptorInfo():
return $default(_that.handle,_that.uuid);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int handle,  DeepskyUuid uuid)?  $default,) {final _that = this;
switch (_that) {
case _BleDescriptorInfo() when $default != null:
return $default(_that.handle,_that.uuid);case _:
  return null;

}
}

}

/// @nodoc


class _BleDescriptorInfo implements BleDescriptorInfo {
  const _BleDescriptorInfo({required this.handle, required this.uuid}): assert(handle >= 0, 'handle must be non-negative');


@override final  int handle;
@override final  DeepskyUuid uuid;

/// Create a copy of BleDescriptorInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BleDescriptorInfoCopyWith<_BleDescriptorInfo> get copyWith => __$BleDescriptorInfoCopyWithImpl<_BleDescriptorInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BleDescriptorInfo&&(identical(other.handle, handle) || other.handle == handle)&&(identical(other.uuid, uuid) || other.uuid == uuid));
}


@override
int get hashCode => Object.hash(runtimeType,handle,uuid);

@override
String toString() {
  return 'BleDescriptorInfo(handle: $handle, uuid: $uuid)';
}


}

/// @nodoc
abstract mixin class _$BleDescriptorInfoCopyWith<$Res> implements $BleDescriptorInfoCopyWith<$Res> {
  factory _$BleDescriptorInfoCopyWith(_BleDescriptorInfo value, $Res Function(_BleDescriptorInfo) _then) = __$BleDescriptorInfoCopyWithImpl;
@override @useResult
$Res call({
 int handle, DeepskyUuid uuid
});


@override $DeepskyUuidCopyWith<$Res> get uuid;

}
/// @nodoc
class __$BleDescriptorInfoCopyWithImpl<$Res>
    implements _$BleDescriptorInfoCopyWith<$Res> {
  __$BleDescriptorInfoCopyWithImpl(this._self, this._then);

  final _BleDescriptorInfo _self;
  final $Res Function(_BleDescriptorInfo) _then;

/// Create a copy of BleDescriptorInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? handle = null,Object? uuid = null,}) {
  return _then(_BleDescriptorInfo(
handle: null == handle ? _self.handle : handle // ignore: cast_nullable_to_non_nullable
as int,uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as DeepskyUuid,
  ));
}

/// Create a copy of BleDescriptorInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeepskyUuidCopyWith<$Res> get uuid {

  return $DeepskyUuidCopyWith<$Res>(_self.uuid, (value) {
    return _then(_self.copyWith(uuid: value));
  });
}
}

/// @nodoc
mixin _$BleCharacteristicTarget {

 DeepskyDeviceId get deviceId; int get connectionEpoch; int get characteristicHandle;
/// Create a copy of BleCharacteristicTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BleCharacteristicTargetCopyWith<BleCharacteristicTarget> get copyWith => _$BleCharacteristicTargetCopyWithImpl<BleCharacteristicTarget>(this as BleCharacteristicTarget, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BleCharacteristicTarget&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.connectionEpoch, connectionEpoch) || other.connectionEpoch == connectionEpoch)&&(identical(other.characteristicHandle, characteristicHandle) || other.characteristicHandle == characteristicHandle));
}


@override
int get hashCode => Object.hash(runtimeType,deviceId,connectionEpoch,characteristicHandle);

@override
String toString() {
  return 'BleCharacteristicTarget(deviceId: $deviceId, connectionEpoch: $connectionEpoch, characteristicHandle: $characteristicHandle)';
}


}

/// @nodoc
abstract mixin class $BleCharacteristicTargetCopyWith<$Res>  {
  factory $BleCharacteristicTargetCopyWith(BleCharacteristicTarget value, $Res Function(BleCharacteristicTarget) _then) = _$BleCharacteristicTargetCopyWithImpl;
@useResult
$Res call({
 DeepskyDeviceId deviceId, int connectionEpoch, int characteristicHandle
});


$DeepskyDeviceIdCopyWith<$Res> get deviceId;

}
/// @nodoc
class _$BleCharacteristicTargetCopyWithImpl<$Res>
    implements $BleCharacteristicTargetCopyWith<$Res> {
  _$BleCharacteristicTargetCopyWithImpl(this._self, this._then);

  final BleCharacteristicTarget _self;
  final $Res Function(BleCharacteristicTarget) _then;

/// Create a copy of BleCharacteristicTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceId = null,Object? connectionEpoch = null,Object? characteristicHandle = null,}) {
  return _then(_self.copyWith(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as DeepskyDeviceId,connectionEpoch: null == connectionEpoch ? _self.connectionEpoch : connectionEpoch // ignore: cast_nullable_to_non_nullable
as int,characteristicHandle: null == characteristicHandle ? _self.characteristicHandle : characteristicHandle // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of BleCharacteristicTarget
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeepskyDeviceIdCopyWith<$Res> get deviceId {

  return $DeepskyDeviceIdCopyWith<$Res>(_self.deviceId, (value) {
    return _then(_self.copyWith(deviceId: value));
  });
}
}


/// Adds pattern-matching-related methods to [BleCharacteristicTarget].
extension BleCharacteristicTargetPatterns on BleCharacteristicTarget {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BleCharacteristicTarget value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BleCharacteristicTarget() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BleCharacteristicTarget value)  $default,){
final _that = this;
switch (_that) {
case _BleCharacteristicTarget():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BleCharacteristicTarget value)?  $default,){
final _that = this;
switch (_that) {
case _BleCharacteristicTarget() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DeepskyDeviceId deviceId,  int connectionEpoch,  int characteristicHandle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BleCharacteristicTarget() when $default != null:
return $default(_that.deviceId,_that.connectionEpoch,_that.characteristicHandle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DeepskyDeviceId deviceId,  int connectionEpoch,  int characteristicHandle)  $default,) {final _that = this;
switch (_that) {
case _BleCharacteristicTarget():
return $default(_that.deviceId,_that.connectionEpoch,_that.characteristicHandle);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DeepskyDeviceId deviceId,  int connectionEpoch,  int characteristicHandle)?  $default,) {final _that = this;
switch (_that) {
case _BleCharacteristicTarget() when $default != null:
return $default(_that.deviceId,_that.connectionEpoch,_that.characteristicHandle);case _:
  return null;

}
}

}

/// @nodoc


class _BleCharacteristicTarget implements BleCharacteristicTarget {
  const _BleCharacteristicTarget({required this.deviceId, required this.connectionEpoch, required this.characteristicHandle}): assert(connectionEpoch >= 0, 'connectionEpoch must be non-negative'),assert(characteristicHandle >= 0, 'handle must be non-negative');


@override final  DeepskyDeviceId deviceId;
@override final  int connectionEpoch;
@override final  int characteristicHandle;

/// Create a copy of BleCharacteristicTarget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BleCharacteristicTargetCopyWith<_BleCharacteristicTarget> get copyWith => __$BleCharacteristicTargetCopyWithImpl<_BleCharacteristicTarget>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BleCharacteristicTarget&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.connectionEpoch, connectionEpoch) || other.connectionEpoch == connectionEpoch)&&(identical(other.characteristicHandle, characteristicHandle) || other.characteristicHandle == characteristicHandle));
}


@override
int get hashCode => Object.hash(runtimeType,deviceId,connectionEpoch,characteristicHandle);

@override
String toString() {
  return 'BleCharacteristicTarget(deviceId: $deviceId, connectionEpoch: $connectionEpoch, characteristicHandle: $characteristicHandle)';
}


}

/// @nodoc
abstract mixin class _$BleCharacteristicTargetCopyWith<$Res> implements $BleCharacteristicTargetCopyWith<$Res> {
  factory _$BleCharacteristicTargetCopyWith(_BleCharacteristicTarget value, $Res Function(_BleCharacteristicTarget) _then) = __$BleCharacteristicTargetCopyWithImpl;
@override @useResult
$Res call({
 DeepskyDeviceId deviceId, int connectionEpoch, int characteristicHandle
});


@override $DeepskyDeviceIdCopyWith<$Res> get deviceId;

}
/// @nodoc
class __$BleCharacteristicTargetCopyWithImpl<$Res>
    implements _$BleCharacteristicTargetCopyWith<$Res> {
  __$BleCharacteristicTargetCopyWithImpl(this._self, this._then);

  final _BleCharacteristicTarget _self;
  final $Res Function(_BleCharacteristicTarget) _then;

/// Create a copy of BleCharacteristicTarget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceId = null,Object? connectionEpoch = null,Object? characteristicHandle = null,}) {
  return _then(_BleCharacteristicTarget(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as DeepskyDeviceId,connectionEpoch: null == connectionEpoch ? _self.connectionEpoch : connectionEpoch // ignore: cast_nullable_to_non_nullable
as int,characteristicHandle: null == characteristicHandle ? _self.characteristicHandle : characteristicHandle // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of BleCharacteristicTarget
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeepskyDeviceIdCopyWith<$Res> get deviceId {

  return $DeepskyDeviceIdCopyWith<$Res>(_self.deviceId, (value) {
    return _then(_self.copyWith(deviceId: value));
  });
}
}

/// @nodoc
mixin _$BleDescriptorTarget {

 DeepskyDeviceId get deviceId; int get connectionEpoch; int get characteristicHandle; int get descriptorHandle;
/// Create a copy of BleDescriptorTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BleDescriptorTargetCopyWith<BleDescriptorTarget> get copyWith => _$BleDescriptorTargetCopyWithImpl<BleDescriptorTarget>(this as BleDescriptorTarget, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BleDescriptorTarget&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.connectionEpoch, connectionEpoch) || other.connectionEpoch == connectionEpoch)&&(identical(other.characteristicHandle, characteristicHandle) || other.characteristicHandle == characteristicHandle)&&(identical(other.descriptorHandle, descriptorHandle) || other.descriptorHandle == descriptorHandle));
}


@override
int get hashCode => Object.hash(runtimeType,deviceId,connectionEpoch,characteristicHandle,descriptorHandle);

@override
String toString() {
  return 'BleDescriptorTarget(deviceId: $deviceId, connectionEpoch: $connectionEpoch, characteristicHandle: $characteristicHandle, descriptorHandle: $descriptorHandle)';
}


}

/// @nodoc
abstract mixin class $BleDescriptorTargetCopyWith<$Res>  {
  factory $BleDescriptorTargetCopyWith(BleDescriptorTarget value, $Res Function(BleDescriptorTarget) _then) = _$BleDescriptorTargetCopyWithImpl;
@useResult
$Res call({
 DeepskyDeviceId deviceId, int connectionEpoch, int characteristicHandle, int descriptorHandle
});


$DeepskyDeviceIdCopyWith<$Res> get deviceId;

}
/// @nodoc
class _$BleDescriptorTargetCopyWithImpl<$Res>
    implements $BleDescriptorTargetCopyWith<$Res> {
  _$BleDescriptorTargetCopyWithImpl(this._self, this._then);

  final BleDescriptorTarget _self;
  final $Res Function(BleDescriptorTarget) _then;

/// Create a copy of BleDescriptorTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceId = null,Object? connectionEpoch = null,Object? characteristicHandle = null,Object? descriptorHandle = null,}) {
  return _then(_self.copyWith(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as DeepskyDeviceId,connectionEpoch: null == connectionEpoch ? _self.connectionEpoch : connectionEpoch // ignore: cast_nullable_to_non_nullable
as int,characteristicHandle: null == characteristicHandle ? _self.characteristicHandle : characteristicHandle // ignore: cast_nullable_to_non_nullable
as int,descriptorHandle: null == descriptorHandle ? _self.descriptorHandle : descriptorHandle // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of BleDescriptorTarget
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeepskyDeviceIdCopyWith<$Res> get deviceId {

  return $DeepskyDeviceIdCopyWith<$Res>(_self.deviceId, (value) {
    return _then(_self.copyWith(deviceId: value));
  });
}
}


/// Adds pattern-matching-related methods to [BleDescriptorTarget].
extension BleDescriptorTargetPatterns on BleDescriptorTarget {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BleDescriptorTarget value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BleDescriptorTarget() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BleDescriptorTarget value)  $default,){
final _that = this;
switch (_that) {
case _BleDescriptorTarget():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BleDescriptorTarget value)?  $default,){
final _that = this;
switch (_that) {
case _BleDescriptorTarget() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DeepskyDeviceId deviceId,  int connectionEpoch,  int characteristicHandle,  int descriptorHandle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BleDescriptorTarget() when $default != null:
return $default(_that.deviceId,_that.connectionEpoch,_that.characteristicHandle,_that.descriptorHandle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DeepskyDeviceId deviceId,  int connectionEpoch,  int characteristicHandle,  int descriptorHandle)  $default,) {final _that = this;
switch (_that) {
case _BleDescriptorTarget():
return $default(_that.deviceId,_that.connectionEpoch,_that.characteristicHandle,_that.descriptorHandle);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DeepskyDeviceId deviceId,  int connectionEpoch,  int characteristicHandle,  int descriptorHandle)?  $default,) {final _that = this;
switch (_that) {
case _BleDescriptorTarget() when $default != null:
return $default(_that.deviceId,_that.connectionEpoch,_that.characteristicHandle,_that.descriptorHandle);case _:
  return null;

}
}

}

/// @nodoc


class _BleDescriptorTarget implements BleDescriptorTarget {
  const _BleDescriptorTarget({required this.deviceId, required this.connectionEpoch, required this.characteristicHandle, required this.descriptorHandle}): assert(connectionEpoch >= 0, 'connectionEpoch must be non-negative'),assert(characteristicHandle >= 0, 'handle must be non-negative'),assert(descriptorHandle >= 0, 'handle must be non-negative');


@override final  DeepskyDeviceId deviceId;
@override final  int connectionEpoch;
@override final  int characteristicHandle;
@override final  int descriptorHandle;

/// Create a copy of BleDescriptorTarget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BleDescriptorTargetCopyWith<_BleDescriptorTarget> get copyWith => __$BleDescriptorTargetCopyWithImpl<_BleDescriptorTarget>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BleDescriptorTarget&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.connectionEpoch, connectionEpoch) || other.connectionEpoch == connectionEpoch)&&(identical(other.characteristicHandle, characteristicHandle) || other.characteristicHandle == characteristicHandle)&&(identical(other.descriptorHandle, descriptorHandle) || other.descriptorHandle == descriptorHandle));
}


@override
int get hashCode => Object.hash(runtimeType,deviceId,connectionEpoch,characteristicHandle,descriptorHandle);

@override
String toString() {
  return 'BleDescriptorTarget(deviceId: $deviceId, connectionEpoch: $connectionEpoch, characteristicHandle: $characteristicHandle, descriptorHandle: $descriptorHandle)';
}


}

/// @nodoc
abstract mixin class _$BleDescriptorTargetCopyWith<$Res> implements $BleDescriptorTargetCopyWith<$Res> {
  factory _$BleDescriptorTargetCopyWith(_BleDescriptorTarget value, $Res Function(_BleDescriptorTarget) _then) = __$BleDescriptorTargetCopyWithImpl;
@override @useResult
$Res call({
 DeepskyDeviceId deviceId, int connectionEpoch, int characteristicHandle, int descriptorHandle
});


@override $DeepskyDeviceIdCopyWith<$Res> get deviceId;

}
/// @nodoc
class __$BleDescriptorTargetCopyWithImpl<$Res>
    implements _$BleDescriptorTargetCopyWith<$Res> {
  __$BleDescriptorTargetCopyWithImpl(this._self, this._then);

  final _BleDescriptorTarget _self;
  final $Res Function(_BleDescriptorTarget) _then;

/// Create a copy of BleDescriptorTarget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceId = null,Object? connectionEpoch = null,Object? characteristicHandle = null,Object? descriptorHandle = null,}) {
  return _then(_BleDescriptorTarget(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as DeepskyDeviceId,connectionEpoch: null == connectionEpoch ? _self.connectionEpoch : connectionEpoch // ignore: cast_nullable_to_non_nullable
as int,characteristicHandle: null == characteristicHandle ? _self.characteristicHandle : characteristicHandle // ignore: cast_nullable_to_non_nullable
as int,descriptorHandle: null == descriptorHandle ? _self.descriptorHandle : descriptorHandle // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of BleDescriptorTarget
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeepskyDeviceIdCopyWith<$Res> get deviceId {

  return $DeepskyDeviceIdCopyWith<$Res>(_self.deviceId, (value) {
    return _then(_self.copyWith(deviceId: value));
  });
}
}

/// @nodoc
mixin _$ConnectionAttempt {

 int get connectionEpoch;
/// Create a copy of ConnectionAttempt
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConnectionAttemptCopyWith<ConnectionAttempt> get copyWith => _$ConnectionAttemptCopyWithImpl<ConnectionAttempt>(this as ConnectionAttempt, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConnectionAttempt&&(identical(other.connectionEpoch, connectionEpoch) || other.connectionEpoch == connectionEpoch));
}


@override
int get hashCode => Object.hash(runtimeType,connectionEpoch);

@override
String toString() {
  return 'ConnectionAttempt(connectionEpoch: $connectionEpoch)';
}


}

/// @nodoc
abstract mixin class $ConnectionAttemptCopyWith<$Res>  {
  factory $ConnectionAttemptCopyWith(ConnectionAttempt value, $Res Function(ConnectionAttempt) _then) = _$ConnectionAttemptCopyWithImpl;
@useResult
$Res call({
 int connectionEpoch
});




}
/// @nodoc
class _$ConnectionAttemptCopyWithImpl<$Res>
    implements $ConnectionAttemptCopyWith<$Res> {
  _$ConnectionAttemptCopyWithImpl(this._self, this._then);

  final ConnectionAttempt _self;
  final $Res Function(ConnectionAttempt) _then;

/// Create a copy of ConnectionAttempt
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? connectionEpoch = null,}) {
  return _then(_self.copyWith(
connectionEpoch: null == connectionEpoch ? _self.connectionEpoch : connectionEpoch // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ConnectionAttempt].
extension ConnectionAttemptPatterns on ConnectionAttempt {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConnectionAttempt value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConnectionAttempt() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConnectionAttempt value)  $default,){
final _that = this;
switch (_that) {
case _ConnectionAttempt():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConnectionAttempt value)?  $default,){
final _that = this;
switch (_that) {
case _ConnectionAttempt() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int connectionEpoch)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConnectionAttempt() when $default != null:
return $default(_that.connectionEpoch);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int connectionEpoch)  $default,) {final _that = this;
switch (_that) {
case _ConnectionAttempt():
return $default(_that.connectionEpoch);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int connectionEpoch)?  $default,) {final _that = this;
switch (_that) {
case _ConnectionAttempt() when $default != null:
return $default(_that.connectionEpoch);case _:
  return null;

}
}

}

/// @nodoc


class _ConnectionAttempt implements ConnectionAttempt {
  const _ConnectionAttempt({required this.connectionEpoch}): assert(connectionEpoch >= 0, 'connectionEpoch must be non-negative');


@override final  int connectionEpoch;

/// Create a copy of ConnectionAttempt
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConnectionAttemptCopyWith<_ConnectionAttempt> get copyWith => __$ConnectionAttemptCopyWithImpl<_ConnectionAttempt>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConnectionAttempt&&(identical(other.connectionEpoch, connectionEpoch) || other.connectionEpoch == connectionEpoch));
}


@override
int get hashCode => Object.hash(runtimeType,connectionEpoch);

@override
String toString() {
  return 'ConnectionAttempt(connectionEpoch: $connectionEpoch)';
}


}

/// @nodoc
abstract mixin class _$ConnectionAttemptCopyWith<$Res> implements $ConnectionAttemptCopyWith<$Res> {
  factory _$ConnectionAttemptCopyWith(_ConnectionAttempt value, $Res Function(_ConnectionAttempt) _then) = __$ConnectionAttemptCopyWithImpl;
@override @useResult
$Res call({
 int connectionEpoch
});




}
/// @nodoc
class __$ConnectionAttemptCopyWithImpl<$Res>
    implements _$ConnectionAttemptCopyWith<$Res> {
  __$ConnectionAttemptCopyWithImpl(this._self, this._then);

  final _ConnectionAttempt _self;
  final $Res Function(_ConnectionAttempt) _then;

/// Create a copy of ConnectionAttempt
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? connectionEpoch = null,}) {
  return _then(_ConnectionAttempt(
connectionEpoch: null == connectionEpoch ? _self.connectionEpoch : connectionEpoch // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$BlePlatformConnectionEvent {

 DeepskyDeviceId get deviceId; int? get connectionEpoch; BleConnectionState get state; BleDisconnectReason? get reason;
/// Create a copy of BlePlatformConnectionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BlePlatformConnectionEventCopyWith<BlePlatformConnectionEvent> get copyWith => _$BlePlatformConnectionEventCopyWithImpl<BlePlatformConnectionEvent>(this as BlePlatformConnectionEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BlePlatformConnectionEvent&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.connectionEpoch, connectionEpoch) || other.connectionEpoch == connectionEpoch)&&(identical(other.state, state) || other.state == state)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,deviceId,connectionEpoch,state,reason);

@override
String toString() {
  return 'BlePlatformConnectionEvent(deviceId: $deviceId, connectionEpoch: $connectionEpoch, state: $state, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $BlePlatformConnectionEventCopyWith<$Res>  {
  factory $BlePlatformConnectionEventCopyWith(BlePlatformConnectionEvent value, $Res Function(BlePlatformConnectionEvent) _then) = _$BlePlatformConnectionEventCopyWithImpl;
@useResult
$Res call({
 DeepskyDeviceId deviceId, int? connectionEpoch, BleConnectionState state, BleDisconnectReason? reason
});


$DeepskyDeviceIdCopyWith<$Res> get deviceId;

}
/// @nodoc
class _$BlePlatformConnectionEventCopyWithImpl<$Res>
    implements $BlePlatformConnectionEventCopyWith<$Res> {
  _$BlePlatformConnectionEventCopyWithImpl(this._self, this._then);

  final BlePlatformConnectionEvent _self;
  final $Res Function(BlePlatformConnectionEvent) _then;

/// Create a copy of BlePlatformConnectionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceId = null,Object? connectionEpoch = freezed,Object? state = null,Object? reason = freezed,}) {
  return _then(_self.copyWith(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as DeepskyDeviceId,connectionEpoch: freezed == connectionEpoch ? _self.connectionEpoch : connectionEpoch // ignore: cast_nullable_to_non_nullable
as int?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as BleConnectionState,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as BleDisconnectReason?,
  ));
}
/// Create a copy of BlePlatformConnectionEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeepskyDeviceIdCopyWith<$Res> get deviceId {

  return $DeepskyDeviceIdCopyWith<$Res>(_self.deviceId, (value) {
    return _then(_self.copyWith(deviceId: value));
  });
}
}


/// Adds pattern-matching-related methods to [BlePlatformConnectionEvent].
extension BlePlatformConnectionEventPatterns on BlePlatformConnectionEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BlePlatformConnectionEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BlePlatformConnectionEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BlePlatformConnectionEvent value)  $default,){
final _that = this;
switch (_that) {
case _BlePlatformConnectionEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BlePlatformConnectionEvent value)?  $default,){
final _that = this;
switch (_that) {
case _BlePlatformConnectionEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DeepskyDeviceId deviceId,  int? connectionEpoch,  BleConnectionState state,  BleDisconnectReason? reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BlePlatformConnectionEvent() when $default != null:
return $default(_that.deviceId,_that.connectionEpoch,_that.state,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DeepskyDeviceId deviceId,  int? connectionEpoch,  BleConnectionState state,  BleDisconnectReason? reason)  $default,) {final _that = this;
switch (_that) {
case _BlePlatformConnectionEvent():
return $default(_that.deviceId,_that.connectionEpoch,_that.state,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DeepskyDeviceId deviceId,  int? connectionEpoch,  BleConnectionState state,  BleDisconnectReason? reason)?  $default,) {final _that = this;
switch (_that) {
case _BlePlatformConnectionEvent() when $default != null:
return $default(_that.deviceId,_that.connectionEpoch,_that.state,_that.reason);case _:
  return null;

}
}

}

/// @nodoc


class _BlePlatformConnectionEvent implements BlePlatformConnectionEvent {
  const _BlePlatformConnectionEvent({required this.deviceId, required this.connectionEpoch, required this.state, this.reason}): assert(state == BleConnectionState.disconnected ? reason != null : reason == null, 'Only disconnected events must have a reason.'),assert(connectionEpoch == null || connectionEpoch >= 0, 'connectionEpoch must be non-negative');


@override final  DeepskyDeviceId deviceId;
@override final  int? connectionEpoch;
@override final  BleConnectionState state;
@override final  BleDisconnectReason? reason;

/// Create a copy of BlePlatformConnectionEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BlePlatformConnectionEventCopyWith<_BlePlatformConnectionEvent> get copyWith => __$BlePlatformConnectionEventCopyWithImpl<_BlePlatformConnectionEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BlePlatformConnectionEvent&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.connectionEpoch, connectionEpoch) || other.connectionEpoch == connectionEpoch)&&(identical(other.state, state) || other.state == state)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,deviceId,connectionEpoch,state,reason);

@override
String toString() {
  return 'BlePlatformConnectionEvent(deviceId: $deviceId, connectionEpoch: $connectionEpoch, state: $state, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$BlePlatformConnectionEventCopyWith<$Res> implements $BlePlatformConnectionEventCopyWith<$Res> {
  factory _$BlePlatformConnectionEventCopyWith(_BlePlatformConnectionEvent value, $Res Function(_BlePlatformConnectionEvent) _then) = __$BlePlatformConnectionEventCopyWithImpl;
@override @useResult
$Res call({
 DeepskyDeviceId deviceId, int? connectionEpoch, BleConnectionState state, BleDisconnectReason? reason
});


@override $DeepskyDeviceIdCopyWith<$Res> get deviceId;

}
/// @nodoc
class __$BlePlatformConnectionEventCopyWithImpl<$Res>
    implements _$BlePlatformConnectionEventCopyWith<$Res> {
  __$BlePlatformConnectionEventCopyWithImpl(this._self, this._then);

  final _BlePlatformConnectionEvent _self;
  final $Res Function(_BlePlatformConnectionEvent) _then;

/// Create a copy of BlePlatformConnectionEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceId = null,Object? connectionEpoch = freezed,Object? state = null,Object? reason = freezed,}) {
  return _then(_BlePlatformConnectionEvent(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as DeepskyDeviceId,connectionEpoch: freezed == connectionEpoch ? _self.connectionEpoch : connectionEpoch // ignore: cast_nullable_to_non_nullable
as int?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as BleConnectionState,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as BleDisconnectReason?,
  ));
}

/// Create a copy of BlePlatformConnectionEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeepskyDeviceIdCopyWith<$Res> get deviceId {

  return $DeepskyDeviceIdCopyWith<$Res>(_self.deviceId, (value) {
    return _then(_self.copyWith(deviceId: value));
  });
}
}

/// @nodoc
mixin _$BleNotifyEvent {

 DeepskyDeviceId get deviceId; int get connectionEpoch; int get characteristicHandle; Uint8List get value;
/// Create a copy of BleNotifyEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BleNotifyEventCopyWith<BleNotifyEvent> get copyWith => _$BleNotifyEventCopyWithImpl<BleNotifyEvent>(this as BleNotifyEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BleNotifyEvent&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.connectionEpoch, connectionEpoch) || other.connectionEpoch == connectionEpoch)&&(identical(other.characteristicHandle, characteristicHandle) || other.characteristicHandle == characteristicHandle)&&const DeepCollectionEquality().equals(other.value, value));
}


@override
int get hashCode => Object.hash(runtimeType,deviceId,connectionEpoch,characteristicHandle,const DeepCollectionEquality().hash(value));

@override
String toString() {
  return 'BleNotifyEvent(deviceId: $deviceId, connectionEpoch: $connectionEpoch, characteristicHandle: $characteristicHandle, value: $value)';
}


}

/// @nodoc
abstract mixin class $BleNotifyEventCopyWith<$Res>  {
  factory $BleNotifyEventCopyWith(BleNotifyEvent value, $Res Function(BleNotifyEvent) _then) = _$BleNotifyEventCopyWithImpl;
@useResult
$Res call({
 DeepskyDeviceId deviceId, int connectionEpoch, int characteristicHandle, Uint8List value
});


$DeepskyDeviceIdCopyWith<$Res> get deviceId;

}
/// @nodoc
class _$BleNotifyEventCopyWithImpl<$Res>
    implements $BleNotifyEventCopyWith<$Res> {
  _$BleNotifyEventCopyWithImpl(this._self, this._then);

  final BleNotifyEvent _self;
  final $Res Function(BleNotifyEvent) _then;

/// Create a copy of BleNotifyEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceId = null,Object? connectionEpoch = null,Object? characteristicHandle = null,Object? value = null,}) {
  return _then(_self.copyWith(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as DeepskyDeviceId,connectionEpoch: null == connectionEpoch ? _self.connectionEpoch : connectionEpoch // ignore: cast_nullable_to_non_nullable
as int,characteristicHandle: null == characteristicHandle ? _self.characteristicHandle : characteristicHandle // ignore: cast_nullable_to_non_nullable
as int,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as Uint8List,
  ));
}
/// Create a copy of BleNotifyEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeepskyDeviceIdCopyWith<$Res> get deviceId {

  return $DeepskyDeviceIdCopyWith<$Res>(_self.deviceId, (value) {
    return _then(_self.copyWith(deviceId: value));
  });
}
}


/// Adds pattern-matching-related methods to [BleNotifyEvent].
extension BleNotifyEventPatterns on BleNotifyEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BleNotifyEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BleNotifyEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BleNotifyEvent value)  $default,){
final _that = this;
switch (_that) {
case _BleNotifyEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BleNotifyEvent value)?  $default,){
final _that = this;
switch (_that) {
case _BleNotifyEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DeepskyDeviceId deviceId,  int connectionEpoch,  int characteristicHandle,  Uint8List value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BleNotifyEvent() when $default != null:
return $default(_that.deviceId,_that.connectionEpoch,_that.characteristicHandle,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DeepskyDeviceId deviceId,  int connectionEpoch,  int characteristicHandle,  Uint8List value)  $default,) {final _that = this;
switch (_that) {
case _BleNotifyEvent():
return $default(_that.deviceId,_that.connectionEpoch,_that.characteristicHandle,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DeepskyDeviceId deviceId,  int connectionEpoch,  int characteristicHandle,  Uint8List value)?  $default,) {final _that = this;
switch (_that) {
case _BleNotifyEvent() when $default != null:
return $default(_that.deviceId,_that.connectionEpoch,_that.characteristicHandle,_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _BleNotifyEvent implements BleNotifyEvent {
  const _BleNotifyEvent({required this.deviceId, required this.connectionEpoch, required this.characteristicHandle, required this.value}): assert(connectionEpoch >= 0, 'connectionEpoch must be non-negative'),assert(characteristicHandle >= 0, 'handle must be non-negative');


@override final  DeepskyDeviceId deviceId;
@override final  int connectionEpoch;
@override final  int characteristicHandle;
@override final  Uint8List value;

/// Create a copy of BleNotifyEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BleNotifyEventCopyWith<_BleNotifyEvent> get copyWith => __$BleNotifyEventCopyWithImpl<_BleNotifyEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BleNotifyEvent&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.connectionEpoch, connectionEpoch) || other.connectionEpoch == connectionEpoch)&&(identical(other.characteristicHandle, characteristicHandle) || other.characteristicHandle == characteristicHandle)&&const DeepCollectionEquality().equals(other.value, value));
}


@override
int get hashCode => Object.hash(runtimeType,deviceId,connectionEpoch,characteristicHandle,const DeepCollectionEquality().hash(value));

@override
String toString() {
  return 'BleNotifyEvent(deviceId: $deviceId, connectionEpoch: $connectionEpoch, characteristicHandle: $characteristicHandle, value: $value)';
}


}

/// @nodoc
abstract mixin class _$BleNotifyEventCopyWith<$Res> implements $BleNotifyEventCopyWith<$Res> {
  factory _$BleNotifyEventCopyWith(_BleNotifyEvent value, $Res Function(_BleNotifyEvent) _then) = __$BleNotifyEventCopyWithImpl;
@override @useResult
$Res call({
 DeepskyDeviceId deviceId, int connectionEpoch, int characteristicHandle, Uint8List value
});


@override $DeepskyDeviceIdCopyWith<$Res> get deviceId;

}
/// @nodoc
class __$BleNotifyEventCopyWithImpl<$Res>
    implements _$BleNotifyEventCopyWith<$Res> {
  __$BleNotifyEventCopyWithImpl(this._self, this._then);

  final _BleNotifyEvent _self;
  final $Res Function(_BleNotifyEvent) _then;

/// Create a copy of BleNotifyEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceId = null,Object? connectionEpoch = null,Object? characteristicHandle = null,Object? value = null,}) {
  return _then(_BleNotifyEvent(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as DeepskyDeviceId,connectionEpoch: null == connectionEpoch ? _self.connectionEpoch : connectionEpoch // ignore: cast_nullable_to_non_nullable
as int,characteristicHandle: null == characteristicHandle ? _self.characteristicHandle : characteristicHandle // ignore: cast_nullable_to_non_nullable
as int,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as Uint8List,
  ));
}

/// Create a copy of BleNotifyEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeepskyDeviceIdCopyWith<$Res> get deviceId {

  return $DeepskyDeviceIdCopyWith<$Res>(_self.deviceId, (value) {
    return _then(_self.copyWith(deviceId: value));
  });
}
}

/// @nodoc
mixin _$BleOperationTimeout {

 DeepskyDeviceId get deviceId; int get connectionEpoch;
/// Create a copy of BleOperationTimeout
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BleOperationTimeoutCopyWith<BleOperationTimeout> get copyWith => _$BleOperationTimeoutCopyWithImpl<BleOperationTimeout>(this as BleOperationTimeout, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BleOperationTimeout&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.connectionEpoch, connectionEpoch) || other.connectionEpoch == connectionEpoch));
}


@override
int get hashCode => Object.hash(runtimeType,deviceId,connectionEpoch);

@override
String toString() {
  return 'BleOperationTimeout(deviceId: $deviceId, connectionEpoch: $connectionEpoch)';
}


}

/// @nodoc
abstract mixin class $BleOperationTimeoutCopyWith<$Res>  {
  factory $BleOperationTimeoutCopyWith(BleOperationTimeout value, $Res Function(BleOperationTimeout) _then) = _$BleOperationTimeoutCopyWithImpl;
@useResult
$Res call({
 DeepskyDeviceId deviceId, int connectionEpoch
});


$DeepskyDeviceIdCopyWith<$Res> get deviceId;

}
/// @nodoc
class _$BleOperationTimeoutCopyWithImpl<$Res>
    implements $BleOperationTimeoutCopyWith<$Res> {
  _$BleOperationTimeoutCopyWithImpl(this._self, this._then);

  final BleOperationTimeout _self;
  final $Res Function(BleOperationTimeout) _then;

/// Create a copy of BleOperationTimeout
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceId = null,Object? connectionEpoch = null,}) {
  return _then(_self.copyWith(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as DeepskyDeviceId,connectionEpoch: null == connectionEpoch ? _self.connectionEpoch : connectionEpoch // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of BleOperationTimeout
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeepskyDeviceIdCopyWith<$Res> get deviceId {

  return $DeepskyDeviceIdCopyWith<$Res>(_self.deviceId, (value) {
    return _then(_self.copyWith(deviceId: value));
  });
}
}


/// Adds pattern-matching-related methods to [BleOperationTimeout].
extension BleOperationTimeoutPatterns on BleOperationTimeout {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BleOperationTimeout value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BleOperationTimeout() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BleOperationTimeout value)  $default,){
final _that = this;
switch (_that) {
case _BleOperationTimeout():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BleOperationTimeout value)?  $default,){
final _that = this;
switch (_that) {
case _BleOperationTimeout() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DeepskyDeviceId deviceId,  int connectionEpoch)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BleOperationTimeout() when $default != null:
return $default(_that.deviceId,_that.connectionEpoch);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DeepskyDeviceId deviceId,  int connectionEpoch)  $default,) {final _that = this;
switch (_that) {
case _BleOperationTimeout():
return $default(_that.deviceId,_that.connectionEpoch);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DeepskyDeviceId deviceId,  int connectionEpoch)?  $default,) {final _that = this;
switch (_that) {
case _BleOperationTimeout() when $default != null:
return $default(_that.deviceId,_that.connectionEpoch);case _:
  return null;

}
}

}

/// @nodoc


class _BleOperationTimeout implements BleOperationTimeout {
  const _BleOperationTimeout({required this.deviceId, required this.connectionEpoch}): assert(connectionEpoch >= 0, 'connectionEpoch must be non-negative');


@override final  DeepskyDeviceId deviceId;
@override final  int connectionEpoch;

/// Create a copy of BleOperationTimeout
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BleOperationTimeoutCopyWith<_BleOperationTimeout> get copyWith => __$BleOperationTimeoutCopyWithImpl<_BleOperationTimeout>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BleOperationTimeout&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.connectionEpoch, connectionEpoch) || other.connectionEpoch == connectionEpoch));
}


@override
int get hashCode => Object.hash(runtimeType,deviceId,connectionEpoch);

@override
String toString() {
  return 'BleOperationTimeout(deviceId: $deviceId, connectionEpoch: $connectionEpoch)';
}


}

/// @nodoc
abstract mixin class _$BleOperationTimeoutCopyWith<$Res> implements $BleOperationTimeoutCopyWith<$Res> {
  factory _$BleOperationTimeoutCopyWith(_BleOperationTimeout value, $Res Function(_BleOperationTimeout) _then) = __$BleOperationTimeoutCopyWithImpl;
@override @useResult
$Res call({
 DeepskyDeviceId deviceId, int connectionEpoch
});


@override $DeepskyDeviceIdCopyWith<$Res> get deviceId;

}
/// @nodoc
class __$BleOperationTimeoutCopyWithImpl<$Res>
    implements _$BleOperationTimeoutCopyWith<$Res> {
  __$BleOperationTimeoutCopyWithImpl(this._self, this._then);

  final _BleOperationTimeout _self;
  final $Res Function(_BleOperationTimeout) _then;

/// Create a copy of BleOperationTimeout
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceId = null,Object? connectionEpoch = null,}) {
  return _then(_BleOperationTimeout(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as DeepskyDeviceId,connectionEpoch: null == connectionEpoch ? _self.connectionEpoch : connectionEpoch // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of BleOperationTimeout
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeepskyDeviceIdCopyWith<$Res> get deviceId {

  return $DeepskyDeviceIdCopyWith<$Res>(_self.deviceId, (value) {
    return _then(_self.copyWith(deviceId: value));
  });
}
}

/// @nodoc
mixin _$BleCompanionEvent {

 DeepskyDeviceId get deviceId; bool get appeared;
/// Create a copy of BleCompanionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BleCompanionEventCopyWith<BleCompanionEvent> get copyWith => _$BleCompanionEventCopyWithImpl<BleCompanionEvent>(this as BleCompanionEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BleCompanionEvent&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.appeared, appeared) || other.appeared == appeared));
}


@override
int get hashCode => Object.hash(runtimeType,deviceId,appeared);

@override
String toString() {
  return 'BleCompanionEvent(deviceId: $deviceId, appeared: $appeared)';
}


}

/// @nodoc
abstract mixin class $BleCompanionEventCopyWith<$Res>  {
  factory $BleCompanionEventCopyWith(BleCompanionEvent value, $Res Function(BleCompanionEvent) _then) = _$BleCompanionEventCopyWithImpl;
@useResult
$Res call({
 DeepskyDeviceId deviceId, bool appeared
});


$DeepskyDeviceIdCopyWith<$Res> get deviceId;

}
/// @nodoc
class _$BleCompanionEventCopyWithImpl<$Res>
    implements $BleCompanionEventCopyWith<$Res> {
  _$BleCompanionEventCopyWithImpl(this._self, this._then);

  final BleCompanionEvent _self;
  final $Res Function(BleCompanionEvent) _then;

/// Create a copy of BleCompanionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceId = null,Object? appeared = null,}) {
  return _then(_self.copyWith(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as DeepskyDeviceId,appeared: null == appeared ? _self.appeared : appeared // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of BleCompanionEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeepskyDeviceIdCopyWith<$Res> get deviceId {

  return $DeepskyDeviceIdCopyWith<$Res>(_self.deviceId, (value) {
    return _then(_self.copyWith(deviceId: value));
  });
}
}


/// Adds pattern-matching-related methods to [BleCompanionEvent].
extension BleCompanionEventPatterns on BleCompanionEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BleCompanionEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BleCompanionEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BleCompanionEvent value)  $default,){
final _that = this;
switch (_that) {
case _BleCompanionEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BleCompanionEvent value)?  $default,){
final _that = this;
switch (_that) {
case _BleCompanionEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DeepskyDeviceId deviceId,  bool appeared)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BleCompanionEvent() when $default != null:
return $default(_that.deviceId,_that.appeared);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DeepskyDeviceId deviceId,  bool appeared)  $default,) {final _that = this;
switch (_that) {
case _BleCompanionEvent():
return $default(_that.deviceId,_that.appeared);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DeepskyDeviceId deviceId,  bool appeared)?  $default,) {final _that = this;
switch (_that) {
case _BleCompanionEvent() when $default != null:
return $default(_that.deviceId,_that.appeared);case _:
  return null;

}
}

}

/// @nodoc


class _BleCompanionEvent implements BleCompanionEvent {
  const _BleCompanionEvent({required this.deviceId, required this.appeared});


@override final  DeepskyDeviceId deviceId;
@override final  bool appeared;

/// Create a copy of BleCompanionEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BleCompanionEventCopyWith<_BleCompanionEvent> get copyWith => __$BleCompanionEventCopyWithImpl<_BleCompanionEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BleCompanionEvent&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.appeared, appeared) || other.appeared == appeared));
}


@override
int get hashCode => Object.hash(runtimeType,deviceId,appeared);

@override
String toString() {
  return 'BleCompanionEvent(deviceId: $deviceId, appeared: $appeared)';
}


}

/// @nodoc
abstract mixin class _$BleCompanionEventCopyWith<$Res> implements $BleCompanionEventCopyWith<$Res> {
  factory _$BleCompanionEventCopyWith(_BleCompanionEvent value, $Res Function(_BleCompanionEvent) _then) = __$BleCompanionEventCopyWithImpl;
@override @useResult
$Res call({
 DeepskyDeviceId deviceId, bool appeared
});


@override $DeepskyDeviceIdCopyWith<$Res> get deviceId;

}
/// @nodoc
class __$BleCompanionEventCopyWithImpl<$Res>
    implements _$BleCompanionEventCopyWith<$Res> {
  __$BleCompanionEventCopyWithImpl(this._self, this._then);

  final _BleCompanionEvent _self;
  final $Res Function(_BleCompanionEvent) _then;

/// Create a copy of BleCompanionEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceId = null,Object? appeared = null,}) {
  return _then(_BleCompanionEvent(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as DeepskyDeviceId,appeared: null == appeared ? _self.appeared : appeared // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of BleCompanionEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeepskyDeviceIdCopyWith<$Res> get deviceId {

  return $DeepskyDeviceIdCopyWith<$Res>(_self.deviceId, (value) {
    return _then(_self.copyWith(deviceId: value));
  });
}
}

/// @nodoc
mixin _$BleStateSnapshot {

 DeepskyDeviceId get deviceId; int get connectionEpoch; BleConnectionState get state; BleDisconnectReason? get disconnectReason; List<int> get activeNotifyHandles; List<BleServiceInfo>? get services; bool get restored;
/// Create a copy of BleStateSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BleStateSnapshotCopyWith<BleStateSnapshot> get copyWith => _$BleStateSnapshotCopyWithImpl<BleStateSnapshot>(this as BleStateSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BleStateSnapshot&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.connectionEpoch, connectionEpoch) || other.connectionEpoch == connectionEpoch)&&(identical(other.state, state) || other.state == state)&&(identical(other.disconnectReason, disconnectReason) || other.disconnectReason == disconnectReason)&&const DeepCollectionEquality().equals(other.activeNotifyHandles, activeNotifyHandles)&&const DeepCollectionEquality().equals(other.services, services)&&(identical(other.restored, restored) || other.restored == restored));
}


@override
int get hashCode => Object.hash(runtimeType,deviceId,connectionEpoch,state,disconnectReason,const DeepCollectionEquality().hash(activeNotifyHandles),const DeepCollectionEquality().hash(services),restored);

@override
String toString() {
  return 'BleStateSnapshot(deviceId: $deviceId, connectionEpoch: $connectionEpoch, state: $state, disconnectReason: $disconnectReason, activeNotifyHandles: $activeNotifyHandles, services: $services, restored: $restored)';
}


}

/// @nodoc
abstract mixin class $BleStateSnapshotCopyWith<$Res>  {
  factory $BleStateSnapshotCopyWith(BleStateSnapshot value, $Res Function(BleStateSnapshot) _then) = _$BleStateSnapshotCopyWithImpl;
@useResult
$Res call({
 DeepskyDeviceId deviceId, int connectionEpoch, BleConnectionState state, BleDisconnectReason? disconnectReason, List<int> activeNotifyHandles, List<BleServiceInfo>? services, bool restored
});


$DeepskyDeviceIdCopyWith<$Res> get deviceId;

}
/// @nodoc
class _$BleStateSnapshotCopyWithImpl<$Res>
    implements $BleStateSnapshotCopyWith<$Res> {
  _$BleStateSnapshotCopyWithImpl(this._self, this._then);

  final BleStateSnapshot _self;
  final $Res Function(BleStateSnapshot) _then;

/// Create a copy of BleStateSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceId = null,Object? connectionEpoch = null,Object? state = null,Object? disconnectReason = freezed,Object? activeNotifyHandles = null,Object? services = freezed,Object? restored = null,}) {
  return _then(_self.copyWith(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as DeepskyDeviceId,connectionEpoch: null == connectionEpoch ? _self.connectionEpoch : connectionEpoch // ignore: cast_nullable_to_non_nullable
as int,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as BleConnectionState,disconnectReason: freezed == disconnectReason ? _self.disconnectReason : disconnectReason // ignore: cast_nullable_to_non_nullable
as BleDisconnectReason?,activeNotifyHandles: null == activeNotifyHandles ? _self.activeNotifyHandles : activeNotifyHandles // ignore: cast_nullable_to_non_nullable
as List<int>,services: freezed == services ? _self.services : services // ignore: cast_nullable_to_non_nullable
as List<BleServiceInfo>?,restored: null == restored ? _self.restored : restored // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of BleStateSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeepskyDeviceIdCopyWith<$Res> get deviceId {

  return $DeepskyDeviceIdCopyWith<$Res>(_self.deviceId, (value) {
    return _then(_self.copyWith(deviceId: value));
  });
}
}


/// Adds pattern-matching-related methods to [BleStateSnapshot].
extension BleStateSnapshotPatterns on BleStateSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BleStateSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BleStateSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BleStateSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _BleStateSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BleStateSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _BleStateSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DeepskyDeviceId deviceId,  int connectionEpoch,  BleConnectionState state,  BleDisconnectReason? disconnectReason,  List<int> activeNotifyHandles,  List<BleServiceInfo>? services,  bool restored)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BleStateSnapshot() when $default != null:
return $default(_that.deviceId,_that.connectionEpoch,_that.state,_that.disconnectReason,_that.activeNotifyHandles,_that.services,_that.restored);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DeepskyDeviceId deviceId,  int connectionEpoch,  BleConnectionState state,  BleDisconnectReason? disconnectReason,  List<int> activeNotifyHandles,  List<BleServiceInfo>? services,  bool restored)  $default,) {final _that = this;
switch (_that) {
case _BleStateSnapshot():
return $default(_that.deviceId,_that.connectionEpoch,_that.state,_that.disconnectReason,_that.activeNotifyHandles,_that.services,_that.restored);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DeepskyDeviceId deviceId,  int connectionEpoch,  BleConnectionState state,  BleDisconnectReason? disconnectReason,  List<int> activeNotifyHandles,  List<BleServiceInfo>? services,  bool restored)?  $default,) {final _that = this;
switch (_that) {
case _BleStateSnapshot() when $default != null:
return $default(_that.deviceId,_that.connectionEpoch,_that.state,_that.disconnectReason,_that.activeNotifyHandles,_that.services,_that.restored);case _:
  return null;

}
}

}

/// @nodoc


class _BleStateSnapshot implements BleStateSnapshot {
  const _BleStateSnapshot({required this.deviceId, required this.connectionEpoch, required this.state, this.disconnectReason, final  List<int> activeNotifyHandles = const <int>[], final  List<BleServiceInfo>? services, this.restored = false}): assert(connectionEpoch >= 0, 'connectionEpoch must be non-negative'),assert(state == BleConnectionState.disconnected ? disconnectReason != null : disconnectReason == null, 'Only disconnected snapshots must have a reason.'),_activeNotifyHandles = activeNotifyHandles,_services = services;


@override final  DeepskyDeviceId deviceId;
@override final  int connectionEpoch;
@override final  BleConnectionState state;
@override final  BleDisconnectReason? disconnectReason;
 final  List<int> _activeNotifyHandles;
@override@JsonKey() List<int> get activeNotifyHandles {
  if (_activeNotifyHandles is EqualUnmodifiableListView) return _activeNotifyHandles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activeNotifyHandles);
}

 final  List<BleServiceInfo>? _services;
@override List<BleServiceInfo>? get services {
  final value = _services;
  if (value == null) return null;
  if (_services is EqualUnmodifiableListView) return _services;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey() final  bool restored;

/// Create a copy of BleStateSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BleStateSnapshotCopyWith<_BleStateSnapshot> get copyWith => __$BleStateSnapshotCopyWithImpl<_BleStateSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BleStateSnapshot&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.connectionEpoch, connectionEpoch) || other.connectionEpoch == connectionEpoch)&&(identical(other.state, state) || other.state == state)&&(identical(other.disconnectReason, disconnectReason) || other.disconnectReason == disconnectReason)&&const DeepCollectionEquality().equals(other._activeNotifyHandles, _activeNotifyHandles)&&const DeepCollectionEquality().equals(other._services, _services)&&(identical(other.restored, restored) || other.restored == restored));
}


@override
int get hashCode => Object.hash(runtimeType,deviceId,connectionEpoch,state,disconnectReason,const DeepCollectionEquality().hash(_activeNotifyHandles),const DeepCollectionEquality().hash(_services),restored);

@override
String toString() {
  return 'BleStateSnapshot(deviceId: $deviceId, connectionEpoch: $connectionEpoch, state: $state, disconnectReason: $disconnectReason, activeNotifyHandles: $activeNotifyHandles, services: $services, restored: $restored)';
}


}

/// @nodoc
abstract mixin class _$BleStateSnapshotCopyWith<$Res> implements $BleStateSnapshotCopyWith<$Res> {
  factory _$BleStateSnapshotCopyWith(_BleStateSnapshot value, $Res Function(_BleStateSnapshot) _then) = __$BleStateSnapshotCopyWithImpl;
@override @useResult
$Res call({
 DeepskyDeviceId deviceId, int connectionEpoch, BleConnectionState state, BleDisconnectReason? disconnectReason, List<int> activeNotifyHandles, List<BleServiceInfo>? services, bool restored
});


@override $DeepskyDeviceIdCopyWith<$Res> get deviceId;

}
/// @nodoc
class __$BleStateSnapshotCopyWithImpl<$Res>
    implements _$BleStateSnapshotCopyWith<$Res> {
  __$BleStateSnapshotCopyWithImpl(this._self, this._then);

  final _BleStateSnapshot _self;
  final $Res Function(_BleStateSnapshot) _then;

/// Create a copy of BleStateSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceId = null,Object? connectionEpoch = null,Object? state = null,Object? disconnectReason = freezed,Object? activeNotifyHandles = null,Object? services = freezed,Object? restored = null,}) {
  return _then(_BleStateSnapshot(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as DeepskyDeviceId,connectionEpoch: null == connectionEpoch ? _self.connectionEpoch : connectionEpoch // ignore: cast_nullable_to_non_nullable
as int,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as BleConnectionState,disconnectReason: freezed == disconnectReason ? _self.disconnectReason : disconnectReason // ignore: cast_nullable_to_non_nullable
as BleDisconnectReason?,activeNotifyHandles: null == activeNotifyHandles ? _self._activeNotifyHandles : activeNotifyHandles // ignore: cast_nullable_to_non_nullable
as List<int>,services: freezed == services ? _self._services : services // ignore: cast_nullable_to_non_nullable
as List<BleServiceInfo>?,restored: null == restored ? _self.restored : restored // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of BleStateSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeepskyDeviceIdCopyWith<$Res> get deviceId {

  return $DeepskyDeviceIdCopyWith<$Res>(_self.deviceId, (value) {
    return _then(_self.copyWith(deviceId: value));
  });
}
}

/// @nodoc
mixin _$BleStateResync {

 String get snapshotId; List<BleStateSnapshot> get devices;
/// Create a copy of BleStateResync
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BleStateResyncCopyWith<BleStateResync> get copyWith => _$BleStateResyncCopyWithImpl<BleStateResync>(this as BleStateResync, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BleStateResync&&(identical(other.snapshotId, snapshotId) || other.snapshotId == snapshotId)&&const DeepCollectionEquality().equals(other.devices, devices));
}


@override
int get hashCode => Object.hash(runtimeType,snapshotId,const DeepCollectionEquality().hash(devices));

@override
String toString() {
  return 'BleStateResync(snapshotId: $snapshotId, devices: $devices)';
}


}

/// @nodoc
abstract mixin class $BleStateResyncCopyWith<$Res>  {
  factory $BleStateResyncCopyWith(BleStateResync value, $Res Function(BleStateResync) _then) = _$BleStateResyncCopyWithImpl;
@useResult
$Res call({
 String snapshotId, List<BleStateSnapshot> devices
});




}
/// @nodoc
class _$BleStateResyncCopyWithImpl<$Res>
    implements $BleStateResyncCopyWith<$Res> {
  _$BleStateResyncCopyWithImpl(this._self, this._then);

  final BleStateResync _self;
  final $Res Function(BleStateResync) _then;

/// Create a copy of BleStateResync
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? snapshotId = null,Object? devices = null,}) {
  return _then(_self.copyWith(
snapshotId: null == snapshotId ? _self.snapshotId : snapshotId // ignore: cast_nullable_to_non_nullable
as String,devices: null == devices ? _self.devices : devices // ignore: cast_nullable_to_non_nullable
as List<BleStateSnapshot>,
  ));
}

}


/// Adds pattern-matching-related methods to [BleStateResync].
extension BleStateResyncPatterns on BleStateResync {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BleStateResync value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BleStateResync() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BleStateResync value)  $default,){
final _that = this;
switch (_that) {
case _BleStateResync():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BleStateResync value)?  $default,){
final _that = this;
switch (_that) {
case _BleStateResync() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String snapshotId,  List<BleStateSnapshot> devices)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BleStateResync() when $default != null:
return $default(_that.snapshotId,_that.devices);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String snapshotId,  List<BleStateSnapshot> devices)  $default,) {final _that = this;
switch (_that) {
case _BleStateResync():
return $default(_that.snapshotId,_that.devices);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String snapshotId,  List<BleStateSnapshot> devices)?  $default,) {final _that = this;
switch (_that) {
case _BleStateResync() when $default != null:
return $default(_that.snapshotId,_that.devices);case _:
  return null;

}
}

}

/// @nodoc


class _BleStateResync implements BleStateResync {
  const _BleStateResync({required this.snapshotId, final  List<BleStateSnapshot> devices = const <BleStateSnapshot>[]}): _devices = devices;


@override final  String snapshotId;
 final  List<BleStateSnapshot> _devices;
@override@JsonKey() List<BleStateSnapshot> get devices {
  if (_devices is EqualUnmodifiableListView) return _devices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_devices);
}


/// Create a copy of BleStateResync
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BleStateResyncCopyWith<_BleStateResync> get copyWith => __$BleStateResyncCopyWithImpl<_BleStateResync>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BleStateResync&&(identical(other.snapshotId, snapshotId) || other.snapshotId == snapshotId)&&const DeepCollectionEquality().equals(other._devices, _devices));
}


@override
int get hashCode => Object.hash(runtimeType,snapshotId,const DeepCollectionEquality().hash(_devices));

@override
String toString() {
  return 'BleStateResync(snapshotId: $snapshotId, devices: $devices)';
}


}

/// @nodoc
abstract mixin class _$BleStateResyncCopyWith<$Res> implements $BleStateResyncCopyWith<$Res> {
  factory _$BleStateResyncCopyWith(_BleStateResync value, $Res Function(_BleStateResync) _then) = __$BleStateResyncCopyWithImpl;
@override @useResult
$Res call({
 String snapshotId, List<BleStateSnapshot> devices
});




}
/// @nodoc
class __$BleStateResyncCopyWithImpl<$Res>
    implements _$BleStateResyncCopyWith<$Res> {
  __$BleStateResyncCopyWithImpl(this._self, this._then);

  final _BleStateResync _self;
  final $Res Function(_BleStateResync) _then;

/// Create a copy of BleStateResync
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? snapshotId = null,Object? devices = null,}) {
  return _then(_BleStateResync(
snapshotId: null == snapshotId ? _self.snapshotId : snapshotId // ignore: cast_nullable_to_non_nullable
as String,devices: null == devices ? _self._devices : devices // ignore: cast_nullable_to_non_nullable
as List<BleStateSnapshot>,
  ));
}


}

// dart format on
