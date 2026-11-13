import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/app/preferences_provider.dart';
import 'package:zema/app/routes.dart';
import 'package:zema/features/identify/application/shared_fingerprints.dart';
import 'package:zema/features/identify/data/audio_decoder.dart';
import 'package:zema/l10n/generated/app_localizations.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_contributions.dart';
import '../../helpers/fake_library.dart';
import '../../helpers/pump_app.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

/// Decodes every file to 20 s of noise; [unreadable] files to nothing.
class _Decoder implements AudioDecoder {
  final decoded = <String>[];
  final unreadable = <String>{};

  @override
  Future<DecodedAudio?> decode(
    String uri, {
    Duration maxLength = maxDecodedLength,
  }) async {
    decoded.add(uri);
    if (unreadable.contains(uri)) return null;
    final random = Random(1);
    final samples = ByteData(fingerprintSampleRate * 20 * 2);
    for (var i = 0; i < samples.lengthInBytes; i += 2) {
      samples.setInt16(i, random.nextInt(20000) - 10000, Endian.little);
    }
    return DecodedAudio(pcm16: samples.buffer.asUint8List());
  }

  @override
  Future<DecodeDevice?> device() async => null;
}

class _Catalog implements AudioCatalog {
  Set<String> missing = {};
  final shared = <String>[];
  ZemaFailure? failure;
  final asked = <List<String>>[];

  @override
  Future<List<CatalogAudioMatch>> identify(
    List<AudioFingerprint> queries, {
    required String installId,
    int limit = 3,
  }) async => const [];

  @override
  Future<List<OfflineFingerprintEntry>> offlineFingerprints() async => const [];

  @override
  Future<List<CatalogFingerprint>> fingerprints(
    List<String> recordingIds,
  ) async => const [];

  @override
  Future<Set<String>> missingFingerprints(List<String> recordingIds) async {
    asked.add(recordingIds);
    return {...recordingIds.where(missing.contains)};
  }

  @override
  Future<FingerprintShare> shareFingerprint(
    String recordingId,
    AudioFingerprint fingerprint, {
    required String installId,
  }) async {
    if (failure case final f?) throw f;
    expect(fingerprint.length, greaterThan(100));
    shared.add(recordingId);
    return FingerprintShare.pending;
  }
}

ShareCandidate _candidate(int trackId, String recordingId) => (
  track: Track(
    id: trackId,
    mediaStoreId: trackId,
    uri: 'content://media/$trackId',
    path: '/m/$trackId.mp3',
    title: 'Song $trackId',
    duration: const Duration(seconds: 20),
    sizeBytes: 1000,
    dateAdded: DateTime(2026),
  ),
  recording: Recording(
    id: recordingId,
    songId: 'song-$recordingId',
    source: RecordingSource.localFile,
    duration: const Duration(seconds: 20),
  ),
);

void main() {
  late SharedPreferences preferences;
  late _Catalog catalog;
  late _Decoder decoder;
  late List<ShareCandidate> candidates;

  FingerprintSharer sharer() => FingerprintSharer(
    catalog: catalog,
    decoder: decoder,
    preferences: preferences,
    candidates: () async => candidates,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    catalog = _Catalog();
    decoder = _Decoder();
    candidates = [_candidate(1, 'a'), _candidate(2, 'b'), _candidate(3, 'a')];
  });

  group('sharing library fingerprints', () {
    test('only recordings the catalog lacks, once each', () async {
      catalog.missing = {'a'};
      final needed = await sharer().needed();
      expect([for (final c in needed) c.track.id], [1]);
      expect(catalog.asked.single, ['a', 'b']);

      await sharer().needed();
      expect(catalog.asked.last, [
        'a',
      ], reason: 'b needs none: not asked again');
    });

    test('shares each, and not again', () async {
      catalog.missing = {'a', 'b'};
      expect(await sharer().share(), 2);
      expect(catalog.shared, ['a', 'b']);
      expect(decoder.decoded, ['content://media/1', 'content://media/2']);

      expect(await sharer().share(), 0);
      expect(catalog.asked, hasLength(1));
    });

    test('at most [limit] at a time', () async {
      catalog.missing = {'a', 'b'};
      expect(await sharer().share(limit: 1), 1);
      expect(await sharer().share(limit: 1), 1);
      expect(catalog.shared, ['a', 'b']);
    });

    test('offline, waits for the next time', () async {
      catalog
        ..missing = {'a', 'b'}
        ..failure = const NetworkFailure('offline');
      expect(await sharer().share(), 0);
      catalog.failure = null;
      expect(await sharer().share(), 2);
    });

    test('an unreadable file is skipped for good', () async {
      catalog.missing = {'a', 'b'};
      decoder.unreadable.add('content://media/1');
      expect(await sharer().share(), 1);
      expect(catalog.shared, ['b']);
      expect(await sharer().share(), 0);
    });
  });

  testWidgets('the app asks once, and Share turns sharing on', (tester) async {
    catalog.missing = {'a'};
    await pumpZemaApp(
      tester,
      location: AppRoutes.home,
      overrides: [
        fingerprintSharerProvider.overrideWith(
          (ref) => FingerprintSharer(
            catalog: catalog,
            decoder: decoder,
            preferences: ref.watch(sharedPreferencesProvider),
            candidates: () async => candidates,
          ),
        ),
      ],
    );
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
    expect(find.text(_l10n.shareFingerprintsTitle), findsOneWidget);
    await tester.tap(find.text(_l10n.shareFingerprintsYes));
    await tester.pumpAndSettle();
    expect(find.text(_l10n.shareFingerprintsTitle), findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    expect(container.read(shareFingerprintsProvider), isTrue);
  });

  group('contribution fingerprints', () {
    late ZemaDatabase db;
    late FakeContributionRepository repository;

    setUp(() {
      db = memoryDatabase();
      repository = FakeContributionRepository();
    });
    tearDown(() => db.close());

    Future<String> submitted(Recording? recording) =>
        repository.submit(Contribution.newSong(_song, recording: recording));

    ContributionFingerprints fingerprints() => ContributionFingerprints(
      repository: repository,
      decoder: decoder,
      library: db.libraryDao,
    );

    test('a shared file\'s fingerprint is attached', () async {
      const recording = Recording(
        id: 'shared-rec',
        songId: 'test-song',
        source: RecordingSource.telegram,
        duration: Duration(seconds: 20),
        fileName: 'a.mp3',
      );
      final id = await submitted(recording);
      await fingerprints().attach(
        id,
        const ContributionDraft(
          recording: recording,
          audioPath: '/shared/a.mp3',
        ),
      );
      expect(decoder.decoded, [Uri.file('/shared/a.mp3').toString()]);
      expect(repository.attached[id]!.length, greaterThan(100));
    });

    test('nothing for a YouTube recording', () async {
      const recording = Recording(
        id: 'yt-rec',
        songId: 'test-song',
        source: RecordingSource.youtube,
        youtubeId: 'dQw4w9WgXcQ',
      );
      final id = await submitted(recording);
      await fingerprints().attach(
        id,
        const ContributionDraft(recording: recording),
      );
      expect(decoder.decoded, isEmpty);
      expect(repository.attached, isEmpty);
    });
  });
}

const _song = Song(
  id: 'test-song',
  title: 'Test',
  sections: [
    LyricSection(id: 'v', kind: SectionKind.verse, lines: [LyricLine('a')]),
  ],
  playOrder: ['v'],
);
