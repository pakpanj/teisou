# Canonical N5/N4/N3 character scope — the single source of truth both
# fetch_kanjivg.py (which SVGs to download) and the dataset-authoring
# scripts (which kanji to write full content for) import, so the two can
# never drift out of sync with each other.
#
# Landed at 107 N5 + 133 N4 (240 total) rather than the ~80/~170 targets:
# every kanji here is one I'm confident is standard/core for its level;
# none were cut or added just to hit a round number (same accuracy-first
# call as the Kotoba dataset). N5 runs a bit over ~80 because trimming
# well-established N5 kanji down to an exact count would mean cutting ones
# I'm sure about; N4 runs under ~170 because several borderline characters
# (戦/経/治/確 among them) were left out — confident of their
# reading/meaning, not confident enough of the *level* classification.
#
# N3_CHARACTERS (Batch 9) is sourced from the Tanos JLPT kanji list
# (http://www.tanos.co.uk/jlpt/jlpt3/kanji/, a widely-used community
# reference — there's no official JLPT kanji list) with every character
# already used in N5_CHARACTERS/N4_CHARACTERS removed (checked
# programmatically, not by eye — 52 of Tanos' N3 characters, including
# 戦/経/治/確, turned out to already be this project's N4 characters,
# which incidentally confirms those four were reasonable to classify as
# N4-adjacent-but-not-N4 back when Batch 8 left them out). 315 remain.
# Content is authored incrementally in batches against this locked list,
# same as N4 was — see generate_kanji_seed.py's N3_KANJI for how far
# that's gotten; most of these 315 are still awaiting real content.
#
# N2_CHARACTERS is sourced from jlptsensei.com's N2 kanji list (374
# characters across 4 paginated pages, fetched in frequency order) rather
# than Tanos this time — Tanos' own N2 page (both http and https) returned
# HTTP 500 during this session, so a different well-established community
# reference was used instead (same reasoning as always: no official JLPT
# kanji list exists, so any single source is a community convention, not
# an authority). Same dedup approach as N3: checked programmatically
# against N5_CHARACTERS/N4_CHARACTERS/N3_CHARACTERS, not by eye. 7 of the
# 374 fetched characters were already in this project's N5 (村森林) or N4
# (細軽弱浅) lists and were removed. 367 remain.
#
# N1_CHARACTERS is sourced from jlptsensei.com's N1 kanji list too (same
# reason as N2 — Tanos' N1 page also returned HTTP 500), 1504 characters
# across 16 paginated pages (page 16 has only 4), fetched in frequency
# order — this is by far the largest of the four locked lists, roughly
# 4x N2's size, and the tail end of the list (later pages) skews toward
# genuinely rare/name-only kanji rather than common vocabulary; content
# is still authored batch-by-batch in the same frequency order the source
# provides, so the most useful/common N1 kanji get real content first.
# Same dedup approach: checked programmatically, not by eye. 1 of the
# 1504 fetched characters (嫌) was already in this project's N4 list and
# was removed. 1503 remain.

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

N3_CHARACTERS = list(
    "政議民連対市内相定回選米関戦経最調化当約首"
    "法性要制治務成期取都和機平加受数記初指権支"
    "産点報済活原共得解交資予向際勝面告反判認参"
    "組信件側任引求次昨論官増係情投示打直両式確"
    "果容必演歳争談能位置流格疑過局放常状球職与"
    "供役構割費付説難優夫収断違消神番規術備宅害"
    "警席訪残想念助労限追商葉伝形景落退負渡失差"
    "末守種美命福望非観察段横申財港識呼達良候程"
    "満敗値突路積他処客否師登易速存殺号単座破除"
    "完責捕危給迎園具辞因馬愛富彼未舞亡冷適婦寄"
    "込類余王妻背熱宿薬険頼船途許抜便留罪努精散"
    "静婚喜浮絶幸押倒等老曲払庭徒勤居雑招欠更刻"
    "賛抱犯恐息願絵越欲痛笑互束似列探逃迷夢君緒"
    "折草暮酒晴掛到盗吸陽御歯吹娘誤慣礼窓貧怒祖"
    "杯疲皆鳴腹煙眠怖耳頂箱晩寒髪才靴恥偶偉猫幾"
)

N2_CHARACTERS = list(
    "党協総区領県設保改第結派府査委軍案策団各島"
    "革勢減再税営比防補境導副算輸述線農州武象域"
    "額欧担準賞辺造被技低復移個門課脳極含蔵量型"
    "況針専谷史階管兵接効丸湾録省旧橋岸周材戸央"
    "券編捜竹超並療採競介根販歴将幅般貿講装諸劇"
    "河航鉄児禁印逆換久短油暴輪占植清倍均億圧芸"
    "署伸停爆陸玉波帯延羽固則乱普測豊厚齢囲卒略"
    "承順岩練了庁城患層版令角絡損募裏仏績築貨混"
    "昇池血温季星永著誌庫刊像香坂底布寺宇巨震希"
    "触依籍汚枚複郵仲栄札板骨傾届巻燃跡包駐紹雇"
    "替預焼簡章臓律贈照薄群秒奥詰双刺純翌快片敬"
    "悩泉皮漁荒貯硬埋柱祭袋筆訓浴童宝封胸砂塩賢"
    "腕兆床毛緑尊祝柔殿濃液衣肩零幼荷泊黄甘臣掃"
    "雲掘捨軟沈凍乳恋紅郊腰炭踊冊勇械菜珍卵湖喫"
    "干虫刷湯溶鉱涙匹孫鋭枝塗軒毒叫拝氷乾棒祈拾"
    "粉糸綿汗銅湿瓶咲召缶隻脂蒸肌耕鈍泥隅灯辛磨"
    "麦姓筒鼻粒詞胃畳机膚濯塔沸灰菓帽枯涼舟貝符"
    "憎皿肯燥畜坊挟曇滴伺"
)

N1_CHARACTERS = list(
    "氏統基価提挙応企検藤沢裁証援可施井護展態鮮"
    "視条幹独宮率衛張監環審義訴株姿閣韓衆評岡影"
    "松撃佐核整融製票渉響推請器士討攻崎督授催及"
    "憲離激摘系批郎健従修隊織拡故振弁就異献厳維"
    "浜遺塁邦素遣抗模雄益緊標宣昭廃伊江僚吉盛皇"
    "臨踏壊債興源儀創障継筋狙闘葬避司康善逮迫惑"
    "崩紀聴脱級博締救執房撤削密措志載陣我為抑幕"
    "染奈傷択秀徴弾償功拠秘拒刑塚致繰尾描鈴盤項"
    "喪伴養懸街契掲躍棄邸縮還属慮枠恵露沖緩節需"
    "射購揮充貢鹿却端賃獲郡併徹貴埼衝焦奪災浦析"
    "譲称納樹挑誘紛至宗促慎控智握宙俊銭渋銃操携"
    "診託撮誕侵括謝孝駆透津壁稲仮裂敏是排裕堅訳"
    "芝綱典賀扱顧弘看訟戒祉誉歓奏勧騒閥甲縄郷揺"
    "免既薦隣華範隠徳哲杉里釈己妥威豪熊滞微隆症"
    "暫忠倉彦肝喚沿妙唱阿索誠襲懇俳柄驚麻李浩剤"
    "瀬趣陥斎貫仙慰序旬兼聖旨即柳舎偽較覇畑詳抵"
    "脅茂犠旗距雅飾網竜詩繁翼茨潟敵魅斉敷擁圏酸"
    "罰滅礎腐脚菱潮梅尽僕桜滑孤煕炎賠句寿鋼頑鎖"
    "彩摩励縦輝蓄軸巡稼瞬砲噴誇祥牲秩帝宏唆阻泰"
    "賄撲堀菊絞縁唯膨耐塾漏慶猛芳懲剣幌彰棋丁恒"
    "揚冒之曽倫陳憶潜梨仁克岳概拘墓黙須偏雰遇諮"
    "狭卓亀糧梶簿炉牧殊殖艦輩穴奇慢鶴謀暖昌拍朗"
    "丈寛覆胞泣隔浄没暇肺貞靖鑑飼陰銘随烈尋渕稿"
    "丹啓也丘棟壌漫玄粘悟舗妊熟旭恩騰往豆遂狂栃"
    "岐陛緯培衰艇屈径淡抽披廷錦准暑磯奨浸剰胆繊"
    "駒虚孜霊帳悔諭惨虐翻墜沼据肥徐糖搭盾脈滝軌"
    "俵妨盧擦鯨荘諾雷漂懐勘栽拐笠駄添冠斜鏡聡浪"
    "亜覧詐壇勲魔酬紫曙紋卸奮趙欄逸涯拓眼獄筑尚"
    "阜彫穏顕巧矛垣欺釣萩粧葛粛栗愚嘉遭架篠鬼庶"
    "稚菅滋幻煮姫誓把践呈疎仰剛疾征砕謡嫁謙后嘆"
    "俣菌鎌巣頻琴班淵棚潔酷宰廊寂辰霞伏柏碁俗漠"
    "邪晶辻墨鎮洞履劣那殴娠奉憂朴亭淳荻嶋怪鳩柴"
    "酔惜穫佳潤悼乏該赴桑桂髄虎盆晋穂壮堤飢傍疫"
    "累痴搬晃癒桐寸郭尿凶吐宴鷹賓虜陶鐘憾畿猪紘"
    "磁弥昆粗訂芽尻庄傘敦騎寧循忍磐怠如寮祐鵬鉛"
    "珠凝苗獣哀跳匠垂蛇澄縫僧眺唐亘呉凡憩鄭芦龍"
    "媛溝恭刈睡錯伯笹穀柿陵霧魂弊釧妃舶餓腎窮掌"
    "麗綾臭釜悦刃縛暦宜盲粋辱毅轄猿弦嶌稔窒炊洪"
    "摂飽函冗桃狩朱渦紳枢碑鍛刀鼓裸鴨猶塊旋弓幣"
    "膜扇脇腸槽鍋慈樋楊伐駿漬糾亮墳坪紺慌娯吾椿"
    "舌羅峡俸厘峰圭醸蓮弔乙倶汁尼遍堺衡呆薫瓦猟"
    "羊窪款閲雀偵喝敢畠胎酵憤豚遮扉硫赦挫窃泡瑞"
    "又慨紡恨肪扶戯伍忌濁奔斗蘭蒲迅肖鉢朽殻享秦"
    "茅藩沙輔媒鶏禅嘱胴粕冨迭挿湘嵐椎灘堰獅姜絹"
    "陪剖譜郁悠淑帆暁鷲傑楠笛芥其玲奴錠拳翔遷拙"
    "侍尺峠篤肇渇榎劉幡諏叔雌亨堪叙酢吟逓痕嶺袖"
    "甚喬崔妖琵琶聯蘇闇崇漆岬癖愉寅捉礁乃洲屯樽"
    "樺槙薩姻巌淀麹賭擬塀唇睦閑胡幽峻曹哨詠炒屏"
    "卑侮鋳抹尉槻隷禍蝶酪茎汎頃帥梁逝汽謎琢箕匿"
    "爪芭逗苫鍵襟蛍楢蕉兜寡琉痢庸朋坑姑烏藍僑賊"
    "搾奄臼畔遼唄孔橘漱呂桧拷宋嬢苑巽杜渓翁藝廉"
    "牙謹瞳湧欣窯褒醜魏篇升此峯殉煩巴禎枕劾菩堕"
    "丼租檜稜牟桟榊錫荏惧倭婿慕廟銚斐罷矯某囚魁"
    "薮虹鴻泌於赳漸逢凧鵜庵膳蚊葵厄藻萬禄孟鴈狼"
    "嫡呪斬尖翫嶽尭怨卿串已嚇巳凸暢腫粟燕韻綴埴"
    "霜餅魯硝牡箸勅芹杏迦棺儒鳳馨斑蔭焉慧祇摯愁"
    "鷺楼彬袴匡眉苅讃尹欽薪湛堆狐褐鴎瀋挺賜嵯雁"
    "佃綜繕狛壷橿栓翠鮎芯蜜播榛凹艶帖桶惣股匂鞍"
    "蔦玩萱梯雫絆錬湊蜂隼舵渚珂煥衷逐斥稀癌峨嘘"
    "旛篭芙詔皐雛娼篆鮫椅惟牌宕喧佑蒋樟耀黛叱櫛"
    "渥挨憧濡槍宵襄妄惇蛋脩笘宍甫酌蚕壕嬉囃蒼餌"
    "簗峙粥舘銕鄒蜷暉捧頒只肢箏檀鵠凱彗謄諌樫噂"
    "脊牝梓洛醍砦丑笏蕨噺抒嗣隈叶凄汐絢叩嫉朔蔡"
    "膝鍾仇伽夷恣瞑畝抄杭寓麺戴爽裾黎惰坐鍼蛮塙"
    "冴旺葦礒咸萌饗歪冥偲壱瑠韮漕杵薔膠允眞蒙蕃"
    "呑侯碓茗麓瀕蒔鯉竪弧稽瘤澤溥遥蹴或訃矩厦冤"
    "剥舜侠贅杖蓋畏喉汪猷瑛搜曼附彪撚噛卯桝撫喋"
    "但溢闊藏浙彭淘剃揃綺徘巷竿蟹芋袁舩拭茜凌頬"
    "厨犀簑皓甦洸毬檄姚蛭婆叢椙轟贋洒貰儲緋諜鯛"
    "蓼甕喘怜溜邑鉾倣碧燈諦煎瓜緻哺槌啄穣嗜偕罵"
    "酉蹄頚胚牢糞悌吊楕鮭乞倹嗅詫鱒蔑轍醤惚廣藁"
    "柚舛縞謳杞鱗繭釘弛狸壬硯"
)


def _assert_no_overlap():
    n5, n4, n3, n2, n1 = (
        set(N5_CHARACTERS),
        set(N4_CHARACTERS),
        set(N3_CHARACTERS),
        set(N2_CHARACTERS),
        set(N1_CHARACTERS),
    )
    assert len(n5) == len(N5_CHARACTERS), "duplicate within N5_CHARACTERS"
    assert len(n4) == len(N4_CHARACTERS), "duplicate within N4_CHARACTERS"
    assert len(n3) == len(N3_CHARACTERS), "duplicate within N3_CHARACTERS"
    assert len(n2) == len(N2_CHARACTERS), "duplicate within N2_CHARACTERS"
    assert len(n1) == len(N1_CHARACTERS), "duplicate within N1_CHARACTERS"
    assert not (n5 & n4), f"overlap between N5 and N4: {sorted(n5 & n4)}"
    assert not (n3 & n5), f"overlap between N3 and N5: {sorted(n3 & n5)}"
    assert not (n3 & n4), f"overlap between N3 and N4: {sorted(n3 & n4)}"
    assert not (n2 & n5), f"overlap between N2 and N5: {sorted(n2 & n5)}"
    assert not (n2 & n4), f"overlap between N2 and N4: {sorted(n2 & n4)}"
    assert not (n2 & n3), f"overlap between N2 and N3: {sorted(n2 & n3)}"
    assert not (n1 & n5), f"overlap between N1 and N5: {sorted(n1 & n5)}"
    assert not (n1 & n4), f"overlap between N1 and N4: {sorted(n1 & n4)}"
    assert not (n1 & n3), f"overlap between N1 and N3: {sorted(n1 & n3)}"
    assert not (n1 & n2), f"overlap between N1 and N2: {sorted(n1 & n2)}"


_assert_no_overlap()

if __name__ == "__main__":
    print(f"N5: {len(N5_CHARACTERS)} kanji")
    print(f"N4: {len(N4_CHARACTERS)} kanji")
    print(f"N3: {len(N3_CHARACTERS)} kanji")
    print(f"N2: {len(N2_CHARACTERS)} kanji")
    print(f"N1: {len(N1_CHARACTERS)} kanji")
    print(
        "Combined: "
        f"{len(N5_CHARACTERS) + len(N4_CHARACTERS) + len(N3_CHARACTERS) + len(N2_CHARACTERS) + len(N1_CHARACTERS)} kanji"
    )
