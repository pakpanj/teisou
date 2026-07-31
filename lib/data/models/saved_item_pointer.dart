import 'package:cloud_firestore/cloud_firestore.dart';

/// A dictionary bookmark written by `ProgressRepository.saveDictionaryItem`
/// (the bookmark icon on the search-flow `KanjiDetailScreen`/
/// `KotobaDetailScreen`) — just a pointer, not the resolved word content.
/// Callers resolve [itemId] via `KanjiRepository`/`KotobaRepository`
/// depending on [type].
class SavedItemPointer {
  final String itemId;
  final String type;
  final DateTime savedAt;

  SavedItemPointer({
    required this.itemId,
    required this.type,
    required this.savedAt,
  });

  factory SavedItemPointer.fromFirestore(String itemId, Map<String, dynamic> map) {
    final rawSavedAt = map['savedAt'];
    return SavedItemPointer(
      itemId: itemId,
      type: map['type'] as String? ?? '',
      savedAt: rawSavedAt is Timestamp ? rawSavedAt.toDate() : DateTime.now(),
    );
  }
}
