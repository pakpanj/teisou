"""Split kanji `meanings` into an Indonesian list + an English list (`meaningsEn`).

Why this exists
---------------
`generate_kanji_seed.py` authored each kanji's meanings as ONE list holding both
languages, Indonesian first then English — e.g. 朝 -> ["pagi", "morning"], 恥 ->
["malu", "aib", "shame", "embarrassment"]. That made every kanji screen show both
languages at once regardless of the app's language setting. The English glosses
were already there; they just needed separating, not translating.

How it works
------------
1. Build an Indonesian lexicon from fields elsewhere in the datasets that are
   known to be Indonesian-only (kanji word-example meanings + sentence
   translations, kotoba meanings/translations, bunpou/kaiwa/dictionary
   translations), and an English lexicon seeded from kotoba's authored
   `meaningEn` values.
2. Score each meanings[] item, then pick the boundary k that best separates
   [indonesian...] from [english...]. Feed confident splits back into both
   lexicons and repeat, so rare English glosses ("surplus", "rumor", "mediate")
   become recognisable from how they were used on other kanji.
3. OVERRIDES below wins over the classifier. It holds the 192 entries a manual
   review pass corrected: loanwords that look Indonesian ("proposal", "momentum"),
   entries authored with no English gloss at all (English written by hand), and
   two entries authored in reverse order (English first) - 萩 and 葛.

Re-run safety: this reads `meanings` as authored and rewrites both fields, so it
is idempotent, and it must be re-run after `generate_kanji_seed.py` regenerates
`kanji_data.json` (that generator does not know about `meaningsEn`).

Usage:  python scripts/split_kanji_meanings_en.py [--dry-run]
"""

import collections
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "assets", "data")
KANJI_JSON = os.path.join(DATA, "kanji_data.json")

JP = re.compile(r"[぀-ヿ一-鿿]")
TOK = re.compile(r"[a-zA-Z']+")

# Manually reviewed splits: kanji id -> (indonesian, english).
# Everything not listed here is split by the classifier below.
OVERRIDES = {
    "kanji_fun":           (['menit', 'bagian'], ['minute', 'part', 'understand']),  # 分
    "kanji_koe":           (['suara (manusia)'], ['voice']),  # 声
    "kanji_wakareru":      (['berpisah', 'terpisah'], ['separate']),  # 別
    "kanji_osoi":          (['lambat', 'terlambat'], ['late', 'slow']),  # 遅
    "kanji_kubaru":        (['membagikan'], ['distribute']),  # 配
    "kanji_suki2":         (['suka'], ['like']),  # 好
    "kanji_bu":            (['bagian', 'departemen'], ['part', 'section']),  # 部
    "kanji_dai2":          (['dudukan', 'platform', 'alas'], ['stand', 'platform', 'base']),  # 台  (manual)
    "kanji_hin":           (['barang', 'produk'], ['goods', 'item', 'product']),  # 品
    "kanji_teki":          (['sasaran', '-seperti'], ['target', '-like']),  # 的
    "kanji_kan3":          (['merasa', 'perasaan'], ['feel', 'feeling', 'sense']),  # 感
    "kanji_komaru":        (['kesulitan', 'bingung'], ['troubled', 'in difficulty']),  # 困
    "kanji_gi_n3":         (['musyawarah', 'diskusi'], ['deliberation', 'discussion']),  # 議
    "kanji_you_n3":        (['perlu', 'penting'], ['need', 'main point']),  # 要
    "kanji_ki3_n3":        (['mencatat', 'menulis'], ['record', 'note']),  # 記
    "kanji_kou2_n3":       (['menghadap', 'arah'], ['face', 'direction']),  # 向
    "kanji_han_n3":        (['lawan', 'anti-'], ['opposite', 'anti-']),  # 反
    "kanji_san2_n3":       (['pergi (sopan)', 'ikut serta'], ['go (humble)', 'visit']),  # 参
    "kanji_shin_n3":       (['percaya', 'kepercayaan'], ['faith', 'trust']),  # 信
    "kanji_ron_n3":        (['argumen', 'diskusi'], ['argument', 'discourse']),  # 論
    "kanji_dan_n3":        (['berbicara', 'diskusi'], ['talk', 'discuss']),  # 談
    "kanji_ka4_n3":        (['berlebihan', 'melewati'], ['exceed', 'pass']),  # 過
    "kanji_shin2_n3":      (['dewa', 'roh'], ['god', 'spirit']),  # 神
    "kanji_shitsu_n3":     (['kehilangan', 'kesalahan'], ['lose', 'error']),  # 失
    "kanji_hi3_n3":        (['menyangkal', 'menolak'], ['deny', 'no']),  # 否
    "kanji_tan_n3":        (['sederhana', 'tunggal'], ['simple', 'single']),  # 単
    "kanji_kan4_n3":       (['sempurna', 'selesai'], ['complete', 'perfect']),  # 完
    "kanji_san3_n3":       (['berserakan', 'menyebar'], ['scatter', 'disperse']),  # 散
    "kanji_kin_n3":        (['bekerja', 'rajin'], ['work', 'diligent']),  # 勤
    "kanji_koku2_n3":      (['mengukir', 'waktu'], ['engrave', 'time']),  # 刻
    "kanji_yoku_n3":       (['hasrat', 'keinginan'], ['desire', 'greed']),  # 欲
    "kanji_kun_n3":        (['kamu (akrab)'], ['you (familiar)']),  # 君
    "kanji_bo_n3":         (['mencari nafkah', 'menjalani hidup'], ['livelihood', 'live']),  # 暮
    "kanji_kai4_n3":       (['menggantung', 'menelepon'], ['hang', 'call']),  # 掛
    "kanji_go3_n3":        (['kesalahan', 'salah'], ['mistake', 'error']),  # 誤
    "kanji_byou_n3":       (['kucing'], ['cat']),  # 猫
    "kanji_ki8_n3":        (['berapa', 'beberapa'], ['how many', 'several']),  # 幾
    "kanji_ryou_n2":       (['wilayah', 'memimpin'], ['territory']),  # 領
    "kanji_an_n2":         (['rencana', 'proposal', 'gagasan'], ['plan', 'proposal', 'idea']),  # 案  (manual)
    "kanji_sei2_n2":       (['kekuatan', 'momentum', 'semangat'], ['force', 'momentum', 'energy']),  # 勢  (manual)
    "kanji_jun_n2":        (['standar', 'semi-'], ['standard', 'semi-']),  # 準  (manual)
    "kanji_gi_n2":         (['keterampilan', 'teknik'], ['skill']),  # 技
    "kanji_shou2_n2":      (['kementerian', 'merenungkan', 'menghemat'], ['ministry', 'reflect', 'conserve']),  # 省  (manual)
    "kanji_zai_n2":        (['bahan'], ['material']),  # 材
    "kanji_kin_n2":        (['melarang'], ['prohibit']),  # 禁
    "kanji_kyuu2_n2":      (['lama (waktu)'], ['long time']),  # 久
    "kanji_ran_n2":        (['kekacauan'], ['disorder']),  # 乱
    "kanji_jun2_n2":       (['urutan'], ['order/sequence']),  # 順
    "kanji_butsu_n2":      (['Buddha'], ['Buddha']),  # 仏  (manual)
    "kanji_satsu_n2":      (['uang kertas', 'label'], ['bill']),  # 札
    "kanji_han5_n2":       (['papan'], ['board']),  # 板
    "kanji_zou4_n2":       (['organ dalam'], ['internal organ']),  # 臓
    "kanji_byou_n2":       (['detik'], ['second']),  # 秒
    "kanji_sai3_n2":       (['festival'], ['festival']),  # 祭  (manual)
    "kanji_sha2_n2":       (['membuang'], ['discard']),  # 捨
    "kanji_satsu2_n2":     (['kata bantu bilangan buku', 'jilid'], ['volume']),  # 冊
    "kanji_jou3_n2":       (['tikar tatami'], ['tatami mat']),  # 畳
    "kanji_ki_n1":         (['dasar'], ['base']),  # 基
    "kanji_tou2_n1":       (['bunga wisteria'], ['wisteria']),  # 藤
    "kanji_shi4_n1":       (['penampilan', 'sosok'], ['figure']),  # 姿
    "kanji_kan4_n1":       (['Korea'], ['Korea']),  # 韓  (manual)
    "kanji_ri_n1":         (['berpisah'], ['separate']),  # 離
    "kanji_juu_n1":        (['mengikuti'], ['follow']),  # 従
    "kanji_i_n1":          (['berbeda'], ['different']),  # 異
    "kanji_gen_n1":        (['ketat'], ['strict']),  # 厳
    "kanji_ken5_n1":       (['mengutus'], ['dispatch']),  # 遣
    "kanji_jin_n1":        (['markas', 'formasi'], ['camp']),  # 陣
    "kanji_kyo2_n1":       (['dasar'], ['base']),  # 拠
    "kanji_ban_n1":        (['papan', 'piringan'], ['board']),  # 盤
    "kanji_sai5_n1":       (['bencana'], ['disaster']),  # 災
    "kanji_shin4_n1":      (['mendiagnosis'], ['diagnose']),  # 診
    "kanji_sou6_n1":       (['keributan'], ['noise', 'disturbance']),  # 騒
    "kanji_sugi_n1":       (['pohon cemara Jepang'], ['cedar']),  # 杉
    "kanji_i6_n1":         (['wibawa'], ['authority', 'dignity']),  # 威
    "kanji_kan16_n1":      (['hati organ'], ['liver']),  # 肝
    "kanji_ri3_n1":        (['buah plum'], ['plum']),  # 李
    "kanji_kan19_n1":      (['menembus'], ['penetrate']),  # 貫
    "kanji_ryuu2_n1":      (['pohon willow'], ['willow']),  # 柳
    "kanji_kyo4_n1":       (['jarak'], ['distance']),  # 距
    "kanji_you3_n1":       (['mendukung', 'memeluk'], ['embrace', 'support']),  # 擁
    "kanji_bai_n1":        (['pohon plum Jepang'], ['plum']),  # 梅
    "kanji_boku_n1":       (['saya (pria)', 'pelayan'], ['servant']),  # 僕
    "kanji_ki10_n1":       (['cerah/makmur (arkais)', 'nama dalam Kaisar Kangxi'], ['bright/prosperous (archaic)', 'name in Emperor Kangxi']),  # 煕  (manual)
    "kanji_jun2_n1":       (['berkeliling'], ['patrol', 'tour']),  # 巡
    "kanji_ki12_n1":       (['catur', 'permainan papan'], ['chess', 'board game']),  # 棋
    "kanji_kaji_n1":       (['kemudi'], ['rudder', 'helm']),  # 梶
    "kanji_man_n1":        (['sombong', 'lamban'], ['arrogant', 'slow']),  # 慢
    "kanji_kaku6_n1":      (['memisahkan'], ['separate']),  # 隔
    "kanji_ka7_n1":        (['waktu luang'], ['leisure', 'spare time']),  # 暇
    "kanji_hi4_n1":        (['membuka', 'mengungkapkan'], ['open', 'disclose']),  # 披
    "kanji_shin7_n1":      (['merendam'], ['soak', 'permeate']),  # 浸
    "kanji_jou7_n1":       (['kelebihan'], ['surplus']),  # 剰
    "kanji_shi16_n1":      (['rajin (arkais)'], ['diligent']),  # 孜
    "kanji_rei3_n1":       (['roh'], ['spirit']),  # 霊
    "kanji_kyo6_n1":       (['memasang'], ['install', 'set']),  # 据
    "kanji_kai4_n1":       (['pangkuan', 'rindu'], ['bosom', 'nostalgia']),  # 懐
    "kanji_a2_n1":         (['sub', 'kedua'], ['sub-', 'second']),  # 亜
    "kanji_chou9_n1":      (['marga/negara Zhao'], ['Zhao']),  # 趙
    "kanji_gai3_n1":       (['batas', 'tepi'], ['shore', 'limit']),  # 涯
    "kanji_shuu8_n1":      (['semak clover Jepang'], ['bush clover']),  # 萩  (manual)
    "kanji_katsu3_n1":     (['tanaman kudzu'], ['kudzu vine']),  # 葛  (manual)
    "kanji_suga_n1":       (['rumput sedge'], ['sedge']),  # 菅
    "kanji_sai9_n1":       (['menghancurkan'], ['crush', 'smash']),  # 砕
    "kanji_you5_n1":       (['lagu tradisional'], ['song', 'ballad']),  # 謡
    "kanji_koto_n1":       (['alat musik koto'], ['koto']),  # 琴
    "kanji_shin8_n1":      (['naga (shio)', 'waktu'], ['dragon (zodiac)', 'time']),  # 辰  (manual)
    "kanji_haku4_n1":      (['pohon ek Jepang'], ['oak']),  # 柏
    "kanji_go3_n1":        (['permainan go'], ['go (board game)']),  # 碁
    "kanji_tei10_n1":      (['paviliun'], ['pavilion']),  # 亭
    "kanji_kei11_n1":      (['pohon kayu manis'], ['cinnamon', 'laurel']),  # 桂
    "kanji_nin2_n1":       (['menahan', 'bertahan'], ['endure', 'ninja']),  # 忍
    "kanji_jo3_n1":        (['seperti'], ['as if', 'like']),  # 如
    "kanji_byou2_n1":      (['bibit tanaman'], ['seedling']),  # 苗
    "kanji_kei12_n1":      (['beristirahat'], ['rest']),  # 憩
    "kanji_tei13_n1":      (['marga Zheng'], ['Zheng']),  # 鄭
    "kanji_kaki2_n1":      (['buah kesemek'], ['persimmon']),  # 柿
    "kanji_fu5_n1":        (['kuali', 'panci besar'], ['cauldron', 'pot']),  # 釜
    "kanji_joku_n1":       (['mempermalukan'], ['disgrace']),  # 辱
    "kanji_shin11_n1":     (['pria terhormat'], ['gentleman']),  # 紳
    "kanji_ko6_n1":        (['gendang'], ['drum']),  # 鼓
    "kanji_yuu7_n1":       (['masih', 'seperti'], ['still', 'like']),  # 猶
    "kanji_maku2_n1":      (['selaput'], ['membrane']),  # 膜
    "kanji_nabe_n1":       (['panci'], ['hotpot', 'pot']),  # 鍋
    "kanji_you7_n1":       (['pohon willow (nama)'], ['willow']),  # 楊
    "kanji_hyou6_n1":      (['satuan luas Jepang'], ['unit of area']),  # 坪
    "kanji_kei13_n1":      (['lempengan giok (nama)'], ['jade tablet']),  # 圭
    "kanji_kan27_n1":      (['pasal', 'ketentuan'], ['article', 'section']),  # 款
    "kanji_za_n1":         (['terkilir', 'gagal'], ['sprain', 'setback']),  # 挫
    "kanji_hachi_n1":      (['mangkuk'], ['bowl', 'pot']),  # 鉢
    "kanji_han6_n1":       (['wilayah feodal'], ['feudal domain']),  # 藩
    "kanji_zen2_n1":       (['Zen', 'meditasi'], ['Zen', 'meditation']),  # 禅  (manual)
    "kanji_dou3_n1":       (['badan'], ['torso']),  # 胴
    "kanji_bou11_n1":      (['membedah'], ['dissect']),  # 剖
    "kanji_yuu9_n1":       (['santai', 'jauh'], ['leisurely', 'distant']),  # 悠
    "kanji_do_n1":         (['pelayan', 'orang (kasar)'], ['servant']),  # 奴
    "kanji_kyou13_n1":     (['keberhasilan (nama)'], ['success', 'pass through']),  # 亨
    "kanji_tei15_n1":      (['bergiliran'], ['in turn', 'relay']),  # 逓
    "kanji_bi3_n1":        (['biwa (instrumen)'], ['biwa (instrument)']),  # 琵  (manual)
    "kanji_wa_n1":         (['biwa (instrumen)'], ['biwa (instrument)']),  # 琶  (manual)
    "kanji_satsu3_n1":     (['nama daerah Satsuma'], ['Satsuma']),  # 薩
    "kanji_kouji_n1":      (['ragi koji'], ['koji mold']),  # 麹
    "kanji_ka15_n1":       (['bencana'], ['misfortune', 'disaster']),  # 禍
    "kanji_sei13_n1":      (['meninggal'], ['pass away']),  # 逝
    "kanji_ki25_n1":       (['nyiru'], ['winnowing basket']),  # 箕
    "kanji_tou19_n1":      (['singgah'], ['stay', 'stop over']),  # 逗
    "kanji_kabuto_n1":     (['helm samurai'], ['samurai helmet']),  # 兜
    "kanji_ryuu7_n1":      (['nama Kepulauan Ryukyu'], ['Ryukyu']),  # 琉
    "kanji_ri6_n1":        (['diare'], ['diarrhea']),  # 痢
    "kanji_ran5_n1":       (['nila', 'warna indigo'], ['indigo']),  # 藍
    "kanji_ryou10_n1":     (['jauh', 'Dinasti Liao'], ['distant']),  # 遼
    "kanji_bai6_n1":       (['lagu tradisional'], ['song']),  # 唄
    "kanji_kitsu_n1":      (['jeruk mandarin liar (nama)'], ['mandarin orange']),  # 橘
    "kanji_sou21_n1":      (['Dinasti Song'], ['Song (Chinese dynasty)']),  # 宋
    "kanji_kin6_n1":       (['hormat'], ['respectful', 'discreet']),  # 謹
    "kanji_dou4_n1":       (['manik mata'], ['pupil']),  # 瞳
    "kanji_gi9_n1":        (['Dinasti Wei'], ['Wei (Chinese dynasty)']),  # 魏
    "kanji_bo3_n1":        (['bodhi (dalam kata majemuk)'], ['bodhi']),  # 菩
    "kanji_chou23_n1":     (['teko sake (dalam kata majemuk)'], ['sake pot']),  # 銚
    "kanji_shuu14_n1":     (['tahanan'], ['prisoner']),  # 囚
    "kanji_yabu_n1":       (['semak belukar (variant 藪)'], ['thicket', 'bush']),  # 薮
    "kanji_hitsu_n1":      (['mengeluarkan cairan'], ['secrete']),  # 泌
    "kanji_ki26_n1":       (['bunga hollyhock'], ['hollyhock']),  # 葵
    "kanji_sou22_n1":      (['alga'], ['seaweed']),  # 藻
    "kanji_shu7_n1":       (['bengkak'], ['swell', 'tumor']),  # 腫
    "kanji_ka18_n1":       (['istilah Buddhis (dalam kata majemuk)'], ['Buddhist term (in compounds)']),  # 迦  (manual)
    "kanji_hou18_n1":      (['burung phoenix (nama)'], ['phoenix']),  # 鳳
    "kanji_ko9_n1":        (['celana tradisional Jepang'], ['hakama']),  # 袴
    "kanji_ou7_n1":        (['burung camar'], ['seagull']),  # 鴎
    "kanji_shin16_n1":     (['Kota Shenyang', 'sari (klasik)'], ['Shenyang city', 'juice (classical)']),  # 瀋  (manual)
    "kanji_kashi_n1":      (['pohon ek (nama tempat)'], ['oak']),  # 橿
    "kanji_chou26_n1":     (['tanaman ivy'], ['ivy']),  # 蔦
    "kanji_gan8_n1":       (['kanker'], ['cancer']),  # 癌
    "kanji_fu10_n1":       (['lotus/hibiscus (dalam kata majemuk)'], ['lotus/hibiscus (in compounds)']),  # 芙  (manual)
    "kanji_toma2_n1":      (['nama keluarga langka (variant 苫)'], ['rare surname kanji (variant of 苫)']),  # 笘  (manual)
    "kanji_ki28_n1":       (['senang'], ['happy']),  # 嬉
    "kanji_han15_n1":      (['mendistribusikan'], ['distribute']),  # 頒
    "kanji_sou29_n1":      (['alat musik koto (variant)'], ['koto']),  # 箏
    "kanji_koku4_n1":      (['angsa', 'sasaran'], ['swan', 'target']),  # 鵠
    "kanji_kashi2_n1":     (['pohon ek'], ['oak']),  # 樫
    "kanji_uwasa_n1":      (['gosip'], ['rumor']),  # 噂
    "kanji_sou30_n1":      (['segar'], ['refreshing']),  # 爽
    "kanji_wai3_n1":       (['bengkok', 'terdistorsi'], ['distorted']),  # 歪
    "kanji_ru_n1":         (['lapis lazuli (dalam kata majemuk)'], ['lapis lazuli (in compounds)']),  # 瑠  (manual)
    "kanji_you13_n1":      (['jauh (variant 遙)'], ['distant']),  # 遥
    "kanji_shun5_n1":      (['Kaisar legendaris Shun (nama)'], ['legendary emperor Shun']),  # 舜
    "kanji_setsu5_n1":     (['Zhejiang (nama tempat)'], ['Zhejiang, China']),  # 浙
    "kanji_sugi2_n1":      (['cemara (kokuji, nama keluarga)'], ['cedar surname kanji']),  # 椙
    "kanji_chou29_n1":     (['ikan kakap merah'], ['sea bream']),  # 鯛
    "kanji_hou23_n1":      (['meniru'], ['imitate', 'follow example']),  # 倣
    "kanji_kai12_n1":      (['ikan salmon'], ['salmon']),  # 鮭
    "kanji_son3_n1":       (['ikan trout'], ['trout']),  # 鱒
    "kanji_yu5_n1":        (['buah yuzu'], ['yuzu citrus']),  # 柚
}

ID_PREFIX = ("meng", "meny", "memp", "mem", "men", "ber", "ter", "peng", "peny",
             "pem", "pen", "per", "ke", "di", "se")
ID_SUFFIX = ("kan", "nya", "an")


def toks(s):
    return [t.lower() for t in TOK.findall(s)]


def _load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def build_lexicons(kanji):
    """(indonesian counter, english counter) mined from the bundled datasets."""
    id_corpus = []
    for e in kanji:
        for w in e.get("wordExamples", []):
            if w.get("meaning") and not JP.search(w["meaning"]):
                id_corpus.append(w["meaning"])
        for s in e.get("sentenceExamples", []):
            if s.get("translation"):
                id_corpus.append(s["translation"])
    for path in glob.glob(os.path.join(DATA, "kotoba", "*.json")):
        if "_categories" in path:
            continue
        for e in _load(path):
            if e.get("meaning"):
                id_corpus.append(e["meaning"])
            for s in e.get("sentenceExamples", []):
                if s.get("translation"):
                    id_corpus.append(s["translation"])
    for e in _load(os.path.join(DATA, "bunpou_data.json")):
        for s in e.get("sentenceExamples", []):
            if s.get("translation"):
                id_corpus.append(s["translation"])
    for e in _load(os.path.join(DATA, "kaiwa_data.json")):
        for line in e.get("lines", []):
            npc = line.get("npcLine") or {}
            if npc.get("translation"):
                id_corpus.append(npc["translation"])
            for o in line.get("options") or []:
                if o.get("translation"):
                    id_corpus.append(o["translation"])
    for e in _load(os.path.join(DATA, "dictionary_data.json")):
        if e.get("meaning"):
            id_corpus.append(e["meaning"])
        ex = e.get("example") or {}
        if ex.get("translation"):
            id_corpus.append(ex["translation"])

    idf = collections.Counter()
    for s in id_corpus:
        idf.update(toks(s))
    enf = collections.Counter()
    for path in glob.glob(os.path.join(DATA, "kotoba", "*.json")):
        if "_categories" in path:
            continue
        for e in _load(path):
            if e.get("meaningEn"):
                enf.update(toks(e["meaningEn"]))
    return idf, enf


def tok_p_id(x, idf, enf):
    """Probability that a single token is Indonesian rather than English."""
    fi, fe = idf.get(x, 0), enf.get(x, 0)
    if fi + fe >= 6:
        return fi / (fi + fe)
    if fi >= 4 and fe == 0:
        return 0.95
    if fe >= 4 and fi == 0:
        return 0.05
    if len(x) >= 6 and x.startswith(ID_PREFIX) and x.endswith(ID_SUFFIX):
        return 0.9
    if len(x) >= 7 and x.startswith(ID_PREFIX):
        return 0.75
    if fi > fe:
        return 0.7
    if fe > fi:
        return 0.3
    return 0.5


def item_p_id(item, idf, enf):
    t = toks(item)
    if not t:
        return 0.5
    return sum(tok_p_id(x, idf, enf) for x in t) / len(t)


def split_k(ms, idf, enf):
    p = [item_p_id(m, idf, enf) for m in ms]
    best, bk = None, 0
    for k in range(len(ms) + 1):
        v = sum(p[:k]) + sum(1 - x for x in p[k:])
        if best is None or v > best + 1e-9:
            best, bk = v, k
    return bk


def main():
    dry = "--dry-run" in sys.argv
    kanji = _load(KANJI_JSON)
    idf, enf = build_lexicons(kanji)

    # bootstrap: confident splits enrich both lexicons, then re-split
    base_id, base_en = collections.Counter(idf), collections.Counter(enf)
    for _ in range(8):
        new_id, new_en = collections.Counter(base_id), collections.Counter(base_en)
        for e in kanji:
            ms = e["meanings"]
            k = split_k(ms, idf, enf)
            if 0 < k < len(ms):
                for it in ms[:k]:
                    new_id.update(toks(it))
                for it in ms[k:]:
                    new_en.update(toks(it))
        idf, enf = new_id, new_en

    overridden = auto = unsplit = 0
    for e in kanji:
        ms = e["meanings"]
        if e["id"] in OVERRIDES:
            id_side, en_side = OVERRIDES[e["id"]]
            overridden += 1
        else:
            k = split_k(ms, idf, enf)
            if 0 < k < len(ms):
                id_side, en_side = ms[:k], ms[k:]
                auto += 1
            else:
                # never leave a side empty: keep Indonesian as authored, no English
                id_side, en_side = ms, []
                unsplit += 1
        e["meanings"] = list(id_side)
        e["meaningsEn"] = list(en_side)

    print(f"kanji: {len(kanji)}  overrides={overridden}  auto={auto}  unsplit={unsplit}")
    missing = [e["character"] for e in kanji if not e["meaningsEn"]]
    print(f"entries with no English gloss: {len(missing)}"
          + (f" -> {''.join(missing[:20])}" if missing else ""))
    empty_id = [e["character"] for e in kanji if not e["meanings"]]
    assert not empty_id, f"Indonesian side must never be empty: {empty_id}"

    if dry:
        print("(dry run, nothing written)")
        return
    with open(KANJI_JSON, "w", encoding="utf-8") as f:
        json.dump(kanji, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"wrote {KANJI_JSON}")


if __name__ == "__main__":
    main()
