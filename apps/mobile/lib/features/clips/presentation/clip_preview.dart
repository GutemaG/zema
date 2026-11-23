import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../app/theme/zema_colors.dart';
import '../application/clip_controller.dart';
import '../application/clip_look.dart';

/// The clip's preview: the background, and the lyrics moving from the last
/// layer to the new one the way the video moves them, faded at the edges of
/// the lyrics band.
class ClipPreviewView extends StatefulWidget {
  const ClipPreviewView({required this.preview, super.key});

  final ClipPreview preview;

  @override
  State<ClipPreviewView> createState() => _ClipPreviewViewState();
}

class _ClipPreviewViewState extends State<ClipPreviewView>
    with SingleTickerProviderStateMixin {
  late final _change = AnimationController(vsync: this, value: 1);

  @override
  void didUpdateWidget(ClipPreviewView old) {
    super.didUpdateWidget(old);
    final preview = widget.preview;
    if (preview.serial == old.preview.serial) return;
    if (preview.from == null) {
      _change.value = 1;
      return;
    }
    _change
      ..stop()
      ..value = 0
      ..duration = clipTransition(preview.motion);
    unawaited(_start(preview));
  }

  Future<void> _start(ClipPreview preview) async {
    await precacheImage(MemoryImage(preview.lyrics), context);
    if (mounted && widget.preview.serial == preview.serial) {
      unawaited(_change.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _change.dispose();
    super.dispose();
  }

  Widget _layer(Uint8List bytes, ClipLayerMove move) => Opacity(
    opacity: move.alpha.clamp(0, 1),
    child: FractionalTranslation(
      translation: Offset(0, -move.shift),
      child: Transform.scale(
        scale: move.scale,
        alignment: Alignment(0, widget.preview.focus * 2 - 1),
        child: Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final preview = widget.preview;
    final band = context.zemaColors.bg;
    final clear = band.withValues(alpha: 0);
    const w = clipWindow;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(
          preview.background,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
        ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [clear, clear, band, band, clear, clear],
            stops: [0, w.top, w.top + w.fade, w.bottom - w.fade, w.bottom, 1],
          ).createShader(rect),
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _change,
              builder: (context, _) {
                final from = preview.from;
                final (old, next) = clipMoves(
                  preview.motion,
                  from == null ? 1 : _change.value,
                  scroll: preview.scroll,
                );
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (from != null && old.alpha > 0) _layer(from, old),
                    _layer(preview.lyrics, next),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
