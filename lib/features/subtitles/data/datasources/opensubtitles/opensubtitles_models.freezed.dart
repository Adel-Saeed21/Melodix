// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'opensubtitles_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SubtitleSearchResponse {

@JsonKey(name: 'total_count') int get totalCount;@JsonKey(name: 'total_pages') int get totalPages; int get page; List<SubtitleSearchItem> get data;
/// Create a copy of SubtitleSearchResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubtitleSearchResponseCopyWith<SubtitleSearchResponse> get copyWith => _$SubtitleSearchResponseCopyWithImpl<SubtitleSearchResponse>(this as SubtitleSearchResponse, _$identity);

  /// Serializes this SubtitleSearchResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SubtitleSearchResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubtitleSearchResponse&&(identical(other.totalCount, _this.totalCount) || other.totalCount == _this.totalCount)&&(identical(other.totalPages, _this.totalPages) || other.totalPages == _this.totalPages)&&(identical(other.page, _this.page) || other.page == _this.page)&&const DeepCollectionEquality().equals(other.data, _this.data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SubtitleSearchResponse;
  return Object.hash(runtimeType,_this.totalCount,_this.totalPages,_this.page,const DeepCollectionEquality().hash(_this.data));
}

@override
String toString() {
  final _this = this as SubtitleSearchResponse;
  return 'SubtitleSearchResponse(totalCount: ${_this.totalCount}, totalPages: ${_this.totalPages}, page: ${_this.page}, data: ${_this.data})';
}


}

/// @nodoc
abstract mixin class $SubtitleSearchResponseCopyWith<$Res>  {
  factory $SubtitleSearchResponseCopyWith(SubtitleSearchResponse value, $Res Function(SubtitleSearchResponse) _then) = _$SubtitleSearchResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'total_count') int totalCount,@JsonKey(name: 'total_pages') int totalPages, int page, List<SubtitleSearchItem> data
});




}
/// @nodoc
class _$SubtitleSearchResponseCopyWithImpl<$Res>
    implements $SubtitleSearchResponseCopyWith<$Res> {
  _$SubtitleSearchResponseCopyWithImpl(this._self, this._then);

  final SubtitleSearchResponse _self;
  final $Res Function(SubtitleSearchResponse) _then;

/// Create a copy of SubtitleSearchResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalCount = null,Object? totalPages = null,Object? page = null,Object? data = null,}) {
  return _then(SubtitleSearchResponse(
totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,totalPages: null == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as List<SubtitleSearchItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubtitleSearchResponse].
extension SubtitleSearchResponsePatterns on SubtitleSearchResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubtitleSearchResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubtitleSearchResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubtitleSearchResponse value)  $default,){
final _that = this;
switch (_that) {
case _SubtitleSearchResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubtitleSearchResponse value)?  $default,){
final _that = this;
switch (_that) {
case _SubtitleSearchResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'total_count')  int totalCount, @JsonKey(name: 'total_pages')  int totalPages,  int page,  List<SubtitleSearchItem> data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubtitleSearchResponse() when $default != null:
return $default(_that.totalCount,_that.totalPages,_that.page,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'total_count')  int totalCount, @JsonKey(name: 'total_pages')  int totalPages,  int page,  List<SubtitleSearchItem> data)  $default,) {final _that = this;
switch (_that) {
case _SubtitleSearchResponse():
return $default(_that.totalCount,_that.totalPages,_that.page,_that.data);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'total_count')  int totalCount, @JsonKey(name: 'total_pages')  int totalPages,  int page,  List<SubtitleSearchItem> data)?  $default,) {final _that = this;
switch (_that) {
case _SubtitleSearchResponse() when $default != null:
return $default(_that.totalCount,_that.totalPages,_that.page,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubtitleSearchResponse implements SubtitleSearchResponse {
  const _SubtitleSearchResponse({@JsonKey(name: 'total_count') this.totalCount = 0, @JsonKey(name: 'total_pages') this.totalPages = 0, this.page = 1,  List<SubtitleSearchItem> data = const <SubtitleSearchItem>[]}): _data = data;
  factory _SubtitleSearchResponse.fromJson(Map<String, dynamic> json) => _$SubtitleSearchResponseFromJson(json);

@override@JsonKey(name: 'total_count') final  int totalCount;
@override@JsonKey(name: 'total_pages') final  int totalPages;
@override@JsonKey() final  int page;
 final  List<SubtitleSearchItem> _data;
@override@JsonKey() List<SubtitleSearchItem> get data {
  if (_data is EqualUnmodifiableListView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_data);
}


/// Create a copy of SubtitleSearchResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubtitleSearchResponseCopyWith<_SubtitleSearchResponse> get copyWith => __$SubtitleSearchResponseCopyWithImpl<_SubtitleSearchResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubtitleSearchResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubtitleSearchResponse&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.totalPages, totalPages) || other.totalPages == totalPages)&&(identical(other.page, page) || other.page == page)&&const DeepCollectionEquality().equals(other.data, _data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,totalCount,totalPages,page,const DeepCollectionEquality().hash(_data));
}

@override
String toString() {
    return 'SubtitleSearchResponse(totalCount: $totalCount, totalPages: $totalPages, page: $page, data: $data)';
}


}

/// @nodoc
abstract mixin class _$SubtitleSearchResponseCopyWith<$Res> implements $SubtitleSearchResponseCopyWith<$Res> {
  factory _$SubtitleSearchResponseCopyWith(_SubtitleSearchResponse value, $Res Function(_SubtitleSearchResponse) _then) = __$SubtitleSearchResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'total_count') int totalCount,@JsonKey(name: 'total_pages') int totalPages, int page, List<SubtitleSearchItem> data
});




}
/// @nodoc
class __$SubtitleSearchResponseCopyWithImpl<$Res>
    implements _$SubtitleSearchResponseCopyWith<$Res> {
  __$SubtitleSearchResponseCopyWithImpl(this._self, this._then);

  final _SubtitleSearchResponse _self;
  final $Res Function(_SubtitleSearchResponse) _then;

/// Create a copy of SubtitleSearchResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalCount = null,Object? totalPages = null,Object? page = null,Object? data = null,}) {
  return _then(_SubtitleSearchResponse(
totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,totalPages: null == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as List<SubtitleSearchItem>,
  ));
}


}


/// @nodoc
mixin _$SubtitleSearchItem {

 String get id; SubtitleAttributes get attributes;
/// Create a copy of SubtitleSearchItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubtitleSearchItemCopyWith<SubtitleSearchItem> get copyWith => _$SubtitleSearchItemCopyWithImpl<SubtitleSearchItem>(this as SubtitleSearchItem, _$identity);

  /// Serializes this SubtitleSearchItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SubtitleSearchItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubtitleSearchItem&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.attributes, _this.attributes) || other.attributes == _this.attributes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SubtitleSearchItem;
  return Object.hash(runtimeType,_this.id,_this.attributes);
}

@override
String toString() {
  final _this = this as SubtitleSearchItem;
  return 'SubtitleSearchItem(id: ${_this.id}, attributes: ${_this.attributes})';
}


}

/// @nodoc
abstract mixin class $SubtitleSearchItemCopyWith<$Res>  {
  factory $SubtitleSearchItemCopyWith(SubtitleSearchItem value, $Res Function(SubtitleSearchItem) _then) = _$SubtitleSearchItemCopyWithImpl;
@useResult
$Res call({
 String id, SubtitleAttributes attributes
});


$SubtitleAttributesCopyWith<$Res> get attributes;

}
/// @nodoc
class _$SubtitleSearchItemCopyWithImpl<$Res>
    implements $SubtitleSearchItemCopyWith<$Res> {
  _$SubtitleSearchItemCopyWithImpl(this._self, this._then);

  final SubtitleSearchItem _self;
  final $Res Function(SubtitleSearchItem) _then;

/// Create a copy of SubtitleSearchItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? attributes = null,}) {
  return _then(SubtitleSearchItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,attributes: null == attributes ? _self.attributes : attributes // ignore: cast_nullable_to_non_nullable
as SubtitleAttributes,
  ));
}
/// Create a copy of SubtitleSearchItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubtitleAttributesCopyWith<$Res> get attributes {
  
  return $SubtitleAttributesCopyWith<$Res>(_self.attributes, (value) {
    return _then(_self.copyWith(attributes: value));
  });
}
}


/// Adds pattern-matching-related methods to [SubtitleSearchItem].
extension SubtitleSearchItemPatterns on SubtitleSearchItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubtitleSearchItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubtitleSearchItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubtitleSearchItem value)  $default,){
final _that = this;
switch (_that) {
case _SubtitleSearchItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubtitleSearchItem value)?  $default,){
final _that = this;
switch (_that) {
case _SubtitleSearchItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  SubtitleAttributes attributes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubtitleSearchItem() when $default != null:
return $default(_that.id,_that.attributes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  SubtitleAttributes attributes)  $default,) {final _that = this;
switch (_that) {
case _SubtitleSearchItem():
return $default(_that.id,_that.attributes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  SubtitleAttributes attributes)?  $default,) {final _that = this;
switch (_that) {
case _SubtitleSearchItem() when $default != null:
return $default(_that.id,_that.attributes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubtitleSearchItem implements SubtitleSearchItem {
  const _SubtitleSearchItem({required this.id, required this.attributes});
  factory _SubtitleSearchItem.fromJson(Map<String, dynamic> json) => _$SubtitleSearchItemFromJson(json);

@override final  String id;
@override final  SubtitleAttributes attributes;

/// Create a copy of SubtitleSearchItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubtitleSearchItemCopyWith<_SubtitleSearchItem> get copyWith => __$SubtitleSearchItemCopyWithImpl<_SubtitleSearchItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubtitleSearchItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubtitleSearchItem&&(identical(other.id, id) || other.id == id)&&(identical(other.attributes, attributes) || other.attributes == attributes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,attributes);
}

@override
String toString() {
    return 'SubtitleSearchItem(id: $id, attributes: $attributes)';
}


}

/// @nodoc
abstract mixin class _$SubtitleSearchItemCopyWith<$Res> implements $SubtitleSearchItemCopyWith<$Res> {
  factory _$SubtitleSearchItemCopyWith(_SubtitleSearchItem value, $Res Function(_SubtitleSearchItem) _then) = __$SubtitleSearchItemCopyWithImpl;
@override @useResult
$Res call({
 String id, SubtitleAttributes attributes
});


@override $SubtitleAttributesCopyWith<$Res> get attributes;

}
/// @nodoc
class __$SubtitleSearchItemCopyWithImpl<$Res>
    implements _$SubtitleSearchItemCopyWith<$Res> {
  __$SubtitleSearchItemCopyWithImpl(this._self, this._then);

  final _SubtitleSearchItem _self;
  final $Res Function(_SubtitleSearchItem) _then;

/// Create a copy of SubtitleSearchItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? attributes = null,}) {
  return _then(_SubtitleSearchItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,attributes: null == attributes ? _self.attributes : attributes // ignore: cast_nullable_to_non_nullable
as SubtitleAttributes,
  ));
}

/// Create a copy of SubtitleSearchItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubtitleAttributesCopyWith<$Res> get attributes {
  
  return $SubtitleAttributesCopyWith<$Res>(_self.attributes, (value) {
    return _then(_self.copyWith(attributes: value));
  });
}
}


/// @nodoc
mixin _$SubtitleAttributes {

 String? get language; String? get release;@JsonKey(name: 'download_count') int get downloadCount;@JsonKey(name: 'hearing_impaired') bool get hearingImpaired;@JsonKey(name: 'moviehash_match') bool get movieHashMatch;@JsonKey(name: 'feature_details') SubtitleFeatureDetails? get featureDetails; List<SubtitleFileModel> get files;
/// Create a copy of SubtitleAttributes
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubtitleAttributesCopyWith<SubtitleAttributes> get copyWith => _$SubtitleAttributesCopyWithImpl<SubtitleAttributes>(this as SubtitleAttributes, _$identity);

  /// Serializes this SubtitleAttributes to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SubtitleAttributes;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubtitleAttributes&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.release, _this.release) || other.release == _this.release)&&(identical(other.downloadCount, _this.downloadCount) || other.downloadCount == _this.downloadCount)&&(identical(other.hearingImpaired, _this.hearingImpaired) || other.hearingImpaired == _this.hearingImpaired)&&(identical(other.movieHashMatch, _this.movieHashMatch) || other.movieHashMatch == _this.movieHashMatch)&&(identical(other.featureDetails, _this.featureDetails) || other.featureDetails == _this.featureDetails)&&const DeepCollectionEquality().equals(other.files, _this.files));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SubtitleAttributes;
  return Object.hash(runtimeType,_this.language,_this.release,_this.downloadCount,_this.hearingImpaired,_this.movieHashMatch,_this.featureDetails,const DeepCollectionEquality().hash(_this.files));
}

@override
String toString() {
  final _this = this as SubtitleAttributes;
  return 'SubtitleAttributes(language: ${_this.language}, release: ${_this.release}, downloadCount: ${_this.downloadCount}, hearingImpaired: ${_this.hearingImpaired}, movieHashMatch: ${_this.movieHashMatch}, featureDetails: ${_this.featureDetails}, files: ${_this.files})';
}


}

/// @nodoc
abstract mixin class $SubtitleAttributesCopyWith<$Res>  {
  factory $SubtitleAttributesCopyWith(SubtitleAttributes value, $Res Function(SubtitleAttributes) _then) = _$SubtitleAttributesCopyWithImpl;
@useResult
$Res call({
 String? language, String? release,@JsonKey(name: 'download_count') int downloadCount,@JsonKey(name: 'hearing_impaired') bool hearingImpaired,@JsonKey(name: 'moviehash_match') bool movieHashMatch,@JsonKey(name: 'feature_details') SubtitleFeatureDetails? featureDetails, List<SubtitleFileModel> files
});


$SubtitleFeatureDetailsCopyWith<$Res>? get featureDetails;

}
/// @nodoc
class _$SubtitleAttributesCopyWithImpl<$Res>
    implements $SubtitleAttributesCopyWith<$Res> {
  _$SubtitleAttributesCopyWithImpl(this._self, this._then);

  final SubtitleAttributes _self;
  final $Res Function(SubtitleAttributes) _then;

/// Create a copy of SubtitleAttributes
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? language = freezed,Object? release = freezed,Object? downloadCount = null,Object? hearingImpaired = null,Object? movieHashMatch = null,Object? featureDetails = freezed,Object? files = null,}) {
  return _then(SubtitleAttributes(
language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,release: freezed == release ? _self.release : release // ignore: cast_nullable_to_non_nullable
as String?,downloadCount: null == downloadCount ? _self.downloadCount : downloadCount // ignore: cast_nullable_to_non_nullable
as int,hearingImpaired: null == hearingImpaired ? _self.hearingImpaired : hearingImpaired // ignore: cast_nullable_to_non_nullable
as bool,movieHashMatch: null == movieHashMatch ? _self.movieHashMatch : movieHashMatch // ignore: cast_nullable_to_non_nullable
as bool,featureDetails: freezed == featureDetails ? _self.featureDetails : featureDetails // ignore: cast_nullable_to_non_nullable
as SubtitleFeatureDetails?,files: null == files ? _self.files : files // ignore: cast_nullable_to_non_nullable
as List<SubtitleFileModel>,
  ));
}
/// Create a copy of SubtitleAttributes
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubtitleFeatureDetailsCopyWith<$Res>? get featureDetails {
    if (_self.featureDetails == null) {
    return null;
  }

  return $SubtitleFeatureDetailsCopyWith<$Res>(_self.featureDetails!, (value) {
    return _then(_self.copyWith(featureDetails: value));
  });
}
}


/// Adds pattern-matching-related methods to [SubtitleAttributes].
extension SubtitleAttributesPatterns on SubtitleAttributes {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubtitleAttributes value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubtitleAttributes() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubtitleAttributes value)  $default,){
final _that = this;
switch (_that) {
case _SubtitleAttributes():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubtitleAttributes value)?  $default,){
final _that = this;
switch (_that) {
case _SubtitleAttributes() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? language,  String? release, @JsonKey(name: 'download_count')  int downloadCount, @JsonKey(name: 'hearing_impaired')  bool hearingImpaired, @JsonKey(name: 'moviehash_match')  bool movieHashMatch, @JsonKey(name: 'feature_details')  SubtitleFeatureDetails? featureDetails,  List<SubtitleFileModel> files)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubtitleAttributes() when $default != null:
return $default(_that.language,_that.release,_that.downloadCount,_that.hearingImpaired,_that.movieHashMatch,_that.featureDetails,_that.files);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? language,  String? release, @JsonKey(name: 'download_count')  int downloadCount, @JsonKey(name: 'hearing_impaired')  bool hearingImpaired, @JsonKey(name: 'moviehash_match')  bool movieHashMatch, @JsonKey(name: 'feature_details')  SubtitleFeatureDetails? featureDetails,  List<SubtitleFileModel> files)  $default,) {final _that = this;
switch (_that) {
case _SubtitleAttributes():
return $default(_that.language,_that.release,_that.downloadCount,_that.hearingImpaired,_that.movieHashMatch,_that.featureDetails,_that.files);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? language,  String? release, @JsonKey(name: 'download_count')  int downloadCount, @JsonKey(name: 'hearing_impaired')  bool hearingImpaired, @JsonKey(name: 'moviehash_match')  bool movieHashMatch, @JsonKey(name: 'feature_details')  SubtitleFeatureDetails? featureDetails,  List<SubtitleFileModel> files)?  $default,) {final _that = this;
switch (_that) {
case _SubtitleAttributes() when $default != null:
return $default(_that.language,_that.release,_that.downloadCount,_that.hearingImpaired,_that.movieHashMatch,_that.featureDetails,_that.files);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubtitleAttributes implements SubtitleAttributes {
  const _SubtitleAttributes({this.language, this.release, @JsonKey(name: 'download_count') this.downloadCount = 0, @JsonKey(name: 'hearing_impaired') this.hearingImpaired = false, @JsonKey(name: 'moviehash_match') this.movieHashMatch = false, @JsonKey(name: 'feature_details') this.featureDetails,  List<SubtitleFileModel> files = const <SubtitleFileModel>[]}): _files = files;
  factory _SubtitleAttributes.fromJson(Map<String, dynamic> json) => _$SubtitleAttributesFromJson(json);

@override final  String? language;
@override final  String? release;
@override@JsonKey(name: 'download_count') final  int downloadCount;
@override@JsonKey(name: 'hearing_impaired') final  bool hearingImpaired;
@override@JsonKey(name: 'moviehash_match') final  bool movieHashMatch;
@override@JsonKey(name: 'feature_details') final  SubtitleFeatureDetails? featureDetails;
 final  List<SubtitleFileModel> _files;
@override@JsonKey() List<SubtitleFileModel> get files {
  if (_files is EqualUnmodifiableListView) return _files;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_files);
}


/// Create a copy of SubtitleAttributes
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubtitleAttributesCopyWith<_SubtitleAttributes> get copyWith => __$SubtitleAttributesCopyWithImpl<_SubtitleAttributes>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubtitleAttributesToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubtitleAttributes&&(identical(other.language, language) || other.language == language)&&(identical(other.release, release) || other.release == release)&&(identical(other.downloadCount, downloadCount) || other.downloadCount == downloadCount)&&(identical(other.hearingImpaired, hearingImpaired) || other.hearingImpaired == hearingImpaired)&&(identical(other.movieHashMatch, movieHashMatch) || other.movieHashMatch == movieHashMatch)&&(identical(other.featureDetails, featureDetails) || other.featureDetails == featureDetails)&&const DeepCollectionEquality().equals(other.files, _files));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,language,release,downloadCount,hearingImpaired,movieHashMatch,featureDetails,const DeepCollectionEquality().hash(_files));
}

@override
String toString() {
    return 'SubtitleAttributes(language: $language, release: $release, downloadCount: $downloadCount, hearingImpaired: $hearingImpaired, movieHashMatch: $movieHashMatch, featureDetails: $featureDetails, files: $files)';
}


}

/// @nodoc
abstract mixin class _$SubtitleAttributesCopyWith<$Res> implements $SubtitleAttributesCopyWith<$Res> {
  factory _$SubtitleAttributesCopyWith(_SubtitleAttributes value, $Res Function(_SubtitleAttributes) _then) = __$SubtitleAttributesCopyWithImpl;
@override @useResult
$Res call({
 String? language, String? release,@JsonKey(name: 'download_count') int downloadCount,@JsonKey(name: 'hearing_impaired') bool hearingImpaired,@JsonKey(name: 'moviehash_match') bool movieHashMatch,@JsonKey(name: 'feature_details') SubtitleFeatureDetails? featureDetails, List<SubtitleFileModel> files
});


@override $SubtitleFeatureDetailsCopyWith<$Res>? get featureDetails;

}
/// @nodoc
class __$SubtitleAttributesCopyWithImpl<$Res>
    implements _$SubtitleAttributesCopyWith<$Res> {
  __$SubtitleAttributesCopyWithImpl(this._self, this._then);

  final _SubtitleAttributes _self;
  final $Res Function(_SubtitleAttributes) _then;

/// Create a copy of SubtitleAttributes
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? language = freezed,Object? release = freezed,Object? downloadCount = null,Object? hearingImpaired = null,Object? movieHashMatch = null,Object? featureDetails = freezed,Object? files = null,}) {
  return _then(_SubtitleAttributes(
language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,release: freezed == release ? _self.release : release // ignore: cast_nullable_to_non_nullable
as String?,downloadCount: null == downloadCount ? _self.downloadCount : downloadCount // ignore: cast_nullable_to_non_nullable
as int,hearingImpaired: null == hearingImpaired ? _self.hearingImpaired : hearingImpaired // ignore: cast_nullable_to_non_nullable
as bool,movieHashMatch: null == movieHashMatch ? _self.movieHashMatch : movieHashMatch // ignore: cast_nullable_to_non_nullable
as bool,featureDetails: freezed == featureDetails ? _self.featureDetails : featureDetails // ignore: cast_nullable_to_non_nullable
as SubtitleFeatureDetails?,files: null == files ? _self._files : files // ignore: cast_nullable_to_non_nullable
as List<SubtitleFileModel>,
  ));
}

/// Create a copy of SubtitleAttributes
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubtitleFeatureDetailsCopyWith<$Res>? get featureDetails {
    if (_self.featureDetails == null) {
    return null;
  }

  return $SubtitleFeatureDetailsCopyWith<$Res>(_self.featureDetails!, (value) {
    return _then(_self.copyWith(featureDetails: value));
  });
}
}


/// @nodoc
mixin _$SubtitleFeatureDetails {

 String? get title;@JsonKey(name: 'movie_name') String? get movieName; int? get year;@JsonKey(name: 'imdb_id') int? get imdbId;
/// Create a copy of SubtitleFeatureDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubtitleFeatureDetailsCopyWith<SubtitleFeatureDetails> get copyWith => _$SubtitleFeatureDetailsCopyWithImpl<SubtitleFeatureDetails>(this as SubtitleFeatureDetails, _$identity);

  /// Serializes this SubtitleFeatureDetails to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SubtitleFeatureDetails;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubtitleFeatureDetails&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.movieName, _this.movieName) || other.movieName == _this.movieName)&&(identical(other.year, _this.year) || other.year == _this.year)&&(identical(other.imdbId, _this.imdbId) || other.imdbId == _this.imdbId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SubtitleFeatureDetails;
  return Object.hash(runtimeType,_this.title,_this.movieName,_this.year,_this.imdbId);
}

@override
String toString() {
  final _this = this as SubtitleFeatureDetails;
  return 'SubtitleFeatureDetails(title: ${_this.title}, movieName: ${_this.movieName}, year: ${_this.year}, imdbId: ${_this.imdbId})';
}


}

/// @nodoc
abstract mixin class $SubtitleFeatureDetailsCopyWith<$Res>  {
  factory $SubtitleFeatureDetailsCopyWith(SubtitleFeatureDetails value, $Res Function(SubtitleFeatureDetails) _then) = _$SubtitleFeatureDetailsCopyWithImpl;
@useResult
$Res call({
 String? title,@JsonKey(name: 'movie_name') String? movieName, int? year,@JsonKey(name: 'imdb_id') int? imdbId
});




}
/// @nodoc
class _$SubtitleFeatureDetailsCopyWithImpl<$Res>
    implements $SubtitleFeatureDetailsCopyWith<$Res> {
  _$SubtitleFeatureDetailsCopyWithImpl(this._self, this._then);

  final SubtitleFeatureDetails _self;
  final $Res Function(SubtitleFeatureDetails) _then;

/// Create a copy of SubtitleFeatureDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = freezed,Object? movieName = freezed,Object? year = freezed,Object? imdbId = freezed,}) {
  return _then(SubtitleFeatureDetails(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,movieName: freezed == movieName ? _self.movieName : movieName // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,imdbId: freezed == imdbId ? _self.imdbId : imdbId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [SubtitleFeatureDetails].
extension SubtitleFeatureDetailsPatterns on SubtitleFeatureDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubtitleFeatureDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubtitleFeatureDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubtitleFeatureDetails value)  $default,){
final _that = this;
switch (_that) {
case _SubtitleFeatureDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubtitleFeatureDetails value)?  $default,){
final _that = this;
switch (_that) {
case _SubtitleFeatureDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? title, @JsonKey(name: 'movie_name')  String? movieName,  int? year, @JsonKey(name: 'imdb_id')  int? imdbId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubtitleFeatureDetails() when $default != null:
return $default(_that.title,_that.movieName,_that.year,_that.imdbId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? title, @JsonKey(name: 'movie_name')  String? movieName,  int? year, @JsonKey(name: 'imdb_id')  int? imdbId)  $default,) {final _that = this;
switch (_that) {
case _SubtitleFeatureDetails():
return $default(_that.title,_that.movieName,_that.year,_that.imdbId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? title, @JsonKey(name: 'movie_name')  String? movieName,  int? year, @JsonKey(name: 'imdb_id')  int? imdbId)?  $default,) {final _that = this;
switch (_that) {
case _SubtitleFeatureDetails() when $default != null:
return $default(_that.title,_that.movieName,_that.year,_that.imdbId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubtitleFeatureDetails implements SubtitleFeatureDetails {
  const _SubtitleFeatureDetails({this.title, @JsonKey(name: 'movie_name') this.movieName, this.year, @JsonKey(name: 'imdb_id') this.imdbId});
  factory _SubtitleFeatureDetails.fromJson(Map<String, dynamic> json) => _$SubtitleFeatureDetailsFromJson(json);

@override final  String? title;
@override@JsonKey(name: 'movie_name') final  String? movieName;
@override final  int? year;
@override@JsonKey(name: 'imdb_id') final  int? imdbId;

/// Create a copy of SubtitleFeatureDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubtitleFeatureDetailsCopyWith<_SubtitleFeatureDetails> get copyWith => __$SubtitleFeatureDetailsCopyWithImpl<_SubtitleFeatureDetails>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubtitleFeatureDetailsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubtitleFeatureDetails&&(identical(other.title, title) || other.title == title)&&(identical(other.movieName, movieName) || other.movieName == movieName)&&(identical(other.year, year) || other.year == year)&&(identical(other.imdbId, imdbId) || other.imdbId == imdbId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,title,movieName,year,imdbId);
}

@override
String toString() {
    return 'SubtitleFeatureDetails(title: $title, movieName: $movieName, year: $year, imdbId: $imdbId)';
}


}

/// @nodoc
abstract mixin class _$SubtitleFeatureDetailsCopyWith<$Res> implements $SubtitleFeatureDetailsCopyWith<$Res> {
  factory _$SubtitleFeatureDetailsCopyWith(_SubtitleFeatureDetails value, $Res Function(_SubtitleFeatureDetails) _then) = __$SubtitleFeatureDetailsCopyWithImpl;
@override @useResult
$Res call({
 String? title,@JsonKey(name: 'movie_name') String? movieName, int? year,@JsonKey(name: 'imdb_id') int? imdbId
});




}
/// @nodoc
class __$SubtitleFeatureDetailsCopyWithImpl<$Res>
    implements _$SubtitleFeatureDetailsCopyWith<$Res> {
  __$SubtitleFeatureDetailsCopyWithImpl(this._self, this._then);

  final _SubtitleFeatureDetails _self;
  final $Res Function(_SubtitleFeatureDetails) _then;

/// Create a copy of SubtitleFeatureDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = freezed,Object? movieName = freezed,Object? year = freezed,Object? imdbId = freezed,}) {
  return _then(_SubtitleFeatureDetails(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,movieName: freezed == movieName ? _self.movieName : movieName // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,imdbId: freezed == imdbId ? _self.imdbId : imdbId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$SubtitleFileModel {

@JsonKey(name: 'file_id') int get fileId;@JsonKey(name: 'file_name') String? get fileName;@JsonKey(name: 'cd_number') int? get cdNumber;
/// Create a copy of SubtitleFileModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubtitleFileModelCopyWith<SubtitleFileModel> get copyWith => _$SubtitleFileModelCopyWithImpl<SubtitleFileModel>(this as SubtitleFileModel, _$identity);

  /// Serializes this SubtitleFileModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SubtitleFileModel;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubtitleFileModel&&(identical(other.fileId, _this.fileId) || other.fileId == _this.fileId)&&(identical(other.fileName, _this.fileName) || other.fileName == _this.fileName)&&(identical(other.cdNumber, _this.cdNumber) || other.cdNumber == _this.cdNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SubtitleFileModel;
  return Object.hash(runtimeType,_this.fileId,_this.fileName,_this.cdNumber);
}

@override
String toString() {
  final _this = this as SubtitleFileModel;
  return 'SubtitleFileModel(fileId: ${_this.fileId}, fileName: ${_this.fileName}, cdNumber: ${_this.cdNumber})';
}


}

/// @nodoc
abstract mixin class $SubtitleFileModelCopyWith<$Res>  {
  factory $SubtitleFileModelCopyWith(SubtitleFileModel value, $Res Function(SubtitleFileModel) _then) = _$SubtitleFileModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'file_id') int fileId,@JsonKey(name: 'file_name') String? fileName,@JsonKey(name: 'cd_number') int? cdNumber
});




}
/// @nodoc
class _$SubtitleFileModelCopyWithImpl<$Res>
    implements $SubtitleFileModelCopyWith<$Res> {
  _$SubtitleFileModelCopyWithImpl(this._self, this._then);

  final SubtitleFileModel _self;
  final $Res Function(SubtitleFileModel) _then;

/// Create a copy of SubtitleFileModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fileId = null,Object? fileName = freezed,Object? cdNumber = freezed,}) {
  return _then(SubtitleFileModel(
fileId: null == fileId ? _self.fileId : fileId // ignore: cast_nullable_to_non_nullable
as int,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,cdNumber: freezed == cdNumber ? _self.cdNumber : cdNumber // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [SubtitleFileModel].
extension SubtitleFileModelPatterns on SubtitleFileModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubtitleFileModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubtitleFileModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubtitleFileModel value)  $default,){
final _that = this;
switch (_that) {
case _SubtitleFileModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubtitleFileModel value)?  $default,){
final _that = this;
switch (_that) {
case _SubtitleFileModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'file_id')  int fileId, @JsonKey(name: 'file_name')  String? fileName, @JsonKey(name: 'cd_number')  int? cdNumber)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubtitleFileModel() when $default != null:
return $default(_that.fileId,_that.fileName,_that.cdNumber);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'file_id')  int fileId, @JsonKey(name: 'file_name')  String? fileName, @JsonKey(name: 'cd_number')  int? cdNumber)  $default,) {final _that = this;
switch (_that) {
case _SubtitleFileModel():
return $default(_that.fileId,_that.fileName,_that.cdNumber);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'file_id')  int fileId, @JsonKey(name: 'file_name')  String? fileName, @JsonKey(name: 'cd_number')  int? cdNumber)?  $default,) {final _that = this;
switch (_that) {
case _SubtitleFileModel() when $default != null:
return $default(_that.fileId,_that.fileName,_that.cdNumber);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubtitleFileModel implements SubtitleFileModel {
  const _SubtitleFileModel({@JsonKey(name: 'file_id') required this.fileId, @JsonKey(name: 'file_name') this.fileName, @JsonKey(name: 'cd_number') this.cdNumber});
  factory _SubtitleFileModel.fromJson(Map<String, dynamic> json) => _$SubtitleFileModelFromJson(json);

@override@JsonKey(name: 'file_id') final  int fileId;
@override@JsonKey(name: 'file_name') final  String? fileName;
@override@JsonKey(name: 'cd_number') final  int? cdNumber;

/// Create a copy of SubtitleFileModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubtitleFileModelCopyWith<_SubtitleFileModel> get copyWith => __$SubtitleFileModelCopyWithImpl<_SubtitleFileModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubtitleFileModelToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubtitleFileModel&&(identical(other.fileId, fileId) || other.fileId == fileId)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.cdNumber, cdNumber) || other.cdNumber == cdNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,fileId,fileName,cdNumber);
}

@override
String toString() {
    return 'SubtitleFileModel(fileId: $fileId, fileName: $fileName, cdNumber: $cdNumber)';
}


}

/// @nodoc
abstract mixin class _$SubtitleFileModelCopyWith<$Res> implements $SubtitleFileModelCopyWith<$Res> {
  factory _$SubtitleFileModelCopyWith(_SubtitleFileModel value, $Res Function(_SubtitleFileModel) _then) = __$SubtitleFileModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'file_id') int fileId,@JsonKey(name: 'file_name') String? fileName,@JsonKey(name: 'cd_number') int? cdNumber
});




}
/// @nodoc
class __$SubtitleFileModelCopyWithImpl<$Res>
    implements _$SubtitleFileModelCopyWith<$Res> {
  __$SubtitleFileModelCopyWithImpl(this._self, this._then);

  final _SubtitleFileModel _self;
  final $Res Function(_SubtitleFileModel) _then;

/// Create a copy of SubtitleFileModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fileId = null,Object? fileName = freezed,Object? cdNumber = freezed,}) {
  return _then(_SubtitleFileModel(
fileId: null == fileId ? _self.fileId : fileId // ignore: cast_nullable_to_non_nullable
as int,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,cdNumber: freezed == cdNumber ? _self.cdNumber : cdNumber // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$SubtitleDownloadRequest {

@JsonKey(name: 'file_id') int get fileId;/// The format to receive (the service converts): always one the app
/// reads.
@JsonKey(name: 'sub_format', includeIfNull: false) String? get subFormat;
/// Create a copy of SubtitleDownloadRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubtitleDownloadRequestCopyWith<SubtitleDownloadRequest> get copyWith => _$SubtitleDownloadRequestCopyWithImpl<SubtitleDownloadRequest>(this as SubtitleDownloadRequest, _$identity);

  /// Serializes this SubtitleDownloadRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SubtitleDownloadRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubtitleDownloadRequest&&(identical(other.fileId, _this.fileId) || other.fileId == _this.fileId)&&(identical(other.subFormat, _this.subFormat) || other.subFormat == _this.subFormat));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SubtitleDownloadRequest;
  return Object.hash(runtimeType,_this.fileId,_this.subFormat);
}

@override
String toString() {
  final _this = this as SubtitleDownloadRequest;
  return 'SubtitleDownloadRequest(fileId: ${_this.fileId}, subFormat: ${_this.subFormat})';
}


}

/// @nodoc
abstract mixin class $SubtitleDownloadRequestCopyWith<$Res>  {
  factory $SubtitleDownloadRequestCopyWith(SubtitleDownloadRequest value, $Res Function(SubtitleDownloadRequest) _then) = _$SubtitleDownloadRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'file_id') int fileId,@JsonKey(name: 'sub_format', includeIfNull: false) String? subFormat
});




}
/// @nodoc
class _$SubtitleDownloadRequestCopyWithImpl<$Res>
    implements $SubtitleDownloadRequestCopyWith<$Res> {
  _$SubtitleDownloadRequestCopyWithImpl(this._self, this._then);

  final SubtitleDownloadRequest _self;
  final $Res Function(SubtitleDownloadRequest) _then;

/// Create a copy of SubtitleDownloadRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fileId = null,Object? subFormat = freezed,}) {
  return _then(SubtitleDownloadRequest(
fileId: null == fileId ? _self.fileId : fileId // ignore: cast_nullable_to_non_nullable
as int,subFormat: freezed == subFormat ? _self.subFormat : subFormat // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SubtitleDownloadRequest].
extension SubtitleDownloadRequestPatterns on SubtitleDownloadRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubtitleDownloadRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubtitleDownloadRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubtitleDownloadRequest value)  $default,){
final _that = this;
switch (_that) {
case _SubtitleDownloadRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubtitleDownloadRequest value)?  $default,){
final _that = this;
switch (_that) {
case _SubtitleDownloadRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'file_id')  int fileId, @JsonKey(name: 'sub_format', includeIfNull: false)  String? subFormat)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubtitleDownloadRequest() when $default != null:
return $default(_that.fileId,_that.subFormat);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'file_id')  int fileId, @JsonKey(name: 'sub_format', includeIfNull: false)  String? subFormat)  $default,) {final _that = this;
switch (_that) {
case _SubtitleDownloadRequest():
return $default(_that.fileId,_that.subFormat);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'file_id')  int fileId, @JsonKey(name: 'sub_format', includeIfNull: false)  String? subFormat)?  $default,) {final _that = this;
switch (_that) {
case _SubtitleDownloadRequest() when $default != null:
return $default(_that.fileId,_that.subFormat);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubtitleDownloadRequest implements SubtitleDownloadRequest {
  const _SubtitleDownloadRequest({@JsonKey(name: 'file_id') required this.fileId, @JsonKey(name: 'sub_format', includeIfNull: false) this.subFormat});
  factory _SubtitleDownloadRequest.fromJson(Map<String, dynamic> json) => _$SubtitleDownloadRequestFromJson(json);

@override@JsonKey(name: 'file_id') final  int fileId;
/// The format to receive (the service converts): always one the app
/// reads.
@override@JsonKey(name: 'sub_format', includeIfNull: false) final  String? subFormat;

/// Create a copy of SubtitleDownloadRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubtitleDownloadRequestCopyWith<_SubtitleDownloadRequest> get copyWith => __$SubtitleDownloadRequestCopyWithImpl<_SubtitleDownloadRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubtitleDownloadRequestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubtitleDownloadRequest&&(identical(other.fileId, fileId) || other.fileId == fileId)&&(identical(other.subFormat, subFormat) || other.subFormat == subFormat));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,fileId,subFormat);
}

@override
String toString() {
    return 'SubtitleDownloadRequest(fileId: $fileId, subFormat: $subFormat)';
}


}

/// @nodoc
abstract mixin class _$SubtitleDownloadRequestCopyWith<$Res> implements $SubtitleDownloadRequestCopyWith<$Res> {
  factory _$SubtitleDownloadRequestCopyWith(_SubtitleDownloadRequest value, $Res Function(_SubtitleDownloadRequest) _then) = __$SubtitleDownloadRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'file_id') int fileId,@JsonKey(name: 'sub_format', includeIfNull: false) String? subFormat
});




}
/// @nodoc
class __$SubtitleDownloadRequestCopyWithImpl<$Res>
    implements _$SubtitleDownloadRequestCopyWith<$Res> {
  __$SubtitleDownloadRequestCopyWithImpl(this._self, this._then);

  final _SubtitleDownloadRequest _self;
  final $Res Function(_SubtitleDownloadRequest) _then;

/// Create a copy of SubtitleDownloadRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fileId = null,Object? subFormat = freezed,}) {
  return _then(_SubtitleDownloadRequest(
fileId: null == fileId ? _self.fileId : fileId // ignore: cast_nullable_to_non_nullable
as int,subFormat: freezed == subFormat ? _self.subFormat : subFormat // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SubtitleDownloadResponse {

 String get link;@JsonKey(name: 'file_name') String? get fileName; int? get requests; int? get remaining;@JsonKey(name: 'reset_time') String? get resetTime;@JsonKey(name: 'reset_time_utc') String? get resetTimeUtc;
/// Create a copy of SubtitleDownloadResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubtitleDownloadResponseCopyWith<SubtitleDownloadResponse> get copyWith => _$SubtitleDownloadResponseCopyWithImpl<SubtitleDownloadResponse>(this as SubtitleDownloadResponse, _$identity);

  /// Serializes this SubtitleDownloadResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SubtitleDownloadResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubtitleDownloadResponse&&(identical(other.link, _this.link) || other.link == _this.link)&&(identical(other.fileName, _this.fileName) || other.fileName == _this.fileName)&&(identical(other.requests, _this.requests) || other.requests == _this.requests)&&(identical(other.remaining, _this.remaining) || other.remaining == _this.remaining)&&(identical(other.resetTime, _this.resetTime) || other.resetTime == _this.resetTime)&&(identical(other.resetTimeUtc, _this.resetTimeUtc) || other.resetTimeUtc == _this.resetTimeUtc));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SubtitleDownloadResponse;
  return Object.hash(runtimeType,_this.link,_this.fileName,_this.requests,_this.remaining,_this.resetTime,_this.resetTimeUtc);
}

@override
String toString() {
  final _this = this as SubtitleDownloadResponse;
  return 'SubtitleDownloadResponse(link: ${_this.link}, fileName: ${_this.fileName}, requests: ${_this.requests}, remaining: ${_this.remaining}, resetTime: ${_this.resetTime}, resetTimeUtc: ${_this.resetTimeUtc})';
}


}

/// @nodoc
abstract mixin class $SubtitleDownloadResponseCopyWith<$Res>  {
  factory $SubtitleDownloadResponseCopyWith(SubtitleDownloadResponse value, $Res Function(SubtitleDownloadResponse) _then) = _$SubtitleDownloadResponseCopyWithImpl;
@useResult
$Res call({
 String link,@JsonKey(name: 'file_name') String? fileName, int? requests, int? remaining,@JsonKey(name: 'reset_time') String? resetTime,@JsonKey(name: 'reset_time_utc') String? resetTimeUtc
});




}
/// @nodoc
class _$SubtitleDownloadResponseCopyWithImpl<$Res>
    implements $SubtitleDownloadResponseCopyWith<$Res> {
  _$SubtitleDownloadResponseCopyWithImpl(this._self, this._then);

  final SubtitleDownloadResponse _self;
  final $Res Function(SubtitleDownloadResponse) _then;

/// Create a copy of SubtitleDownloadResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? link = null,Object? fileName = freezed,Object? requests = freezed,Object? remaining = freezed,Object? resetTime = freezed,Object? resetTimeUtc = freezed,}) {
  return _then(SubtitleDownloadResponse(
link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,requests: freezed == requests ? _self.requests : requests // ignore: cast_nullable_to_non_nullable
as int?,remaining: freezed == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as int?,resetTime: freezed == resetTime ? _self.resetTime : resetTime // ignore: cast_nullable_to_non_nullable
as String?,resetTimeUtc: freezed == resetTimeUtc ? _self.resetTimeUtc : resetTimeUtc // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SubtitleDownloadResponse].
extension SubtitleDownloadResponsePatterns on SubtitleDownloadResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubtitleDownloadResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubtitleDownloadResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubtitleDownloadResponse value)  $default,){
final _that = this;
switch (_that) {
case _SubtitleDownloadResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubtitleDownloadResponse value)?  $default,){
final _that = this;
switch (_that) {
case _SubtitleDownloadResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String link, @JsonKey(name: 'file_name')  String? fileName,  int? requests,  int? remaining, @JsonKey(name: 'reset_time')  String? resetTime, @JsonKey(name: 'reset_time_utc')  String? resetTimeUtc)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubtitleDownloadResponse() when $default != null:
return $default(_that.link,_that.fileName,_that.requests,_that.remaining,_that.resetTime,_that.resetTimeUtc);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String link, @JsonKey(name: 'file_name')  String? fileName,  int? requests,  int? remaining, @JsonKey(name: 'reset_time')  String? resetTime, @JsonKey(name: 'reset_time_utc')  String? resetTimeUtc)  $default,) {final _that = this;
switch (_that) {
case _SubtitleDownloadResponse():
return $default(_that.link,_that.fileName,_that.requests,_that.remaining,_that.resetTime,_that.resetTimeUtc);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String link, @JsonKey(name: 'file_name')  String? fileName,  int? requests,  int? remaining, @JsonKey(name: 'reset_time')  String? resetTime, @JsonKey(name: 'reset_time_utc')  String? resetTimeUtc)?  $default,) {final _that = this;
switch (_that) {
case _SubtitleDownloadResponse() when $default != null:
return $default(_that.link,_that.fileName,_that.requests,_that.remaining,_that.resetTime,_that.resetTimeUtc);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubtitleDownloadResponse implements SubtitleDownloadResponse {
  const _SubtitleDownloadResponse({required this.link, @JsonKey(name: 'file_name') this.fileName, this.requests, this.remaining, @JsonKey(name: 'reset_time') this.resetTime, @JsonKey(name: 'reset_time_utc') this.resetTimeUtc});
  factory _SubtitleDownloadResponse.fromJson(Map<String, dynamic> json) => _$SubtitleDownloadResponseFromJson(json);

@override final  String link;
@override@JsonKey(name: 'file_name') final  String? fileName;
@override final  int? requests;
@override final  int? remaining;
@override@JsonKey(name: 'reset_time') final  String? resetTime;
@override@JsonKey(name: 'reset_time_utc') final  String? resetTimeUtc;

/// Create a copy of SubtitleDownloadResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubtitleDownloadResponseCopyWith<_SubtitleDownloadResponse> get copyWith => __$SubtitleDownloadResponseCopyWithImpl<_SubtitleDownloadResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubtitleDownloadResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubtitleDownloadResponse&&(identical(other.link, link) || other.link == link)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.requests, requests) || other.requests == requests)&&(identical(other.remaining, remaining) || other.remaining == remaining)&&(identical(other.resetTime, resetTime) || other.resetTime == resetTime)&&(identical(other.resetTimeUtc, resetTimeUtc) || other.resetTimeUtc == resetTimeUtc));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,link,fileName,requests,remaining,resetTime,resetTimeUtc);
}

@override
String toString() {
    return 'SubtitleDownloadResponse(link: $link, fileName: $fileName, requests: $requests, remaining: $remaining, resetTime: $resetTime, resetTimeUtc: $resetTimeUtc)';
}


}

/// @nodoc
abstract mixin class _$SubtitleDownloadResponseCopyWith<$Res> implements $SubtitleDownloadResponseCopyWith<$Res> {
  factory _$SubtitleDownloadResponseCopyWith(_SubtitleDownloadResponse value, $Res Function(_SubtitleDownloadResponse) _then) = __$SubtitleDownloadResponseCopyWithImpl;
@override @useResult
$Res call({
 String link,@JsonKey(name: 'file_name') String? fileName, int? requests, int? remaining,@JsonKey(name: 'reset_time') String? resetTime,@JsonKey(name: 'reset_time_utc') String? resetTimeUtc
});




}
/// @nodoc
class __$SubtitleDownloadResponseCopyWithImpl<$Res>
    implements _$SubtitleDownloadResponseCopyWith<$Res> {
  __$SubtitleDownloadResponseCopyWithImpl(this._self, this._then);

  final _SubtitleDownloadResponse _self;
  final $Res Function(_SubtitleDownloadResponse) _then;

/// Create a copy of SubtitleDownloadResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? link = null,Object? fileName = freezed,Object? requests = freezed,Object? remaining = freezed,Object? resetTime = freezed,Object? resetTimeUtc = freezed,}) {
  return _then(_SubtitleDownloadResponse(
link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,requests: freezed == requests ? _self.requests : requests // ignore: cast_nullable_to_non_nullable
as int?,remaining: freezed == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as int?,resetTime: freezed == resetTime ? _self.resetTime : resetTime // ignore: cast_nullable_to_non_nullable
as String?,resetTimeUtc: freezed == resetTimeUtc ? _self.resetTimeUtc : resetTimeUtc // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
