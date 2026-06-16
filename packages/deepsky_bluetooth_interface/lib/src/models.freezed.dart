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
mixin _$BleConnectionEvent {

 BleConnectionState get state; BleDisconnectReason? get reason;



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
mixin _$DeepskyScanFilterManufacturerData {

 int get manufacturerId; Uint8List get data;



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
mixin _$DeepskyScanFilterServiceData {

 DeepskyUuid get uuid; Uint8List get data;



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
mixin _$DeepskyScanFilter {

 List<DeepskyDeviceId> get deviceIds; List<String> get names; List<DeepskyScanFilterManufacturerData> get manufacturerData; List<DeepskyScanFilterServiceData> get serviceData; List<DeepskyUuid> get serviceUuids;



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
mixin _$DeepskyAndroidScanSetting {

 DeepskyAndroidScanMode get mode; DeepskyAndroidScanCallbackType get callbackType; bool get onlyLegacy; DeepskyAndroidScanMatchMode get matchMode; DeepskyAndroidScanNumOfMatch get numOfMatch; Duration get reportDelay; DeepskyAndroidScanPhy get phy;



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
mixin _$DeepskyDarwinScanSetting {

 bool get allowDuplicates; List<DeepskyUuid> get solicitedServiceUuids;



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
mixin _$DeepskyScanOptions {

 DeepskyAndroidScanSetting get android; DeepskyDarwinScanSetting get darwin;



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
mixin _$BleScanResult {

 DeepskyDeviceId get deviceId; int get rssi; List<DeepskyUuid> get serviceUuids; String? get name; Uint8List? get manufacturerData; Uint8List? get raw;



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
mixin _$BleCharacteristicProperties {

 List<BleCharacteristicProperty> get values;



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BleCharacteristicProperties&&const DeepCollectionEquality().equals(other.values, values));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(values));

@override
String toString() {
  return 'BleCharacteristicProperties(values: $values)';
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<BleCharacteristicProperty> values)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BleCharacteristicProperties() when $default != null:
return $default(_that.values);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<BleCharacteristicProperty> values)  $default,) {final _that = this;
switch (_that) {
case _BleCharacteristicProperties():
return $default(_that.values);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<BleCharacteristicProperty> values)?  $default,) {final _that = this;
switch (_that) {
case _BleCharacteristicProperties() when $default != null:
return $default(_that.values);case _:
  return null;

}
}

}

/// @nodoc


class _BleCharacteristicProperties implements BleCharacteristicProperties {
  const _BleCharacteristicProperties({final  List<BleCharacteristicProperty> values = const <BleCharacteristicProperty>[]}): _values = values;


 final  List<BleCharacteristicProperty> _values;
@override@JsonKey() List<BleCharacteristicProperty> get values {
  if (_values is EqualUnmodifiableListView) return _values;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_values);
}





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BleCharacteristicProperties&&const DeepCollectionEquality().equals(other._values, _values));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_values));

@override
String toString() {
  return 'BleCharacteristicProperties(values: $values)';
}


}




/// @nodoc
mixin _$BleServiceInfo {

 int get handle; DeepskyUuid get uuid; List<BleCharacteristicInfo> get characteristics;



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
mixin _$BleCharacteristicInfo {

 int get handle; int get serviceHandle; DeepskyUuid get uuid; BleCharacteristicProperties get properties; List<BleDescriptorInfo> get descriptors;



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
mixin _$BleDescriptorInfo {

 int get handle; DeepskyUuid get uuid;



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
mixin _$BleCharacteristicTarget {

 DeepskyDeviceId get deviceId; int get connectionEpoch; int get characteristicHandle;



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
mixin _$BleDescriptorTarget {

 DeepskyDeviceId get deviceId; int get connectionEpoch; int get characteristicHandle; int get descriptorHandle;



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
mixin _$ConnectionAttempt {

 int get connectionEpoch;



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
mixin _$BlePlatformConnectionEvent {

 DeepskyDeviceId get deviceId; int? get connectionEpoch; BleConnectionState get state; BleDisconnectReason? get reason;



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
mixin _$BleNotifyEvent {

 DeepskyDeviceId get deviceId; int get connectionEpoch; int get characteristicHandle; Uint8List get value;



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
mixin _$BleOperationTimeout {

 DeepskyDeviceId get deviceId; int get connectionEpoch;



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
mixin _$BleCompanionEvent {

 DeepskyDeviceId get deviceId; bool get appeared;



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
mixin _$BleStateSnapshot {

 DeepskyDeviceId get deviceId; int get connectionEpoch; BleConnectionState get state; BleDisconnectReason? get disconnectReason; List<int> get activeNotifyHandles; List<BleServiceInfo>? get services; bool get restored;



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
mixin _$BleStateResync {

 String get snapshotId; List<BleStateSnapshot> get devices;



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




// dart format on
