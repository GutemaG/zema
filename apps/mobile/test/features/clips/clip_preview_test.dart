import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/features/clips/application/clip_controller.dart';
import 'package:zema/features/clips/application/clip_look.dart';
import 'package:zema/features/clips/presentation/clip_preview.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('dragging the lyrics reports how far they went, within the '
      'limits', (tester) async {
    final moves = <(double, double)>[];
    await pumpThemed(
      tester,
      Center(
        child: SizedBox(
          width: 180,
          height: 320,
          child: ClipPreviewView(
            preview: ClipPreview(
              background: testAvatar,
              lyrics: testAvatar,
              serial: 1,
              focus: ClipTextPosition.center.focus,
            ),
            onMoved: (dx, dy) => moves.add((dx, dy)),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(ClipPreviewView), const Offset(-18, 64));
    await tester.pumpAndSettle();
    expect(moves, hasLength(1));
    expect(moves.single.$1, closeTo(-0.1, 0.02));
    expect(moves.single.$2, closeTo(0.2, 0.02));

    await tester.drag(find.byType(ClipPreviewView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(moves.last.$1, closeTo(ClipTextPosition.minX - 0.5, 0.001));
  });
}
