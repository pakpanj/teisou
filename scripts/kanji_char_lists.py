# Canonical N5/N4 character scope for Batch 7 Fase 1 — the single source
# of truth both fetch_kanjivg.py (which SVGs to download) and the Section 5
# dataset-authoring scripts (which kanji to write full content for) import,
# so the two can never drift out of sync with each other.
#
# Landed at 107 N5 + 133 N4 (240 total) rather than the ~80/~170 targets:
# every kanji here is one I'm confident is standard/core for its level;
# none were cut or added just to hit a round number (same accuracy-first
# call as the Kotoba dataset). N5 runs a bit over ~80 because trimming
# well-established N5 kanji down to an exact count would mean cutting ones
# I'm sure about; N4 runs under ~170 because several borderline characters
# (戦/経/治/確 among them) were left out — confident of their
# reading/meaning, not confident enough of the *level* classification.

N5_CHARACTERS = list(
    "一二三四五六七八九十人日月山川"  # from Batch 4 (Section 1 migration)
    "百千万円"
    "年時分間週曜今半"
    "木林森田火水土空気雨石花"
    "子女男名前学生先友私父母"
    "目口手足"
    "上下中外左右後東西南北"
    "行来食飲見聞読書話買売立休入出会"
    "校語文字本"
    "国町村駅店家"
    "大小多少高安新古長白"
    "何車電道"
)

N4_CHARACTERS = list(
    "朝昼夜度"
    "雪風音光"
    "体心頭病死顔声"
    "妹弟兄姉主者員"
    "使作思知持遊働走泳飛送教習覚忘決別変始終開閉集動"
    "早遅強弱重軽暗明深浅太細"
    "図意味配"
    "方仕室乗降通"
    "好嫌楽"
    "赤青黒"
    "昔特急有無全部"
    "近遠実然究研理科"
    "屋台所業界計画品"
    "建起寝着洗続若忙漢進戻育服由自利用"
    "悲族的表現在合悪苦感質問題例返答正様困"
)


def _assert_no_overlap():
    n5, n4 = set(N5_CHARACTERS), set(N4_CHARACTERS)
    assert len(n5) == len(N5_CHARACTERS), "duplicate within N5_CHARACTERS"
    assert len(n4) == len(N4_CHARACTERS), "duplicate within N4_CHARACTERS"
    assert not (n5 & n4), f"overlap between N5 and N4: {sorted(n5 & n4)}"


_assert_no_overlap()

if __name__ == "__main__":
    print(f"N5: {len(N5_CHARACTERS)} kanji")
    print(f"N4: {len(N4_CHARACTERS)} kanji")
    print(f"Combined: {len(N5_CHARACTERS) + len(N4_CHARACTERS)} kanji")
