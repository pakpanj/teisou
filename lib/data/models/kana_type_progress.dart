import 'kana_progress.dart';

/// Progress for a single [KanaType] (hiragana or katakana): resume position
/// in the flashcard deck plus per-kana progress, keyed by kana id.
class KanaTypeProgress {
  final int lastIndex;
  final Map<String, KanaProgress> items;

  KanaTypeProgress({required this.lastIndex, required this.items});

  factory KanaTypeProgress.empty() =>
      KanaTypeProgress(lastIndex: 0, items: {});

  factory KanaTypeProgress.fromMap(Map<String, dynamic>? map) {
    if (map == null) return KanaTypeProgress.empty();
    final rawItems = map['items'] as Map<String, dynamic>? ?? {};
    return KanaTypeProgress(
      lastIndex: (map['lastIndex'] as num?)?.toInt() ?? 0,
      items: rawItems.map(
        (kanaId, value) => MapEntry(
          kanaId,
          KanaProgress.fromMap(kanaId, value as Map<String, dynamic>),
        ),
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'lastIndex': lastIndex,
        'items': items.map((kanaId, progress) => MapEntry(kanaId, progress.toMap())),
      };

  KanaProgress progressFor(String kanaId) =>
      items[kanaId] ?? KanaProgress.initial(kanaId);
}
