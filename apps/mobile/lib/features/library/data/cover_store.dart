import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Covers the user picks for songs (S09), copied into the app's files.
abstract interface class CoverStore {
  /// Lets the user pick an image and keeps a copy for track [trackId];
  /// returns its path, or null when nothing was picked.
  Future<String?> pick(int trackId);

  /// Deletes a kept cover; a path that doesn't exist is fine.
  Future<void> delete(String? path);
}

/// [CoverStore] with the system photo picker, keeping covers in the app's
/// support folder.
class PickerCoverStore implements CoverStore {
  PickerCoverStore({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<String?> pick(int trackId) async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (image == null) return null;
    final folder = Directory(
      p.join((await getApplicationSupportDirectory()).path, 'covers'),
    );
    await folder.create(recursive: true);
    // A new name each time, so the old image isn't shown from a cache.
    final name =
        '$trackId-${DateTime.now().millisecondsSinceEpoch}'
        '${p.extension(image.path)}';
    return (await File(image.path).copy(p.join(folder.path, name))).path;
  }

  @override
  Future<void> delete(String? path) async {
    if (path == null) return;
    try {
      await File(path).delete();
    } on FileSystemException {
      // Already gone.
    }
  }
}
