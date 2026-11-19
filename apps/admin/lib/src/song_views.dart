import 'package:flutter/material.dart';
import 'package:zema_core/zema_core.dart';

import 'format.dart';
import 'strings.dart';

TextStyle? _muted(BuildContext context) =>
    Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

/// A small heading over a part of a review.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0.8,
      ),
    ),
  );
}

String sectionName(Song song, LyricSection section) {
  final same = song.sections.where((s) => s.kind == section.kind).toList();
  final name = switch (section.kind) {
    SectionKind.verse => 'Verse',
    SectionKind.chorus => 'Chorus',
    SectionKind.bridge => 'Bridge',
    SectionKind.other => 'Part',
  };
  return same.length > 1 ? '$name ${same.indexOf(section) + 1}' : name;
}

/// The song's written sections and lines, and its play order.
class SongLines extends StatelessWidget {
  const SongLines(this.song, {super.key});

  final Song song;

  @override
  Widget build(BuildContext context) {
    final byId = {for (final s in song.sections) s.id: s};
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final section in song.sections) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Text(sectionName(song, section), style: _muted(context)),
            ),
            for (final line in section.lines) ...[
              Text(line.text),
              if (line.transliteration case final t?)
                Text(t, style: _muted(context)),
            ],
          ],
          if (song.playOrder.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Sung: ${[for (final id in song.playOrder)
                  if (byId[id] case final s?) sectionName(song, s)].join(' → ')}',
                style: _muted(context),
              ),
            ),
        ],
      ),
    );
  }
}

/// What a correction adds, removes or changes.
class LineChanges extends StatelessWidget {
  const LineChanges({super.key, required this.base, required this.edited});

  final Song base;
  final Song edited;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final changes = changedLines(base, edited);
    if (changes.isEmpty) {
      return Text(Strings.noChanges, style: _muted(context));
    }
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final c in changes)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      switch (c.kind) {
                        LineChangeKind.added => '+',
                        LineChangeKind.removed => '−',
                        LineChangeKind.changed => '~',
                      },
                      style: TextStyle(
                        color: c.kind == LineChangeKind.removed
                            ? scheme.error
                            : scheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (c.before case final before?)
                          Text(
                            before.text,
                            style: TextStyle(
                              color: scheme.error,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        if (c.after case final after?)
                          Text(
                            after.text,
                            style: TextStyle(color: scheme.primary),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// When each sung line of [song] starts in [timing].
class TimingTable extends StatelessWidget {
  const TimingTable({super.key, required this.song, required this.timing});

  final Song song;
  final SyncTiming timing;

  @override
  Widget build(BuildContext context) {
    final lines = expandPlayOrder(song).occurrences;
    final count = lines.length < timing.starts.length
        ? lines.length
        : timing.starts.length;
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(
                      formatTime(timing.starts[i]),
                      style: _muted(context)?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(child: Text(lines[i].line.text)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Where a recording comes from.
class RecordingInfo extends StatelessWidget {
  const RecordingInfo(this.recording, {super.key});

  final Recording recording;

  @override
  Widget build(BuildContext context) => SelectableText(
    [
      switch (recording.source) {
        RecordingSource.youtube => 'YouTube',
        RecordingSource.localFile => 'File',
        RecordingSource.telegram => 'Telegram',
        RecordingSource.bundled => 'Bundled',
      },
      recording.artist ?? Strings.unknownArtist,
      if (recording.duration case final d?) formatDuration(d),
      if (recording.youtubeId case final id?) 'youtube.com/watch?v=$id',
      ?recording.fileName,
    ].join(' · '),
  );
}
