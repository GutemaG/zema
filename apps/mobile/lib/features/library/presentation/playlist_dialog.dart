import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/playlists.dart';

/// A playlist S16 saved: its ID and its name as stored (trimmed).
typedef SavedPlaylist = ({int id, String name});

/// Opens S16 to create a playlist, or to rename [editing]. Returns the
/// saved playlist, or null when cancelled.
Future<SavedPlaylist?> showPlaylistDialog(
  BuildContext context, {
  Playlist? editing,
}) {
  return showDialog<SavedPlaylist>(
    context: context,
    builder: (_) => PlaylistDialog(editing: editing),
  );
}

/// S16: name (required, unique ignoring case and surrounding spaces) and an
/// optional description. Save stays disabled while the name can't be saved.
class PlaylistDialog extends ConsumerStatefulWidget {
  const PlaylistDialog({super.key, this.editing});

  final Playlist? editing;

  /// Longest name accepted.
  static const maxNameLength = 80;

  @override
  ConsumerState<PlaylistDialog> createState() => _PlaylistDialogState();
}

class _PlaylistDialogState extends ConsumerState<PlaylistDialog> {
  late final _name = TextEditingController(text: widget.editing?.name);
  late final _description = TextEditingController(
    text: widget.editing?.description,
  );

  /// The name was edited, so an empty one is reported rather than only
  /// disabling Save.
  var _touched = false;
  var _saving = false;

  /// Set when saving found the name taken (e.g. created elsewhere since).
  String? _takenName;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  PlaylistNameProblem? _problem(List<Playlist> playlists) {
    if (_takenName != null && playlistNameKey(_name.text) == _takenName) {
      return PlaylistNameProblem.duplicate;
    }
    return checkPlaylistName(
      _name.text,
      playlists,
      editing: widget.editing?.id,
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final controller = ref.read(playlistsControllerProvider);
    final description = _description.text;
    try {
      final int id;
      if (widget.editing case final playlist?) {
        id = playlist.id;
        await controller.rename(id, _name.text, description: description);
      } else {
        id = await controller.create(_name.text, description: description);
      }
      if (mounted) {
        Navigator.of(context).pop((id: id, name: _name.text.trim()));
      }
    } on DuplicateNameFailure {
      setState(() {
        _takenName = playlistNameKey(_name.text);
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final playlists = ref.watch(playlistsProvider).value ?? const [];
    final problem = _problem(playlists);
    final error = switch (problem) {
      PlaylistNameProblem.duplicate => l10n.playlistNameTaken,
      PlaylistNameProblem.empty when _touched => l10n.playlistNameRequired,
      _ => null,
    };
    final canSave = problem == null && !_saving;
    return AlertDialog(
      title: Text(
        widget.editing == null ? l10n.playlistNew : l10n.playlistRename,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                LengthLimitingTextInputFormatter(PlaylistDialog.maxNameLength),
              ],
              decoration: InputDecoration(
                labelText: l10n.playlistName,
                errorText: error,
              ),
              onChanged: (_) => setState(() => _touched = true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(labelText: l10n.playlistDescription),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        TextButton(
          onPressed: canSave ? _save : null,
          child: Text(
            widget.editing == null ? l10n.actionCreate : l10n.actionSave,
          ),
        ),
      ],
    );
  }
}
