import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import 'choice.dart';
import 'format.dart';
import 'session.dart';
import 'song_views.dart';
import 'strings.dart';

const _page = 50;

final catalogQueryProvider = NotifierProvider<Choice<String>, String>(
  () => Choice(''),
);

/// How many songs are listed; grows with Load more.
final catalogLimitProvider = NotifierProvider<Choice<int>, int>(
  () => Choice(_page),
);

final selectedSongProvider = NotifierProvider<Choice<String?>, String?>(
  () => Choice(null),
);

final catalogSongsProvider = FutureProvider.autoDispose<List<ModeratedSong>>(
  (ref) => ref
      .watch(moderationRepositoryProvider)
      .songs(
        query: ref.watch(catalogQueryProvider),
        limit: ref.watch(catalogLimitProvider),
      ),
);

final catalogSongProvider = FutureProvider.autoDispose
    .family<SongDocument?, String>(
      (ref, id) => ref.watch(moderationRepositoryProvider).song(id),
    );

/// Search beside the selected song; on a narrow screen the song opens on
/// its own page.
class CatalogPage extends ConsumerWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final list = _SongList(
        onOpen: wide
            ? null
            : (song) => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: Text(song.title)),
                    body: SongDetail(song: song),
                  ),
                ),
              ),
      );
      if (!wide) return list;
      final selected = ref.watch(selectedSongProvider);
      final song = ref
          .watch(catalogSongsProvider)
          .value
          ?.where((s) => s.id == selected)
          .firstOrNull;
      return Row(
        children: [
          SizedBox(width: 360, child: list),
          const VerticalDivider(width: 1),
          Expanded(
            child: song == null
                ? const Center(child: Text(Strings.pickOne))
                : SongDetail(key: ValueKey(song.id), song: song),
          ),
        ],
      );
    },
  );
}

class _SongList extends ConsumerStatefulWidget {
  const _SongList({this.onOpen});

  final void Function(ModeratedSong song)? onOpen;

  @override
  ConsumerState<_SongList> createState() => _SongListState();
}

class _SongListState extends ConsumerState<_SongList> {
  late final _query = TextEditingController(
    text: ref.read(catalogQueryProvider),
  );
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _search(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(catalogLimitProvider.notifier).pick(_page);
      ref.read(catalogQueryProvider.notifier).pick(text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(catalogQueryProvider, (_, next) {
      if (_query.text.trim() != next) _query.text = next;
    });
    final selected = ref.watch(selectedSongProvider);
    final limit = ref.watch(catalogLimitProvider);
    final muted = TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _query,
            onChanged: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: Strings.search,
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: switch (ref.watch(catalogSongsProvider)) {
            AsyncData(value: final songs) when songs.isEmpty => const Center(
              child: Text(Strings.noSongs),
            ),
            AsyncData(value: final songs) => ListView(
              children: [
                for (final song in songs)
                  ListTile(
                    selected: song.id == selected,
                    title: Text(song.title),
                    subtitle: Text(
                      [
                        song.artist ?? Strings.unknownArtist,
                        '${song.lineCount} ${Strings.lines}',
                      ].join(' · '),
                      style: muted,
                    ),
                    trailing: song.hidden
                        ? const Chip(label: Text(Strings.hidden))
                        : null,
                    onTap: () {
                      ref.read(selectedSongProvider.notifier).pick(song.id);
                      widget.onOpen?.call(song);
                    },
                  ),
                if (songs.length >= limit)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextButton(
                      onPressed: () => ref
                          .read(catalogLimitProvider.notifier)
                          .pick(limit + _page),
                      child: const Text(Strings.loadMore),
                    ),
                  ),
              ],
            ),
            AsyncError(:final error) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error is NetworkFailure ? Strings.offline : '$error'),
                  TextButton(
                    onPressed: () => ref.invalidate(catalogSongsProvider),
                    child: const Text(Strings.retry),
                  ),
                ],
              ),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ],
    );
  }
}

/// A song's lyrics and recordings, with Hide or Restore.
class SongDetail extends ConsumerStatefulWidget {
  const SongDetail({super.key, required this.song});

  final ModeratedSong song;

  @override
  ConsumerState<SongDetail> createState() => _SongDetailState();
}

class _SongDetailState extends ConsumerState<SongDetail> {
  late bool _hidden = widget.song.hidden;
  var _busy = false;

  Future<void> _setHidden(bool hidden) async {
    if (hidden) {
      final sure = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(Strings.hideTitle),
          content: const Text(Strings.hideBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(Strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(Strings.hide),
            ),
          ],
        ),
      );
      if (sure != true) return;
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(moderationRepositoryProvider)
          .setHidden(widget.song.id, hidden: hidden);
      if (mounted) setState(() => _hidden = hidden);
      messenger.showSnackBar(
        SnackBar(
          content: Text(hidden ? Strings.songHidden : Strings.songRestored),
        ),
      );
      ref.invalidate(catalogSongsProvider);
    } on ZemaFailure catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e is NetworkFailure ? Strings.offline : e.message),
        ),
      );
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    final muted = TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                song.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            if (_hidden)
              FilledButton(
                onPressed: _busy ? null : () => _setHidden(false),
                child: const Text(Strings.restore),
              )
            else
              OutlinedButton(
                onPressed: _busy ? null : () => _setHidden(true),
                child: const Text(Strings.hide),
              ),
          ],
        ),
        SelectableText(
          [
            song.artist ?? Strings.unknownArtist,
            song.id,
            '${Strings.version} ${song.version}',
            formatAge(song.updatedAt),
            if (_hidden) Strings.hidden,
          ].join(' · '),
          style: muted,
        ),
        switch (ref.watch(catalogSongProvider(song.id))) {
          AsyncData(value: final document?) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (document.recordings.isNotEmpty) ...[
                const SectionTitle(Strings.recordings),
                for (final r in document.recordings)
                  Row(
                    children: [
                      Expanded(child: RecordingInfo(r)),
                      Text(
                        document.timings.any((t) => t.recordingId == r.id)
                            ? Strings.synced
                            : Strings.notSynced,
                        style: muted,
                      ),
                    ],
                  ),
              ],
              const SectionTitle(Strings.lines),
              SongLines(document.song),
            ],
          ),
          AsyncData() => const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Text(Strings.noSongs),
          ),
          AsyncError(:final error) => Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(error is NetworkFailure ? Strings.offline : '$error'),
          ),
          _ => const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        },
      ],
    );
  }
}
