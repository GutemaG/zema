import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';
import 'package:zema_data/zema_data.dart';

/// Unit tests with a fake HTTP client: no backend needed.
void main() {
  final requests = <http.Request>[];
  late SupabaseCatalogRepository repository;

  /// A repository whose every request is answered by [answer].
  void answerWith(
    FutureOr<http.Response> Function(http.Request request) answer, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    repository = SupabaseCatalogRepository(
      url: 'http://backend.test',
      key: 'anon-key',
      timeout: timeout,
      httpClient: MockClient((request) async {
        requests.add(request);
        final response = await answer(request);
        // postgrest reads the answer's request, which MockClient leaves out.
        return http.Response.bytes(
          response.bodyBytes,
          response.statusCode,
          headers: response.headers,
          request: request,
        );
      }),
    );
  }

  http.Response json(Object? body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  http.Response error(String code, int status, [String message = 'error']) =>
      json({
        'code': code,
        'message': message,
        'details': null,
        'hint': null,
      }, status);

  setUp(requests.clear);
  tearDown(() => repository.close());

  group('index', () {
    test('calls song_index and reads its rows', () async {
      answerWith(
        (_) => json([
          {
            'id': 'selam',
            'title': 'ሰላም',
            'transliteration': 'Selam',
            'artist': 'Zema',
            'album': null,
            'synced': true,
            'version': 18,
            'approved_at': '2026-10-29T08:15:34.56386+00:00',
          },
        ]),
      );
      final index = await repository.index();
      expect(requests.single.url.path, '/rest/v1/rpc/song_index');
      expect(requests.single.headers['apikey'], 'anon-key');
      expect(index, [
        CatalogEntry(
          id: 'selam',
          title: 'ሰላም',
          transliteration: 'Selam',
          artist: 'Zema',
          synced: true,
          version: 18,
          approvedAt: DateTime.parse('2026-10-29T08:15:34.56386Z'),
        ),
      ]);
    });

    test('a row of the wrong shape is a LyricsFormatFailure', () async {
      answerWith(
        (_) => json([
          {
            'id': 'selam',
            'title': 'ሰላም',
            'synced': 'yes',
            'version': 1,
            'approved_at': '2026-10-29T08:15:34Z',
          },
        ]),
      );
      await expectLater(
        repository.index(),
        throwsA(isA<LyricsFormatFailure>()),
      );
    });

    test('an answer that is not a list is a LyricsFormatFailure', () async {
      answerWith((_) => json({'id': 'selam'}));
      await expectLater(
        repository.index(),
        throwsA(isA<LyricsFormatFailure>()),
      );
    });
  });

  group('song', () {
    test('calls get_song with the ID and reads the document', () async {
      answerWith(
        (_) => json({
          'song': {
            'id': 'selam',
            'title': 'ሰላም',
            'sections': [
              {
                'id': 'v1',
                'kind': 'verse',
                'lines': [
                  {'text': 'ሰላም ለኪ'},
                ],
              },
            ],
          },
          'recordings': [
            {'id': 'selam', 'songId': 'selam', 'source': 'localFile'},
          ],
          'timings': [
            {
              'recordingId': 'selam',
              'startsMs': [0],
            },
          ],
        }),
      );
      final document = await repository.song('selam');
      expect(requests.single.url.path, '/rest/v1/rpc/get_song');
      expect(jsonDecode(requests.single.body), {'song_id': 'selam'});
      expect(document!.song.title, 'ሰላም');
      expect(document.recordings.single.source, RecordingSource.localFile);
      expect(document.timings.single.starts, [Duration.zero]);
    });

    test('is null for a song the catalog does not have', () async {
      answerWith((_) => json(null));
      expect(await repository.song('missing'), isNull);
    });

    test('a malformed document is a LyricsFormatFailure', () async {
      answerWith(
        (_) => json({
          'song': {'id': 'selam'},
        }),
      );
      await expectLater(
        repository.song('selam'),
        throwsA(isA<LyricsFormatFailure>()),
      );
    });
  });

  group('search', () {
    test('calls search_songs and reads title and line hits', () async {
      answerWith(
        (_) => json([
          {
            'song_id': 'selam',
            'title': 'ሰላም',
            'transliteration': 'Selam',
            'artist': null,
            'score': 1,
            'line_text': null,
            'line_transliteration': null,
          },
          {
            'song_id': 'kidist',
            'title': 'ቅድስት',
            'transliteration': null,
            'artist': null,
            'score': 0.92,
            'line_text': 'ሰላም ለኪ',
            'line_transliteration': 'Selam leki',
          },
        ]),
      );
      final hits = await repository.search('selam');
      expect(jsonDecode(requests.single.body), {'query': 'selam'});
      expect([for (final h in hits) h.songId], ['selam', 'kidist']);
      expect(hits.first.score, 1.0);
      expect(hits.first.line, isNull);
      expect(hits.last.line, 'ሰላም ለኪ');
      expect(hits.last.lineTransliteration, 'Selam leki');
    });

    test('an empty query sends no request', () async {
      answerWith((_) => json([]));
      expect(await repository.search('  '), isEmpty);
      expect(requests, isEmpty);
    });
  });

  group('report', () {
    test('calls submit_report with the backend\'s names', () async {
      answerWith((_) => http.Response('', 204));
      await repository.report(
        songId: 'selam',
        reason: ReportReason.wrongTiming,
        installId: 'install-1234',
        recordingId: 'selam',
        note: 'Line 3 is late',
        reportId: '3f2b8c1e-9a4d-4e7f-b2c6-0d5e8a1f7c93',
      );
      expect(requests.single.url.path, '/rest/v1/rpc/submit_report');
      expect(jsonDecode(requests.single.body), {
        'song_id': 'selam',
        'reason': 'wrong_timing',
        'install_id': 'install-1234',
        'recording_id': 'selam',
        'note': 'Line 3 is late',
        'report_id': '3f2b8c1e-9a4d-4e7f-b2c6-0d5e8a1f7c93',
      });
    });

    test('leaves out a missing recording, note and report ID', () async {
      answerWith((_) => http.Response('', 204));
      await repository.report(
        songId: 'selam',
        reason: ReportReason.other,
        installId: 'install-1234',
      );
      expect(jsonDecode(requests.single.body), {
        'song_id': 'selam',
        'reason': 'other',
        'install_id': 'install-1234',
      });
    });

    test('every reason has a backend name', () async {
      answerWith((_) => http.Response('', 204));
      for (final reason in ReportReason.values) {
        await repository.report(
          songId: 'selam',
          reason: reason,
          installId: 'install-1234',
        );
      }
      expect(
        [for (final r in requests) jsonDecode(r.body)['reason']],
        ['wrong_words', 'wrong_timing', 'wrong_song', 'other'],
      );
    });
  });

  group('errors become ZemaFailures', () {
    for (final (what, answer, failure) in [
      (
        'the daily report limit (PT429)',
        () => error('PT429', 429, 'Too many reports today'),
        isA<RateLimitFailure>(),
      ),
      (
        'a refused key (PGRST301)',
        () => error('PGRST301', 401, 'Expected 3 parts in JWT; got 1'),
        isA<BackendFailure>().having(
          (f) => f.message,
          'message',
          contains('refused'),
        ),
      ),
      (
        'the gateway\'s 401 for an unknown key',
        () => http.Response('{"message":"Invalid API key"}', 401),
        isA<BackendFailure>().having(
          (f) => f.message,
          'message',
          contains('refused'),
        ),
      ),
      (
        'rejected input (22023)',
        () => error('22023', 400, 'Unknown song'),
        isA<BackendFailure>(),
      ),
      (
        'the API down behind the gateway (503)',
        () => http.Response('<html>Service Unavailable</html>', 503),
        isA<NetworkFailure>(),
      ),
      (
        'a server error page (500)',
        () => http.Response('<html>oops</html>', 500),
        isA<BackendFailure>(),
      ),
    ]) {
      test(what, () async {
        answerWith((_) => answer());
        await expectLater(repository.index(), throwsA(failure));
      });
    }

    test('no connection is a NetworkFailure', () async {
      answerWith(
        (request) =>
            throw http.ClientException('Connection refused', request.url),
      );
      await expectLater(repository.index(), throwsA(isA<NetworkFailure>()));
    });

    test(
      'a request that never answers times out as a NetworkFailure',
      () async {
        answerWith(
          (_) => Completer<http.Response>().future,
          timeout: const Duration(milliseconds: 50),
        );
        await expectLater(
          repository.song('selam'),
          throwsA(
            isA<NetworkFailure>().having(
              (f) => f.cause,
              'cause',
              isA<TimeoutException>(),
            ),
          ),
        );
      },
    );

    test('reports fail the same way', () async {
      answerWith((_) => error('PT429', 429));
      await expectLater(
        repository.report(
          songId: 'selam',
          reason: ReportReason.wrongWords,
          installId: 'install-1234',
        ),
        throwsA(isA<RateLimitFailure>()),
      );
    });
  });
}
