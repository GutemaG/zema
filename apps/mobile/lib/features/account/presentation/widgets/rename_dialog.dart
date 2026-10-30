import 'package:flutter/material.dart';
import 'package:zema_core/zema_core.dart';

import '../../../../l10n/generated/app_localizations.dart';

/// Asks for a new display name, starting from [current]. The name trimmed,
/// or null when cancelled. Save is off while the name is empty, too long or
/// unchanged.
Future<String?> showRenameDialog(BuildContext context, String current) =>
    showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(current: current),
    );

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.current});

  final String current;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(text: widget.current);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? get _valid {
    final name = _controller.text.trim();
    if (name.isEmpty || name == widget.current) return null;
    if (name.runes.length > displayNameMaxLength) return null;
    return name;
  }

  void _save() {
    final name = _valid;
    if (name != null) Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canSave = _valid != null;
    return AlertDialog(
      title: Text(l10n.profileEditName),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: displayNameMaxLength,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(labelText: l10n.profileNameLabel),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        TextButton(
          onPressed: canSave ? _save : null,
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}
