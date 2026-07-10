// Stop hook: trigger a post-generation code review when lib/ Dart files changed.
// Run via hooks.json on the `stop` event. Stdin: Cursor stop payload JSON.
// Stdout: {} or {"followup_message":"..."}

import 'dart:convert';
import 'dart:io';

const _stateFile = '.cursor/hooks/.last-reviewed-diff-hash';

Future<void> main() async {
  try {
    final inputRaw = await stdin.transform(utf8.decoder).join();
    final input = inputRaw.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(inputRaw) as Map<String, dynamic>;

    final status = input['status'] as String? ?? '';
    if (status != 'completed') {
      stdout.writeln('{}');
      return;
    }

    final fingerprint = await _libDiffFingerprint();
    if (fingerprint.trim().isEmpty) {
      stdout.writeln('{}');
      return;
    }

    final stateFile = File(_stateFile);
    if (stateFile.existsSync()) {
      final last = stateFile.readAsStringSync();
      if (last == fingerprint) {
        stdout.writeln('{}');
        return;
      }
    }

    stateFile.parent.createSync(recursive: true);
    stateFile.writeAsStringSync(fingerprint);

    stdout.writeln(
      jsonEncode({
        'followup_message': '''
Run the post-generation code review per @prompts/review_code.md.

Review only the current git diff under lib/. Follow the prompt exactly — suggest improvements; do not rewrite unless a Must fix issue requires it.
''',
      }),
    );
  } catch (error, stack) {
    stderr.writeln('[post_codegen_review] $error\n$stack');
    stdout.writeln('{}');
  }
}

Future<String> _libDiffFingerprint() async {
  final parts = <String>[];
  for (final args in [
    ['diff', 'HEAD', '--', 'lib/'],
    ['diff', '--cached', '--', 'lib/'],
    ['status', '--porcelain', '--', 'lib/'],
  ]) {
    final result = await Process.run('git', args, runInShell: false);
    parts.add(result.stdout.toString());
    if (result.stderr.toString().trim().isNotEmpty) {
      parts.add(result.stderr.toString());
    }
  }
  return parts.join('\n---\n');
}
