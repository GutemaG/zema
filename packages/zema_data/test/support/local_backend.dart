import 'dart:convert';
import 'dart:io';

/// The local backend (npx supabase start in `backend/`).
const localUrl = 'http://127.0.0.1:54321';

/// The repo's `backend/` folder, from this package.
final backendDir = Directory('../../backend');

/// The local backend's public anon key, or null when it isn't running.
String? localAnonKey() {
  try {
    final result = Process.runSync('npx', [
      'supabase',
      'status',
      '-o',
      'json',
    ], workingDirectory: backendDir.path);
    if (result.exitCode != 0) return null;
    final status = jsonDecode(result.stdout as String) as Map<String, Object?>;
    return status['ANON_KEY'] as String?;
  } on Object {
    return null;
  }
}

/// Why backend tests are skipped when [key] is null.
const backendNotRunning =
    "Local backend not running: start it with 'npx supabase start' in "
    'backend/';
