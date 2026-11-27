import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../app/theme/zema_colors.dart';
import '../application/clip_controller.dart';
import '../application/clip_look.dart';

/// The clip's preview: the background, and the lyrics moving from the last
/// layer to the new one the way the video moves them, faded at the edges of
/// the lyrics band. With [onMoved] the lyrics can be dragged; it gets how
/// far they went across and down, as parts of the frame, once let go.
class ClipPreviewView extends StatefulWidget {
  const ClipPreviewView({required this.preview, this.onMoved, super.key});

  final ClipPreview preview;
  final void Function(double dx, double dy)? onMoved;

  @override
  State<ClipPreviewView> createState() => _ClipPreviewViewState();
}

class _ClipPreviewViewState extends State<ClipPreviewView>
    with SingleTickerProviderStateMixin {
  late final _change = AnimationController(vsync: this, value: 1);

  /// How far the lyrics are being dragged, as parts of the frame.
  Offset _drag = Offset.zero;

  void _dragBy(Offset delta) {
    final size = context.size;
    if (size == null || size.isEmpty) return;
    final preview = widget.preview;
    final to = ClipTextPosition(
      preview.x + _drag.dx + delta.dx / size.width,
      preview.focus + _drag.dy + delta.dy / size.height,
    );
    setState(() => _drag = Offset(to.x - preview.x, to.focus - preview.focus));
  }

  void _dragEnd() {
    if (_drag != Offset.zero) widget.onMoved?.call(_drag.dx, _drag.dy);
  }

  @override
  void didUpdateWidget(ClipPreviewView old) {
    super.didUpdateWidget(old);
    final preview = widget.preview;
    if (preview.x != old.preview.x || preview.focus != old.preview.focus) {
      _drag = Offset.zero;
    }
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
        alignment: Alignment(
          widget.preview.x * 2 - 1,
          widget.preview.focus * 2 - 1,
        ),
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
    final view = Stack(
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
            child: FractionalTranslation(
              translation: _drag,
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
        ),
      ],
    );
    if (widget.onMoved == null) return view;
    return GestureDetector(
      onPanUpdate: (d) => _dragBy(d.delta),
      onPanEnd: (_) => _dragEnd(),
      onPanCancel: _dragEnd,
      child: view,
    );
  }
}
