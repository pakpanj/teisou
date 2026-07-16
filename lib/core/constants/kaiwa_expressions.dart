/// Emoji reaction shown when a learner's answer matches a
/// `KaiwaAcceptedAnswer` carrying the given `expressionTag` — e.g. 頑張ります
/// tags 'semangat' and gets a 💪 reaction. A tag missing from this map (or a
/// null `expressionTag`) means no reaction badge is shown — a neutral
/// phrasing with nothing special to react to.
const kaiwaExpressionEmoji = <String, String>{
  'semangat': '💪',
  'senang': '😊',
  'sopan': '🙏',
  'santai': '😌',
  'khawatir': '😟',
  'kaget': '😲',
  'minta_maaf': '🙇',
};
