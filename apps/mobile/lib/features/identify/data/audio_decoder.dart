import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('identify.decoder');

/// A decoded file.
class DecodedAudio {
  const DecodedAudio({
    required this.pcm16,
    this.codec = '',
    this.took = Duration.zero,
  });

  /// 16-bit little-endian mono samples at `fingerprintSampleRate` (see
  /// [pcm16ToFloat]). Half the size of float samples, so several files can
  /// be in flight at once.
  final Uint8List pcm16;

  /// The platform codec that decoded it, e.g. `c2.android.mp3.decoder`.
  final String codec;

  /// How long decoding took.
  final Duration took;
}

/// What the phone offers for the work: shown in Listen's details.
class DecodeDevice {
  const DecodeDevice({required this.cores, required this.powerSave});

  final int cores;

  /// Battery saver is on; the system slows background work.
  final bool powerSave;
}

/// Turns an audio file into mono samples at `fingerprintSampleRate`.
abstract interface class AudioDecoder {
  /// The file at [uri], at most its first [maxLength], or null when it
  /// can't be decoded.
  Future<DecodedAudio?> decode(String uri, {Duration maxLength});

  /// The phone's cores and battery saver, or null when unknown.
  Future<DecodeDevice?> device();
}

/// The part of a file that gets fingerprinted: enough for any song, and it
/// keeps hour-long recordings from using hundreds of MB.
const maxDecodedLength = Duration(minutes: 15);

/// Files decoded at the same time (`AudioDecodeChannel.WORKERS`).
const decodeWorkers = 3;

final audioDecoderProvider = Provider<AudioDecoder>(
  (ref) => const PlatformAudioDecoder(),
);

/// Decodes with the platform's codecs (`AudioDecodeChannel` on Android).
class PlatformAudioDecoder implements AudioDecoder {
  const PlatformAudioDecoder();

  static const _channel = MethodChannel('zema/audio_decode');

  @override
  Future<DecodedAudio?> decode(
    String uri, {
    Duration maxLength = maxDecodedLength,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<String, Object?>('decode', {
        'uri': uri,
        'maxSeconds': maxLength.inSeconds,
      });
      final pcm = result?['pcm'];
      if (pcm is! Uint8List) return null;
      return DecodedAudio(
        pcm16: pcm,
        codec: result?['codec'] as String? ?? '',
        took: Duration(milliseconds: (result?['millis'] as num?)?.toInt() ?? 0),
      );
    } on PlatformException catch (e) {
      _log.warning('Could not decode $uri: ${e.code} ${e.message}');
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<DecodeDevice?> device() async {
    try {
      final result = await _channel.invokeMapMethod<String, Object?>('device');
      if (result == null) return null;
      return DecodeDevice(
        cores: (result['cores'] as num?)?.toInt() ?? 0,
        powerSave: result['powerSave'] == true,
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

/// 16-bit little-endian samples as -1…1.
Float32List pcm16ToFloat(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  final out = Float32List(bytes.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = data.getInt16(i * 2, Endian.little) / 32768;
  }
  return out;
}
