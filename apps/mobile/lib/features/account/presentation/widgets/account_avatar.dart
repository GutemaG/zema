import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../../app/theme/zema_colors.dart';
import '../../../library/presentation/widgets/track_art.dart';
import '../../application/profile.dart';

/// A round avatar: [profile]'s saved photo, a [LetterTile] of the name
/// while it loads or without one, and a guest icon when [profile] is null.
class AccountAvatar extends ConsumerWidget {
  const AccountAvatar({super.key, required this.profile, required this.size});

  final Profile? profile;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = this.profile;
    final Widget child;
    if (profile == null) {
      final colors = context.zemaColors;
      child = DecoratedBox(
        decoration: BoxDecoration(color: colors.soft, shape: BoxShape.circle),
        child: Icon(
          Icons.person_outline,
          size: size * 0.6,
          color: colors.accentText,
        ),
      );
    } else {
      final url = profile.avatarUrl;
      final image = url == null
          ? null
          : ref.watch(avatarProvider((userId: profile.userId, url: url))).value;
      final letter = LetterTile(
        label: profile.displayName,
        size: size,
        radius: size / 2,
      );
      child = image == null
          ? letter
          : ClipOval(
              child: Image.memory(
                image,
                fit: BoxFit.cover,
                cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => letter,
              ),
            );
    }
    return ExcludeSemantics(
      child: SizedBox.square(dimension: size, child: child),
    );
  }
}
