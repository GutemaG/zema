// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zema_database.dart';

// ignore_for_file: type=lint
class $TracksTable extends Tracks with TableInfo<$TracksTable, TrackRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _mediaStoreIdMeta = const VerificationMeta(
    'mediaStoreId',
  );
  @override
  late final GeneratedColumn<int> mediaStoreId = GeneratedColumn<int>(
    'media_store_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uriMeta = const VerificationMeta('uri');
  @override
  late final GeneratedColumn<String> uri = GeneratedColumn<String>(
    'uri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _folderMeta = const VerificationMeta('folder');
  @override
  late final GeneratedColumn<String> folder = GeneratedColumn<String>(
    'folder',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
    'album',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumArtistMeta = const VerificationMeta(
    'albumArtist',
  );
  @override
  late final GeneratedColumn<String> albumArtist = GeneratedColumn<String>(
    'album_artist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trackNumberMeta = const VerificationMeta(
    'trackNumber',
  );
  @override
  late final GeneratedColumn<int> trackNumber = GeneratedColumn<int>(
    'track_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateAddedMeta = const VerificationMeta(
    'dateAdded',
  );
  @override
  late final GeneratedColumn<DateTime> dateAdded = GeneratedColumn<DateTime>(
    'date_added',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _missingMeta = const VerificationMeta(
    'missing',
  );
  @override
  late final GeneratedColumn<bool> missing = GeneratedColumn<bool>(
    'missing',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("missing" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mediaStoreId,
    uri,
    path,
    folder,
    title,
    artist,
    album,
    albumArtist,
    trackNumber,
    year,
    durationMs,
    sizeBytes,
    dateAdded,
    missing,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrackRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('media_store_id')) {
      context.handle(
        _mediaStoreIdMeta,
        mediaStoreId.isAcceptableOrUnknown(
          data['media_store_id']!,
          _mediaStoreIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mediaStoreIdMeta);
    }
    if (data.containsKey('uri')) {
      context.handle(
        _uriMeta,
        uri.isAcceptableOrUnknown(data['uri']!, _uriMeta),
      );
    } else if (isInserting) {
      context.missing(_uriMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('folder')) {
      context.handle(
        _folderMeta,
        folder.isAcceptableOrUnknown(data['folder']!, _folderMeta),
      );
    } else if (isInserting) {
      context.missing(_folderMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    }
    if (data.containsKey('album')) {
      context.handle(
        _albumMeta,
        album.isAcceptableOrUnknown(data['album']!, _albumMeta),
      );
    }
    if (data.containsKey('album_artist')) {
      context.handle(
        _albumArtistMeta,
        albumArtist.isAcceptableOrUnknown(
          data['album_artist']!,
          _albumArtistMeta,
        ),
      );
    }
    if (data.containsKey('track_number')) {
      context.handle(
        _trackNumberMeta,
        trackNumber.isAcceptableOrUnknown(
          data['track_number']!,
          _trackNumberMeta,
        ),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('date_added')) {
      context.handle(
        _dateAddedMeta,
        dateAdded.isAcceptableOrUnknown(data['date_added']!, _dateAddedMeta),
      );
    } else if (isInserting) {
      context.missing(_dateAddedMeta);
    }
    if (data.containsKey('missing')) {
      context.handle(
        _missingMeta,
        missing.isAcceptableOrUnknown(data['missing']!, _missingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrackRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      mediaStoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_store_id'],
      )!,
      uri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uri'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      folder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      ),
      album: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album'],
      ),
      albumArtist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_artist'],
      ),
      trackNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_number'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      dateAdded: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_added'],
      )!,
      missing: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}missing'],
      )!,
    );
  }

  @override
  $TracksTable createAlias(String alias) {
    return $TracksTable(attachedDatabase, alias);
  }
}

class TrackRow extends DataClass implements Insertable<TrackRow> {
  /// Zema's own ID, stable across rescans (see `reconcileTracks`).
  final int id;
  final int mediaStoreId;
  final String uri;
  final String path;

  /// Parent folder of [path], stored so folder queries can use an index.
  final String folder;
  final String title;
  final String? artist;
  final String? album;
  final String? albumArtist;
  final int? trackNumber;
  final int? year;
  final int durationMs;
  final int sizeBytes;
  final DateTime dateAdded;
  final bool missing;
  const TrackRow({
    required this.id,
    required this.mediaStoreId,
    required this.uri,
    required this.path,
    required this.folder,
    required this.title,
    this.artist,
    this.album,
    this.albumArtist,
    this.trackNumber,
    this.year,
    required this.durationMs,
    required this.sizeBytes,
    required this.dateAdded,
    required this.missing,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['media_store_id'] = Variable<int>(mediaStoreId);
    map['uri'] = Variable<String>(uri);
    map['path'] = Variable<String>(path);
    map['folder'] = Variable<String>(folder);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || artist != null) {
      map['artist'] = Variable<String>(artist);
    }
    if (!nullToAbsent || album != null) {
      map['album'] = Variable<String>(album);
    }
    if (!nullToAbsent || albumArtist != null) {
      map['album_artist'] = Variable<String>(albumArtist);
    }
    if (!nullToAbsent || trackNumber != null) {
      map['track_number'] = Variable<int>(trackNumber);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    map['duration_ms'] = Variable<int>(durationMs);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['date_added'] = Variable<DateTime>(dateAdded);
    map['missing'] = Variable<bool>(missing);
    return map;
  }

  TracksCompanion toCompanion(bool nullToAbsent) {
    return TracksCompanion(
      id: Value(id),
      mediaStoreId: Value(mediaStoreId),
      uri: Value(uri),
      path: Value(path),
      folder: Value(folder),
      title: Value(title),
      artist: artist == null && nullToAbsent
          ? const Value.absent()
          : Value(artist),
      album: album == null && nullToAbsent
          ? const Value.absent()
          : Value(album),
      albumArtist: albumArtist == null && nullToAbsent
          ? const Value.absent()
          : Value(albumArtist),
      trackNumber: trackNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(trackNumber),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      durationMs: Value(durationMs),
      sizeBytes: Value(sizeBytes),
      dateAdded: Value(dateAdded),
      missing: Value(missing),
    );
  }

  factory TrackRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackRow(
      id: serializer.fromJson<int>(json['id']),
      mediaStoreId: serializer.fromJson<int>(json['mediaStoreId']),
      uri: serializer.fromJson<String>(json['uri']),
      path: serializer.fromJson<String>(json['path']),
      folder: serializer.fromJson<String>(json['folder']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String?>(json['artist']),
      album: serializer.fromJson<String?>(json['album']),
      albumArtist: serializer.fromJson<String?>(json['albumArtist']),
      trackNumber: serializer.fromJson<int?>(json['trackNumber']),
      year: serializer.fromJson<int?>(json['year']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      dateAdded: serializer.fromJson<DateTime>(json['dateAdded']),
      missing: serializer.fromJson<bool>(json['missing']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'mediaStoreId': serializer.toJson<int>(mediaStoreId),
      'uri': serializer.toJson<String>(uri),
      'path': serializer.toJson<String>(path),
      'folder': serializer.toJson<String>(folder),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String?>(artist),
      'album': serializer.toJson<String?>(album),
      'albumArtist': serializer.toJson<String?>(albumArtist),
      'trackNumber': serializer.toJson<int?>(trackNumber),
      'year': serializer.toJson<int?>(year),
      'durationMs': serializer.toJson<int>(durationMs),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'dateAdded': serializer.toJson<DateTime>(dateAdded),
      'missing': serializer.toJson<bool>(missing),
    };
  }

  TrackRow copyWith({
    int? id,
    int? mediaStoreId,
    String? uri,
    String? path,
    String? folder,
    String? title,
    Value<String?> artist = const Value.absent(),
    Value<String?> album = const Value.absent(),
    Value<String?> albumArtist = const Value.absent(),
    Value<int?> trackNumber = const Value.absent(),
    Value<int?> year = const Value.absent(),
    int? durationMs,
    int? sizeBytes,
    DateTime? dateAdded,
    bool? missing,
  }) => TrackRow(
    id: id ?? this.id,
    mediaStoreId: mediaStoreId ?? this.mediaStoreId,
    uri: uri ?? this.uri,
    path: path ?? this.path,
    folder: folder ?? this.folder,
    title: title ?? this.title,
    artist: artist.present ? artist.value : this.artist,
    album: album.present ? album.value : this.album,
    albumArtist: albumArtist.present ? albumArtist.value : this.albumArtist,
    trackNumber: trackNumber.present ? trackNumber.value : this.trackNumber,
    year: year.present ? year.value : this.year,
    durationMs: durationMs ?? this.durationMs,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    dateAdded: dateAdded ?? this.dateAdded,
    missing: missing ?? this.missing,
  );
  TrackRow copyWithCompanion(TracksCompanion data) {
    return TrackRow(
      id: data.id.present ? data.id.value : this.id,
      mediaStoreId: data.mediaStoreId.present
          ? data.mediaStoreId.value
          : this.mediaStoreId,
      uri: data.uri.present ? data.uri.value : this.uri,
      path: data.path.present ? data.path.value : this.path,
      folder: data.folder.present ? data.folder.value : this.folder,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      album: data.album.present ? data.album.value : this.album,
      albumArtist: data.albumArtist.present
          ? data.albumArtist.value
          : this.albumArtist,
      trackNumber: data.trackNumber.present
          ? data.trackNumber.value
          : this.trackNumber,
      year: data.year.present ? data.year.value : this.year,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      dateAdded: data.dateAdded.present ? data.dateAdded.value : this.dateAdded,
      missing: data.missing.present ? data.missing.value : this.missing,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackRow(')
          ..write('id: $id, ')
          ..write('mediaStoreId: $mediaStoreId, ')
          ..write('uri: $uri, ')
          ..write('path: $path, ')
          ..write('folder: $folder, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('albumArtist: $albumArtist, ')
          ..write('trackNumber: $trackNumber, ')
          ..write('year: $year, ')
          ..write('durationMs: $durationMs, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('dateAdded: $dateAdded, ')
          ..write('missing: $missing')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mediaStoreId,
    uri,
    path,
    folder,
    title,
    artist,
    album,
    albumArtist,
    trackNumber,
    year,
    durationMs,
    sizeBytes,
    dateAdded,
    missing,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackRow &&
          other.id == this.id &&
          other.mediaStoreId == this.mediaStoreId &&
          other.uri == this.uri &&
          other.path == this.path &&
          other.folder == this.folder &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.album == this.album &&
          other.albumArtist == this.albumArtist &&
          other.trackNumber == this.trackNumber &&
          other.year == this.year &&
          other.durationMs == this.durationMs &&
          other.sizeBytes == this.sizeBytes &&
          other.dateAdded == this.dateAdded &&
          other.missing == this.missing);
}

class TracksCompanion extends UpdateCompanion<TrackRow> {
  final Value<int> id;
  final Value<int> mediaStoreId;
  final Value<String> uri;
  final Value<String> path;
  final Value<String> folder;
  final Value<String> title;
  final Value<String?> artist;
  final Value<String?> album;
  final Value<String?> albumArtist;
  final Value<int?> trackNumber;
  final Value<int?> year;
  final Value<int> durationMs;
  final Value<int> sizeBytes;
  final Value<DateTime> dateAdded;
  final Value<bool> missing;
  const TracksCompanion({
    this.id = const Value.absent(),
    this.mediaStoreId = const Value.absent(),
    this.uri = const Value.absent(),
    this.path = const Value.absent(),
    this.folder = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.albumArtist = const Value.absent(),
    this.trackNumber = const Value.absent(),
    this.year = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.dateAdded = const Value.absent(),
    this.missing = const Value.absent(),
  });
  TracksCompanion.insert({
    this.id = const Value.absent(),
    required int mediaStoreId,
    required String uri,
    required String path,
    required String folder,
    required String title,
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.albumArtist = const Value.absent(),
    this.trackNumber = const Value.absent(),
    this.year = const Value.absent(),
    required int durationMs,
    required int sizeBytes,
    required DateTime dateAdded,
    this.missing = const Value.absent(),
  }) : mediaStoreId = Value(mediaStoreId),
       uri = Value(uri),
       path = Value(path),
       folder = Value(folder),
       title = Value(title),
       durationMs = Value(durationMs),
       sizeBytes = Value(sizeBytes),
       dateAdded = Value(dateAdded);
  static Insertable<TrackRow> custom({
    Expression<int>? id,
    Expression<int>? mediaStoreId,
    Expression<String>? uri,
    Expression<String>? path,
    Expression<String>? folder,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<String>? album,
    Expression<String>? albumArtist,
    Expression<int>? trackNumber,
    Expression<int>? year,
    Expression<int>? durationMs,
    Expression<int>? sizeBytes,
    Expression<DateTime>? dateAdded,
    Expression<bool>? missing,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mediaStoreId != null) 'media_store_id': mediaStoreId,
      if (uri != null) 'uri': uri,
      if (path != null) 'path': path,
      if (folder != null) 'folder': folder,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
      if (albumArtist != null) 'album_artist': albumArtist,
      if (trackNumber != null) 'track_number': trackNumber,
      if (year != null) 'year': year,
      if (durationMs != null) 'duration_ms': durationMs,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (dateAdded != null) 'date_added': dateAdded,
      if (missing != null) 'missing': missing,
    });
  }

  TracksCompanion copyWith({
    Value<int>? id,
    Value<int>? mediaStoreId,
    Value<String>? uri,
    Value<String>? path,
    Value<String>? folder,
    Value<String>? title,
    Value<String?>? artist,
    Value<String?>? album,
    Value<String?>? albumArtist,
    Value<int?>? trackNumber,
    Value<int?>? year,
    Value<int>? durationMs,
    Value<int>? sizeBytes,
    Value<DateTime>? dateAdded,
    Value<bool>? missing,
  }) {
    return TracksCompanion(
      id: id ?? this.id,
      mediaStoreId: mediaStoreId ?? this.mediaStoreId,
      uri: uri ?? this.uri,
      path: path ?? this.path,
      folder: folder ?? this.folder,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumArtist: albumArtist ?? this.albumArtist,
      trackNumber: trackNumber ?? this.trackNumber,
      year: year ?? this.year,
      durationMs: durationMs ?? this.durationMs,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      dateAdded: dateAdded ?? this.dateAdded,
      missing: missing ?? this.missing,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (mediaStoreId.present) {
      map['media_store_id'] = Variable<int>(mediaStoreId.value);
    }
    if (uri.present) {
      map['uri'] = Variable<String>(uri.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (folder.present) {
      map['folder'] = Variable<String>(folder.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (albumArtist.present) {
      map['album_artist'] = Variable<String>(albumArtist.value);
    }
    if (trackNumber.present) {
      map['track_number'] = Variable<int>(trackNumber.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (dateAdded.present) {
      map['date_added'] = Variable<DateTime>(dateAdded.value);
    }
    if (missing.present) {
      map['missing'] = Variable<bool>(missing.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TracksCompanion(')
          ..write('id: $id, ')
          ..write('mediaStoreId: $mediaStoreId, ')
          ..write('uri: $uri, ')
          ..write('path: $path, ')
          ..write('folder: $folder, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('albumArtist: $albumArtist, ')
          ..write('trackNumber: $trackNumber, ')
          ..write('year: $year, ')
          ..write('durationMs: $durationMs, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('dateAdded: $dateAdded, ')
          ..write('missing: $missing')
          ..write(')'))
        .toString();
  }
}

class $HiddenFoldersTable extends HiddenFolders
    with TableInfo<$HiddenFoldersTable, HiddenFolderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HiddenFoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hiddenAtMeta = const VerificationMeta(
    'hiddenAt',
  );
  @override
  late final GeneratedColumn<DateTime> hiddenAt = GeneratedColumn<DateTime>(
    'hidden_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [path, hiddenAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hidden_folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<HiddenFolderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('hidden_at')) {
      context.handle(
        _hiddenAtMeta,
        hiddenAt.isAcceptableOrUnknown(data['hidden_at']!, _hiddenAtMeta),
      );
    } else if (isInserting) {
      context.missing(_hiddenAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {path};
  @override
  HiddenFolderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HiddenFolderRow(
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      hiddenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}hidden_at'],
      )!,
    );
  }

  @override
  $HiddenFoldersTable createAlias(String alias) {
    return $HiddenFoldersTable(attachedDatabase, alias);
  }
}

class HiddenFolderRow extends DataClass implements Insertable<HiddenFolderRow> {
  final String path;
  final DateTime hiddenAt;
  const HiddenFolderRow({required this.path, required this.hiddenAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['path'] = Variable<String>(path);
    map['hidden_at'] = Variable<DateTime>(hiddenAt);
    return map;
  }

  HiddenFoldersCompanion toCompanion(bool nullToAbsent) {
    return HiddenFoldersCompanion(path: Value(path), hiddenAt: Value(hiddenAt));
  }

  factory HiddenFolderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HiddenFolderRow(
      path: serializer.fromJson<String>(json['path']),
      hiddenAt: serializer.fromJson<DateTime>(json['hiddenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'path': serializer.toJson<String>(path),
      'hiddenAt': serializer.toJson<DateTime>(hiddenAt),
    };
  }

  HiddenFolderRow copyWith({String? path, DateTime? hiddenAt}) =>
      HiddenFolderRow(
        path: path ?? this.path,
        hiddenAt: hiddenAt ?? this.hiddenAt,
      );
  HiddenFolderRow copyWithCompanion(HiddenFoldersCompanion data) {
    return HiddenFolderRow(
      path: data.path.present ? data.path.value : this.path,
      hiddenAt: data.hiddenAt.present ? data.hiddenAt.value : this.hiddenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HiddenFolderRow(')
          ..write('path: $path, ')
          ..write('hiddenAt: $hiddenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(path, hiddenAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HiddenFolderRow &&
          other.path == this.path &&
          other.hiddenAt == this.hiddenAt);
}

class HiddenFoldersCompanion extends UpdateCompanion<HiddenFolderRow> {
  final Value<String> path;
  final Value<DateTime> hiddenAt;
  final Value<int> rowid;
  const HiddenFoldersCompanion({
    this.path = const Value.absent(),
    this.hiddenAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HiddenFoldersCompanion.insert({
    required String path,
    required DateTime hiddenAt,
    this.rowid = const Value.absent(),
  }) : path = Value(path),
       hiddenAt = Value(hiddenAt);
  static Insertable<HiddenFolderRow> custom({
    Expression<String>? path,
    Expression<DateTime>? hiddenAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (path != null) 'path': path,
      if (hiddenAt != null) 'hidden_at': hiddenAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HiddenFoldersCompanion copyWith({
    Value<String>? path,
    Value<DateTime>? hiddenAt,
    Value<int>? rowid,
  }) {
    return HiddenFoldersCompanion(
      path: path ?? this.path,
      hiddenAt: hiddenAt ?? this.hiddenAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (hiddenAt.present) {
      map['hidden_at'] = Variable<DateTime>(hiddenAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HiddenFoldersCompanion(')
          ..write('path: $path, ')
          ..write('hiddenAt: $hiddenAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HiddenTracksTable extends HiddenTracks
    with TableInfo<$HiddenTracksTable, HiddenTrackRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HiddenTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<int> trackId = GeneratedColumn<int>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _hiddenAtMeta = const VerificationMeta(
    'hiddenAt',
  );
  @override
  late final GeneratedColumn<DateTime> hiddenAt = GeneratedColumn<DateTime>(
    'hidden_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [trackId, hiddenAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hidden_tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<HiddenTrackRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    }
    if (data.containsKey('hidden_at')) {
      context.handle(
        _hiddenAtMeta,
        hiddenAt.isAcceptableOrUnknown(data['hidden_at']!, _hiddenAtMeta),
      );
    } else if (isInserting) {
      context.missing(_hiddenAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {trackId};
  @override
  HiddenTrackRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HiddenTrackRow(
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
      hiddenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}hidden_at'],
      )!,
    );
  }

  @override
  $HiddenTracksTable createAlias(String alias) {
    return $HiddenTracksTable(attachedDatabase, alias);
  }
}

class HiddenTrackRow extends DataClass implements Insertable<HiddenTrackRow> {
  final int trackId;
  final DateTime hiddenAt;
  const HiddenTrackRow({required this.trackId, required this.hiddenAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['track_id'] = Variable<int>(trackId);
    map['hidden_at'] = Variable<DateTime>(hiddenAt);
    return map;
  }

  HiddenTracksCompanion toCompanion(bool nullToAbsent) {
    return HiddenTracksCompanion(
      trackId: Value(trackId),
      hiddenAt: Value(hiddenAt),
    );
  }

  factory HiddenTrackRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HiddenTrackRow(
      trackId: serializer.fromJson<int>(json['trackId']),
      hiddenAt: serializer.fromJson<DateTime>(json['hiddenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackId': serializer.toJson<int>(trackId),
      'hiddenAt': serializer.toJson<DateTime>(hiddenAt),
    };
  }

  HiddenTrackRow copyWith({int? trackId, DateTime? hiddenAt}) => HiddenTrackRow(
    trackId: trackId ?? this.trackId,
    hiddenAt: hiddenAt ?? this.hiddenAt,
  );
  HiddenTrackRow copyWithCompanion(HiddenTracksCompanion data) {
    return HiddenTrackRow(
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      hiddenAt: data.hiddenAt.present ? data.hiddenAt.value : this.hiddenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HiddenTrackRow(')
          ..write('trackId: $trackId, ')
          ..write('hiddenAt: $hiddenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(trackId, hiddenAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HiddenTrackRow &&
          other.trackId == this.trackId &&
          other.hiddenAt == this.hiddenAt);
}

class HiddenTracksCompanion extends UpdateCompanion<HiddenTrackRow> {
  final Value<int> trackId;
  final Value<DateTime> hiddenAt;
  const HiddenTracksCompanion({
    this.trackId = const Value.absent(),
    this.hiddenAt = const Value.absent(),
  });
  HiddenTracksCompanion.insert({
    this.trackId = const Value.absent(),
    required DateTime hiddenAt,
  }) : hiddenAt = Value(hiddenAt);
  static Insertable<HiddenTrackRow> custom({
    Expression<int>? trackId,
    Expression<DateTime>? hiddenAt,
  }) {
    return RawValuesInsertable({
      if (trackId != null) 'track_id': trackId,
      if (hiddenAt != null) 'hidden_at': hiddenAt,
    });
  }

  HiddenTracksCompanion copyWith({
    Value<int>? trackId,
    Value<DateTime>? hiddenAt,
  }) {
    return HiddenTracksCompanion(
      trackId: trackId ?? this.trackId,
      hiddenAt: hiddenAt ?? this.hiddenAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (trackId.present) {
      map['track_id'] = Variable<int>(trackId.value);
    }
    if (hiddenAt.present) {
      map['hidden_at'] = Variable<DateTime>(hiddenAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HiddenTracksCompanion(')
          ..write('trackId: $trackId, ')
          ..write('hiddenAt: $hiddenAt')
          ..write(')'))
        .toString();
  }
}

class $FavoritesTable extends Favorites
    with TableInfo<$FavoritesTable, FavoriteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<int> trackId = GeneratedColumn<int>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [trackId, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavoriteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {trackId};
  @override
  FavoriteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteRow(
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $FavoritesTable createAlias(String alias) {
    return $FavoritesTable(attachedDatabase, alias);
  }
}

class FavoriteRow extends DataClass implements Insertable<FavoriteRow> {
  final int trackId;
  final DateTime addedAt;
  const FavoriteRow({required this.trackId, required this.addedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['track_id'] = Variable<int>(trackId);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(trackId: Value(trackId), addedAt: Value(addedAt));
  }

  factory FavoriteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteRow(
      trackId: serializer.fromJson<int>(json['trackId']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackId': serializer.toJson<int>(trackId),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  FavoriteRow copyWith({int? trackId, DateTime? addedAt}) => FavoriteRow(
    trackId: trackId ?? this.trackId,
    addedAt: addedAt ?? this.addedAt,
  );
  FavoriteRow copyWithCompanion(FavoritesCompanion data) {
    return FavoriteRow(
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteRow(')
          ..write('trackId: $trackId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(trackId, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteRow &&
          other.trackId == this.trackId &&
          other.addedAt == this.addedAt);
}

class FavoritesCompanion extends UpdateCompanion<FavoriteRow> {
  final Value<int> trackId;
  final Value<DateTime> addedAt;
  const FavoritesCompanion({
    this.trackId = const Value.absent(),
    this.addedAt = const Value.absent(),
  });
  FavoritesCompanion.insert({
    this.trackId = const Value.absent(),
    required DateTime addedAt,
  }) : addedAt = Value(addedAt);
  static Insertable<FavoriteRow> custom({
    Expression<int>? trackId,
    Expression<DateTime>? addedAt,
  }) {
    return RawValuesInsertable({
      if (trackId != null) 'track_id': trackId,
      if (addedAt != null) 'added_at': addedAt,
    });
  }

  FavoritesCompanion copyWith({Value<int>? trackId, Value<DateTime>? addedAt}) {
    return FavoritesCompanion(
      trackId: trackId ?? this.trackId,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (trackId.present) {
      map['track_id'] = Variable<int>(trackId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesCompanion(')
          ..write('trackId: $trackId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }
}

class $PlaylistsTable extends Playlists
    with TableInfo<$PlaylistsTable, PlaylistRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameKeyMeta = const VerificationMeta(
    'nameKey',
  );
  @override
  late final GeneratedColumn<String> nameKey = GeneratedColumn<String>(
    'name_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    nameKey,
    description,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaylistRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('name_key')) {
      context.handle(
        _nameKeyMeta,
        nameKey.isAcceptableOrUnknown(data['name_key']!, _nameKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_nameKeyMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaylistRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      nameKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_key'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PlaylistsTable createAlias(String alias) {
    return $PlaylistsTable(attachedDatabase, alias);
  }
}

class PlaylistRow extends DataClass implements Insertable<PlaylistRow> {
  final int id;
  final String name;

  /// [name] trimmed and lowercased; unique, so names can't repeat in any
  /// letter case.
  final String nameKey;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PlaylistRow({
    required this.id,
    required this.name,
    required this.nameKey,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['name_key'] = Variable<String>(nameKey);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PlaylistsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistsCompanion(
      id: Value(id),
      name: Value(name),
      nameKey: Value(nameKey),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PlaylistRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      nameKey: serializer.fromJson<String>(json['nameKey']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'nameKey': serializer.toJson<String>(nameKey),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PlaylistRow copyWith({
    int? id,
    String? name,
    String? nameKey,
    Value<String?> description = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PlaylistRow(
    id: id ?? this.id,
    name: name ?? this.name,
    nameKey: nameKey ?? this.nameKey,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PlaylistRow copyWithCompanion(PlaylistsCompanion data) {
    return PlaylistRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      nameKey: data.nameKey.present ? data.nameKey.value : this.nameKey,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nameKey: $nameKey, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, nameKey, description, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.nameKey == this.nameKey &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PlaylistsCompanion extends UpdateCompanion<PlaylistRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> nameKey;
  final Value<String?> description;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PlaylistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.nameKey = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PlaylistsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String nameKey,
    this.description = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : name = Value(name),
       nameKey = Value(nameKey),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PlaylistRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? nameKey,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (nameKey != null) 'name_key': nameKey,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PlaylistsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? nameKey,
    Value<String?>? description,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return PlaylistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      nameKey: nameKey ?? this.nameKey,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nameKey.present) {
      map['name_key'] = Variable<String>(nameKey.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nameKey: $nameKey, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PlaylistEntriesTable extends PlaylistEntries
    with TableInfo<$PlaylistEntriesTable, PlaylistEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<int> playlistId = GeneratedColumn<int>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES playlists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<int> trackId = GeneratedColumn<int>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [playlistId, trackId, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaylistEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playlistId, trackId};
  @override
  PlaylistEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistEntryRow(
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}playlist_id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $PlaylistEntriesTable createAlias(String alias) {
    return $PlaylistEntriesTable(attachedDatabase, alias);
  }
}

class PlaylistEntryRow extends DataClass
    implements Insertable<PlaylistEntryRow> {
  final int playlistId;
  final int trackId;
  final int position;
  const PlaylistEntryRow({
    required this.playlistId,
    required this.trackId,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['playlist_id'] = Variable<int>(playlistId);
    map['track_id'] = Variable<int>(trackId);
    map['position'] = Variable<int>(position);
    return map;
  }

  PlaylistEntriesCompanion toCompanion(bool nullToAbsent) {
    return PlaylistEntriesCompanion(
      playlistId: Value(playlistId),
      trackId: Value(trackId),
      position: Value(position),
    );
  }

  factory PlaylistEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistEntryRow(
      playlistId: serializer.fromJson<int>(json['playlistId']),
      trackId: serializer.fromJson<int>(json['trackId']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playlistId': serializer.toJson<int>(playlistId),
      'trackId': serializer.toJson<int>(trackId),
      'position': serializer.toJson<int>(position),
    };
  }

  PlaylistEntryRow copyWith({int? playlistId, int? trackId, int? position}) =>
      PlaylistEntryRow(
        playlistId: playlistId ?? this.playlistId,
        trackId: trackId ?? this.trackId,
        position: position ?? this.position,
      );
  PlaylistEntryRow copyWithCompanion(PlaylistEntriesCompanion data) {
    return PlaylistEntryRow(
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistEntryRow(')
          ..write('playlistId: $playlistId, ')
          ..write('trackId: $trackId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playlistId, trackId, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistEntryRow &&
          other.playlistId == this.playlistId &&
          other.trackId == this.trackId &&
          other.position == this.position);
}

class PlaylistEntriesCompanion extends UpdateCompanion<PlaylistEntryRow> {
  final Value<int> playlistId;
  final Value<int> trackId;
  final Value<int> position;
  final Value<int> rowid;
  const PlaylistEntriesCompanion({
    this.playlistId = const Value.absent(),
    this.trackId = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistEntriesCompanion.insert({
    required int playlistId,
    required int trackId,
    required int position,
    this.rowid = const Value.absent(),
  }) : playlistId = Value(playlistId),
       trackId = Value(trackId),
       position = Value(position);
  static Insertable<PlaylistEntryRow> custom({
    Expression<int>? playlistId,
    Expression<int>? trackId,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playlistId != null) 'playlist_id': playlistId,
      if (trackId != null) 'track_id': trackId,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistEntriesCompanion copyWith({
    Value<int>? playlistId,
    Value<int>? trackId,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return PlaylistEntriesCompanion(
      playlistId: playlistId ?? this.playlistId,
      trackId: trackId ?? this.trackId,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playlistId.present) {
      map['playlist_id'] = Variable<int>(playlistId.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<int>(trackId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistEntriesCompanion(')
          ..write('playlistId: $playlistId, ')
          ..write('trackId: $trackId, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlayEventsTable extends PlayEvents
    with TableInfo<$PlayEventsTable, PlayEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<int> trackId = GeneratedColumn<int>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _playedAtMeta = const VerificationMeta(
    'playedAt',
  );
  @override
  late final GeneratedColumn<DateTime> playedAt = GeneratedColumn<DateTime>(
    'played_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, trackId, playedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'play_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlayEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('played_at')) {
      context.handle(
        _playedAtMeta,
        playedAt.isAcceptableOrUnknown(data['played_at']!, _playedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_playedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlayEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
      playedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}played_at'],
      )!,
    );
  }

  @override
  $PlayEventsTable createAlias(String alias) {
    return $PlayEventsTable(attachedDatabase, alias);
  }
}

class PlayEventRow extends DataClass implements Insertable<PlayEventRow> {
  final int id;
  final int trackId;
  final DateTime playedAt;
  const PlayEventRow({
    required this.id,
    required this.trackId,
    required this.playedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['track_id'] = Variable<int>(trackId);
    map['played_at'] = Variable<DateTime>(playedAt);
    return map;
  }

  PlayEventsCompanion toCompanion(bool nullToAbsent) {
    return PlayEventsCompanion(
      id: Value(id),
      trackId: Value(trackId),
      playedAt: Value(playedAt),
    );
  }

  factory PlayEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayEventRow(
      id: serializer.fromJson<int>(json['id']),
      trackId: serializer.fromJson<int>(json['trackId']),
      playedAt: serializer.fromJson<DateTime>(json['playedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trackId': serializer.toJson<int>(trackId),
      'playedAt': serializer.toJson<DateTime>(playedAt),
    };
  }

  PlayEventRow copyWith({int? id, int? trackId, DateTime? playedAt}) =>
      PlayEventRow(
        id: id ?? this.id,
        trackId: trackId ?? this.trackId,
        playedAt: playedAt ?? this.playedAt,
      );
  PlayEventRow copyWithCompanion(PlayEventsCompanion data) {
    return PlayEventRow(
      id: data.id.present ? data.id.value : this.id,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      playedAt: data.playedAt.present ? data.playedAt.value : this.playedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayEventRow(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('playedAt: $playedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, trackId, playedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayEventRow &&
          other.id == this.id &&
          other.trackId == this.trackId &&
          other.playedAt == this.playedAt);
}

class PlayEventsCompanion extends UpdateCompanion<PlayEventRow> {
  final Value<int> id;
  final Value<int> trackId;
  final Value<DateTime> playedAt;
  const PlayEventsCompanion({
    this.id = const Value.absent(),
    this.trackId = const Value.absent(),
    this.playedAt = const Value.absent(),
  });
  PlayEventsCompanion.insert({
    this.id = const Value.absent(),
    required int trackId,
    required DateTime playedAt,
  }) : trackId = Value(trackId),
       playedAt = Value(playedAt);
  static Insertable<PlayEventRow> custom({
    Expression<int>? id,
    Expression<int>? trackId,
    Expression<DateTime>? playedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackId != null) 'track_id': trackId,
      if (playedAt != null) 'played_at': playedAt,
    });
  }

  PlayEventsCompanion copyWith({
    Value<int>? id,
    Value<int>? trackId,
    Value<DateTime>? playedAt,
  }) {
    return PlayEventsCompanion(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      playedAt: playedAt ?? this.playedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<int>(trackId.value);
    }
    if (playedAt.present) {
      map['played_at'] = Variable<DateTime>(playedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayEventsCompanion(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('playedAt: $playedAt')
          ..write(')'))
        .toString();
  }
}

class $LyricsLinksTable extends LyricsLinks
    with TableInfo<$LyricsLinksTable, LyricsLinkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LyricsLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<int> trackId = GeneratedColumn<int>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _songIdMeta = const VerificationMeta('songId');
  @override
  late final GeneratedColumn<String> songId = GeneratedColumn<String>(
    'song_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _manualMeta = const VerificationMeta('manual');
  @override
  late final GeneratedColumn<bool> manual = GeneratedColumn<bool>(
    'manual',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("manual" IN (0, 1))',
    ),
  );
  static const VerificationMeta _linkedAtMeta = const VerificationMeta(
    'linkedAt',
  );
  @override
  late final GeneratedColumn<DateTime> linkedAt = GeneratedColumn<DateTime>(
    'linked_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [trackId, songId, manual, linkedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lyrics_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<LyricsLinkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    }
    if (data.containsKey('song_id')) {
      context.handle(
        _songIdMeta,
        songId.isAcceptableOrUnknown(data['song_id']!, _songIdMeta),
      );
    }
    if (data.containsKey('manual')) {
      context.handle(
        _manualMeta,
        manual.isAcceptableOrUnknown(data['manual']!, _manualMeta),
      );
    } else if (isInserting) {
      context.missing(_manualMeta);
    }
    if (data.containsKey('linked_at')) {
      context.handle(
        _linkedAtMeta,
        linkedAt.isAcceptableOrUnknown(data['linked_at']!, _linkedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_linkedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {trackId};
  @override
  LyricsLinkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LyricsLinkRow(
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
      songId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}song_id'],
      ),
      manual: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}manual'],
      )!,
      linkedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}linked_at'],
      )!,
    );
  }

  @override
  $LyricsLinksTable createAlias(String alias) {
    return $LyricsLinksTable(attachedDatabase, alias);
  }
}

class LyricsLinkRow extends DataClass implements Insertable<LyricsLinkRow> {
  final int trackId;
  final String? songId;
  final bool manual;
  final DateTime linkedAt;
  const LyricsLinkRow({
    required this.trackId,
    this.songId,
    required this.manual,
    required this.linkedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['track_id'] = Variable<int>(trackId);
    if (!nullToAbsent || songId != null) {
      map['song_id'] = Variable<String>(songId);
    }
    map['manual'] = Variable<bool>(manual);
    map['linked_at'] = Variable<DateTime>(linkedAt);
    return map;
  }

  LyricsLinksCompanion toCompanion(bool nullToAbsent) {
    return LyricsLinksCompanion(
      trackId: Value(trackId),
      songId: songId == null && nullToAbsent
          ? const Value.absent()
          : Value(songId),
      manual: Value(manual),
      linkedAt: Value(linkedAt),
    );
  }

  factory LyricsLinkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LyricsLinkRow(
      trackId: serializer.fromJson<int>(json['trackId']),
      songId: serializer.fromJson<String?>(json['songId']),
      manual: serializer.fromJson<bool>(json['manual']),
      linkedAt: serializer.fromJson<DateTime>(json['linkedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackId': serializer.toJson<int>(trackId),
      'songId': serializer.toJson<String?>(songId),
      'manual': serializer.toJson<bool>(manual),
      'linkedAt': serializer.toJson<DateTime>(linkedAt),
    };
  }

  LyricsLinkRow copyWith({
    int? trackId,
    Value<String?> songId = const Value.absent(),
    bool? manual,
    DateTime? linkedAt,
  }) => LyricsLinkRow(
    trackId: trackId ?? this.trackId,
    songId: songId.present ? songId.value : this.songId,
    manual: manual ?? this.manual,
    linkedAt: linkedAt ?? this.linkedAt,
  );
  LyricsLinkRow copyWithCompanion(LyricsLinksCompanion data) {
    return LyricsLinkRow(
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      songId: data.songId.present ? data.songId.value : this.songId,
      manual: data.manual.present ? data.manual.value : this.manual,
      linkedAt: data.linkedAt.present ? data.linkedAt.value : this.linkedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LyricsLinkRow(')
          ..write('trackId: $trackId, ')
          ..write('songId: $songId, ')
          ..write('manual: $manual, ')
          ..write('linkedAt: $linkedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(trackId, songId, manual, linkedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LyricsLinkRow &&
          other.trackId == this.trackId &&
          other.songId == this.songId &&
          other.manual == this.manual &&
          other.linkedAt == this.linkedAt);
}

class LyricsLinksCompanion extends UpdateCompanion<LyricsLinkRow> {
  final Value<int> trackId;
  final Value<String?> songId;
  final Value<bool> manual;
  final Value<DateTime> linkedAt;
  const LyricsLinksCompanion({
    this.trackId = const Value.absent(),
    this.songId = const Value.absent(),
    this.manual = const Value.absent(),
    this.linkedAt = const Value.absent(),
  });
  LyricsLinksCompanion.insert({
    this.trackId = const Value.absent(),
    this.songId = const Value.absent(),
    required bool manual,
    required DateTime linkedAt,
  }) : manual = Value(manual),
       linkedAt = Value(linkedAt);
  static Insertable<LyricsLinkRow> custom({
    Expression<int>? trackId,
    Expression<String>? songId,
    Expression<bool>? manual,
    Expression<DateTime>? linkedAt,
  }) {
    return RawValuesInsertable({
      if (trackId != null) 'track_id': trackId,
      if (songId != null) 'song_id': songId,
      if (manual != null) 'manual': manual,
      if (linkedAt != null) 'linked_at': linkedAt,
    });
  }

  LyricsLinksCompanion copyWith({
    Value<int>? trackId,
    Value<String?>? songId,
    Value<bool>? manual,
    Value<DateTime>? linkedAt,
  }) {
    return LyricsLinksCompanion(
      trackId: trackId ?? this.trackId,
      songId: songId ?? this.songId,
      manual: manual ?? this.manual,
      linkedAt: linkedAt ?? this.linkedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (trackId.present) {
      map['track_id'] = Variable<int>(trackId.value);
    }
    if (songId.present) {
      map['song_id'] = Variable<String>(songId.value);
    }
    if (manual.present) {
      map['manual'] = Variable<bool>(manual.value);
    }
    if (linkedAt.present) {
      map['linked_at'] = Variable<DateTime>(linkedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LyricsLinksCompanion(')
          ..write('trackId: $trackId, ')
          ..write('songId: $songId, ')
          ..write('manual: $manual, ')
          ..write('linkedAt: $linkedAt')
          ..write(')'))
        .toString();
  }
}

class $CatalogSongsTable extends CatalogSongs
    with TableInfo<$CatalogSongsTable, CatalogSongRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CatalogSongsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transliterationMeta = const VerificationMeta(
    'transliteration',
  );
  @override
  late final GeneratedColumn<String> transliteration = GeneratedColumn<String>(
    'transliteration',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
    'album',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _approvedAtMeta = const VerificationMeta(
    'approvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> approvedAt = GeneratedColumn<DateTime>(
    'approved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    transliteration,
    artist,
    album,
    synced,
    version,
    approvedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'catalog_songs';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatalogSongRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('transliteration')) {
      context.handle(
        _transliterationMeta,
        transliteration.isAcceptableOrUnknown(
          data['transliteration']!,
          _transliterationMeta,
        ),
      );
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    }
    if (data.containsKey('album')) {
      context.handle(
        _albumMeta,
        album.isAcceptableOrUnknown(data['album']!, _albumMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('approved_at')) {
      context.handle(
        _approvedAtMeta,
        approvedAt.isAcceptableOrUnknown(data['approved_at']!, _approvedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_approvedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CatalogSongRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatalogSongRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      transliteration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transliteration'],
      ),
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      ),
      album: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album'],
      ),
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      approvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}approved_at'],
      )!,
    );
  }

  @override
  $CatalogSongsTable createAlias(String alias) {
    return $CatalogSongsTable(attachedDatabase, alias);
  }
}

class CatalogSongRow extends DataClass implements Insertable<CatalogSongRow> {
  final String id;
  final String title;
  final String? transliteration;
  final String? artist;
  final String? album;
  final bool synced;
  final int version;
  final DateTime approvedAt;
  const CatalogSongRow({
    required this.id,
    required this.title,
    this.transliteration,
    this.artist,
    this.album,
    required this.synced,
    required this.version,
    required this.approvedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || transliteration != null) {
      map['transliteration'] = Variable<String>(transliteration);
    }
    if (!nullToAbsent || artist != null) {
      map['artist'] = Variable<String>(artist);
    }
    if (!nullToAbsent || album != null) {
      map['album'] = Variable<String>(album);
    }
    map['synced'] = Variable<bool>(synced);
    map['version'] = Variable<int>(version);
    map['approved_at'] = Variable<DateTime>(approvedAt);
    return map;
  }

  CatalogSongsCompanion toCompanion(bool nullToAbsent) {
    return CatalogSongsCompanion(
      id: Value(id),
      title: Value(title),
      transliteration: transliteration == null && nullToAbsent
          ? const Value.absent()
          : Value(transliteration),
      artist: artist == null && nullToAbsent
          ? const Value.absent()
          : Value(artist),
      album: album == null && nullToAbsent
          ? const Value.absent()
          : Value(album),
      synced: Value(synced),
      version: Value(version),
      approvedAt: Value(approvedAt),
    );
  }

  factory CatalogSongRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatalogSongRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      transliteration: serializer.fromJson<String?>(json['transliteration']),
      artist: serializer.fromJson<String?>(json['artist']),
      album: serializer.fromJson<String?>(json['album']),
      synced: serializer.fromJson<bool>(json['synced']),
      version: serializer.fromJson<int>(json['version']),
      approvedAt: serializer.fromJson<DateTime>(json['approvedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'transliteration': serializer.toJson<String?>(transliteration),
      'artist': serializer.toJson<String?>(artist),
      'album': serializer.toJson<String?>(album),
      'synced': serializer.toJson<bool>(synced),
      'version': serializer.toJson<int>(version),
      'approvedAt': serializer.toJson<DateTime>(approvedAt),
    };
  }

  CatalogSongRow copyWith({
    String? id,
    String? title,
    Value<String?> transliteration = const Value.absent(),
    Value<String?> artist = const Value.absent(),
    Value<String?> album = const Value.absent(),
    bool? synced,
    int? version,
    DateTime? approvedAt,
  }) => CatalogSongRow(
    id: id ?? this.id,
    title: title ?? this.title,
    transliteration: transliteration.present
        ? transliteration.value
        : this.transliteration,
    artist: artist.present ? artist.value : this.artist,
    album: album.present ? album.value : this.album,
    synced: synced ?? this.synced,
    version: version ?? this.version,
    approvedAt: approvedAt ?? this.approvedAt,
  );
  CatalogSongRow copyWithCompanion(CatalogSongsCompanion data) {
    return CatalogSongRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      transliteration: data.transliteration.present
          ? data.transliteration.value
          : this.transliteration,
      artist: data.artist.present ? data.artist.value : this.artist,
      album: data.album.present ? data.album.value : this.album,
      synced: data.synced.present ? data.synced.value : this.synced,
      version: data.version.present ? data.version.value : this.version,
      approvedAt: data.approvedAt.present
          ? data.approvedAt.value
          : this.approvedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatalogSongRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('transliteration: $transliteration, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('synced: $synced, ')
          ..write('version: $version, ')
          ..write('approvedAt: $approvedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    transliteration,
    artist,
    album,
    synced,
    version,
    approvedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatalogSongRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.transliteration == this.transliteration &&
          other.artist == this.artist &&
          other.album == this.album &&
          other.synced == this.synced &&
          other.version == this.version &&
          other.approvedAt == this.approvedAt);
}

class CatalogSongsCompanion extends UpdateCompanion<CatalogSongRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> transliteration;
  final Value<String?> artist;
  final Value<String?> album;
  final Value<bool> synced;
  final Value<int> version;
  final Value<DateTime> approvedAt;
  final Value<int> rowid;
  const CatalogSongsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.transliteration = const Value.absent(),
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.synced = const Value.absent(),
    this.version = const Value.absent(),
    this.approvedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatalogSongsCompanion.insert({
    required String id,
    required String title,
    this.transliteration = const Value.absent(),
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    required bool synced,
    required int version,
    required DateTime approvedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       synced = Value(synced),
       version = Value(version),
       approvedAt = Value(approvedAt);
  static Insertable<CatalogSongRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? transliteration,
    Expression<String>? artist,
    Expression<String>? album,
    Expression<bool>? synced,
    Expression<int>? version,
    Expression<DateTime>? approvedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (transliteration != null) 'transliteration': transliteration,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
      if (synced != null) 'synced': synced,
      if (version != null) 'version': version,
      if (approvedAt != null) 'approved_at': approvedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatalogSongsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? transliteration,
    Value<String?>? artist,
    Value<String?>? album,
    Value<bool>? synced,
    Value<int>? version,
    Value<DateTime>? approvedAt,
    Value<int>? rowid,
  }) {
    return CatalogSongsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      transliteration: transliteration ?? this.transliteration,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      synced: synced ?? this.synced,
      version: version ?? this.version,
      approvedAt: approvedAt ?? this.approvedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (transliteration.present) {
      map['transliteration'] = Variable<String>(transliteration.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (approvedAt.present) {
      map['approved_at'] = Variable<DateTime>(approvedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatalogSongsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('transliteration: $transliteration, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('synced: $synced, ')
          ..write('version: $version, ')
          ..write('approvedAt: $approvedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedSongsTable extends CachedSongs
    with TableInfo<$CachedSongsTable, CachedSongRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedSongsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentMeta = const VerificationMeta(
    'document',
  );
  @override
  late final GeneratedColumn<String> document = GeneratedColumn<String>(
    'document',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, version, document, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_songs';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedSongRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('document')) {
      context.handle(
        _documentMeta,
        document.isAcceptableOrUnknown(data['document']!, _documentMeta),
      );
    } else if (isInserting) {
      context.missing(_documentMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedSongRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedSongRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      document: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedSongsTable createAlias(String alias) {
    return $CachedSongsTable(attachedDatabase, alias);
  }
}

class CachedSongRow extends DataClass implements Insertable<CachedSongRow> {
  final String id;

  /// The catalog version the document was fetched at.
  final int version;

  /// [SongDocument.toJson], encoded.
  final String document;
  final DateTime cachedAt;
  const CachedSongRow({
    required this.id,
    required this.version,
    required this.document,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['version'] = Variable<int>(version);
    map['document'] = Variable<String>(document);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedSongsCompanion toCompanion(bool nullToAbsent) {
    return CachedSongsCompanion(
      id: Value(id),
      version: Value(version),
      document: Value(document),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedSongRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedSongRow(
      id: serializer.fromJson<String>(json['id']),
      version: serializer.fromJson<int>(json['version']),
      document: serializer.fromJson<String>(json['document']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'version': serializer.toJson<int>(version),
      'document': serializer.toJson<String>(document),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedSongRow copyWith({
    String? id,
    int? version,
    String? document,
    DateTime? cachedAt,
  }) => CachedSongRow(
    id: id ?? this.id,
    version: version ?? this.version,
    document: document ?? this.document,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedSongRow copyWithCompanion(CachedSongsCompanion data) {
    return CachedSongRow(
      id: data.id.present ? data.id.value : this.id,
      version: data.version.present ? data.version.value : this.version,
      document: data.document.present ? data.document.value : this.document,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedSongRow(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('document: $document, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, version, document, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedSongRow &&
          other.id == this.id &&
          other.version == this.version &&
          other.document == this.document &&
          other.cachedAt == this.cachedAt);
}

class CachedSongsCompanion extends UpdateCompanion<CachedSongRow> {
  final Value<String> id;
  final Value<int> version;
  final Value<String> document;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedSongsCompanion({
    this.id = const Value.absent(),
    this.version = const Value.absent(),
    this.document = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedSongsCompanion.insert({
    required String id,
    required int version,
    required String document,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       version = Value(version),
       document = Value(document),
       cachedAt = Value(cachedAt);
  static Insertable<CachedSongRow> custom({
    Expression<String>? id,
    Expression<int>? version,
    Expression<String>? document,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (version != null) 'version': version,
      if (document != null) 'document': document,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedSongsCompanion copyWith({
    Value<String>? id,
    Value<int>? version,
    Value<String>? document,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedSongsCompanion(
      id: id ?? this.id,
      version: version ?? this.version,
      document: document ?? this.document,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (document.present) {
      map['document'] = Variable<String>(document.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedSongsCompanion(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('document: $document, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QueuedReportsTable extends QueuedReports
    with TableInfo<$QueuedReportsTable, QueuedReportRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QueuedReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _reportIdMeta = const VerificationMeta(
    'reportId',
  );
  @override
  late final GeneratedColumn<String> reportId = GeneratedColumn<String>(
    'report_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _songIdMeta = const VerificationMeta('songId');
  @override
  late final GeneratedColumn<String> songId = GeneratedColumn<String>(
    'song_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordingIdMeta = const VerificationMeta(
    'recordingId',
  );
  @override
  late final GeneratedColumn<String> recordingId = GeneratedColumn<String>(
    'recording_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    reportId,
    songId,
    recordingId,
    reason,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'queued_reports';
  @override
  VerificationContext validateIntegrity(
    Insertable<QueuedReportRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('report_id')) {
      context.handle(
        _reportIdMeta,
        reportId.isAcceptableOrUnknown(data['report_id']!, _reportIdMeta),
      );
    } else if (isInserting) {
      context.missing(_reportIdMeta);
    }
    if (data.containsKey('song_id')) {
      context.handle(
        _songIdMeta,
        songId.isAcceptableOrUnknown(data['song_id']!, _songIdMeta),
      );
    } else if (isInserting) {
      context.missing(_songIdMeta);
    }
    if (data.containsKey('recording_id')) {
      context.handle(
        _recordingIdMeta,
        recordingId.isAcceptableOrUnknown(
          data['recording_id']!,
          _recordingIdMeta,
        ),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QueuedReportRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueuedReportRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      reportId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}report_id'],
      )!,
      songId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}song_id'],
      )!,
      recordingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recording_id'],
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $QueuedReportsTable createAlias(String alias) {
    return $QueuedReportsTable(attachedDatabase, alias);
  }
}

class QueuedReportRow extends DataClass implements Insertable<QueuedReportRow> {
  final int id;

  /// The report's own UUID, sent with every try so the catalog stores it
  /// once.
  final String reportId;
  final String songId;
  final String? recordingId;

  /// [ReportReason.name].
  final String reason;
  final String? note;
  final DateTime createdAt;
  const QueuedReportRow({
    required this.id,
    required this.reportId,
    required this.songId,
    this.recordingId,
    required this.reason,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['report_id'] = Variable<String>(reportId);
    map['song_id'] = Variable<String>(songId);
    if (!nullToAbsent || recordingId != null) {
      map['recording_id'] = Variable<String>(recordingId);
    }
    map['reason'] = Variable<String>(reason);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  QueuedReportsCompanion toCompanion(bool nullToAbsent) {
    return QueuedReportsCompanion(
      id: Value(id),
      reportId: Value(reportId),
      songId: Value(songId),
      recordingId: recordingId == null && nullToAbsent
          ? const Value.absent()
          : Value(recordingId),
      reason: Value(reason),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory QueuedReportRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueuedReportRow(
      id: serializer.fromJson<int>(json['id']),
      reportId: serializer.fromJson<String>(json['reportId']),
      songId: serializer.fromJson<String>(json['songId']),
      recordingId: serializer.fromJson<String?>(json['recordingId']),
      reason: serializer.fromJson<String>(json['reason']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'reportId': serializer.toJson<String>(reportId),
      'songId': serializer.toJson<String>(songId),
      'recordingId': serializer.toJson<String?>(recordingId),
      'reason': serializer.toJson<String>(reason),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  QueuedReportRow copyWith({
    int? id,
    String? reportId,
    String? songId,
    Value<String?> recordingId = const Value.absent(),
    String? reason,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => QueuedReportRow(
    id: id ?? this.id,
    reportId: reportId ?? this.reportId,
    songId: songId ?? this.songId,
    recordingId: recordingId.present ? recordingId.value : this.recordingId,
    reason: reason ?? this.reason,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  QueuedReportRow copyWithCompanion(QueuedReportsCompanion data) {
    return QueuedReportRow(
      id: data.id.present ? data.id.value : this.id,
      reportId: data.reportId.present ? data.reportId.value : this.reportId,
      songId: data.songId.present ? data.songId.value : this.songId,
      recordingId: data.recordingId.present
          ? data.recordingId.value
          : this.recordingId,
      reason: data.reason.present ? data.reason.value : this.reason,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueuedReportRow(')
          ..write('id: $id, ')
          ..write('reportId: $reportId, ')
          ..write('songId: $songId, ')
          ..write('recordingId: $recordingId, ')
          ..write('reason: $reason, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, reportId, songId, recordingId, reason, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueuedReportRow &&
          other.id == this.id &&
          other.reportId == this.reportId &&
          other.songId == this.songId &&
          other.recordingId == this.recordingId &&
          other.reason == this.reason &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class QueuedReportsCompanion extends UpdateCompanion<QueuedReportRow> {
  final Value<int> id;
  final Value<String> reportId;
  final Value<String> songId;
  final Value<String?> recordingId;
  final Value<String> reason;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  const QueuedReportsCompanion({
    this.id = const Value.absent(),
    this.reportId = const Value.absent(),
    this.songId = const Value.absent(),
    this.recordingId = const Value.absent(),
    this.reason = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  QueuedReportsCompanion.insert({
    this.id = const Value.absent(),
    required String reportId,
    required String songId,
    this.recordingId = const Value.absent(),
    required String reason,
    this.note = const Value.absent(),
    required DateTime createdAt,
  }) : reportId = Value(reportId),
       songId = Value(songId),
       reason = Value(reason),
       createdAt = Value(createdAt);
  static Insertable<QueuedReportRow> custom({
    Expression<int>? id,
    Expression<String>? reportId,
    Expression<String>? songId,
    Expression<String>? recordingId,
    Expression<String>? reason,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reportId != null) 'report_id': reportId,
      if (songId != null) 'song_id': songId,
      if (recordingId != null) 'recording_id': recordingId,
      if (reason != null) 'reason': reason,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  QueuedReportsCompanion copyWith({
    Value<int>? id,
    Value<String>? reportId,
    Value<String>? songId,
    Value<String?>? recordingId,
    Value<String>? reason,
    Value<String?>? note,
    Value<DateTime>? createdAt,
  }) {
    return QueuedReportsCompanion(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      songId: songId ?? this.songId,
      recordingId: recordingId ?? this.recordingId,
      reason: reason ?? this.reason,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (reportId.present) {
      map['report_id'] = Variable<String>(reportId.value);
    }
    if (songId.present) {
      map['song_id'] = Variable<String>(songId.value);
    }
    if (recordingId.present) {
      map['recording_id'] = Variable<String>(recordingId.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QueuedReportsCompanion(')
          ..write('id: $id, ')
          ..write('reportId: $reportId, ')
          ..write('songId: $songId, ')
          ..write('recordingId: $recordingId, ')
          ..write('reason: $reason, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $UnmatchedEntriesTable extends UnmatchedEntries
    with TableInfo<$UnmatchedEntriesTable, UnmatchedEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnmatchedEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
    'album',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _playlistMeta = const VerificationMeta(
    'playlist',
  );
  @override
  late final GeneratedColumn<String> playlist = GeneratedColumn<String>(
    'playlist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _songIdMeta = const VerificationMeta('songId');
  @override
  late final GeneratedColumn<String> songId = GeneratedColumn<String>(
    'song_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    title,
    artist,
    album,
    durationMs,
    fileName,
    addedAt,
    playlist,
    position,
    songId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'unmatched_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<UnmatchedEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    }
    if (data.containsKey('album')) {
      context.handle(
        _albumMeta,
        album.isAcceptableOrUnknown(data['album']!, _albumMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    if (data.containsKey('playlist')) {
      context.handle(
        _playlistMeta,
        playlist.isAcceptableOrUnknown(data['playlist']!, _playlistMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('song_id')) {
      context.handle(
        _songIdMeta,
        songId.isAcceptableOrUnknown(data['song_id']!, _songIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UnmatchedEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UnmatchedEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      ),
      album: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      ),
      playlist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      ),
      songId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}song_id'],
      ),
    );
  }

  @override
  $UnmatchedEntriesTable createAlias(String alias) {
    return $UnmatchedEntriesTable(attachedDatabase, alias);
  }
}

class UnmatchedEntryRow extends DataClass
    implements Insertable<UnmatchedEntryRow> {
  final int id;

  /// [BackupEntryKind.name].
  final String kind;
  final String title;
  final String? artist;
  final String? album;
  final int durationMs;
  final String fileName;

  /// A favorite's date.
  final DateTime? addedAt;

  /// A playlist entry's playlist name and place.
  final String? playlist;
  final int? position;

  /// A lyrics choice's song; null is "no lyrics".
  final String? songId;
  const UnmatchedEntryRow({
    required this.id,
    required this.kind,
    required this.title,
    this.artist,
    this.album,
    required this.durationMs,
    required this.fileName,
    this.addedAt,
    this.playlist,
    this.position,
    this.songId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<String>(kind);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || artist != null) {
      map['artist'] = Variable<String>(artist);
    }
    if (!nullToAbsent || album != null) {
      map['album'] = Variable<String>(album);
    }
    map['duration_ms'] = Variable<int>(durationMs);
    map['file_name'] = Variable<String>(fileName);
    if (!nullToAbsent || addedAt != null) {
      map['added_at'] = Variable<DateTime>(addedAt);
    }
    if (!nullToAbsent || playlist != null) {
      map['playlist'] = Variable<String>(playlist);
    }
    if (!nullToAbsent || position != null) {
      map['position'] = Variable<int>(position);
    }
    if (!nullToAbsent || songId != null) {
      map['song_id'] = Variable<String>(songId);
    }
    return map;
  }

  UnmatchedEntriesCompanion toCompanion(bool nullToAbsent) {
    return UnmatchedEntriesCompanion(
      id: Value(id),
      kind: Value(kind),
      title: Value(title),
      artist: artist == null && nullToAbsent
          ? const Value.absent()
          : Value(artist),
      album: album == null && nullToAbsent
          ? const Value.absent()
          : Value(album),
      durationMs: Value(durationMs),
      fileName: Value(fileName),
      addedAt: addedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(addedAt),
      playlist: playlist == null && nullToAbsent
          ? const Value.absent()
          : Value(playlist),
      position: position == null && nullToAbsent
          ? const Value.absent()
          : Value(position),
      songId: songId == null && nullToAbsent
          ? const Value.absent()
          : Value(songId),
    );
  }

  factory UnmatchedEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UnmatchedEntryRow(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String?>(json['artist']),
      album: serializer.fromJson<String?>(json['album']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      fileName: serializer.fromJson<String>(json['fileName']),
      addedAt: serializer.fromJson<DateTime?>(json['addedAt']),
      playlist: serializer.fromJson<String?>(json['playlist']),
      position: serializer.fromJson<int?>(json['position']),
      songId: serializer.fromJson<String?>(json['songId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(kind),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String?>(artist),
      'album': serializer.toJson<String?>(album),
      'durationMs': serializer.toJson<int>(durationMs),
      'fileName': serializer.toJson<String>(fileName),
      'addedAt': serializer.toJson<DateTime?>(addedAt),
      'playlist': serializer.toJson<String?>(playlist),
      'position': serializer.toJson<int?>(position),
      'songId': serializer.toJson<String?>(songId),
    };
  }

  UnmatchedEntryRow copyWith({
    int? id,
    String? kind,
    String? title,
    Value<String?> artist = const Value.absent(),
    Value<String?> album = const Value.absent(),
    int? durationMs,
    String? fileName,
    Value<DateTime?> addedAt = const Value.absent(),
    Value<String?> playlist = const Value.absent(),
    Value<int?> position = const Value.absent(),
    Value<String?> songId = const Value.absent(),
  }) => UnmatchedEntryRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    title: title ?? this.title,
    artist: artist.present ? artist.value : this.artist,
    album: album.present ? album.value : this.album,
    durationMs: durationMs ?? this.durationMs,
    fileName: fileName ?? this.fileName,
    addedAt: addedAt.present ? addedAt.value : this.addedAt,
    playlist: playlist.present ? playlist.value : this.playlist,
    position: position.present ? position.value : this.position,
    songId: songId.present ? songId.value : this.songId,
  );
  UnmatchedEntryRow copyWithCompanion(UnmatchedEntriesCompanion data) {
    return UnmatchedEntryRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      album: data.album.present ? data.album.value : this.album,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      playlist: data.playlist.present ? data.playlist.value : this.playlist,
      position: data.position.present ? data.position.value : this.position,
      songId: data.songId.present ? data.songId.value : this.songId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UnmatchedEntryRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('durationMs: $durationMs, ')
          ..write('fileName: $fileName, ')
          ..write('addedAt: $addedAt, ')
          ..write('playlist: $playlist, ')
          ..write('position: $position, ')
          ..write('songId: $songId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    title,
    artist,
    album,
    durationMs,
    fileName,
    addedAt,
    playlist,
    position,
    songId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UnmatchedEntryRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.album == this.album &&
          other.durationMs == this.durationMs &&
          other.fileName == this.fileName &&
          other.addedAt == this.addedAt &&
          other.playlist == this.playlist &&
          other.position == this.position &&
          other.songId == this.songId);
}

class UnmatchedEntriesCompanion extends UpdateCompanion<UnmatchedEntryRow> {
  final Value<int> id;
  final Value<String> kind;
  final Value<String> title;
  final Value<String?> artist;
  final Value<String?> album;
  final Value<int> durationMs;
  final Value<String> fileName;
  final Value<DateTime?> addedAt;
  final Value<String?> playlist;
  final Value<int?> position;
  final Value<String?> songId;
  const UnmatchedEntriesCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.fileName = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.playlist = const Value.absent(),
    this.position = const Value.absent(),
    this.songId = const Value.absent(),
  });
  UnmatchedEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String kind,
    required String title,
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    required int durationMs,
    required String fileName,
    this.addedAt = const Value.absent(),
    this.playlist = const Value.absent(),
    this.position = const Value.absent(),
    this.songId = const Value.absent(),
  }) : kind = Value(kind),
       title = Value(title),
       durationMs = Value(durationMs),
       fileName = Value(fileName);
  static Insertable<UnmatchedEntryRow> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<String>? album,
    Expression<int>? durationMs,
    Expression<String>? fileName,
    Expression<DateTime>? addedAt,
    Expression<String>? playlist,
    Expression<int>? position,
    Expression<String>? songId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
      if (durationMs != null) 'duration_ms': durationMs,
      if (fileName != null) 'file_name': fileName,
      if (addedAt != null) 'added_at': addedAt,
      if (playlist != null) 'playlist': playlist,
      if (position != null) 'position': position,
      if (songId != null) 'song_id': songId,
    });
  }

  UnmatchedEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? kind,
    Value<String>? title,
    Value<String?>? artist,
    Value<String?>? album,
    Value<int>? durationMs,
    Value<String>? fileName,
    Value<DateTime?>? addedAt,
    Value<String?>? playlist,
    Value<int?>? position,
    Value<String?>? songId,
  }) {
    return UnmatchedEntriesCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      durationMs: durationMs ?? this.durationMs,
      fileName: fileName ?? this.fileName,
      addedAt: addedAt ?? this.addedAt,
      playlist: playlist ?? this.playlist,
      position: position ?? this.position,
      songId: songId ?? this.songId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (playlist.present) {
      map['playlist'] = Variable<String>(playlist.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (songId.present) {
      map['song_id'] = Variable<String>(songId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnmatchedEntriesCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('durationMs: $durationMs, ')
          ..write('fileName: $fileName, ')
          ..write('addedAt: $addedAt, ')
          ..write('playlist: $playlist, ')
          ..write('position: $position, ')
          ..write('songId: $songId')
          ..write(')'))
        .toString();
  }
}

class $DraftsTable extends Drafts with TableInfo<$DraftsTable, DraftRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stepMeta = const VerificationMeta('step');
  @override
  late final GeneratedColumn<String> step = GeneratedColumn<String>(
    'step',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _draftMeta = const VerificationMeta('draft');
  @override
  late final GeneratedColumn<String> draft = GeneratedColumn<String>(
    'draft',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    step,
    title,
    draft,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<DraftRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('step')) {
      context.handle(
        _stepMeta,
        step.isAcceptableOrUnknown(data['step']!, _stepMeta),
      );
    } else if (isInserting) {
      context.missing(_stepMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('draft')) {
      context.handle(
        _draftMeta,
        draft.isAcceptableOrUnknown(data['draft']!, _draftMeta),
      );
    } else if (isInserting) {
      context.missing(_draftMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DraftRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DraftRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      step: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}step'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      draft: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}draft'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DraftsTable createAlias(String alias) {
    return $DraftsTable(attachedDatabase, alias);
  }
}

class DraftRow extends DataClass implements Insertable<DraftRow> {
  final int id;

  /// [ContributionKind.wire].
  final String kind;

  /// [DraftStep.name], for the list.
  final String step;

  /// The song's title as typed, for the list; empty until typed.
  final String title;

  /// The whole draft ([ContributionDraft.toJson]).
  final String draft;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DraftRow({
    required this.id,
    required this.kind,
    required this.step,
    required this.title,
    required this.draft,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<String>(kind);
    map['step'] = Variable<String>(step);
    map['title'] = Variable<String>(title);
    map['draft'] = Variable<String>(draft);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DraftsCompanion toCompanion(bool nullToAbsent) {
    return DraftsCompanion(
      id: Value(id),
      kind: Value(kind),
      step: Value(step),
      title: Value(title),
      draft: Value(draft),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DraftRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DraftRow(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      step: serializer.fromJson<String>(json['step']),
      title: serializer.fromJson<String>(json['title']),
      draft: serializer.fromJson<String>(json['draft']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(kind),
      'step': serializer.toJson<String>(step),
      'title': serializer.toJson<String>(title),
      'draft': serializer.toJson<String>(draft),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DraftRow copyWith({
    int? id,
    String? kind,
    String? step,
    String? title,
    String? draft,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DraftRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    step: step ?? this.step,
    title: title ?? this.title,
    draft: draft ?? this.draft,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DraftRow copyWithCompanion(DraftsCompanion data) {
    return DraftRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      step: data.step.present ? data.step.value : this.step,
      title: data.title.present ? data.title.value : this.title,
      draft: data.draft.present ? data.draft.value : this.draft,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DraftRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('step: $step, ')
          ..write('title: $title, ')
          ..write('draft: $draft, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, kind, step, title, draft, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DraftRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.step == this.step &&
          other.title == this.title &&
          other.draft == this.draft &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DraftsCompanion extends UpdateCompanion<DraftRow> {
  final Value<int> id;
  final Value<String> kind;
  final Value<String> step;
  final Value<String> title;
  final Value<String> draft;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const DraftsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.step = const Value.absent(),
    this.title = const Value.absent(),
    this.draft = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DraftsCompanion.insert({
    this.id = const Value.absent(),
    required String kind,
    required String step,
    required String title,
    required String draft,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : kind = Value(kind),
       step = Value(step),
       title = Value(title),
       draft = Value(draft),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DraftRow> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<String>? step,
    Expression<String>? title,
    Expression<String>? draft,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (step != null) 'step': step,
      if (title != null) 'title': title,
      if (draft != null) 'draft': draft,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DraftsCompanion copyWith({
    Value<int>? id,
    Value<String>? kind,
    Value<String>? step,
    Value<String>? title,
    Value<String>? draft,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return DraftsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      step: step ?? this.step,
      title: title ?? this.title,
      draft: draft ?? this.draft,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (step.present) {
      map['step'] = Variable<String>(step.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (draft.present) {
      map['draft'] = Variable<String>(draft.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DraftsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('step: $step, ')
          ..write('title: $title, ')
          ..write('draft: $draft, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $OwnCopiesTable extends OwnCopies
    with TableInfo<$OwnCopiesTable, OwnCopyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OwnCopiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _contributionIdMeta = const VerificationMeta(
    'contributionId',
  );
  @override
  late final GeneratedColumn<String> contributionId = GeneratedColumn<String>(
    'contribution_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _songMeta = const VerificationMeta('song');
  @override
  late final GeneratedColumn<String> song = GeneratedColumn<String>(
    'song',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordingMeta = const VerificationMeta(
    'recording',
  );
  @override
  late final GeneratedColumn<String> recording = GeneratedColumn<String>(
    'recording',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timingMeta = const VerificationMeta('timing');
  @override
  late final GeneratedColumn<String> timing = GeneratedColumn<String>(
    'timing',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<int> trackId = GeneratedColumn<int>(
    'track_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioPathMeta = const VerificationMeta(
    'audioPath',
  );
  @override
  late final GeneratedColumn<String> audioPath = GeneratedColumn<String>(
    'audio_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _submittedAtMeta = const VerificationMeta(
    'submittedAt',
  );
  @override
  late final GeneratedColumn<DateTime> submittedAt = GeneratedColumn<DateTime>(
    'submitted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    contributionId,
    kind,
    song,
    recording,
    timing,
    trackId,
    audioPath,
    submittedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'own_copies';
  @override
  VerificationContext validateIntegrity(
    Insertable<OwnCopyRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('contribution_id')) {
      context.handle(
        _contributionIdMeta,
        contributionId.isAcceptableOrUnknown(
          data['contribution_id']!,
          _contributionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contributionIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('song')) {
      context.handle(
        _songMeta,
        song.isAcceptableOrUnknown(data['song']!, _songMeta),
      );
    } else if (isInserting) {
      context.missing(_songMeta);
    }
    if (data.containsKey('recording')) {
      context.handle(
        _recordingMeta,
        recording.isAcceptableOrUnknown(data['recording']!, _recordingMeta),
      );
    }
    if (data.containsKey('timing')) {
      context.handle(
        _timingMeta,
        timing.isAcceptableOrUnknown(data['timing']!, _timingMeta),
      );
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    }
    if (data.containsKey('audio_path')) {
      context.handle(
        _audioPathMeta,
        audioPath.isAcceptableOrUnknown(data['audio_path']!, _audioPathMeta),
      );
    }
    if (data.containsKey('submitted_at')) {
      context.handle(
        _submittedAtMeta,
        submittedAt.isAcceptableOrUnknown(
          data['submitted_at']!,
          _submittedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_submittedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OwnCopyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OwnCopyRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      contributionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contribution_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      song: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}song'],
      )!,
      recording: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recording'],
      ),
      timing: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timing'],
      ),
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      ),
      audioPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_path'],
      ),
      submittedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}submitted_at'],
      )!,
    );
  }

  @override
  $OwnCopiesTable createAlias(String alias) {
    return $OwnCopiesTable(attachedDatabase, alias);
  }
}

class OwnCopyRow extends DataClass implements Insertable<OwnCopyRow> {
  final int id;

  /// The contribution's id on the backend.
  final String contributionId;

  /// [ContributionKind.wire].
  final String kind;

  /// The lyrics as sent ([Song.toJson]).
  final String song;

  /// [Recording.toJson] and [SyncTiming.toJson], when sent.
  final String? recording;
  final String? timing;

  /// The local track it was made for, if any.
  final int? trackId;

  /// Zema's copy of a file shared to it, kept until the contribution is
  /// reviewed.
  final String? audioPath;
  final DateTime submittedAt;
  const OwnCopyRow({
    required this.id,
    required this.contributionId,
    required this.kind,
    required this.song,
    this.recording,
    this.timing,
    this.trackId,
    this.audioPath,
    required this.submittedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['contribution_id'] = Variable<String>(contributionId);
    map['kind'] = Variable<String>(kind);
    map['song'] = Variable<String>(song);
    if (!nullToAbsent || recording != null) {
      map['recording'] = Variable<String>(recording);
    }
    if (!nullToAbsent || timing != null) {
      map['timing'] = Variable<String>(timing);
    }
    if (!nullToAbsent || trackId != null) {
      map['track_id'] = Variable<int>(trackId);
    }
    if (!nullToAbsent || audioPath != null) {
      map['audio_path'] = Variable<String>(audioPath);
    }
    map['submitted_at'] = Variable<DateTime>(submittedAt);
    return map;
  }

  OwnCopiesCompanion toCompanion(bool nullToAbsent) {
    return OwnCopiesCompanion(
      id: Value(id),
      contributionId: Value(contributionId),
      kind: Value(kind),
      song: Value(song),
      recording: recording == null && nullToAbsent
          ? const Value.absent()
          : Value(recording),
      timing: timing == null && nullToAbsent
          ? const Value.absent()
          : Value(timing),
      trackId: trackId == null && nullToAbsent
          ? const Value.absent()
          : Value(trackId),
      audioPath: audioPath == null && nullToAbsent
          ? const Value.absent()
          : Value(audioPath),
      submittedAt: Value(submittedAt),
    );
  }

  factory OwnCopyRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OwnCopyRow(
      id: serializer.fromJson<int>(json['id']),
      contributionId: serializer.fromJson<String>(json['contributionId']),
      kind: serializer.fromJson<String>(json['kind']),
      song: serializer.fromJson<String>(json['song']),
      recording: serializer.fromJson<String?>(json['recording']),
      timing: serializer.fromJson<String?>(json['timing']),
      trackId: serializer.fromJson<int?>(json['trackId']),
      audioPath: serializer.fromJson<String?>(json['audioPath']),
      submittedAt: serializer.fromJson<DateTime>(json['submittedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'contributionId': serializer.toJson<String>(contributionId),
      'kind': serializer.toJson<String>(kind),
      'song': serializer.toJson<String>(song),
      'recording': serializer.toJson<String?>(recording),
      'timing': serializer.toJson<String?>(timing),
      'trackId': serializer.toJson<int?>(trackId),
      'audioPath': serializer.toJson<String?>(audioPath),
      'submittedAt': serializer.toJson<DateTime>(submittedAt),
    };
  }

  OwnCopyRow copyWith({
    int? id,
    String? contributionId,
    String? kind,
    String? song,
    Value<String?> recording = const Value.absent(),
    Value<String?> timing = const Value.absent(),
    Value<int?> trackId = const Value.absent(),
    Value<String?> audioPath = const Value.absent(),
    DateTime? submittedAt,
  }) => OwnCopyRow(
    id: id ?? this.id,
    contributionId: contributionId ?? this.contributionId,
    kind: kind ?? this.kind,
    song: song ?? this.song,
    recording: recording.present ? recording.value : this.recording,
    timing: timing.present ? timing.value : this.timing,
    trackId: trackId.present ? trackId.value : this.trackId,
    audioPath: audioPath.present ? audioPath.value : this.audioPath,
    submittedAt: submittedAt ?? this.submittedAt,
  );
  OwnCopyRow copyWithCompanion(OwnCopiesCompanion data) {
    return OwnCopyRow(
      id: data.id.present ? data.id.value : this.id,
      contributionId: data.contributionId.present
          ? data.contributionId.value
          : this.contributionId,
      kind: data.kind.present ? data.kind.value : this.kind,
      song: data.song.present ? data.song.value : this.song,
      recording: data.recording.present ? data.recording.value : this.recording,
      timing: data.timing.present ? data.timing.value : this.timing,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      audioPath: data.audioPath.present ? data.audioPath.value : this.audioPath,
      submittedAt: data.submittedAt.present
          ? data.submittedAt.value
          : this.submittedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OwnCopyRow(')
          ..write('id: $id, ')
          ..write('contributionId: $contributionId, ')
          ..write('kind: $kind, ')
          ..write('song: $song, ')
          ..write('recording: $recording, ')
          ..write('timing: $timing, ')
          ..write('trackId: $trackId, ')
          ..write('audioPath: $audioPath, ')
          ..write('submittedAt: $submittedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    contributionId,
    kind,
    song,
    recording,
    timing,
    trackId,
    audioPath,
    submittedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OwnCopyRow &&
          other.id == this.id &&
          other.contributionId == this.contributionId &&
          other.kind == this.kind &&
          other.song == this.song &&
          other.recording == this.recording &&
          other.timing == this.timing &&
          other.trackId == this.trackId &&
          other.audioPath == this.audioPath &&
          other.submittedAt == this.submittedAt);
}

class OwnCopiesCompanion extends UpdateCompanion<OwnCopyRow> {
  final Value<int> id;
  final Value<String> contributionId;
  final Value<String> kind;
  final Value<String> song;
  final Value<String?> recording;
  final Value<String?> timing;
  final Value<int?> trackId;
  final Value<String?> audioPath;
  final Value<DateTime> submittedAt;
  const OwnCopiesCompanion({
    this.id = const Value.absent(),
    this.contributionId = const Value.absent(),
    this.kind = const Value.absent(),
    this.song = const Value.absent(),
    this.recording = const Value.absent(),
    this.timing = const Value.absent(),
    this.trackId = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.submittedAt = const Value.absent(),
  });
  OwnCopiesCompanion.insert({
    this.id = const Value.absent(),
    required String contributionId,
    required String kind,
    required String song,
    this.recording = const Value.absent(),
    this.timing = const Value.absent(),
    this.trackId = const Value.absent(),
    this.audioPath = const Value.absent(),
    required DateTime submittedAt,
  }) : contributionId = Value(contributionId),
       kind = Value(kind),
       song = Value(song),
       submittedAt = Value(submittedAt);
  static Insertable<OwnCopyRow> custom({
    Expression<int>? id,
    Expression<String>? contributionId,
    Expression<String>? kind,
    Expression<String>? song,
    Expression<String>? recording,
    Expression<String>? timing,
    Expression<int>? trackId,
    Expression<String>? audioPath,
    Expression<DateTime>? submittedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contributionId != null) 'contribution_id': contributionId,
      if (kind != null) 'kind': kind,
      if (song != null) 'song': song,
      if (recording != null) 'recording': recording,
      if (timing != null) 'timing': timing,
      if (trackId != null) 'track_id': trackId,
      if (audioPath != null) 'audio_path': audioPath,
      if (submittedAt != null) 'submitted_at': submittedAt,
    });
  }

  OwnCopiesCompanion copyWith({
    Value<int>? id,
    Value<String>? contributionId,
    Value<String>? kind,
    Value<String>? song,
    Value<String?>? recording,
    Value<String?>? timing,
    Value<int?>? trackId,
    Value<String?>? audioPath,
    Value<DateTime>? submittedAt,
  }) {
    return OwnCopiesCompanion(
      id: id ?? this.id,
      contributionId: contributionId ?? this.contributionId,
      kind: kind ?? this.kind,
      song: song ?? this.song,
      recording: recording ?? this.recording,
      timing: timing ?? this.timing,
      trackId: trackId ?? this.trackId,
      audioPath: audioPath ?? this.audioPath,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (contributionId.present) {
      map['contribution_id'] = Variable<String>(contributionId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (song.present) {
      map['song'] = Variable<String>(song.value);
    }
    if (recording.present) {
      map['recording'] = Variable<String>(recording.value);
    }
    if (timing.present) {
      map['timing'] = Variable<String>(timing.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<int>(trackId.value);
    }
    if (audioPath.present) {
      map['audio_path'] = Variable<String>(audioPath.value);
    }
    if (submittedAt.present) {
      map['submitted_at'] = Variable<DateTime>(submittedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OwnCopiesCompanion(')
          ..write('id: $id, ')
          ..write('contributionId: $contributionId, ')
          ..write('kind: $kind, ')
          ..write('song: $song, ')
          ..write('recording: $recording, ')
          ..write('timing: $timing, ')
          ..write('trackId: $trackId, ')
          ..write('audioPath: $audioPath, ')
          ..write('submittedAt: $submittedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$ZemaDatabase extends GeneratedDatabase {
  _$ZemaDatabase(QueryExecutor e) : super(e);
  $ZemaDatabaseManager get managers => $ZemaDatabaseManager(this);
  late final $TracksTable tracks = $TracksTable(this);
  late final $HiddenFoldersTable hiddenFolders = $HiddenFoldersTable(this);
  late final $HiddenTracksTable hiddenTracks = $HiddenTracksTable(this);
  late final $FavoritesTable favorites = $FavoritesTable(this);
  late final $PlaylistsTable playlists = $PlaylistsTable(this);
  late final $PlaylistEntriesTable playlistEntries = $PlaylistEntriesTable(
    this,
  );
  late final $PlayEventsTable playEvents = $PlayEventsTable(this);
  late final $LyricsLinksTable lyricsLinks = $LyricsLinksTable(this);
  late final $CatalogSongsTable catalogSongs = $CatalogSongsTable(this);
  late final $CachedSongsTable cachedSongs = $CachedSongsTable(this);
  late final $QueuedReportsTable queuedReports = $QueuedReportsTable(this);
  late final $UnmatchedEntriesTable unmatchedEntries = $UnmatchedEntriesTable(
    this,
  );
  late final $DraftsTable drafts = $DraftsTable(this);
  late final $OwnCopiesTable ownCopies = $OwnCopiesTable(this);
  late final Index tracksFolder = Index(
    'tracks_folder',
    'CREATE INDEX tracks_folder ON tracks (folder)',
  );
  late final Index playlistEntriesOrder = Index(
    'playlist_entries_order',
    'CREATE INDEX playlist_entries_order ON playlist_entries (playlist_id, position)',
  );
  late final Index playEventsTrack = Index(
    'play_events_track',
    'CREATE INDEX play_events_track ON play_events (track_id)',
  );
  late final Index playEventsTime = Index(
    'play_events_time',
    'CREATE INDEX play_events_time ON play_events (played_at)',
  );
  late final LibraryDao libraryDao = LibraryDao(this as ZemaDatabase);
  late final CollectionsDao collectionsDao = CollectionsDao(
    this as ZemaDatabase,
  );
  late final HistoryDao historyDao = HistoryDao(this as ZemaDatabase);
  late final LyricsLinksDao lyricsLinksDao = LyricsLinksDao(
    this as ZemaDatabase,
  );
  late final CatalogDao catalogDao = CatalogDao(this as ZemaDatabase);
  late final CachedSongsDao cachedSongsDao = CachedSongsDao(
    this as ZemaDatabase,
  );
  late final ReportsDao reportsDao = ReportsDao(this as ZemaDatabase);
  late final BackupDao backupDao = BackupDao(this as ZemaDatabase);
  late final RestoreDao restoreDao = RestoreDao(this as ZemaDatabase);
  late final UnmatchedDao unmatchedDao = UnmatchedDao(this as ZemaDatabase);
  late final DraftsDao draftsDao = DraftsDao(this as ZemaDatabase);
  late final OwnCopiesDao ownCopiesDao = OwnCopiesDao(this as ZemaDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tracks,
    hiddenFolders,
    hiddenTracks,
    favorites,
    playlists,
    playlistEntries,
    playEvents,
    lyricsLinks,
    catalogSongs,
    cachedSongs,
    queuedReports,
    unmatchedEntries,
    drafts,
    ownCopies,
    tracksFolder,
    playlistEntriesOrder,
    playEventsTrack,
    playEventsTime,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tracks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('hidden_tracks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tracks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('favorites', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playlist_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tracks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playlist_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tracks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('play_events', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tracks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('lyrics_links', kind: UpdateKind.delete)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$TracksTableCreateCompanionBuilder = TracksCompanion Function({
  Value<int> id,
  required int mediaStoreId,
  required String uri,
  required String path,
  required String folder,
  required String title,
  Value<String?> artist,
  Value<String?> album,
  Value<String?> albumArtist,
  Value<int?> trackNumber,
  Value<int?> year,
  required int durationMs,
  required int sizeBytes,
  required DateTime dateAdded,
  Value<bool> missing,
});
typedef $$TracksTableUpdateCompanionBuilder = TracksCompanion Function({
  Value<int> id,
  Value<int> mediaStoreId,
  Value<String> uri,
  Value<String> path,
  Value<String> folder,
  Value<String> title,
  Value<String?> artist,
  Value<String?> album,
  Value<String?> albumArtist,
  Value<int?> trackNumber,
  Value<int?> year,
  Value<int> durationMs,
  Value<int> sizeBytes,
  Value<DateTime> dateAdded,
  Value<bool> missing,
});

final class $$TracksTableReferences
    extends BaseReferences<_$ZemaDatabase, $TracksTable, TrackRow> {
  $$TracksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$HiddenTracksTable, List<HiddenTrackRow>>
  _hiddenTracksRefsTable(_$ZemaDatabase db) => MultiTypedResultKey.fromTable(
    db.hiddenTracks,
    aliasName: 'tracks__id__hidden_tracks__track_id',
  );

  $$HiddenTracksTableProcessedTableManager get hiddenTracksRefs {
    final manager = $$HiddenTracksTableTableManager(
      $_db,
      $_db.hiddenTracks,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_hiddenTracksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FavoritesTable, List<FavoriteRow>>
  _favoritesRefsTable(_$ZemaDatabase db) => MultiTypedResultKey.fromTable(
    db.favorites,
    aliasName: 'tracks__id__favorites__track_id',
  );

  $$FavoritesTableProcessedTableManager get favoritesRefs {
    final manager = $$FavoritesTableTableManager(
      $_db,
      $_db.favorites,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_favoritesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlaylistEntriesTable, List<PlaylistEntryRow>>
  _playlistEntriesRefsTable(_$ZemaDatabase db) => MultiTypedResultKey.fromTable(
    db.playlistEntries,
    aliasName: 'tracks__id__playlist_entries__track_id',
  );

  $$PlaylistEntriesTableProcessedTableManager get playlistEntriesRefs {
    final manager = $$PlaylistEntriesTableTableManager(
      $_db,
      $_db.playlistEntries,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _playlistEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlayEventsTable, List<PlayEventRow>>
  _playEventsRefsTable(_$ZemaDatabase db) => MultiTypedResultKey.fromTable(
    db.playEvents,
    aliasName: 'tracks__id__play_events__track_id',
  );

  $$PlayEventsTableProcessedTableManager get playEventsRefs {
    final manager = $$PlayEventsTableTableManager(
      $_db,
      $_db.playEvents,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_playEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LyricsLinksTable, List<LyricsLinkRow>>
  _lyricsLinksRefsTable(_$ZemaDatabase db) => MultiTypedResultKey.fromTable(
    db.lyricsLinks,
    aliasName: 'tracks__id__lyrics_links__track_id',
  );

  $$LyricsLinksTableProcessedTableManager get lyricsLinksRefs {
    final manager = $$LyricsLinksTableTableManager(
      $_db,
      $_db.lyricsLinks,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_lyricsLinksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TracksTableFilterComposer
    extends Composer<_$ZemaDatabase, $TracksTable> {
  $$TracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mediaStoreId => $composableBuilder(
    column: $table.mediaStoreId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uri => $composableBuilder(
    column: $table.uri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folder => $composableBuilder(
    column: $table.folder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get missing => $composableBuilder(
    column: $table.missing,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> hiddenTracksRefs(
    Expression<bool> Function($$HiddenTracksTableFilterComposer f) f,
  ) {
    final $$HiddenTracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.hiddenTracks,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HiddenTracksTableFilterComposer(
            $db: $db,
            $table: $db.hiddenTracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> favoritesRefs(
    Expression<bool> Function($$FavoritesTableFilterComposer f) f,
  ) {
    final $$FavoritesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.favorites,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoritesTableFilterComposer(
            $db: $db,
            $table: $db.favorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> playlistEntriesRefs(
    Expression<bool> Function($$PlaylistEntriesTableFilterComposer f) f,
  ) {
    final $$PlaylistEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistEntries,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistEntriesTableFilterComposer(
            $db: $db,
            $table: $db.playlistEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> playEventsRefs(
    Expression<bool> Function($$PlayEventsTableFilterComposer f) f,
  ) {
    final $$PlayEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playEvents,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayEventsTableFilterComposer(
            $db: $db,
            $table: $db.playEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> lyricsLinksRefs(
    Expression<bool> Function($$LyricsLinksTableFilterComposer f) f,
  ) {
    final $$LyricsLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lyricsLinks,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LyricsLinksTableFilterComposer(
            $db: $db,
            $table: $db.lyricsLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TracksTableOrderingComposer
    extends Composer<_$ZemaDatabase, $TracksTable> {
  $$TracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mediaStoreId => $composableBuilder(
    column: $table.mediaStoreId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uri => $composableBuilder(
    column: $table.uri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folder => $composableBuilder(
    column: $table.folder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get missing => $composableBuilder(
    column: $table.missing,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TracksTableAnnotationComposer
    extends Composer<_$ZemaDatabase, $TracksTable> {
  $$TracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get mediaStoreId => $composableBuilder(
    column: $table.mediaStoreId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uri =>
      $composableBuilder(column: $table.uri, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get folder =>
      $composableBuilder(column: $table.folder, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => column,
  );

  GeneratedColumn<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<DateTime> get dateAdded =>
      $composableBuilder(column: $table.dateAdded, builder: (column) => column);

  GeneratedColumn<bool> get missing =>
      $composableBuilder(column: $table.missing, builder: (column) => column);

  Expression<T> hiddenTracksRefs<T extends Object>(
    Expression<T> Function($$HiddenTracksTableAnnotationComposer a) f,
  ) {
    final $$HiddenTracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.hiddenTracks,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HiddenTracksTableAnnotationComposer(
            $db: $db,
            $table: $db.hiddenTracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> favoritesRefs<T extends Object>(
    Expression<T> Function($$FavoritesTableAnnotationComposer a) f,
  ) {
    final $$FavoritesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.favorites,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoritesTableAnnotationComposer(
            $db: $db,
            $table: $db.favorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> playlistEntriesRefs<T extends Object>(
    Expression<T> Function($$PlaylistEntriesTableAnnotationComposer a) f,
  ) {
    final $$PlaylistEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistEntries,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.playlistEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> playEventsRefs<T extends Object>(
    Expression<T> Function($$PlayEventsTableAnnotationComposer a) f,
  ) {
    final $$PlayEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playEvents,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.playEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> lyricsLinksRefs<T extends Object>(
    Expression<T> Function($$LyricsLinksTableAnnotationComposer a) f,
  ) {
    final $$LyricsLinksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lyricsLinks,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LyricsLinksTableAnnotationComposer(
            $db: $db,
            $table: $db.lyricsLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TracksTableTableManager
    extends
        RootTableManager<
          _$ZemaDatabase,
          $TracksTable,
          TrackRow,
          $$TracksTableFilterComposer,
          $$TracksTableOrderingComposer,
          $$TracksTableAnnotationComposer,
          $$TracksTableCreateCompanionBuilder,
          $$TracksTableUpdateCompanionBuilder,
          (TrackRow, $$TracksTableReferences),
          TrackRow,
          PrefetchHooks Function({
            bool hiddenTracksRefs,
            bool favoritesRefs,
            bool playlistEntriesRefs,
            bool playEventsRefs,
            bool lyricsLinksRefs,
          })
        > {
  $$TracksTableTableManager(_$ZemaDatabase db, $TracksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> mediaStoreId = const Value.absent(),
                Value<String> uri = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String> folder = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> artist = const Value.absent(),
                Value<String?> album = const Value.absent(),
                Value<String?> albumArtist = const Value.absent(),
                Value<int?> trackNumber = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<DateTime> dateAdded = const Value.absent(),
                Value<bool> missing = const Value.absent(),
              }) => TracksCompanion(
                id: id,
                mediaStoreId: mediaStoreId,
                uri: uri,
                path: path,
                folder: folder,
                title: title,
                artist: artist,
                album: album,
                albumArtist: albumArtist,
                trackNumber: trackNumber,
                year: year,
                durationMs: durationMs,
                sizeBytes: sizeBytes,
                dateAdded: dateAdded,
                missing: missing,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int mediaStoreId,
                required String uri,
                required String path,
                required String folder,
                required String title,
                Value<String?> artist = const Value.absent(),
                Value<String?> album = const Value.absent(),
                Value<String?> albumArtist = const Value.absent(),
                Value<int?> trackNumber = const Value.absent(),
                Value<int?> year = const Value.absent(),
                required int durationMs,
                required int sizeBytes,
                required DateTime dateAdded,
                Value<bool> missing = const Value.absent(),
              }) => TracksCompanion.insert(
                id: id,
                mediaStoreId: mediaStoreId,
                uri: uri,
                path: path,
                folder: folder,
                title: title,
                artist: artist,
                album: album,
                albumArtist: albumArtist,
                trackNumber: trackNumber,
                year: year,
                durationMs: durationMs,
                sizeBytes: sizeBytes,
                dateAdded: dateAdded,
                missing: missing,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TracksTable, TrackRow>(table),
                  $$TracksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                hiddenTracksRefs = false,
                favoritesRefs = false,
                playlistEntriesRefs = false,
                playEventsRefs = false,
                lyricsLinksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (hiddenTracksRefs) db.hiddenTracks,
                    if (favoritesRefs) db.favorites,
                    if (playlistEntriesRefs) db.playlistEntries,
                    if (playEventsRefs) db.playEvents,
                    if (lyricsLinksRefs) db.lyricsLinks,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (hiddenTracksRefs)
                        await $_getPrefetchedDataByColumns<
                          TrackRow,
                          $TracksTable,
                          HiddenTrackRow,
                          $HiddenTracksTable
                        >(
                          currentTable: table,
                          referencedTable: $$TracksTableReferences
                              ._hiddenTracksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TracksTableReferences(
                                db,
                                table,
                                p0,
                              ).hiddenTracksRefs,
                          currentColumn: 'id',
                          referencedColumn: 'track_id',
                          typedResults: items,
                        ),
                      if (favoritesRefs)
                        await $_getPrefetchedDataByColumns<
                          TrackRow,
                          $TracksTable,
                          FavoriteRow,
                          $FavoritesTable
                        >(
                          currentTable: table,
                          referencedTable: $$TracksTableReferences
                              ._favoritesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TracksTableReferences(
                                db,
                                table,
                                p0,
                              ).favoritesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'track_id',
                          typedResults: items,
                        ),
                      if (playlistEntriesRefs)
                        await $_getPrefetchedDataByColumns<
                          TrackRow,
                          $TracksTable,
                          PlaylistEntryRow,
                          $PlaylistEntriesTable
                        >(
                          currentTable: table,
                          referencedTable: $$TracksTableReferences
                              ._playlistEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TracksTableReferences(
                                db,
                                table,
                                p0,
                              ).playlistEntriesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'track_id',
                          typedResults: items,
                        ),
                      if (playEventsRefs)
                        await $_getPrefetchedDataByColumns<
                          TrackRow,
                          $TracksTable,
                          PlayEventRow,
                          $PlayEventsTable
                        >(
                          currentTable: table,
                          referencedTable: $$TracksTableReferences
                              ._playEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TracksTableReferences(
                                db,
                                table,
                                p0,
                              ).playEventsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'track_id',
                          typedResults: items,
                        ),
                      if (lyricsLinksRefs)
                        await $_getPrefetchedDataByColumns<
                          TrackRow,
                          $TracksTable,
                          LyricsLinkRow,
                          $LyricsLinksTable
                        >(
                          currentTable: table,
                          referencedTable: $$TracksTableReferences
                              ._lyricsLinksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TracksTableReferences(
                                db,
                                table,
                                p0,
                              ).lyricsLinksRefs,
                          currentColumn: 'id',
                          referencedColumn: 'track_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TracksTableProcessedTableManager =
    ProcessedTableManager<
      _$ZemaDatabase,
      $TracksTable,
      TrackRow,
      $$TracksTableFilterComposer,
      $$TracksTableOrderingComposer,
      $$TracksTableAnnotationComposer,
      $$TracksTableCreateCompanionBuilder,
      $$TracksTableUpdateCompanionBuilder,
      (TrackRow, $$TracksTableReferences),
      TrackRow,
      PrefetchHooks Function({
        bool hiddenTracksRefs,
        bool favoritesRefs,
        bool playlistEntriesRefs,
        bool playEventsRefs,
        bool lyricsLinksRefs,
      })
    >;
typedef $$HiddenFoldersTableCreateCompanionBuilder =
    HiddenFoldersCompanion Function({
      required String path,
      required DateTime hiddenAt,
      Value<int> rowid,
    });
typedef $$HiddenFoldersTableUpdateCompanionBuilder =
    HiddenFoldersCompanion Function({
      Value<String> path,
      Value<DateTime> hiddenAt,
      Value<int> rowid,
    });

class $$HiddenFoldersTableFilterComposer
    extends Composer<_$ZemaDatabase, $HiddenFoldersTable> {
  $$HiddenFoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get hiddenAt => $composableBuilder(
    column: $table.hiddenAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HiddenFoldersTableOrderingComposer
    extends Composer<_$ZemaDatabase, $HiddenFoldersTable> {
  $$HiddenFoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get hiddenAt => $composableBuilder(
    column: $table.hiddenAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HiddenFoldersTableAnnotationComposer
    extends Composer<_$ZemaDatabase, $HiddenFoldersTable> {
  $$HiddenFoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<DateTime> get hiddenAt =>
      $composableBuilder(column: $table.hiddenAt, builder: (column) => column);
}

class $$HiddenFoldersTableTableManager
    extends
        RootTableManager<
          _$ZemaDatabase,
          $HiddenFoldersTable,
          HiddenFolderRow,
          $$HiddenFoldersTableFilterComposer,
          $$HiddenFoldersTableOrderingComposer,
          $$HiddenFoldersTableAnnotationComposer,
          $$HiddenFoldersTableCreateCompanionBuilder,
          $$HiddenFoldersTableUpdateCompanionBuilder,
          (
            HiddenFolderRow,
            BaseReferences<
              _$ZemaDatabase,
              $HiddenFoldersTable,
              HiddenFolderRow
            >,
          ),
          HiddenFolderRow,
          PrefetchHooks Function()
        > {
  $$HiddenFoldersTableTableManager(_$ZemaDatabase db, $HiddenFoldersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HiddenFoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HiddenFoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HiddenFoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> path = const Value.absent(),
                Value<DateTime> hiddenAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HiddenFoldersCompanion(
                path: path,
                hiddenAt: hiddenAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String path,
                required DateTime hiddenAt,
                Value<int> rowid = const Value.absent(),
              }) => HiddenFoldersCompanion.insert(
                path: path,
                hiddenAt: hiddenAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HiddenFoldersTable, HiddenFolderRow>(table),
                  BaseReferences<
                    _$ZemaDatabase,
                    $HiddenFoldersTable,
                    HiddenFolderRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HiddenFoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$ZemaDatabase,
      $HiddenFoldersTable,
      HiddenFolderRow,
      $$HiddenFoldersTableFilterComposer,
      $$HiddenFoldersTableOrderingComposer,
      $$HiddenFoldersTableAnnotationComposer,
      $$HiddenFoldersTableCreateCompanionBuilder,
      $$HiddenFoldersTableUpdateCompanionBuilder,
      (
        HiddenFolderRow,
        BaseReferences<_$ZemaDatabase, $HiddenFoldersTable, HiddenFolderRow>,
      ),
      HiddenFolderRow,
      PrefetchHooks Function()
    >;
typedef $$HiddenTracksTableCreateCompanionBuilder =
    HiddenTracksCompanion Function({
      Value<int> trackId,
      required DateTime hiddenAt,
    });
typedef $$HiddenTracksTableUpdateCompanionBuilder =
    HiddenTracksCompanion Function({
      Value<int> trackId,
      Value<DateTime> hiddenAt,
    });

final class $$HiddenTracksTableReferences
    extends BaseReferences<_$ZemaDatabase, $HiddenTracksTable, HiddenTrackRow> {
  $$HiddenTracksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TracksTable _trackIdTable(_$ZemaDatabase db) =>
      db.tracks.createAlias('hidden_tracks__track_id__tracks__id');

  $$TracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<int>('track_id')!;

    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HiddenTracksTableFilterComposer
    extends Composer<_$ZemaDatabase, $HiddenTracksTable> {
  $$HiddenTracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get hiddenAt => $composableBuilder(
    column: $table.hiddenAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TracksTableFilterComposer get trackId {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HiddenTracksTableOrderingComposer
    extends Composer<_$ZemaDatabase, $HiddenTracksTable> {
  $$HiddenTracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get hiddenAt => $composableBuilder(
    column: $table.hiddenAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TracksTableOrderingComposer get trackId {
    final $$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableOrderingComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HiddenTracksTableAnnotationComposer
    extends Composer<_$ZemaDatabase, $HiddenTracksTable> {
  $$HiddenTracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get hiddenAt =>
      $composableBuilder(column: $table.hiddenAt, builder: (column) => column);

  $$TracksTableAnnotationComposer get trackId {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HiddenTracksTableTableManager
    extends
        RootTableManager<
          _$ZemaDatabase,
          $HiddenTracksTable,
          HiddenTrackRow,
          $$HiddenTracksTableFilterComposer,
          $$HiddenTracksTableOrderingComposer,
          $$HiddenTracksTableAnnotationComposer,
          $$HiddenTracksTableCreateCompanionBuilder,
          $$HiddenTracksTableUpdateCompanionBuilder,
          (HiddenTrackRow, $$HiddenTracksTableReferences),
          HiddenTrackRow,
          PrefetchHooks Function({bool trackId})
        > {
  $$HiddenTracksTableTableManager(_$ZemaDatabase db, $HiddenTracksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HiddenTracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HiddenTracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HiddenTracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> trackId = const Value.absent(),
            Value<DateTime> hiddenAt = const Value.absent(),
          }) => HiddenTracksCompanion(trackId: trackId, hiddenAt: hiddenAt),
          createCompanionCallback:
              ({
                Value<int> trackId = const Value.absent(),
                required DateTime hiddenAt,
              }) => HiddenTracksCompanion.insert(
                trackId: trackId,
                hiddenAt: hiddenAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HiddenTracksTable, HiddenTrackRow>(table),
                  $$HiddenTracksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({trackId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (trackId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.trackId,
                        referencedTable: $$HiddenTracksTableReferences
                            ._trackIdTable(db),
                        referencedColumn: $$HiddenTracksTableReferences
                            ._trackIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HiddenTracksTableProcessedTableManager =
    ProcessedTableManager<
      _$ZemaDatabase,
      $HiddenTracksTable,
      HiddenTrackRow,
      $$HiddenTracksTableFilterComposer,
      $$HiddenTracksTableOrderingComposer,
      $$HiddenTracksTableAnnotationComposer,
      $$HiddenTracksTableCreateCompanionBuilder,
      $$HiddenTracksTableUpdateCompanionBuilder,
      (HiddenTrackRow, $$HiddenTracksTableReferences),
      HiddenTrackRow,
      PrefetchHooks Function({bool trackId})
    >;
typedef $$FavoritesTableCreateCompanionBuilder = FavoritesCompanion Function({
  Value<int> trackId,
  required DateTime addedAt,
});
typedef $$FavoritesTableUpdateCompanionBuilder = FavoritesCompanion Function({
  Value<int> trackId,
  Value<DateTime> addedAt,
});

final class $$FavoritesTableReferences
    extends BaseReferences<_$ZemaDatabase, $FavoritesTable, FavoriteRow> {
  $$FavoritesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TracksTable _trackIdTable(_$ZemaDatabase db) =>
      db.tracks.createAlias('favorites__track_id__tracks__id');

  $$TracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<int>('track_id')!;

    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FavoritesTableFilterComposer
    extends Composer<_$ZemaDatabase, $FavoritesTable> {
  $$FavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TracksTableFilterComposer get trackId {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoritesTableOrderingComposer
    extends Composer<_$ZemaDatabase, $FavoritesTable> {
  $$FavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TracksTableOrderingComposer get trackId {
    final $$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableOrderingComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoritesTableAnnotationComposer
    extends Composer<_$ZemaDatabase, $FavoritesTable> {
  $$FavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  $$TracksTableAnnotationComposer get trackId {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoritesTableTableManager
    extends
        RootTableManager<
          _$ZemaDatabase,
          $FavoritesTable,
          FavoriteRow,
          $$FavoritesTableFilterComposer,
          $$FavoritesTableOrderingComposer,
          $$FavoritesTableAnnotationComposer,
          $$FavoritesTableCreateCompanionBuilder,
          $$FavoritesTableUpdateCompanionBuilder,
          (FavoriteRow, $$FavoritesTableReferences),
          FavoriteRow,
          PrefetchHooks Function({bool trackId})
        > {
  $$FavoritesTableTableManager(_$ZemaDatabase db, $FavoritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> trackId = const Value.absent(),
            Value<DateTime> addedAt = const Value.absent(),
          }) => FavoritesCompanion(trackId: trackId, addedAt: addedAt),
          createCompanionCallback: ({
            Value<int> trackId = const Value.absent(),
            required DateTime addedAt,
          }) => FavoritesCompanion.insert(trackId: trackId, addedAt: addedAt),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FavoritesTable, FavoriteRow>(table),
                  $$FavoritesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({trackId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (trackId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.trackId,
                        referencedTable: $$FavoritesTableReferences
                            ._trackIdTable(db),
                        referencedColumn: $$FavoritesTableReferences
                            ._trackIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FavoritesTableProcessedTableManager =
    ProcessedTableManager<
      _$ZemaDatabase,
      $FavoritesTable,
      FavoriteRow,
      $$FavoritesTableFilterComposer,
      $$FavoritesTableOrderingComposer,
      $$FavoritesTableAnnotationComposer,
      $$FavoritesTableCreateCompanionBuilder,
      $$FavoritesTableUpdateCompanionBuilder,
      (FavoriteRow, $$FavoritesTableReferences),
      FavoriteRow,
      PrefetchHooks Function({bool trackId})
    >;
typedef $$PlaylistsTableCreateCompanionBuilder = PlaylistsCompanion Function({
  Value<int> id,
  required String name,
  required String nameKey,
  Value<String?> description,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$PlaylistsTableUpdateCompanionBuilder = PlaylistsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> nameKey,
  Value<String?> description,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$PlaylistsTableReferences
    extends BaseReferences<_$ZemaDatabase, $PlaylistsTable, PlaylistRow> {
  $$PlaylistsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlaylistEntriesTable, List<PlaylistEntryRow>>
  _playlistEntriesRefsTable(_$ZemaDatabase db) => MultiTypedResultKey.fromTable(
    db.playlistEntries,
    aliasName: 'playlists__id__playlist_entries__playlist_id',
  );

  $$PlaylistEntriesTableProcessedTableManager get playlistEntriesRefs {
    final manager = $$PlaylistEntriesTableTableManager(
      $_db,
      $_db.playlistEntries,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _playlistEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlaylistsTableFilterComposer
    extends Composer<_$ZemaDatabase, $PlaylistsTable> {
  $$PlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameKey => $composableBuilder(
    column: $table.nameKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> playlistEntriesRefs(
    Expression<bool> Function($$PlaylistEntriesTableFilterComposer f) f,
  ) {
    final $$PlaylistEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistEntries,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistEntriesTableFilterComposer(
            $db: $db,
            $table: $db.playlistEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistsTableOrderingComposer
    extends Composer<_$ZemaDatabase, $PlaylistsTable> {
  $$PlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameKey => $composableBuilder(
    column: $table.nameKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaylistsTableAnnotationComposer
    extends Composer<_$ZemaDatabase, $PlaylistsTable> {
  $$PlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get nameKey =>
      $composableBuilder(column: $table.nameKey, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> playlistEntriesRefs<T extends Object>(
    Expression<T> Function($$PlaylistEntriesTableAnnotationComposer a) f,
  ) {
    final $$PlaylistEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistEntries,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.playlistEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistsTableTableManager
    extends
        RootTableManager<
          _$ZemaDatabase,
          $PlaylistsTable,
          PlaylistRow,
          $$PlaylistsTableFilterComposer,
          $$PlaylistsTableOrderingComposer,
          $$PlaylistsTableAnnotationComposer,
          $$PlaylistsTableCreateCompanionBuilder,
          $$PlaylistsTableUpdateCompanionBuilder,
          (PlaylistRow, $$PlaylistsTableReferences),
          PlaylistRow,
          PrefetchHooks Function({bool playlistEntriesRefs})
        > {
  $$PlaylistsTableTableManager(_$ZemaDatabase db, $PlaylistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> nameKey = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PlaylistsCompanion(
                id: id,
                name: name,
                nameKey: nameKey,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String nameKey,
                Value<String?> description = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => PlaylistsCompanion.insert(
                id: id,
                name: name,
                nameKey: nameKey,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaylistsTable, PlaylistRow>(table),
                  $$PlaylistsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (playlistEntriesRefs) db.playlistEntries,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (playlistEntriesRefs)
                    await $_getPrefetchedDataByColumns<
                      PlaylistRow,
                      $PlaylistsTable,
                      PlaylistEntryRow,
                      $PlaylistEntriesTable
                    >(
                      currentTable: table,
                      referencedTable: $$PlaylistsTableReferences
                          ._playlistEntriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PlaylistsTableReferences(
                            db,
                            table,
                            p0,
                          ).playlistEntriesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'playlist_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$ZemaDatabase,
      $PlaylistsTable,
      PlaylistRow,
      $$PlaylistsTableFilterComposer,
      $$PlaylistsTableOrderingComposer,
      $$PlaylistsTableAnnotationComposer,
      $$PlaylistsTableCreateCompanionBuilder,
      $$PlaylistsTableUpdateCompanionBuilder,
      (PlaylistRow, $$PlaylistsTableReferences),
      PlaylistRow,
      PrefetchHooks Function({bool playlistEntriesRefs})
    >;
typedef $$PlaylistEntriesTableCreateCompanionBuilder =
    PlaylistEntriesCompanion Function({
      required int playlistId,
      required int trackId,
      required int position,
      Value<int> rowid,
    });
typedef $$PlaylistEntriesTableUpdateCompanionBuilder =
    PlaylistEntriesCompanion Function({
      Value<int> playlistId,
      Value<int> trackId,
      Value<int> position,
      Value<int> rowid,
    });

final class $$PlaylistEntriesTableReferences
    extends
        BaseReferences<
          _$ZemaDatabase,
          $PlaylistEntriesTable,
          PlaylistEntryRow
        > {
  $$PlaylistEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlaylistsTable _playlistIdTable(_$ZemaDatabase db) =>
      db.playlists.createAlias('playlist_entries__playlist_id__playlists__id');

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<int>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager(
      $_db,
      $_db.playlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TracksTable _trackIdTable(_$ZemaDatabase db) =>
      db.tracks.createAlias('playlist_entries__track_id__tracks__id');

  $$TracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<int>('track_id')!;

    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlaylistEntriesTableFilterComposer
    extends Composer<_$ZemaDatabase, $PlaylistEntriesTable> {
  $$PlaylistEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TracksTableFilterComposer get trackId {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistEntriesTableOrderingComposer
    extends Composer<_$ZemaDatabase, $PlaylistEntriesTable> {
  $$PlaylistEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TracksTableOrderingComposer get trackId {
    final $$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableOrderingComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistEntriesTableAnnotationComposer
    extends Composer<_$ZemaDatabase, $PlaylistEntriesTable> {
  $$PlaylistEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TracksTableAnnotationComposer get trackId {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistEntriesTableTableManager
    extends
        RootTableManager<
          _$ZemaDatabase,
          $PlaylistEntriesTable,
          PlaylistEntryRow,
          $$PlaylistEntriesTableFilterComposer,
          $$PlaylistEntriesTableOrderingComposer,
          $$PlaylistEntriesTableAnnotationComposer,
          $$PlaylistEntriesTableCreateCompanionBuilder,
          $$PlaylistEntriesTableUpdateCompanionBuilder,
          (PlaylistEntryRow, $$PlaylistEntriesTableReferences),
          PlaylistEntryRow,
          PrefetchHooks Function({bool playlistId, bool trackId})
        > {
  $$PlaylistEntriesTableTableManager(
    _$ZemaDatabase db,
    $PlaylistEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> playlistId = const Value.absent(),
                Value<int> trackId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistEntriesCompanion(
                playlistId: playlistId,
                trackId: trackId,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int playlistId,
                required int trackId,
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => PlaylistEntriesCompanion.insert(
                playlistId: playlistId,
                trackId: trackId,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaylistEntriesTable, PlaylistEntryRow>(table),
                  $$PlaylistEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistId = false, trackId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (playlistId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.playlistId,
                        referencedTable: $$PlaylistEntriesTableReferences
                            ._playlistIdTable(db),
                        referencedColumn: $$PlaylistEntriesTableReferences
                            ._playlistIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (trackId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.trackId,
                        referencedTable: $$PlaylistEntriesTableReferences
                            ._trackIdTable(db),
                        referencedColumn: $$PlaylistEntriesTableReferences
                            ._trackIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlaylistEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$ZemaDatabase,
      $PlaylistEntriesTable,
      PlaylistEntryRow,
      $$PlaylistEntriesTableFilterComposer,
      $$PlaylistEntriesTableOrderingComposer,
      $$PlaylistEntriesTableAnnotationComposer,
      $$PlaylistEntriesTableCreateCompanionBuilder,
      $$PlaylistEntriesTableUpdateCompanionBuilder,
      (PlaylistEntryRow, $$PlaylistEntriesTableReferences),
      PlaylistEntryRow,
      PrefetchHooks Function({bool playlistId, bool trackId})
    >;
typedef $$PlayEventsTableCreateCompanionBuilder = PlayEventsCompanion Function({
  Value<int> id,
  required int trackId,
  required DateTime playedAt,
});
typedef $$PlayEventsTableUpdateCompanionBuilder = PlayEventsCompanion Function({
  Value<int> id,
  Value<int> trackId,
  Value<DateTime> playedAt,
});

final class $$PlayEventsTableReferences
    extends BaseReferences<_$ZemaDatabase, $PlayEventsTable, PlayEventRow> {
  $$PlayEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TracksTable _trackIdTable(_$ZemaDatabase db) =>
      db.tracks.createAlias('play_events__track_id__tracks__id');

  $$TracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<int>('track_id')!;

    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlayEventsTableFilterComposer
    extends Composer<_$ZemaDatabase, $PlayEventsTable> {
  $$PlayEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TracksTableFilterComposer get trackId {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayEventsTableOrderingComposer
    extends Composer<_$ZemaDatabase, $PlayEventsTable> {
  $$PlayEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TracksTableOrderingComposer get trackId {
    final $$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableOrderingComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayEventsTableAnnotationComposer
    extends Composer<_$ZemaDatabase, $PlayEventsTable> {
  $$PlayEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get playedAt =>
      $composableBuilder(column: $table.playedAt, builder: (column) => column);

  $$TracksTableAnnotationComposer get trackId {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayEventsTableTableManager
    extends
        RootTableManager<
          _$ZemaDatabase,
          $PlayEventsTable,
          PlayEventRow,
          $$PlayEventsTableFilterComposer,
          $$PlayEventsTableOrderingComposer,
          $$PlayEventsTableAnnotationComposer,
          $$PlayEventsTableCreateCompanionBuilder,
          $$PlayEventsTableUpdateCompanionBuilder,
          (PlayEventRow, $$PlayEventsTableReferences),
          PlayEventRow,
          PrefetchHooks Function({bool trackId})
        > {
  $$PlayEventsTableTableManager(_$ZemaDatabase db, $PlayEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> trackId = const Value.absent(),
                Value<DateTime> playedAt = const Value.absent(),
              }) => PlayEventsCompanion(
                id: id,
                trackId: trackId,
                playedAt: playedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int trackId,
                required DateTime playedAt,
              }) => PlayEventsCompanion.insert(
                id: id,
                trackId: trackId,
                playedAt: playedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlayEventsTable, PlayEventRow>(table),
                  $$PlayEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({trackId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (trackId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.trackId,
                        referencedTable: $$PlayEventsTableReferences
                            ._trackIdTable(db),
                        referencedColumn: $$PlayEventsTableReferences
                            ._trackIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlayEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$ZemaDatabase,
      $PlayEventsTable,
      PlayEventRow,
      $$PlayEventsTableFilterComposer,
      $$PlayEventsTableOrderingComposer,
      $$PlayEventsTableAnnotationComposer,
      $$PlayEventsTableCreateCompanionBuilder,
      $$PlayEventsTableUpdateCompanionBuilder,
      (PlayEventRow, $$PlayEventsTableReferences),
      PlayEventRow,
      PrefetchHooks Function({bool trackId})
    >;
typedef $$LyricsLinksTableCreateCompanionBuilder =
    LyricsLinksCompanion Function({
      Value<int> trackId,
      Value<String?> songId,
      required bool manual,
      required DateTime linkedAt,
    });
typedef $$LyricsLinksTableUpdateCompanionBuilder =
    LyricsLinksCompanion Function({
      Value<int> trackId,
      Value<String?> songId,
      Value<bool> manual,
      Value<DateTime> linkedAt,
    });

final class $$LyricsLinksTableReferences
    extends BaseReferences<_$ZemaDatabase, $LyricsLinksTable, LyricsLinkRow> {
  $$LyricsLinksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TracksTable _trackIdTable(_$ZemaDatabase db) =>
      db.tracks.createAlias('lyrics_links__track_id__tracks__id');

  $$TracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<int>('track_id')!;

    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LyricsLinksTableFilterComposer
    extends Composer<_$ZemaDatabase, $LyricsLinksTable> {
  $$LyricsLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get songId => $composableBuilder(
    column: $table.songId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get manual => $composableBuilder(
    column: $table.manual,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get linkedAt => $composableBuilder(
    column: $table.linkedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TracksTableFilterComposer get trackId {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LyricsLinksTableOrderingComposer
    extends Composer<_$ZemaDatabase, $LyricsLinksTable> {
  $$LyricsLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get songId => $composableBuilder(
    column: $table.songId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get manual => $composableBuilder(
    column: $table.manual,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get linkedAt => $composableBuilder(
    column: $table.linkedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TracksTableOrderingComposer get trackId {
    final $$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableOrderingComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LyricsLinksTableAnnotationComposer
    extends Composer<_$ZemaDatabase, $LyricsLinksTable> {
  $$LyricsLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get songId =>
      $composableBuilder(column: $table.songId, builder: (column) => column);

  GeneratedColumn<bool> get manual =>
      $composableBuilder(column: $table.manual, builder: (column) => column);

  GeneratedColumn<DateTime> get linkedAt =>
      $composableBuilder(column: $table.linkedAt, builder: (column) => column);

  $$TracksTableAnnotationComposer get trackId {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LyricsLinksTableTableManager
    extends
        RootTableManager<
          _$ZemaDatabase,
          $LyricsLinksTable,
          LyricsLinkRow,
          $$LyricsLinksTableFilterComposer,
          $$LyricsLinksTableOrderingComposer,
          $$LyricsLinksTableAnnotationComposer,
          $$LyricsLinksTableCreateCompanionBuilder,
          $$LyricsLinksTableUpdateCompanionBuilder,
          (LyricsLinkRow, $$LyricsLinksTableReferences),
          LyricsLinkRow,
          PrefetchHooks Function({bool trackId})
        > {
  $$LyricsLinksTableTableManager(_$ZemaDatabase db, $LyricsLinksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LyricsLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LyricsLinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LyricsLinksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> trackId = const Value.absent(),
                Value<String?> songId = const Value.absent(),
                Value<bool> manual = const Value.absent(),
                Value<DateTime> linkedAt = const Value.absent(),
              }) => LyricsLinksCompanion(
                trackId: trackId,
                songId: songId,
                manual: manual,
                linkedAt: linkedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> trackId = const Value.absent(),
                Value<String?> songId = const Value.absent(),
                required bool manual,
                required DateTime linkedAt,
              }) => LyricsLinksCompanion.insert(
                trackId: trackId,
                songId: songId,
                manual: manual,
                linkedAt: linkedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LyricsLinksTable, LyricsLinkRow>(table),
                  $$LyricsLinksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({trackId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (trackId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.trackId,
                        referencedTable: $$LyricsLinksTableReferences
                            ._trackIdTable(db),
                        referencedColumn: $$LyricsLinksTableReferences
                            ._trackIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LyricsLinksTableProcessedTableManager =
    ProcessedTableManager<
      _$ZemaDatabase,
      $LyricsLinksTable,
      LyricsLinkRow,
      $$LyricsLinksTableFilterComposer,
      $$LyricsLinksTableOrderingComposer,
      $$LyricsLinksTableAnnotationComposer,
      $$LyricsLinksTableCreateCompanionBuilder,
      $$LyricsLinksTableUpdateCompanionBuilder,
      (LyricsLinkRow, $$LyricsLinksTableReferences),
      LyricsLinkRow,
      PrefetchHooks Function({bool trackId})
    >;
typedef $$CatalogSongsTableCreateCompanionBuilder =
    CatalogSongsCompanion Function({
      required String id,
      required String title,
      Value<String?> transliteration,
      Value<String?> artist,
      Value<String?> album,
      required bool synced,
      required int version,
      required DateTime approvedAt,
      Value<int> rowid,
    });
typedef $$CatalogSongsTableUpdateCompanionBuilder =
    CatalogSongsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> transliteration,
      Value<String?> artist,
      Value<String?> album,
      Value<bool> synced,
      Value<int> version,
      Value<DateTime> approvedAt,
      Value<int> rowid,
    });

class $$CatalogSongsTableFilterComposer
    extends Composer<_$ZemaDatabase, $CatalogSongsTable> {
  $$CatalogSongsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transliteration => $composableBuilder(
    column: $table.transliteration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get approvedAt => $composableBuilder(
    column: $table.approvedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CatalogSongsTableOrderingComposer
    extends Composer<_$ZemaDatabase, $CatalogSongsTable> {
  $$CatalogSongsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transliteration => $composableBuilder(
    column: $table.transliteration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get approvedAt => $composableBuilder(
    column: $table.approvedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CatalogSongsTableAnnotationComposer
    extends Composer<_$ZemaDatabase, $CatalogSongsTable> {
  $$CatalogSongsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get transliteration => $composableBuilder(
    column: $table.transliteration,
    builder: (column) => column,
  );

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get approvedAt => $composableBuilder(
    column: $table.approvedAt,
    builder: (column) => column,
  );
}

class $$CatalogSongsTableTableManager
    extends
        RootTableManager<
          _$ZemaDatabase,
          $CatalogSongsTable,
          CatalogSongRow,
          $$CatalogSongsTableFilterComposer,
          $$CatalogSongsTableOrderingComposer,
          $$CatalogSongsTableAnnotationComposer,
          $$CatalogSongsTableCreateCompanionBuilder,
          $$CatalogSongsTableUpdateCompanionBuilder,
          (
            CatalogSongRow,
            BaseReferences<_$ZemaDatabase, $CatalogSongsTable, CatalogSongRow>,
          ),
          CatalogSongRow,
          PrefetchHooks Function()
        > {
  $$CatalogSongsTableTableManager(_$ZemaDatabase db, $CatalogSongsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CatalogSongsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CatalogSongsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CatalogSongsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> transliteration = const Value.absent(),
                Value<String?> artist = const Value.absent(),
                Value<String?> album = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime> approvedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatalogSongsCompanion(
                id: id,
                title: title,
                transliteration: transliteration,
                artist: artist,
                album: album,
                synced: synced,
                version: version,
                approvedAt: approvedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> transliteration = const Value.absent(),
                Value<String?> artist = const Value.absent(),
                Value<String?> album = const Value.absent(),
                required bool synced,
                required int version,
                required DateTime approvedAt,
                Value<int> rowid = const Value.absent(),
              }) => CatalogSongsCompanion.insert(
                id: id,
                title: title,
                transliteration: transliteration,
                artist: artist,
                album: album,
                synced: synced,
                version: version,
                approvedAt: approvedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CatalogSongsTable, CatalogSongRow>(table),
                  BaseReferences<
                    _$ZemaDatabase,
                    $CatalogSongsTable,
                    CatalogSongRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CatalogSongsTableProcessedTableManager =
    ProcessedTableManager<
      _$ZemaDatabase,
      $CatalogSongsTable,
      CatalogSongRow,
      $$CatalogSongsTableFilterComposer,
      $$CatalogSongsTableOrderingComposer,
      $$CatalogSongsTableAnnotationComposer,
      $$CatalogSongsTableCreateCompanionBuilder,
      $$CatalogSongsTableUpdateCompanionBuilder,
      (
        CatalogSongRow,
        BaseReferences<_$ZemaDatabase, $CatalogSongsTable, CatalogSongRow>,
      ),
      CatalogSongRow,
      PrefetchHooks Function()
    >;
typedef $$CachedSongsTableCreateCompanionBuilder =
    CachedSongsCompanion Function({
      required String id,
      required int version,
      required String document,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedSongsTableUpdateCompanionBuilder =
    CachedSongsCompanion Function({
      Value<String> id,
      Value<int> version,
      Value<String> document,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedSongsTableFilterComposer
    extends Composer<_$ZemaDatabase, $CachedSongsTable> {
  $$CachedSongsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get document => $composableBuilder(
    column: $table.document,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedSongsTableOrderingComposer
    extends Composer<_$ZemaDatabase, $CachedSongsTable> {
  $$CachedSongsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get document => $composableBuilder(
    column: $table.document,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedSongsTableAnnotationComposer
    extends Composer<_$ZemaDatabase, $CachedSongsTable> {
  $$CachedSongsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get document =>
      $composableBuilder(column: $table.document, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedSongsTableTableManager
    extends
        RootTableManager<
          _$ZemaDatabase,
          $CachedSongsTable,
          CachedSongRow,
          $$CachedSongsTableFilterComposer,
          $$CachedSongsTableOrderingComposer,
          $$CachedSongsTableAnnotationComposer,
          $$CachedSongsTableCreateCompanionBuilder,
          $$CachedSongsTableUpdateCompanionBuilder,
          (
            CachedSongRow,
            BaseReferences<_$ZemaDatabase, $CachedSongsTable, CachedSongRow>,
          ),
          CachedSongRow,
          PrefetchHooks Function()
        > {
  $$CachedSongsTableTableManager(_$ZemaDatabase db, $CachedSongsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedSongsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedSongsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedSongsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> document = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedSongsCompanion(
                id: id,
                version: version,
                document: document,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int version,
                required String document,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedSongsCompanion.insert(
                id: id,
                version: version,
                document: document,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedSongsTable, CachedSongRow>(table),
                  BaseReferences<
                    _$ZemaDatabase,
                    $CachedSongsTable,
                    CachedSongRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedSongsTableProcessedTableManager =
    ProcessedTableManager<
      _$ZemaDatabase,
      $CachedSongsTable,
      CachedSongRow,
      $$CachedSongsTableFilterComposer,
      $$CachedSongsTableOrderingComposer,
      $$CachedSongsTableAnnotationComposer,
      $$CachedSongsTableCreateCompanionBuilder,
      $$CachedSongsTableUpdateCompanionBuilder,
      (
        CachedSongRow,
        BaseReferences<_$ZemaDatabase, $CachedSongsTable, CachedSongRow>,
      ),
      CachedSongRow,
      PrefetchHooks Function()
    >;
typedef $$QueuedReportsTableCreateCompanionBuilder =
    QueuedReportsCompanion Function({
      Value<int> id,
      required String reportId,
      required String songId,
      Value<String?> recordingId,
      required String reason,
      Value<String?> note,
      required DateTime createdAt,
    });
typedef $$QueuedReportsTableUpdateCompanionBuilder =
    QueuedReportsCompanion Function({
      Value<int> id,
      Value<String> reportId,
      Value<String> songId,
      Value<String?> recordingId,
      Value<String> reason,
      Value<String?> note,
      Value<DateTime> createdAt,
    });

class $$QueuedReportsTableFilterComposer
    extends Composer<_$ZemaDatabase, $QueuedReportsTable> {
  $$QueuedReportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reportId => $composableBuilder(
    column: $table.reportId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get songId => $composableBuilder(
    column: $table.songId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordingId => $composableBuilder(
    column: $table.recordingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QueuedReportsTableOrderingComposer
    extends Composer<_$ZemaDatabase, $QueuedReportsTable> {
  $$QueuedReportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reportId => $composableBuilder(
    column: $table.reportId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get songId => $composableBuilder(
    column: $table.songId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordingId => $composableBuilder(
    column: $table.recordingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QueuedReportsTableAnnotationComposer
    extends Composer<_$ZemaDatabase, $QueuedReportsTable> {
  $$QueuedReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get reportId =>
      $composableBuilder(column: $table.reportId, builder: (column) => column);

  GeneratedColumn<String> get songId =>
      $composableBuilder(column: $table.songId, builder: (column) => column);

  GeneratedColumn<String> get recordingId => $composableBuilder(
    column: $table.recordingId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$QueuedReportsTableTableManager
    extends
        RootTableManager<
          _$ZemaDatabase,
          $QueuedReportsTable,
          QueuedReportRow,
          $$QueuedReportsTableFilterComposer,
          $$QueuedReportsTableOrderingComposer,
          $$QueuedReportsTableAnnotationComposer,
          $$QueuedReportsTableCreateCompanionBuilder,
          $$QueuedReportsTableUpdateCompanionBuilder,
          (
            QueuedReportRow,
            BaseReferences<
              _$ZemaDatabase,
              $QueuedReportsTable,
              QueuedReportRow
            >,
          ),
          QueuedReportRow,
          PrefetchHooks Function()
        > {
  $$QueuedReportsTableTableManager(_$ZemaDatabase db, $QueuedReportsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QueuedReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QueuedReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QueuedReportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> reportId = const Value.absent(),
                Value<String> songId = const Value.absent(),
                Value<String?> recordingId = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => QueuedReportsCompanion(
                id: id,
                reportId: reportId,
                songId: songId,
                recordingId: recordingId,
                reason: reason,
                note: note,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String reportId,
                required String songId,
                Value<String?> recordingId = const Value.absent(),
                required String reason,
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
              }) => QueuedReportsCompanion.insert(
                id: id,
                reportId: reportId,
                songId: songId,
                recordingId: recordingId,
                reason: reason,
                note: note,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QueuedReportsTable, QueuedReportRow>(table),
                  BaseReferences<
                    _$ZemaDatabase,
                    $QueuedReportsTable,
                    QueuedReportRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QueuedReportsTableProcessedTableManager =
    ProcessedTableManager<
      _$ZemaDatabase,
      $QueuedReportsTable,
      QueuedReportRow,
      $$QueuedReportsTableFilterComposer,
      $$QueuedReportsTableOrderingComposer,
      $$QueuedReportsTableAnnotationComposer,
      $$QueuedReportsTableCreateCompanionBuilder,
      $$QueuedReportsTableUpdateCompanionBuilder,
      (
        QueuedReportRow,
        BaseReferences<_$ZemaDatabase, $QueuedReportsTable, QueuedReportRow>,
      ),
      QueuedReportRow,
      PrefetchHooks Function()
    >;
typedef $$UnmatchedEntriesTableCreateCompanionBuilder =
    UnmatchedEntriesCompanion Function({
      Value<int> id,
      required String kind,
      required String title,
      Value<String?> artist,
      Value<String?> album,
      required int durationMs,
      required String fileName,
      Value<DateTime?> addedAt,
      Value<String?> playlist,
      Value<int?> position,
      Value<String?> songId,
    });
typedef $$UnmatchedEntriesTableUpdateCompanionBuilder =
    UnmatchedEntriesCompanion Function({
      Value<int> id,
      Value<String> kind,
      Value<String> title,
      Value<String?> artist,
      Value<String?> album,
      Value<int> durationMs,
      Value<String> fileName,
      Value<DateTime?> addedAt,
      Value<String?> playlist,
      Value<int?> position,
      Value<String?> songId,
    });

class $$UnmatchedEntriesTableFilterComposer
    extends Composer<_$ZemaDatabase, $UnmatchedEntriesTable> {
  $$UnmatchedEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playlist => $composableBuilder(
    column: $table.playlist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get songId => $composableBuilder(
    column: $table.songId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UnmatchedEntriesTableOrderingComposer
    extends Composer<_$ZemaDatabase, $UnmatchedEntriesTable> {
  $$UnmatchedEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playlist => $composableBuilder(
    column: $table.playlist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get songId => $composableBuilder(
    column: $table.songId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UnmatchedEntriesTableAnnotationComposer
    extends Composer<_$ZemaDatabase, $UnmatchedEntriesTable> {
  $$UnmatchedEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<String> get playlist =>
      $composableBuilder(column: $table.playlist, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get songId =>
      $composableBuilder(column: $table.songId, builder: (column) => column);
}

class $$UnmatchedEntriesTableTableManager
    extends
        RootTableManager<
          _$ZemaDatabase,
          $UnmatchedEntriesTable,
          UnmatchedEntryRow,
          $$UnmatchedEntriesTableFilterComposer,
          $$UnmatchedEntriesTableOrderingComposer,
          $$UnmatchedEntriesTableAnnotationComposer,
          $$UnmatchedEntriesTableCreateCompanionBuilder,
          $$UnmatchedEntriesTableUpdateCompanionBuilder,
          (
            UnmatchedEntryRow,
            BaseReferences<
              _$ZemaDatabase,
              $UnmatchedEntriesTable,
              UnmatchedEntryRow
            >,
          ),
          UnmatchedEntryRow,
          PrefetchHooks Function()
        > {
  $$UnmatchedEntriesTableTableManager(
    _$ZemaDatabase db,
    $UnmatchedEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnmatchedEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UnmatchedEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UnmatchedEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> artist = const Value.absent(),
                Value<String?> album = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<DateTime?> addedAt = const Value.absent(),
                Value<String?> playlist = const Value.absent(),
                Value<int?> position = const Value.absent(),
                Value<String?> songId = const Value.absent(),
              }) => UnmatchedEntriesCompanion(
                id: id,
                kind: kind,
                title: title,
                artist: artist,
                album: album,
                durationMs: durationMs,
                fileName: fileName,
                addedAt: addedAt,
                playlist: playlist,
                position: position,
                songId: songId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String kind,
                required String title,
                Value<String?> artist = const Value.absent(),
                Value<String?> album = const Value.absent(),
                required int durationMs,
                required String fileName,
                Value<DateTime?> addedAt = const Value.absent(),
                Value<String?> playlist = const Value.absent(),
                Value<int?> position = const Value.absent(),
                Value<String?> songId = const Value.absent(),
              }) => UnmatchedEntriesCompanion.insert(
                id: id,
                kind: kind,
                title: title,
                artist: artist,
                album: album,
                durationMs: durationMs,
                fileName: fileName,
                addedAt: addedAt,
                playlist: playlist,
                position: position,
                songId: songId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UnmatchedEntriesTable, UnmatchedEntryRow>(table),
                  BaseReferences<
                    _$ZemaDatabase,
                    $UnmatchedEntriesTable,
                    UnmatchedEntryRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UnmatchedEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$ZemaDatabase,
      $UnmatchedEntriesTable,
      UnmatchedEntryRow,
      $$UnmatchedEntriesTableFilterComposer,
      $$UnmatchedEntriesTableOrderingComposer,
      $$UnmatchedEntriesTableAnnotationComposer,
      $$UnmatchedEntriesTableCreateCompanionBuilder,
      $$UnmatchedEntriesTableUpdateCompanionBuilder,
      (
        UnmatchedEntryRow,
        BaseReferences<
          _$ZemaDatabase,
          $UnmatchedEntriesTable,
          UnmatchedEntryRow
        >,
      ),
      UnmatchedEntryRow,
      PrefetchHooks Function()
    >;
typedef $$DraftsTableCreateCompanionBuilder = DraftsCompanion Function({
  Value<int> id,
  required String kind,
  required String step,
  required String title,
  required String draft,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$DraftsTableUpdateCompanionBuilder = DraftsCompanion Function({
  Value<int> id,
  Value<String> kind,
  Value<String> step,
  Value<String> title,
  Value<String> draft,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$DraftsTableFilterComposer
    extends Composer<_$ZemaDatabase, $DraftsTable> {
  $$DraftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get draft => $composableBuilder(
    column: $table.draft,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DraftsTableOrderingComposer
    extends Composer<_$ZemaDatabase, $DraftsTable> {
  $$DraftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get draft => $composableBuilder(
    column: $table.draft,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DraftsTableAnnotationComposer
    extends Composer<_$ZemaDatabase, $DraftsTable> {
  $$DraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get step =>
      $composableBuilder(column: $table.step, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get draft =>
      $composableBuilder(column: $table.draft, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DraftsTableTableManager
    extends
        RootTableManager<
          _$ZemaDatabase,
          $DraftsTable,
          DraftRow,
          $$DraftsTableFilterComposer,
          $$DraftsTableOrderingComposer,
          $$DraftsTableAnnotationComposer,
          $$DraftsTableCreateCompanionBuilder,
          $$DraftsTableUpdateCompanionBuilder,
          (DraftRow, BaseReferences<_$ZemaDatabase, $DraftsTable, DraftRow>),
          DraftRow,
          PrefetchHooks Function()
        > {
  $$DraftsTableTableManager(_$ZemaDatabase db, $DraftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> step = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> draft = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DraftsCompanion(
                id: id,
                kind: kind,
                step: step,
                title: title,
                draft: draft,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String kind,
                required String step,
                required String title,
                required String draft,
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => DraftsCompanion.insert(
                id: id,
                kind: kind,
                step: step,
                title: title,
                draft: draft,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DraftsTable, DraftRow>(table),
                  BaseReferences<_$ZemaDatabase, $DraftsTable, DraftRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$ZemaDatabase,
      $DraftsTable,
      DraftRow,
      $$DraftsTableFilterComposer,
      $$DraftsTableOrderingComposer,
      $$DraftsTableAnnotationComposer,
      $$DraftsTableCreateCompanionBuilder,
      $$DraftsTableUpdateCompanionBuilder,
      (DraftRow, BaseReferences<_$ZemaDatabase, $DraftsTable, DraftRow>),
      DraftRow,
      PrefetchHooks Function()
    >;
typedef $$OwnCopiesTableCreateCompanionBuilder = OwnCopiesCompanion Function({
  Value<int> id,
  required String contributionId,
  required String kind,
  required String song,
  Value<String?> recording,
  Value<String?> timing,
  Value<int?> trackId,
  Value<String?> audioPath,
  required DateTime submittedAt,
});
typedef $$OwnCopiesTableUpdateCompanionBuilder = OwnCopiesCompanion Function({
  Value<int> id,
  Value<String> contributionId,
  Value<String> kind,
  Value<String> song,
  Value<String?> recording,
  Value<String?> timing,
  Value<int?> trackId,
  Value<String?> audioPath,
  Value<DateTime> submittedAt,
});

class $$OwnCopiesTableFilterComposer
    extends Composer<_$ZemaDatabase, $OwnCopiesTable> {
  $$OwnCopiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contributionId => $composableBuilder(
    column: $table.contributionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get song => $composableBuilder(
    column: $table.song,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recording => $composableBuilder(
    column: $table.recording,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timing => $composableBuilder(
    column: $table.timing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioPath => $composableBuilder(
    column: $table.audioPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OwnCopiesTableOrderingComposer
    extends Composer<_$ZemaDatabase, $OwnCopiesTable> {
  $$OwnCopiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contributionId => $composableBuilder(
    column: $table.contributionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get song => $composableBuilder(
    column: $table.song,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recording => $composableBuilder(
    column: $table.recording,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timing => $composableBuilder(
    column: $table.timing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioPath => $composableBuilder(
    column: $table.audioPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OwnCopiesTableAnnotationComposer
    extends Composer<_$ZemaDatabase, $OwnCopiesTable> {
  $$OwnCopiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get contributionId => $composableBuilder(
    column: $table.contributionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get song =>
      $composableBuilder(column: $table.song, builder: (column) => column);

  GeneratedColumn<String> get recording =>
      $composableBuilder(column: $table.recording, builder: (column) => column);

  GeneratedColumn<String> get timing =>
      $composableBuilder(column: $table.timing, builder: (column) => column);

  GeneratedColumn<int> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<String> get audioPath =>
      $composableBuilder(column: $table.audioPath, builder: (column) => column);

  GeneratedColumn<DateTime> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => column,
  );
}

class $$OwnCopiesTableTableManager
    extends
        RootTableManager<
          _$ZemaDatabase,
          $OwnCopiesTable,
          OwnCopyRow,
          $$OwnCopiesTableFilterComposer,
          $$OwnCopiesTableOrderingComposer,
          $$OwnCopiesTableAnnotationComposer,
          $$OwnCopiesTableCreateCompanionBuilder,
          $$OwnCopiesTableUpdateCompanionBuilder,
          (
            OwnCopyRow,
            BaseReferences<_$ZemaDatabase, $OwnCopiesTable, OwnCopyRow>,
          ),
          OwnCopyRow,
          PrefetchHooks Function()
        > {
  $$OwnCopiesTableTableManager(_$ZemaDatabase db, $OwnCopiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OwnCopiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OwnCopiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OwnCopiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> contributionId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> song = const Value.absent(),
                Value<String?> recording = const Value.absent(),
                Value<String?> timing = const Value.absent(),
                Value<int?> trackId = const Value.absent(),
                Value<String?> audioPath = const Value.absent(),
                Value<DateTime> submittedAt = const Value.absent(),
              }) => OwnCopiesCompanion(
                id: id,
                contributionId: contributionId,
                kind: kind,
                song: song,
                recording: recording,
                timing: timing,
                trackId: trackId,
                audioPath: audioPath,
                submittedAt: submittedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String contributionId,
                required String kind,
                required String song,
                Value<String?> recording = const Value.absent(),
                Value<String?> timing = const Value.absent(),
                Value<int?> trackId = const Value.absent(),
                Value<String?> audioPath = const Value.absent(),
                required DateTime submittedAt,
              }) => OwnCopiesCompanion.insert(
                id: id,
                contributionId: contributionId,
                kind: kind,
                song: song,
                recording: recording,
                timing: timing,
                trackId: trackId,
                audioPath: audioPath,
                submittedAt: submittedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OwnCopiesTable, OwnCopyRow>(table),
                  BaseReferences<_$ZemaDatabase, $OwnCopiesTable, OwnCopyRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OwnCopiesTableProcessedTableManager =
    ProcessedTableManager<
      _$ZemaDatabase,
      $OwnCopiesTable,
      OwnCopyRow,
      $$OwnCopiesTableFilterComposer,
      $$OwnCopiesTableOrderingComposer,
      $$OwnCopiesTableAnnotationComposer,
      $$OwnCopiesTableCreateCompanionBuilder,
      $$OwnCopiesTableUpdateCompanionBuilder,
      (OwnCopyRow, BaseReferences<_$ZemaDatabase, $OwnCopiesTable, OwnCopyRow>),
      OwnCopyRow,
      PrefetchHooks Function()
    >;

class $ZemaDatabaseManager {
  final _$ZemaDatabase _db;
  $ZemaDatabaseManager(this._db);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db, _db.tracks);
  $$HiddenFoldersTableTableManager get hiddenFolders =>
      $$HiddenFoldersTableTableManager(_db, _db.hiddenFolders);
  $$HiddenTracksTableTableManager get hiddenTracks =>
      $$HiddenTracksTableTableManager(_db, _db.hiddenTracks);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db, _db.favorites);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db, _db.playlists);
  $$PlaylistEntriesTableTableManager get playlistEntries =>
      $$PlaylistEntriesTableTableManager(_db, _db.playlistEntries);
  $$PlayEventsTableTableManager get playEvents =>
      $$PlayEventsTableTableManager(_db, _db.playEvents);
  $$LyricsLinksTableTableManager get lyricsLinks =>
      $$LyricsLinksTableTableManager(_db, _db.lyricsLinks);
  $$CatalogSongsTableTableManager get catalogSongs =>
      $$CatalogSongsTableTableManager(_db, _db.catalogSongs);
  $$CachedSongsTableTableManager get cachedSongs =>
      $$CachedSongsTableTableManager(_db, _db.cachedSongs);
  $$QueuedReportsTableTableManager get queuedReports =>
      $$QueuedReportsTableTableManager(_db, _db.queuedReports);
  $$UnmatchedEntriesTableTableManager get unmatchedEntries =>
      $$UnmatchedEntriesTableTableManager(_db, _db.unmatchedEntries);
  $$DraftsTableTableManager get drafts =>
      $$DraftsTableTableManager(_db, _db.drafts);
  $$OwnCopiesTableTableManager get ownCopies =>
      $$OwnCopiesTableTableManager(_db, _db.ownCopies);
}
