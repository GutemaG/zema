import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zema/features/account/data/avatar_cache.dart';

void main() {
  late Directory root;
  late Directory folder;
  final requests = <Uri>[];
  late http.Response Function() answer;

  const user = 'user-a';
  const url = 'https://example.com/a.png';

  setUp(() async {
    root = await Directory.systemTemp.createTemp('avatar_cache_test');
    folder = Directory('${root.path}/avatar');
    requests.clear();
    answer = () => http.Response.bytes([1, 2, 3], 200);
  });
  tearDown(() => root.delete(recursive: true));

  FileAvatarCache cache() => FileAvatarCache(
    () async => folder,
    client: MockClient((request) async {
      requests.add(request.url);
      return answer();
    }),
  );

  test('downloads once, then reads the saved image', () async {
    expect(await cache().load(user, url), [1, 2, 3]);
    expect(await cache().load(user, url), [1, 2, 3]);
    expect(requests, [Uri.parse(url)]);
  });

  test('a new URL downloads again', () async {
    await cache().load(user, url);
    answer = () => http.Response.bytes([4, 5], 200);
    expect(await cache().load(user, 'https://example.com/b.png'), [4, 5]);
    expect(requests, hasLength(2));
  });

  test('offline: the saved image, or null when none', () async {
    answer = () => throw http.ClientException('offline');
    expect(await cache().load(user, url), isNull);

    answer = () => http.Response.bytes([1, 2, 3], 200);
    await cache().load(user, url);
    answer = () => throw http.ClientException('offline');
    expect(await cache().load(user, 'https://example.com/b.png'), [
      1,
      2,
      3,
    ], reason: 'a changed URL offline keeps the older image');
  });

  test('an HTTP error keeps the older image', () async {
    await cache().load(user, url);
    answer = () => http.Response('', 500);
    expect(await cache().load(user, 'https://example.com/b.png'), [1, 2, 3]);
  });

  test('an HTTP error or an empty answer saves nothing', () async {
    answer = () => http.Response('', 404);
    expect(await cache().load(user, url), isNull);
    answer = () => http.Response('', 200);
    expect(await cache().load(user, url), isNull);
    expect(folder.existsSync(), isFalse);
  });

  test('Google photos are asked for at 256 pixels', () async {
    const google = 'https://lh3.googleusercontent.com/a/abc=s96-c';
    await cache().load(user, google);
    expect(requests, [
      Uri.parse('https://lh3.googleusercontent.com/a/abc=s256-c'),
    ]);
    expect(FileAvatarCache.sized(url), url, reason: 'other hosts unchanged');
    expect(
      FileAvatarCache.sized('https://lh3.googleusercontent.com/a/abc'),
      'https://lh3.googleusercontent.com/a/abc',
    );
  });

  test('clear deletes every saved avatar', () async {
    await cache().load(user, url);
    await cache().load('user-b', url);
    await cache().clear();
    expect(folder.existsSync(), isFalse);
    await cache().clear();

    await cache().load(user, url);
    expect(requests, hasLength(3), reason: 'downloaded again after clear');
  });
}
