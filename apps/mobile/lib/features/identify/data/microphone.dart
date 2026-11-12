import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

import 'audio_decoder.dart';

/// The microphone, as mono samples. Nothing is saved: the samples only pass
/// through to the fingerprinter.
abstract interface class Microphone {
  /// Samples a second in what [start] streams.
  int get sampleRate;

  /// Asks for the microphone permission when needed; whether it's granted.
  Future<bool> requestPermission();

  /// Starts recording; samples arrive until [stop].
  Future<Stream<Float32List>> start();

  Future<void> stop();
}

final microphoneProvider = Provider<Microphone>((ref) {
  final microphone = RecordMicrophone();
  ref.onDispose(microphone.dispose);
  return microphone;
});

/// The `record` package's PCM stream.
class RecordMicrophone implements Microphone {
  final _recorder = AudioRecorder();

  @override
  int get sampleRate => 44100;

  @override
  Future<bool> requestPermission() => _recorder.hasPermission();

  @override
  Future<Stream<Float32List>> start() async {
    final stream = await _recorder.startStream(
      RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
        // Voice recognition skips most of the speech processing (noise
        // suppression, gain control) that would damage music.
        androidConfig: const AndroidRecordConfig(
          audioSource: AndroidAudioSource.voiceRecognition,
          manageBluetooth: false,
        ),
      ),
    );
    return stream.map(pcm16ToFloat);
  }

  @override
  Future<void> stop() async {
    await _recorder.stop();
  }

  Future<void> dispose() => _recorder.dispose();
}
