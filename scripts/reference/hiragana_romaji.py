# Minimal hiragana -> Hepburn romaji converter, sufficient for the simple
# dictionary-headword readings in tango_n2_source.json (no need to handle
# arbitrary sentences).
_DIGRAPHS = {
    "きゃ": "kya", "きゅ": "kyu", "きょ": "kyo",
    "しゃ": "sha", "しゅ": "shu", "しょ": "sho",
    "ちゃ": "cha", "ちゅ": "chu", "ちょ": "cho",
    "にゃ": "nya", "にゅ": "nyu", "にょ": "nyo",
    "ひゃ": "hya", "ひゅ": "hyu", "ひょ": "hyo",
    "みゃ": "mya", "みゅ": "myu", "みょ": "myo",
    "りゃ": "rya", "りゅ": "ryu", "りょ": "ryo",
    "ぎゃ": "gya", "ぎゅ": "gyu", "ぎょ": "gyo",
    "じゃ": "ja", "じゅ": "ju", "じょ": "jo",
    "びゃ": "bya", "びゅ": "byu", "びょ": "byo",
    "ぴゃ": "pya", "ぴゅ": "pyu", "ぴょ": "pyo",
}

_MONOGRAPHS = {
    "あ": "a", "い": "i", "う": "u", "え": "e", "お": "o",
    "か": "ka", "き": "ki", "く": "ku", "け": "ke", "こ": "ko",
    "さ": "sa", "し": "shi", "す": "su", "せ": "se", "そ": "so",
    "た": "ta", "ち": "chi", "つ": "tsu", "て": "te", "と": "to",
    "な": "na", "に": "ni", "ぬ": "nu", "ね": "ne", "の": "no",
    "は": "ha", "ひ": "hi", "ふ": "fu", "へ": "he", "ほ": "ho",
    "ま": "ma", "み": "mi", "む": "mu", "め": "me", "も": "mo",
    "や": "ya", "ゆ": "yu", "よ": "yo",
    "ら": "ra", "り": "ri", "る": "ru", "れ": "re", "ろ": "ro",
    "わ": "wa", "ゐ": "i", "ゑ": "e", "を": "o", "ん": "n",
    "が": "ga", "ぎ": "gi", "ぐ": "gu", "げ": "ge", "ご": "go",
    "ざ": "za", "じ": "ji", "ず": "zu", "ぜ": "ze", "ぞ": "zo",
    "だ": "da", "ぢ": "ji", "づ": "zu", "で": "de", "ど": "do",
    "ば": "ba", "び": "bi", "ぶ": "bu", "べ": "be", "ぼ": "bo",
    "ぱ": "pa", "ぴ": "pi", "ぷ": "pu", "ぺ": "pe", "ぽ": "po",
    "ー": "-",
}

_SMALL_Y = {"ゃ": "ya", "ゅ": "yu", "ょ": "yo"}


def to_romaji(hiragana):
    """Convert a plain hiragana string (dictionary-headword style, no
    kanji) to Hepburn romaji. Doubles the following consonant for っ,
    handles ん before b/m/p as 'm' Hepburn-style is skipped (kept as 'n'
    for simplicity - matches most of this dataset's existing romaji
    style, e.g. 'shinbun' not 'shimbun')."""
    s = hiragana
    out = []
    i = 0
    n = len(s)
    while i < n:
        two = s[i:i + 2]
        if two in _DIGRAPHS:
            out.append(_DIGRAPHS[two])
            i += 2
            continue
        ch = s[i]
        if ch == "っ":
            # double next consonant
            nxt = s[i + 1:i + 2]
            nxt2 = s[i + 1:i + 3]
            if nxt2 in _DIGRAPHS:
                romaji_next = _DIGRAPHS[nxt2]
            elif nxt in _MONOGRAPHS:
                romaji_next = _MONOGRAPHS[nxt]
            else:
                romaji_next = ""
            if romaji_next and romaji_next[0] not in "aiueon":
                out.append(romaji_next[0])
            i += 1
            continue
        if ch in _SMALL_Y and out:
            # stray small-y not part of a digraph - just append its own sound
            out.append(_SMALL_Y[ch])
            i += 1
            continue
        if ch == "ー" and out:
            out.append(out[-1][-1])
            i += 1
            continue
        if ch in _MONOGRAPHS:
            out.append(_MONOGRAPHS[ch])
            i += 1
            continue
        # unknown char (space, slash, kanji leaked in, etc.) - keep literally
        out.append(ch)
        i += 1
    romaji = "".join(out)
    # Long-vowel contraction for う following お/お-column and い following え
    # (kept simple; not attempting macron style, matches existing dataset's
    # plain-romaji convention e.g. 'toukyou' not 'tōkyō').
    return romaji
