import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Scans `lib/` for user-visible string literals that never pass through
/// `AppStrings`, so the English build cannot silently ship Indonesian text.
///
/// This exists because the problem kept coming back. An i18n audit closed
/// every gap and verified zero remained; every module built afterwards
/// (Choukai, Dokkai, Kanji Combo, the cover picker) introduced fresh ones,
/// and nothing failed — `flutter analyze` and the whole test suite stay
/// green with a hardcoded label sitting in an `AppBar`. The only thing
/// that catches it is looking at the source, so that is what this does.
///
/// A new literal in a UI slot fails here. Two ways out: route it through
/// `AppStrings` (almost always right), or, if it genuinely reads the same
/// in both languages — a Japanese module name like `Kaiwa`, a JLPT key —
/// add it to [_allowed] below with the reason.
void main() {
  // Anything reaching a slot that renders text.
  final slot = RegExp(
    r"(?:\bText\(|\bSnackBar\(|content:|title:|label:|labelText:|hintText:"
    r"|tooltip:|semanticLabel:)\s*"
    r"(?:const\s+)?(?:Text\(\s*)?'((?:[^'\\\n]|\\.)+)'",
  );

  // Directories whose strings are not UI chrome.
  const skippedDirs = [
    'lib/core/localization/', // the bundle itself
    'lib/features/cam_detector/', // locked out of navigation, see CLAUDE.md
    // Preset registries: `label:` there is a const field initializer, not a
    // widget argument, and each file carries its own localization story —
    // `CoverPreset.labelFor(language)` resolves the rendered name, and
    // `FramePreset.label` is documented as never rendered.
    'lib/core/constants/',
  ];

  /// Literals that are deliberately identical in Indonesian and English.
  const allowed = <String>{
    // Module and exam names are Japanese words used untranslated in both.
    'Bunpou', 'Kaiwa', 'Kanji', 'Kana', 'Choukai', 'Dokkai',
    'Hiragana', 'Katakana',
    // Loanwords the app uses as-is in both languages.
    'Clan', 'Premium', 'PREMIUM', '🌸 FREE',
    // The app's own name.
    'Teisou: Kana Master',
    // `ModuleInfo.title`/`description` are the dataset's own identity
    // strings, never rendered directly — `_AvailableModuleCard._displayText`
    // resolves the shown text from `AppStrings` by module id.
    'Belajar dari Gambar',
    'Belajar dari Video',
  };

  bool isProse(String s) {
    if (s.length < 3) return false;
    if (RegExp(r'^[\W\d\s]+$').hasMatch(s)) return false;
    if (RegExp(r'^[a-z0-9_./\-]+$').hasMatch(s)) return false; // ids, paths
    // A capture that opens an interpolation without closing it stopped at a
    // quote *inside* `${...}`, so the real literal is longer than this and
    // this is not a string of its own.
    if (s.contains(r'${') && !s.contains('}')) return false;
    // Interpolation-only strings carry no words of their own.
    final literalPart = s
        .replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), '')
        .replaceAll(RegExp(r'[\W\d\s]'), '');
    return literalPart.length >= 3;
  }

  test('no user-visible string is hardcoded outside AppStrings', () {
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (skippedDirs.any(path.startsWith)) continue;

      // Comments can contain example code; they ship nothing.
      final source = entity
          .readAsStringSync()
          // `[ 	]*`, not `\s*`: the latter swallows the newline of a
          // preceding blank line and shifts every reported line number.
          .replaceAll(RegExp(r'^[ 	]*//.*$', multiLine: true), '');

      for (final match in slot.allMatches(source)) {
        final literal = match.group(1)!;
        if (!isProse(literal) || allowed.contains(literal)) continue;
        final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
        offenders.add('$path:$line  "$literal"');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'These strings render the same in every language, so an '
          'English user sees Indonesian. Move each into AppStrings, or — '
          'only if it is genuinely identical in both — add it to the '
          '`allowed` set in this test with a reason:\n${offenders.join('\n')}',
    );
  });
}
