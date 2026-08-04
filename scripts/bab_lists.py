# Canonical Bab (curriculum chapter) scope — the single source of truth
# generate_bab_seed.py imports to build assets/data/bab_data.json.
#
# Each chapter is an ORIGINAL theme (not a Minna no Nihongo title, not any
# other textbook's title) that bundles ids the team already authored across
# kotoba_data.json / kanji_data.json / bunpou_data.json / particle_data.json
# / kaiwa_data.json / dokkai_data.json into a Minna-*inspired*,
# difficulty-escalating order — vocabulary -> grammar/particle -> dialogue,
# with kanji/reading as optional extras. generate_bab_seed.py cross-checks
# every id below against those six generated datasets before writing
# bab_data.json, so a typo'd id fails the build loudly instead of becoming
# a silent dead link at runtime.
#
# 31 N5 chapters so far, hand-picked from content already authored in past
# sessions (plus 4 brand-new N5 grammar entries added in the SYLLABUS FIX
# PASS below) — not the full curriculum. Expanding to more N5 chapters and
# then N4-N1 is future-session work, same "batch 1 of many" shape as this
# project's other content rollouts (Dokkai, Dictionary).
#
# REORDER PASS (2026-08-03), grammar-difficulty tiers sourced from the real
# Minna no Nihongo Shokyuu I book (359-page scan, "Minna nihongo 1.pdf" in
# the user's Downloads folder — read directly, page by page, structure only,
# nothing reproduced) plus general SLA sequencing guidance (sentence
# structure -> particles -> basic verb/adjective forms -> compound patterns;
# vocab+grammar learned together, not vocab-first). Every one of Minna's 25
# real lessons was identified from the scan:
# L1 copula (da/desu, wa, mo, no, san) -> L2 demonstratives (kore/sore/are)
# -> L3 location words (koko/soko/asoko) -> L4 time (nan-ji, kara/made) ->
# L5 dates (itsu) -> L6 transitive verbs + the o object particle
# (tabemasu/nomimasu/kaimasu, K.Benda o K.Kerja) -> L7 agemasu/moraimasu ->
# L8 adjectives (i/na + totemo/amari) -> L9 wakarimasu + jouzu/heta -> L10
# arimasu/imasu + ue/shita -> L11 counting -> L12 comparison -> L13 purpose
# of movement -> L14 -te + -te kudasai -> L15 -te imasu -> L16-19 more -te
# patterns -> L20-25 plain/casual form and beyond (N4-adjacent, out of this
# app's current N5 Bab scope).
#
# SYLLABUS FIX PASS (2026-08-03, later the same day as the reorder above):
# the reorder pass above only resequenced the *existing* 25 chapters — it
# explicitly did NOT fix the real content gaps that comparison against
# Minna's real lesson list surfaced (demonstratives, location words, the
# basic verb negative, giving/receiving, comparison, and jouzu/heta skill
# expressions), because at the time none of that grammar existed in
# bunpou_data.json, so no chapter could point at it. The user asked
# directly afterward to close these gaps: author new grammar where the
# dataset was missing it, and where a chapter only needed image assets
# (not a new dataset), just wire up the correct `imagePath` convention and
# leave the actual asset generation/upload to the user's own external
# pipeline (same Firebase Storage convention every other Kotoba/Kaiwa image
# already uses — nothing new to build there, it already works this way).
#
# Checked bunpou_data.json before assuming anything was missing (don't
# guess — verify): comparison (bunpou_wa_yori_desu, bunpou_yori_hou_ga) and
# skill (bunpou_no_ga_jouzu, bunpou_no_ga_heta) already existed in the real
# 85-entry N5 set, just never used by any Bab chapter — no new grammar
# needed for those two, only new chapters to feature them. Four genuinely
# did not exist anywhere in the dataset (checked with a precise id grep,
# not a fuzzy substring match, which produced false positives against
# unrelated N2/N1 compound patterns like kono_ue_nai/sono_tame_ni on the
# first pass): kore/sore/are + kono/sono/ano (demonstratives, Minna L2),
# koko/soko/asoko (location words, L3), the basic polite verb negative
# ~masen (nothing in the dataset covered plain verb negation — only
# compound patterns built ON TOP of the negative stem, like naide_kudasai/
# nakute_wa_ikenai, existed), and agemasu/moraimasu (giving/receiving,
# L7). All four were authored as new N5 entries in generate_bunpou_seed.py
# (`bunpou_kore_sore_are`/`bunpou_koko_soko_asoko`/`bunpou_masen`/
# `bunpou_agemasu_moraimasu`), added to the locked `N5_GRAMMAR` list in
# bunpou_grammar_lists.py (85 -> 89, explicitly marked as NOT sourced from
# jlptsensei.com's list, same deliberate-gap-fill precedent as the earlier
# `bunpou_te_kei` fix), and given English translations in
# bunpou_meaning_en.py immediately after regenerating (the same
# regenerating-wipes-English gotcha documented elsewhere in this project
# applies every time N5_GRAMMAR_ENTRIES changes).
#
# For each of these 4 new grammar points plus the 2 existing-but-unused
# ones, a real N5 Kaiwa dialogue that *already* genuinely uses that
# grammar was found by grepping the whole N5 dialogue set (all 680, not
# just what's already claimed by other Bab chapters) rather than
# authoring a brand-new dialogue from scratch — e.g. `kaiwa_kenalan_
# keluarga`'s own line "これは私の家族の写真です。" already uses これ
# naturally, so the new demonstratives chapter's own bunpou sentence
# example reuses that exact phrase verbatim, guaranteeing kotoba/bunpou/
# kaiwa sync from the very first commit rather than needing a follow-up
# fix like the one documented below for the original 25 chapters. Every
# one of the 6 new chapters' kotoba_ids was chosen the same way: a real,
# already-existing Kotoba entry (never a new one — none needed authoring)
# whose word/kanji field literally appears in that chapter's own
# bunpou_ids sentence examples or kaiwa_ids dialogue text. Where a useful
# word happened to be one that had been swapped OUT of an earlier chapter
# during the original sync-fix pass (ともだち/tomodachi, swapped out of
# the greetings chapter because it didn't fit there) — it found a genuine
# home here instead (the giving/receiving chapter's `kaiwa_jenguk_teman_
# sakit_sekolah`, about visiting a sick friend, where 友達 actually
# appears in the dialogue) rather than being reintroduced somewhere it
# still wouldn't sync.
#
# No new Kotoba words, no new Kaiwa dialogues, and no new images were
# needed for this pass — every one of the 6 new chapters was built purely
# by combining newly-written Bunpou grammar with vocabulary and dialogue
# that already existed. If a future chapter genuinely needs a Kotoba word
# that doesn't exist yet, follow the same imagePath convention every other
# Kotoba entry already uses (`kotoba_images/{category}/{entry_id}.png`,
# see the Kotoba image note elsewhere in CLAUDE.md) — the app already
# renders a graceful placeholder until the real asset is uploaded to
# Firebase Storage, so authoring the entry and wiring its imagePath is a
# complete, working chapter on its own; generating and uploading the
# actual illustration is a separate, later step, same as this project's
# standing Kotoba/Kaiwa image backlog.
#
# Each of the 25 original chapters was assigned a tier by its OWN hardest
# bunpou_ids entry (not its easiest), matched to the closest real Minna
# lesson number above; the 6 new chapters were slotted into the same tier
# scheme at their own correct Minna-lesson position:
#   tier L1  (copula)              -> menyapa, pekerjaan, negara_dan_asal,
#                                      ulang_tahun_dan_umur
#   tier L2  (demonstratives) NEW  -> kore_sore_are
#   tier L3  (location words) NEW  -> koko_soko_asoko
#   tier L10 (arimasu/imasu)       -> keluarga, hewan_peliharaan, di_rumah,
#                                      di_rumah_sakit
#   tier L7  (agemasu/moraimasu) NEW -> memberi_dan_menerima
#   tier ~L6 (basic verb negative) NEW -> mengatakan_tidak
#   tier L4  (kara/made/ni_e/de)   -> menanyakan_arah, stasiun_dan_
#                                      transportasi, hari_dan_jadwal,
#                                      rencana_liburan, cuaca_dan_basa_basi
#   tier L9  (jouzu/heta skill)    -> bisa_dan_tidak_bisa (existing bunpou,
#                                      first chapter to use it)
#   tier L8+ (donna/no_ga_suki)    -> olahraga, warna, musim, bioskop
#   tier L12 (comparison)          -> perbandingan (existing bunpou, first
#                                      chapter to use it)
#   tier ~L13 (o_kudasai/ga_hoshii)-> belanja, di_restoran, angka_dan_uang,
#                                      buah_dan_sayuran
#   tier L14  (-te / -te kudasai)  -> bentuk_te_dan_minta_tolong,
#                                      di_sekolah, telepon
#   tier L15  (-te imasu)          -> kegiatan_sehari_hari (last: needs the
#                                      -te form chapter above it — -te
#                                      forms are genuinely one of the more
#                                      advanced structures in the beginner
#                                      tier, not an early one)
#
# Chapter order is still a deliberate teaching sequence, not just a list
# order — "bab_bentuk_te_dan_minta_tolong" exists specifically to teach -te
# form conjugation *before* "bab_di_sekolah", which already uses the
# ~てください pattern without ever explaining how to build a -te form (that
# dependency survived both the reorder and this syllabus-fix pass
# unchanged: the two chapters are still consecutive). If a future chapter
# needs a grammar/vocab prerequisite that doesn't exist yet, add the
# prerequisite as its own chapter earlier in the sequence rather than
# assuming the learner already knows it.
#
# Known deferred gap, NOT fixed yet (deliberately, per explicit user
# request to keep making Bab progress before reorganizing Bunpou further):
# several real N5 Bunpou patterns (bunpou_masen_ka, bunpou_mashou,
# bunpou_mashou_ka, bunpou_ni_iku, bunpou_tai, bunpou_kata) require
# deriving a verb's ~masu stem, and — same as the -te form gap fixed
# earlier — nothing in this dataset teaches ~masu-form conjugation itself
# either (only the ~masu -> ~masen swap this pass just added, which
# assumes the ~masu form is already known, same as bunpou_te_kei assumed
# the dictionary form was already known). None of the 31 chapters use
# these six patterns for exactly that reason. Also still not built:
# counting/counters (Minna L11, e.g. -tsu/-nin/-dai) and full "N wa N
# desu" location words paired with ue/shita (Minna L10's second half) —
# both real, both smaller in scope than what this pass closed, both
# candidates for a future pass rather than lost/forgotten.
#
# CROSS-CONTENT SYNC PASS (2026-08-03, earlier the same day as the reorder
# and syllabus-fix passes above): the user caught a real design flaw by
# hand — tapping ともだち (the original vocab pick for the greetings
# chapter) opened its own pre-authored example sentence ("友達と遊びます。"),
# which uses と and a ~ます verb, NEITHER of which that chapter actually
# teaches, and the word never appeared in that chapter's だ/です・は・か
# examples or its Kaiwa dialogue either — three lists sitting side by side
# with zero lexical overlap, not an integrated lesson. Every one of the
# original 25 chapters' `kotoba_ids` was re-audited against that same
# test: does this word's own `word`/`kanji` literally appear inside the
# chapter's chosen `bunpou_ids`' sentenceExamples or `kaiwa_ids`' dialogue
# lines? Words that failed were swapped for a different real,
# already-existing Kotoba entry that DOES appear in that same text (found
# by searching the *entire* Kotoba dataset for a literal substring match,
# not just the original source category) — e.g. the greetings chapter's
# ともだち became 学生, since 学生 is literally what both だ/です's own
# example ("私は学生です。") and the Kaiwa dialogue itself already say. For
# tightly closed sets that are pedagogically worth teaching as a whole
# (numbers, colors, days, seasons, cardinal directions), the full set was
# kept and a genuinely-matching word added on top rather than gutting the
# set for sync's sake — a deliberate judgment call, not an oversight if a
# handful of members in those sets still don't literally appear verbatim.
# Re-run this same audit (see the sync-check scripts used for this pass,
# not checked in — regenerate by extracting sentenceExamples/dialogue text
# per chapter and substring-matching against the full Kotoba dataset) after
# adding any future chapter, rather than picking vocab by theme alone —
# the 6 new chapters in this file's syllabus-fix pass were built with this
# check in mind from the start (see above), not retrofitted afterward.

N5_CHAPTERS = [
    dict(
        id="bab_menyapa_dan_berkenalan",
        level="N5",
        title="Menyapa dan Berkenalan",
        title_en="Greetings and Introductions",
        description="Ucapan dasar dan cara memperkenalkan diri ke teman baru.",
        description_en="Basic phrases and how to introduce yourself to a new friend.",
        kotoba_ids=["kotoba_profesi_gakusei"],
        bunpou_ids=["bunpou_da_desu", "bunpou_wa", "bunpou_ka"],
        particle_ids=["particle_wa", "particle_ka"],
        kaiwa_ids=["kaiwa_kenalan_teman_baru"],
    ),
    dict(
        id="bab_pekerjaan",
        level="N5",
        title="Pekerjaan",
        title_en="Occupation",
        description="Kosakata pekerjaan dan cara menanyakan profesi seseorang.",
        description_en="Occupation vocabulary and how to ask what someone does.",
        kotoba_ids=[
            "kotoba_profesi_gakusei",
            "kotoba_pekerjaan_kantor_kaisha",
            "kotoba_pekerjaan_kantor_shigoto",
            "kotoba_profesi_kaishain",
        ],
        bunpou_ids=["bunpou_da_desu", "bunpou_mo"],
        particle_ids=["particle_wa", "particle_mo"],
        kaiwa_ids=["kaiwa_tanya_pekerjaan"],
    ),
    dict(
        id="bab_negara_dan_asal",
        level="N5",
        title="Negara dan Asal",
        title_en="Countries and Origin",
        description="Nama-nama negara dan cara menanyakan asal seseorang.",
        description_en="Country names and how to ask where someone is from.",
        kotoba_ids=[
            "kotoba_negara_kota_nihon",
            "kotoba_negara_kota_indoneshia",
            "kotoba_mata_pelajaran_nihongo",
        ],
        bunpou_ids=["bunpou_kara", "bunpou_no"],
        particle_ids=["particle_kara", "particle_no"],
        kaiwa_ids=["kaiwa_tanya_asal_negara"],
    ),
    dict(
        id="bab_ulang_tahun_dan_umur",
        level="N5",
        title="Ulang Tahun dan Umur",
        title_en="Birthday and Age",
        description="Cara menanyakan umur dan membicarakan ulang tahun.",
        description_en="How to ask someone's age and talk about birthdays.",
        kotoba_ids=[
            "kotoba_perayaan_haribesar_tanjoubi",
            "kotoba_angka_satuan_ni",
            "kotoba_angka_satuan_juu",
            "kotoba_perayaan_haribesar_oiwai",
        ],
        bunpou_ids=["bunpou_da_desu", "bunpou_ka"],
        particle_ids=["particle_ka"],
        kaiwa_ids=["kaiwa_tanya_umur"],
    ),
    dict(
        id="bab_kore_sore_are",
        level="N5",
        title="Ini, Itu, dan Itu (di Sana)",
        title_en="This, That, and That Over There",
        description="Cara menunjuk benda dengan これ/それ/あれ dan この/その/あの.",
        description_en="How to point at things using kore/sore/are and kono/sono/ano.",
        kotoba_ids=["kotoba_hobi_aktivitas_shashin"],
        bunpou_ids=["bunpou_kore_sore_are"],
        particle_ids=["particle_wa"],
        kaiwa_ids=["kaiwa_kenalan_keluarga"],
    ),
    dict(
        id="bab_koko_soko_asoko",
        level="N5",
        title="Di Sini, Di Situ, dan Di Sana",
        title_en="Here, There, and Over There",
        description="Cara menunjuk tempat dengan ここ/そこ/あそこ.",
        description_en="How to point at places using koko/soko/asoko.",
        kotoba_ids=["kotoba_teknologi_gadget_waifai"],
        bunpou_ids=["bunpou_koko_soko_asoko"],
        particle_ids=["particle_ga"],
        kaiwa_ids=["kaiwa_tanya_wifi_restoran"],
    ),
    dict(
        id="bab_keluarga_dan_teman",
        level="N5",
        title="Keluarga dan Teman",
        title_en="Family and Friends",
        description="Kosakata anggota keluarga dan cara membicarakannya.",
        description_en="Family-member vocabulary and how to talk about them.",
        kotoba_ids=[
            "kotoba_keluarga_hubungan_kazoku",
            "kotoba_keluarga_hubungan_chichi",
            "kotoba_keluarga_hubungan_haha",
            "kotoba_keluarga_hubungan_ani",
            "kotoba_keluarga_hubungan_otouto",
            "kotoba_keluarga_hubungan_kyoudai",
            "kotoba_keluarga_hubungan_kodomo",
        ],
        bunpou_ids=["bunpou_ga_imasu", "bunpou_mo"],
        particle_ids=["particle_no", "particle_mo"],
        kaiwa_ids=["kaiwa_kenalkan_keluarga"],
    ),
    dict(
        id="bab_hewan_peliharaan",
        level="N5",
        title="Hewan Peliharaan",
        title_en="Pets",
        description="Nama-nama hewan dan cara membicarakan hewan peliharaan.",
        description_en="Animal names and how to talk about pets.",
        kotoba_ids=[
            "kotoba_hewan_darat_inu",
            "kotoba_hewan_darat_neko",
            "kotoba_hewan_darat_panda",
            "kotoba_hewan_darat_koala",
        ],
        bunpou_ids=["bunpou_ga_imasu", "bunpou_totemo"],
        particle_ids=["particle_ga"],
        kaiwa_ids=["kaiwa_tanya_hewan_peliharaan_kenalan"],
    ),
    dict(
        id="bab_di_rumah",
        level="N5",
        title="Di Rumah",
        title_en="At Home",
        description="Kosakata ruangan rumah dan cara membicarakan rumah keluarga.",
        description_en="Room vocabulary and how to talk about a family home.",
        kotoba_ids=[
            "kotoba_ruangan_rumah_heya",
            "kotoba_ruangan_rumah_niwa",
            "kotoba_keluarga_hubungan_jikka",
        ],
        bunpou_ids=["bunpou_ga_arimasu", "bunpou_ni"],
        particle_ids=["particle_ni"],
        kaiwa_ids=["kaiwa_rumah_keluarga"],
    ),
    dict(
        id="bab_di_rumah_sakit",
        level="N5",
        title="Di Rumah Sakit",
        title_en="At the Hospital",
        description="Kosakata bagian tubuh dan cara menjelaskan sakit ke dokter.",
        description_en="Body-part vocabulary and how to describe pain to a doctor.",
        kotoba_ids=[
            "kotoba_obat_obatan_byouin",
            "kotoba_obat_obatan_kusuri",
            "kotoba_penyakit_gejala_itai",
            "kotoba_anggota_tubuh_atama",
        ],
        bunpou_ids=["bunpou_ga", "bunpou_totemo"],
        particle_ids=["particle_ga"],
        kaiwa_ids=["kaiwa_jelaskan_sakit"],
    ),
    dict(
        id="bab_memberi_dan_menerima",
        level="N5",
        title="Memberi dan Menerima",
        title_en="Giving and Receiving",
        description="Cara memberi sesuatu ke orang lain dan menerima sesuatu dari orang lain.",
        description_en="How to give something to someone and receive something from someone.",
        kotoba_ids=[
            "kotoba_keluarga_hubungan_tomodachi",
            "kotoba_alat_tulis_sekolah_shukudai",
        ],
        bunpou_ids=["bunpou_agemasu_moraimasu"],
        particle_ids=["particle_ni"],
        kaiwa_ids=["kaiwa_jenguk_teman_sakit_sekolah"],
    ),
    dict(
        id="bab_mengatakan_tidak",
        level="N5",
        title="Mengatakan Tidak",
        title_en="Saying No",
        description="Cara mengatakan tidak melakukan atau tidak memiliki sesuatu dengan bentuk ~ません.",
        description_en="How to say you don't do or don't have something using the ~masen form.",
        kotoba_ids=["kotoba_teknologi_gadget_denwa"],
        bunpou_ids=["bunpou_masen"],
        particle_ids=["particle_wa"],
        kaiwa_ids=["kaiwa_tukar_nomor"],
    ),
    dict(
        id="bab_cuaca_dan_basa_basi",
        level="N5",
        title="Cuaca dan Basa-basi",
        title_en="Weather and Small Talk",
        description="Kosakata cuaca dan basa-basi ringan tentang cuaca hari ini.",
        description_en="Weather vocabulary and light small talk about today's weather.",
        kotoba_ids=[
            "kotoba_cuaca_tenki",
            "kotoba_cuaca_ame",
            "kotoba_cuaca_kaze",
        ],
        bunpou_ids=["bunpou_totemo", "bunpou_ne"],
        particle_ids=["particle_ne"],
        kaiwa_ids=["kaiwa_bicara_cuaca"],
    ),
    dict(
        id="bab_menanyakan_arah",
        level="N5",
        title="Menanyakan Arah",
        title_en="Asking for Directions",
        description="Kata penunjuk arah dan cara bertanya jalan ke suatu tempat.",
        description_en="Direction words and how to ask the way to a place.",
        kotoba_ids=[
            "kotoba_arah_lokasi_migi",
            "kotoba_arah_lokasi_hidari",
            "kotoba_arah_lokasi_mae",
            "kotoba_arah_lokasi_ushiro",
            "kotoba_bangunan_fasilitas_gakkou",
        ],
        bunpou_ids=["bunpou_ni_e", "bunpou_made"],
        particle_ids=["particle_ni", "particle_made"],
        kaiwa_ids=["kaiwa_jalan_ke_stasiun"],
    ),
    dict(
        id="bab_stasiun_dan_transportasi",
        level="N5",
        title="Stasiun dan Transportasi",
        title_en="Station and Transportation",
        description="Kosakata kendaraan dan cara membeli tiket di stasiun.",
        description_en="Vehicle vocabulary and how to buy a ticket at the station.",
        kotoba_ids=[
            "kotoba_kendaraan_basu",
            "kotoba_negara_kota_toukyou",
        ],
        bunpou_ids=["bunpou_de", "bunpou_kara"],
        particle_ids=["particle_de", "particle_kara"],
        kaiwa_ids=["kaiwa_beli_tiket"],
    ),
    dict(
        id="bab_hari_dan_jadwal",
        level="N5",
        title="Hari dan Jadwal",
        title_en="Days and Schedule",
        description="Kata keterangan waktu dan cara membuat janji temu.",
        description_en="Time-reference vocabulary and how to make an appointment.",
        kotoba_ids=[
            "kotoba_hari_bulan_raishuu",
            "kotoba_hari_bulan_gogo",
            "kotoba_bangunan_fasilitas_yoyaku",
        ],
        bunpou_ids=["bunpou_kara", "bunpou_made"],
        particle_ids=["particle_kara", "particle_made"],
        kaiwa_ids=["kaiwa_janji_temu"],
    ),
    dict(
        id="bab_rencana_liburan",
        level="N5",
        title="Rencana Liburan",
        title_en="Vacation Plans",
        description="Tempat wisata dan cara membicarakan rencana liburan.",
        description_en="Tourist spots and how to talk about vacation plans.",
        kotoba_ids=[
            "kotoba_hobi_aktivitas_ryokou",
            "kotoba_negara_kota_kyouto",
            "kotoba_hari_bulan_raigetsu",
        ],
        bunpou_ids=["bunpou_ka_ka", "bunpou_totemo"],
        particle_ids=["particle_ya"],
        kaiwa_ids=["kaiwa_tempat_wisata"],
    ),
    dict(
        id="bab_bisa_dan_tidak_bisa",
        level="N5",
        title="Bisa dan Tidak Bisa",
        title_en="Good At and Not Good At",
        description="Cara mengatakan mahir atau tidak mahir melakukan sesuatu dengan 上手/下手.",
        description_en="How to say you're good or not good at something using jouzu/heta.",
        kotoba_ids=["kotoba_hobi_aktivitas_e"],
        bunpou_ids=["bunpou_no_ga_jouzu", "bunpou_no_ga_heta"],
        particle_ids=["particle_ga"],
        kaiwa_ids=["kaiwa_melukis"],
    ),
    dict(
        id="bab_olahraga",
        level="N5",
        title="Olahraga",
        title_en="Sports",
        description="Kosakata olahraga dan cara mengatakan olahraga favorit.",
        description_en="Sports vocabulary and how to say your favorite sport.",
        kotoba_ids=[
            "kotoba_olahraga_supootsu",
            "kotoba_olahraga_basukettobooru",
        ],
        bunpou_ids=["bunpou_no_ga_suki", "bunpou_totemo"],
        particle_ids=["particle_o"],
        kaiwa_ids=["kaiwa_olahraga_favorit"],
    ),
    dict(
        id="bab_warna",
        level="N5",
        title="Warna",
        title_en="Colors",
        description="Nama-nama warna dan cara menyebutkan warna favorit.",
        description_en="Color names and how to say your favorite color.",
        kotoba_ids=[
            "kotoba_aka",
            "kotoba_ao",
            "kotoba_warna_midori",
            "kotoba_warna_kiiroi",
            "kotoba_warna_kuroi",
        ],
        bunpou_ids=["bunpou_donna", "bunpou_no_ga_suki"],
        particle_ids=["particle_ga"],
        kaiwa_ids=["kaiwa_tanya_warna_favorit"],
    ),
    dict(
        id="bab_musim",
        level="N5",
        title="Musim",
        title_en="Seasons",
        description="Nama-nama musim dan cara menyebutkan musim favorit.",
        description_en="Season names and how to say your favorite season.",
        kotoba_ids=[
            "kotoba_musim_haru",
            "kotoba_musim_natsu",
            "kotoba_musim_aki",
            "kotoba_musim_fuyu",
            "kotoba_musim_kisetsu",
        ],
        bunpou_ids=["bunpou_no_ga_suki", "bunpou_donna"],
        particle_ids=["particle_ga"],
        kaiwa_ids=["kaiwa_musim_favorit"],
    ),
    dict(
        id="bab_bioskop",
        level="N5",
        title="Bioskop",
        title_en="Cinema",
        description="Membicarakan film dan jenis film favorit.",
        description_en="Talking about movies and favorite kinds of films.",
        kotoba_ids=[
            "kotoba_hobi_aktivitas_eiga",
            "kotoba_ekspresi_wajah_egao",
        ],
        bunpou_ids=["bunpou_donna", "bunpou_no_ga_suki"],
        particle_ids=["particle_ga"],
        kaiwa_ids=["kaiwa_cerita_film"],
    ),
    dict(
        id="bab_perbandingan",
        level="N5",
        title="Perbandingan",
        title_en="Comparison",
        description="Cara membandingkan dua hal dengan pola より dan ほうが.",
        description_en="How to compare two things using the yori and hou ga patterns.",
        kotoba_ids=["kotoba_kendaraan_densha"],
        bunpou_ids=["bunpou_wa_yori_desu", "bunpou_yori_hou_ga"],
        particle_ids=[],
        kaiwa_ids=["kaiwa_liburan_backpacker"],
    ),
    dict(
        id="bab_belanja",
        level="N5",
        title="Belanja",
        title_en="Shopping",
        description="Kosakata pakaian dan cara meminta atau membeli barang di toko.",
        description_en="Clothing vocabulary and how to ask for or buy things at a shop.",
        kotoba_ids=[
            "kotoba_pakaian_aksesori_kutsu",
            "kotoba_pekerjaan_kantor_ryoushuu",
        ],
        bunpou_ids=["bunpou_o_kudasai", "bunpou_ga_hoshii"],
        particle_ids=["particle_o", "particle_ga"],
        kaiwa_ids=["kaiwa_coba_baju"],
    ),
    dict(
        id="bab_di_restoran",
        level="N5",
        title="Di Restoran",
        title_en="At a Restaurant",
        description="Kosakata makanan/minuman dan cara memesan di restoran.",
        description_en="Food/drink vocabulary and how to order at a restaurant.",
        kotoba_ids=[
            "kotoba_makanan_jepang_ramen",
            "kotoba_minuman_mizu",
            "kotoba_konsep_umum_chuumon",
            "kotoba_makanan_barat_keeki",
        ],
        bunpou_ids=["bunpou_o_kudasai", "bunpou_ga_arimasu", "bunpou_totemo"],
        particle_ids=["particle_o", "particle_ga"],
        kaiwa_ids=["kaiwa_pesan_makanan"],
    ),
    dict(
        id="bab_angka_dan_uang",
        level="N5",
        title="Angka dan Uang",
        title_en="Numbers and Money",
        description="Angka dasar dan cara menukar atau meminta uang.",
        description_en="Basic numbers and how to exchange or ask for money.",
        kotoba_ids=[
            "kotoba_angka_satuan_ichi",
            "kotoba_angka_satuan_ni",
            "kotoba_angka_satuan_san",
            "kotoba_angka_satuan_yon",
            "kotoba_angka_satuan_go",
            "kotoba_angka_satuan_ichiman",
        ],
        bunpou_ids=["bunpou_o_kudasai", "bunpou_ga_arimasu"],
        particle_ids=["particle_o", "particle_ga"],
        kaiwa_ids=["kaiwa_tukar_uang"],
    ),
    dict(
        id="bab_buah_dan_sayuran",
        level="N5",
        title="Buah dan Sayuran",
        title_en="Fruits and Vegetables",
        description="Kosakata buah dan sayuran dan cara menanyakan harga.",
        description_en="Fruit and vegetable vocabulary and how to ask the price.",
        kotoba_ids=[
            "kotoba_buah_ringo",
            "kotoba_buah_banana",
            "kotoba_sayuran_yasai",
            "kotoba_sayuran_tomato",
            "kotoba_minuman_mizu",
        ],
        bunpou_ids=["bunpou_o_kudasai", "bunpou_ga_hoshii"],
        particle_ids=["particle_o", "particle_ga"],
        kaiwa_ids=["kaiwa_tanya_harga"],
    ),
    dict(
        id="bab_bentuk_te_dan_minta_tolong",
        level="N5",
        title="Bentuk -Te dan Meminta Tolong",
        title_en="The -Te Form and Asking for Help",
        description=(
            "Cara mengubah kata kerja ke bentuk -te, lalu memakainya untuk meminta "
            "tolong dengan sopan — dasar yang perlu dikuasai sebelum bab \"Di Sekolah\", "
            "yang sudah memakai pola ~てください."
        ),
        description_en=(
            "How to conjugate verbs into the -te form, then use it to ask for help "
            "politely — the foundation needed before \"At School\", which already "
            "uses the ~te kudasai pattern."
        ),
        kotoba_ids=[
            "kotoba_alat_tulis_sekolah_shukudai",
        ],
        bunpou_ids=["bunpou_te_kei", "bunpou_te_kudasai"],
        particle_ids=["particle_o"],
        kaiwa_ids=["kaiwa_bantuan_koper"],
    ),
    dict(
        id="bab_di_sekolah",
        level="N5",
        title="Di Sekolah",
        title_en="At School",
        description="Alat tulis, mata pelajaran, dan percakapan sehari-hari di sekolah.",
        description_en="School supplies, subjects, and everyday classroom conversation.",
        kotoba_ids=[
            "kotoba_alat_tulis_sekolah_enpitsu",
            "kotoba_alat_tulis_sekolah_hon",
            "kotoba_mata_pelajaran_shiken",
        ],
        bunpou_ids=["bunpou_te_kudasai", "bunpou_ga_arimasu"],
        particle_ids=["particle_ga", "particle_o"],
        kaiwa_ids=["kaiwa_pinjam_alat_tulis"],
    ),
    dict(
        id="bab_telepon",
        level="N5",
        title="Telepon",
        title_en="Phone Calls",
        description="Cara menjawab dan meminta sesuatu lewat telepon.",
        description_en="How to answer the phone and ask for things over a call.",
        kotoba_ids=[
            "kotoba_teknologi_gadget_denwa",
            "kotoba_hari_bulan_jikan",
        ],
        bunpou_ids=["bunpou_te_kudasai", "bunpou_mo"],
        particle_ids=["particle_mo"],
        kaiwa_ids=["kaiwa_terima_telepon"],
    ),
    dict(
        id="bab_kegiatan_sehari_hari",
        level="N5",
        title="Kegiatan Sehari-hari",
        title_en="Daily Activities",
        description=(
            "Menceritakan kegiatan yang sedang dilakukan, memakai bentuk -te yang "
            "sudah dipelajari di bab \"Bentuk -Te dan Meminta Tolong\"."
        ),
        description_en=(
            "Talking about activities in progress, building on the -te form "
            "already taught in \"The -Te Form and Asking for Help\"."
        ),
        kotoba_ids=[
            "kotoba_hobi_aktivitas_shumi",
            "kotoba_hobi_aktivitas_dokusho",
            "kotoba_media_hiburan_terebi",
        ],
        bunpou_ids=["bunpou_te_iru", "bunpou_totemo"],
        particle_ids=["particle_o"],
        kaiwa_ids=["kaiwa_tanya_hobi"],
    ),
    # ---- N5 completion (2026-08-04): +21 chapters, 58 patterns ----
    #
    # Brings N5 to 100% pattern coverage. The 31 chapters above are
    # thematic units (Warna, Musim, Bioskop) built around vocabulary and
    # conversation, which is why they only touched 31 of the level's 89
    # grammar points; these 21 cover the rest by grammatical function
    # (the four ways to say "must", the prohibition set, invitations,
    # the two adjective classes, core particles, and so on).
    #
    # kaiwa_ids=[] throughout, on purpose: the automatic matcher's
    # false-positive rate is ~35% and every hit needs its context read by
    # hand. At this volume an unverified link is worse than none.
    dict(
        id="bab_n5_full_kewajiban",
        level="N5",
        title="Empat Cara Mengatakan “Harus”",
        title_en="Four Ways to Say “Must”",
        description="Pola ないといけない, なくちゃ, なくてはいけない dan なくてはならない.",
        description_en="The ないといけない, なくちゃ, なくてはいけない and なくてはならない patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_nai_to_ikenai", "bunpou_nakucha", "bunpou_nakute_wa_ikenai", "bunpou_nakute_wa_naranai"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n5_full_larangan",
        level="N5",
        title="Melarang: Tidak Boleh dan Tolong Jangan",
        title_en="Forbidding: Must Not, and Please Do Not",
        description="Pola てはいけない, ちゃいけない・じゃいけない dan ないでください.",
        description_en="The てはいけない, ちゃいけない・じゃいけない and ないでください patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_te_wa_ikenai", "bunpou_cha_ikenai", "bunpou_naide_kudasai"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n5_full_izin",
        level="N5",
        title="Boleh Melakukan, dan Tidak Perlu Melakukan",
        title_en="May Do, and Need Not Do",
        description="Pola てもいいです dan なくてもいい.",
        description_en="The てもいいです and なくてもいい patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_temo_ii", "bunpou_nakutemo_ii"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n5_full_ajakan",
        level="N5",
        title="Mengajak dan Menawarkan Bantuan",
        title_en="Inviting, and Offering to Help",
        description="Pola ませんか, ましょう dan ましょうか.",
        description_en="The ませんか, ましょう and ましょうか patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_masen_ka", "bunpou_mashou", "bunpou_mashou_ka"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n5_full_keinginan",
        level="N5",
        title="Ingin, Berniat, dan Sebaiknya",
        title_en="Wanting, Intending, and Ought To",
        description="Pola たい, つもり dan ほうがいい.",
        description_en="The たい, つもり and ほうがいい patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_tai", "bunpou_tsumori", "bunpou_hou_ga_ii"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n5_full_dugaan",
        level="N5",
        title="Menduga: だろう dan でしょう",
        title_en="Guessing: darou and deshou",
        description="Pola だろう dan でしょう.",
        description_en="The だろう and でしょう patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_darou", "bunpou_deshou"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n5_full_penjelas",
        level="N5",
        title="Menjelaskan Alasan dengan んです",
        title_en="Explaining With n desu",
        description="Pola んです dan のです.",
        description_en="The んです and のです patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_n_desu", "bunpou_no_desu"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n5_full_kata_sifat",
        level="N5",
        title="Dua Golongan Kata Sifat, dan Terlalu",
        title_en="The Two Adjective Classes, and Too Much",
        description="Pola い-adjectives, な-adjectives dan すぎる.",
        description_en="The い-adjectives, な-adjectives and すぎる patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_i_keiyoushi", "bunpou_na_keiyoushi", "bunpou_sugiru"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n5_full_paling",
        level="N5",
        title="Menyebut yang Paling di Antara Semua",
        title_en="Naming the Most Among All",
        description="Pola いちばん dan の中で[A]が一番.",
        description_en="The いちばん and の中で[A]が一番 patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_ichiban", "bunpou_no_naka_de_ichiban"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n5_full_bertanya",
        level="N5",
        title="Kata Tanya: Mengapa, Bagaimana",
        title_en="Question Words: Why and How",
        description="Pola どうして, どうやって dan はどうですか.",
        description_en="The どうして, どうやって and はどうですか patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_doushite", "bunpou_douyatte", "bunpou_wa_dou_desu_ka"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n5_full_urutan_waktu",
        level="N5",
        title="Sebelum, Sesudah, dan Ketika",
        title_en="Before, After, and When",
        description="Pola 前に, てから dan とき.",
        description_en="The 前に, てから and とき patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_mae_ni", "bunpou_te_kara", "bunpou_toki"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n5_full_sudah_belum",
        level="N5",
        title="Sudah, Belum, dan Selalu",
        title_en="Already, Not Yet, and Always",
        description="Pola もう, まだ, まだ～ていません dan いつも.",
        description_en="The もう, まだ, まだ～ていません and いつも patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_mou", "bunpou_mada", "bunpou_mada_te_imasen", "bunpou_itsumo"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n5_full_penghubung",
        level="N5",
        title="Menyambung Kalimat: Namun, Lalu, Dan",
        title_en="Joining Sentences: However, Then, And",
        description="Pola しかし, それから dan そして.",
        description_en="The しかし, それから and そして patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_shikashi", "bunpou_sorekara", "bunpou_soshite"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n5_full_tapi_kasual",
        level="N5",
        title="Mengatakan “Tetapi” secara Santai",
        title_en="Saying “But” Casually",
        description="Pola けど dan けれども.",
        description_en="The けど and けれども patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_kedo", "bunpou_keredomo"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n5_full_partikel_dasar",
        level="N5",
        title="Partikel Dasar: を, と, や",
        title_en="Core Particles: o, to, ya",
        description="Pola を, と dan や.",
        description_en="The を, と and や patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_o", "bunpou_to", "bunpou_ya"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n5_full_partikel_akhir",
        level="N5",
        title="Partikel di Akhir Kalimat",
        title_en="Sentence-Final Particles",
        description="Pola よ dan なあ.",
        description_en="The よ and なあ patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_yo", "bunpou_naa"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n5_full_menjadi",
        level="N5",
        title="Menjadi, Memilih, dan Pergi untuk",
        title_en="Becoming, Choosing, and Going To Do",
        description="Pola なる, にする dan に行く.",
        description_en="The なる, にする and に行く patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_naru", "bunpou_ni_suru", "bunpou_ni_iku"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n5_full_keadaan_cara",
        level="N5",
        title="Keadaan Hasil, Cara, dan Tanpa Melakukan",
        title_en="Resulting States, Manner, and Without Doing",
        description="Pola てある, 方 dan ないで.",
        description_en="The てある, 方 and ないで patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_te_aru", "bunpou_kata", "bunpou_naide"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n5_full_pengalaman",
        level="N5",
        title="Pengalaman dan Menyebut Beberapa Kegiatan",
        title_en="Experiences, and Listing Some Activities",
        description="Pola たことがある, たり～たり dan 一緒に.",
        description_en="The たことがある, たり～たり and 一緒に patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_ta_koto_ga_aru", "bunpou_tari_tari", "bunpou_issho_ni"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n5_full_bukan_hanya",
        level="N5",
        title="Bukan, Hanya, dan Tetapi",
        title_en="Not, Only, and But",
        description="Pola じゃない・ではない, だけ dan でも.",
        description_en="The じゃない・ではない, だけ and でも patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_ja_nai", "bunpou_dake", "bunpou_demo"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n5_full_kehalusan",
        level="N5",
        title="Awalan Hormat dan Alasan yang Sopan",
        title_en="Honorific Prefixes and a Polite Reason",
        description="Pola お / ご dan ので.",
        description_en="The お / ご and ので patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_o_go", "bunpou_node"],
        kaiwa_ids=[],
    ),
]

# N4 chapters, first pass (2026-08-04). Continues the global `order`
# sequence from N5's 31 (order=32..50) rather than restarting at 1 —
# `bab_providers.dart`'s `babNextUpProvider` sorts ALL chapters across
# every level by `order` to drive the mascot's cross-level "what's next"
# recommendation, by design (see that provider's own doc comment). If N4
# restarted at order=1 it would collide with N5's own order=1 in that
# global sort and break the recommendation the moment both levels exist —
# checked before assuming a fresh per-level count was safe.
# `generate_bab_seed.py`'s order-contiguity assertion is correspondingly
# global (1..len(ALL_CHAPTERS)), not per-level, so this is the only valid
# scheme without a Dart-side change.
#
# Sequenced against the real Minna no Nihongo Shokyuu II textbook (322-page
# scan, "Minna No Nihongo Beginner II - Textbook.pdf" in the user's
# C:\CV WATER PROFING\e book pdf\ folder — zero extractable text, rendered
# to images with pymupdf and read page by page; only the 目次 (table of
# contents) pages 26-50 were read for their per-lesson grammar list,
# structure only, nothing reproduced), Lessons 26-50 (Lessons 1-25 are
# Minna I / this app's N5 scope). Real lesson-by-lesson grammar found:
# L26 んです / ていただけませんか, L27 potential form + 見える/聞こえる,
# L28 ながら + し, L29 ている(state) + てしまう, L30 てある + ておく,
# L31 volitional + ようと思う + つもり, L32 ほうがいい/でしょう/かもしれない,
# L33 imperative + な + という意味 + と言っていた, L34 とおりに/たあとで/
# ないで, L35 ば, L36 ように/ようになる, L37 受身形, L38 の/こと + のは〜だ,
# L39 て(cause)+ので, L40 かどうか + てみたい, L41 いただく/くださる/やる
# (advanced giving-receiving), L42 ために/のに(purpose), L43 そうだ(様態)+
# 買ってくる(compound てくる), L44 すぎる/やすい/くする, L45 場合は/
# のに(contrast), L46 ところです/たばかり, L47 そうだ(伝聞)/ようだ,
# L48 使役形, L49 尊敬語, L50 謙譲語.
#
# Not every lesson got a chapter this pass — only lessons whose core
# grammar has a real N4-tagged bunpou_data.json entry did (same
# "don't force it" rule N5's own history documents). Genuinely missing
# from the dataset, same deferred-gap shape as N5's masen_ka/mashou/tai/
# kata gap: んです (explanatory nda — n_desu exists but is N5-tagged,
# would break this level's purity), potential form itself (話せる-style
# conjugation, only individual outcomes like ni_mieru exist), ほうがいい/
# でしょう (both exist but are N5-tagged for the same reason as n_desu),
# imperative form (命令形), とおりに, てある (resultant state with
# intention, distinct from ておく), ないで, て+cause/ので, すぎる, ために.
# L34's とおりに/ないで and L49's imperative were skipped entirely (no
# usable anchor at all); L26/L32/L33/L39/L42/L44 kept their other,
# N4-tagged half instead of being dropped outright.
#
# kotoba_ids / kanji_ids are picked from a real N4-tagged entry whose word/
# character literally appears inside the chapter's own kaiwa_ids dialogue
# text (same literal-overlap discipline N5's CROSS-CONTENT SYNC PASS
# added retroactively — done from the start here instead). Coverage is
# real but thinner than N5's: the 296-word N4 kotoba pool is spread across
# many unrelated categories, so several chapters below have kotoba_ids=[]
# rather than a forced, non-matching word — left empty deliberately, not
# forgotten. dokkai_ids is left empty across the board this pass (matching
# N5's own starting state); N5 also still has kanji_ids/dokkai_ids empty
# on all 31 of its chapters, so wiring dokkai up for N4 first would create
# an inconsistent pattern before either level has ever populated it — a
# separate future pass should do both levels together.
#
# 19 chapters so far (order 32-50) — a first batch, same "not the full
# curriculum yet" shape as N5's initial 4-chapter and later 10/20/31-chapter
# passes. Expanding further into N4 (Lessons 26, 32-34, 39, 42, 44, 49 gaps
# above; N3-N1 beyond that) is future-session work.
N4_CHAPTERS = [
    dict(
        id="bab_n4_melihat_dan_terdengar",
        level="N4",
        title="Melihat dan Terdengar",
        title_en="Seeing and Hearing",
        description="Cara menyatakan sesuatu yang terlihat atau terkesan, seperti ～に見える.",
        description_en="How to say something looks or appears a certain way, using ～に見える.",
        kotoba_ids=["kotoba_bangunan_fasilitas_annai"],
        kanji_ids=["kanji_tokoro", "kanji_tateru"],
        bunpou_ids=["bunpou_ni_mieru"],
        kaiwa_ids=["kaiwa_tersesat_minta_bantuan_sopan_n4"],
    ),
    dict(
        id="bab_n4_sambil_melakukan_dan_sekaligus",
        level="N4",
        title="Sambil Melakukan dan Sekaligus",
        title_en="Doing at the Same Time, and Listing Reasons",
        description="Pola ながら (melakukan dua hal sekaligus) dan し (menyebut beberapa alasan/sifat sekaligus).",
        description_en="The ながら pattern (doing two things at once) and し (listing several reasons/qualities together).",
        kotoba_ids=["kotoba_konsep_umum_muri", "kotoba_olahraga_undou"],
        kanji_ids=["kanji_karada", "kanji_ugoku"],
        bunpou_ids=["bunpou_nagara", "bunpou_shi"],
        kaiwa_ids=["kaiwa_target_kebugaran_pribadi_n4"],
    ),
    dict(
        id="bab_n4_menominalkan_dengan_koto",
        level="N4",
        title="Menominalkan dengan Koto",
        title_en="Turning a Verb into a Noun with Koto",
        description="Memakai こと untuk mengubah kata kerja menjadi hal/perkara, dan menekankan bagian kalimat dengan のは〜だ.",
        description_en="Using こと to turn a verb into a noun-like idea, and highlighting part of a sentence with のは〜だ.",
        kotoba_ids=["kotoba_media_hiburan_anime"],
        kanji_ids=["kanji_narau", "kanji_tsuyoi"],
        bunpou_ids=["bunpou_koto", "bunpou_no_wa_da"],
        kaiwa_ids=["kaiwa_kenalan_alasan_belajar_n4"],
    ),
    dict(
        id="bab_n4_terlanjur_dan_menyesal",
        level="N4",
        title="Terlanjur dan Menyesal",
        title_en="Ending Up Doing Something, and Regret",
        description="Pola てしまう untuk menyatakan sesuatu selesai sepenuhnya, atau terjadi tanpa sengaja/disesalkan.",
        description_en="The てしまう pattern, for something finished completely, or done accidentally/regretfully.",
        kotoba_ids=[],
        kanji_ids=["kanji_suki2", "kanji_ga2"],
        bunpou_ids=["bunpou_te_shimau"],
        kaiwa_ids=["kaiwa_suka_nonton_di_rumah_n4"],
    ),
    dict(
        id="bab_n4_bersiap_siap_sebelumnya",
        level="N4",
        title="Bersiap-siap Sebelumnya",
        title_en="Preparing in Advance",
        description="Pola ておく untuk menyatakan sesuatu dilakukan sebagai persiapan untuk nanti.",
        description_en="The ておく pattern, for doing something now to prepare for later.",
        kotoba_ids=["kotoba_hobi_aktivitas_ryokou", "kotoba_konsep_umum_youi"],
        kanji_ids=["kanji_you3", "kanji_i2"],
        bunpou_ids=["bunpou_te_oku"],
        kaiwa_ids=["kaiwa_persiapan_dokumen_perjalanan_n4"],
    ),
    dict(
        id="bab_n4_ajakan_dan_niat",
        level="N4",
        title="Ajakan dan Niat",
        title_en="Suggestions and Intentions",
        description="Bentuk kehendak/ajakan (意向形, mis. 行こう) dan cara menyatakan niat dengan ～ようと思う.",
        description_en="The volitional/suggestion form (意向形, e.g. 行こう) and stating an intention with ～ようと思う.",
        kotoba_ids=["kotoba_hari_bulan_kondo", "kotoba_konsep_umum_futsuu"],
        kanji_ids=["kanji_do", "kanji_ga2"],
        bunpou_ids=["bunpou_ikoukei", "bunpou_you_to_omou"],
        kaiwa_ids=["kaiwa_festival_film_dikunjungi_n4"],
    ),
    dict(
        id="bab_n4_mungkin_saja_terjadi",
        level="N4",
        title="Mungkin Saja Terjadi",
        title_en="It Might Happen",
        description="Pola かもしれません untuk menyatakan kemungkinan yang tidak terlalu yakin.",
        description_en="The かもしれません pattern, for a possibility the speaker isn't very sure about.",
        kotoba_ids=["kotoba_olahraga_shiai"],
        kanji_ids=["kanji_hayai", "kanji_kokoro"],
        bunpou_ids=["bunpou_kamoshirenai"],
        kaiwa_ids=["kaiwa_persiapan_pertandingan_n4"],
    ),
    dict(
        id="bab_n4_pengandaian_dengan_ba",
        level="N4",
        title="Pengandaian dengan Ba",
        title_en="Conditionals with Ba",
        description="Bentuk kondisional ば untuk menyatakan 'jika ~, maka ~'.",
        description_en="The ば conditional form, for 'if ~, then ~'.",
        kotoba_ids=["kotoba_profesi_kaishain"],
        kanji_ids=["kanji_komaru", "kanji_kokoro"],
        bunpou_ids=["bunpou_ba"],
        kaiwa_ids=["kaiwa_kenalan_senior_kerja_n4"],
    ),
    dict(
        id="bab_n4_bentuk_pasif",
        level="N4",
        title="Bentuk Pasif",
        title_en="The Passive Form",
        description="Bentuk pasif (受身形) られる, untuk menyatakan sesuatu dilakukan terhadap subjek kalimat.",
        description_en="The passive form (受身形) られる, for something being done to the sentence's subject.",
        kotoba_ids=["kotoba_konsep_umum_dougu", "kotoba_konsep_umum_kantan"],
        kanji_ids=["kanji_hajimeru", "kanji_tanoshii"],
        bunpou_ids=["bunpou_rareru", "bunpou_ukemikei"],
        kaiwa_ids=["kaiwa_ajak_hobi_menantang_n4"],
    ),
    dict(
        id="bab_n4_apakah_atau_tidak",
        level="N4",
        title="Apakah ~ Atau Tidak",
        title_en="Whether or Not",
        description="Pola かどうか untuk menyatakan ketidakpastian akan sesuatu, 'apakah ~ atau tidak'.",
        description_en="The かどうか pattern, expressing uncertainty about something — 'whether or not ~'.",
        kotoba_ids=["kotoba_konsep_umum_kankyou", "kotoba_mata_pelajaran_sotsugyou"],
        kanji_ids=["kanji_gyou", "kanji_chikai"],
        bunpou_ids=["bunpou_ka_dou_ka"],
        kaiwa_ids=["kaiwa_khawatir_sebelum_lulus_n4"],
    ),
    dict(
        id="bab_n4_kebaikan_diberi_dan_diterima",
        level="N4",
        title="Kebaikan yang Diberi dan Diterima",
        title_en="Doing Favors For, and Receiving Favors From",
        description="Pola てくれる (orang lain melakukan sesuatu untuk saya) dan てあげる (melakukan sesuatu untuk orang lain).",
        description_en="The てくれる pattern (someone does something for me) and てあげる (doing something for someone else).",
        kotoba_ids=[],
        kanji_ids=["kanji_suki2", "kanji_kirai"],
        bunpou_ids=["bunpou_te_kureru", "bunpou_te_ageru"],
        kaiwa_ids=["kaiwa_minta_rekomendasi_hadiah_ortu_n4"],
    ),
    dict(
        id="bab_n4_tujuan_dan_penyesalan_dengan_noni",
        level="N4",
        title="Tujuan dan Penyesalan dengan Noni",
        title_en="Purpose and Contrast with Noni",
        description="Dua fungsi のに yang berbeda: menyatakan tujuan/kegunaan, dan menyatakan kontras yang mengecewakan.",
        description_en="Two different uses of のに: stating a purpose/use, and expressing a disappointing contrast.",
        kotoba_ids=[
            "kotoba_hobi_aktivitas_ryouri",
            "kotoba_perasaan_emosi_zannen",
            "kotoba_profesi_tenin",
        ],
        kanji_ids=["kanji_mon2", "kanji_dai3"],
        bunpou_ids=["bunpou_noni_mokuteki", "bunpou_noni_gyakusetsu"],
        kaiwa_ids=["kaiwa_cerita_pengalaman_buruk_restoran_n4"],
    ),
    dict(
        id="bab_n4_kesan_dan_perkiraan",
        level="N4",
        title="Kesan dan Perkiraan",
        title_en="Impressions and Guesses",
        description="Pola そうだ（様態） untuk menyatakan kesan visual ('kelihatannya ~'), dan てくる untuk kata kerja majemuk.",
        description_en="The そうだ（様態） pattern for a visual impression ('looks like ~'), and てくる for compound verbs.",
        kotoba_ids=["kotoba_kendaraan_takushii"],
        kanji_ids=["kanji_hayai", "kanji_osoi", "kanji_noru"],
        bunpou_ids=["bunpou_souda_youtai", "bunpou_te_kuru"],
        kaiwa_ids=["kaiwa_negosiasi_rute_cepat_murah_n4"],
    ),
    dict(
        id="bab_n4_mudah_dan_sulit_dilakukan",
        level="N4",
        title="Mudah dan Sulit Dilakukan",
        title_en="Easy and Hard to Do",
        description="Pola やすい (mudah untuk ~), dipakai untuk menilai seberapa mudah melakukan sesuatu.",
        description_en="The やすい pattern (easy to ~), used to judge how easy something is to do.",
        kotoba_ids=["kotoba_konsep_umum_soudan"],
        kanji_ids=["kanji_tsukuru", "kanji_komaru"],
        bunpou_ids=["bunpou_yasui"],
        kaiwa_ids=["kaiwa_jelaskan_alasan_pindah_kota_n4"],
    ),
    dict(
        id="bab_n4_dalam_kasus_tertentu",
        level="N4",
        title="Dalam Kasus Tertentu",
        title_en="In That Case",
        description="Pola 場合は untuk menyatakan 'dalam kasus ~' atau 'jika terjadi ~'.",
        description_en="The 場合は pattern, for 'in the case of ~' or 'if ~ happens'.",
        kotoba_ids=["kotoba_teknologi_gadget_koshou"],
        kanji_ids=["kanji_tsukau", "kanji_hin"],
        bunpou_ids=["bunpou_baai_wa"],
        kaiwa_ids=["kaiwa_tanya_garansi_elektronik_n4"],
    ),
    dict(
        id="bab_n4_baru_saja_terjadi",
        level="N4",
        title="Baru Saja Terjadi",
        title_en="Just Happened",
        description="Pola たばかり untuk menyatakan sesuatu baru saja terjadi.",
        description_en="The たばかり pattern, for something that just happened.",
        kotoba_ids=["kotoba_arah_lokasi_basho"],
        kanji_ids=["kanji_tokoro", "kanji_sama"],
        bunpou_ids=["bunpou_ta_bakari"],
        kaiwa_ids=["kaiwa_kenalan_tetangga_pindah_n4"],
    ),
    dict(
        id="bab_n4_kabar_dengar_dan_dugaan",
        level="N4",
        title="Kabar Dengar dan Dugaan",
        title_en="Hearsay and Inference",
        description="Pola そうだ（伝聞） untuk mengutip kabar dari sumber lain, dan ようだ untuk dugaan berdasar bukti.",
        description_en="The そうだ（伝聞） pattern for quoting news from another source, and ようだ for an evidence-based guess.",
        # Re-pointed 2026-08-04. The previous dialogue
        # (kaiwa_keluh_cuaca_tidak_menentu_n4) was matched on 「そうだね」,
        # which is the agreement particle, not hearsay そうだ — it contains
        # no instance of either pattern. This one has 「みんなお元気だそうです
        # よ」, a real 伝聞 そうだ, and is on-topic for "kabar dengar".
        kotoba_ids=["kotoba_konsep_umum_kekkou", "kotoba_konsep_umum_koukan"],
        kanji_ids=["kanji_ji", "kanji_fun"],
        bunpou_ids=["bunpou_souda_denbun", "bunpou_you_da"],
        kaiwa_ids=["kaiwa_kenalan_reuni_alumni_n4"],
    ),
    dict(
        id="bab_n4_bentuk_kausatif",
        level="N4",
        title="Bentuk Kausatif",
        title_en="The Causative Form",
        description="Bentuk kausatif させる, untuk menyatakan menyuruh atau mengizinkan seseorang melakukan sesuatu.",
        description_en="The causative form させる, for making or letting someone do something.",
        kotoba_ids=[],
        kanji_ids=["kanji_jibun", "kanji_susumu"],
        bunpou_ids=["bunpou_saseru"],
        kaiwa_ids=["kaiwa_kenalan_impian_masa_kecil_n4"],
    ),
    dict(
        id="bab_n4_bahasa_sangat_sopan",
        level="N4",
        title="Bahasa Sangat Sopan (Kenjougo)",
        title_en="Very Polite Language (Kenjougo)",
        description="Bahasa merendah (謙譲語) いたします dan でございます, dipakai untuk situasi bisnis/resmi.",
        description_en="Humble language (謙譲語) いたします and でございます, used in business/formal situations.",
        kotoba_ids=[],
        kanji_ids=["kanji_shiru"],
        bunpou_ids=["bunpou_itashimasu", "bunpou_de_gozaimasu"],
        kaiwa_ids=["kaiwa_kenalan_pasangan_bisnis_n4"],
    ),
    # --- Second pass (2026-08-04, same day), order 51-56, below ---
    # Continues past the first pass's Minna-lesson-sequenced 32-50 with 6
    # more chapters, built the same way — an N4-tagged bunpou pair,
    # matched to a real N4 kaiwa dialogue by searching the *entire* N4
    # dialogue pool for the pattern's own literal token, then kotoba/
    # kanji picked from whatever literally appears in that same chosen
    # dialogue.
    #
    # These 6 are not sequenced against a specific further Minna II
    # lesson — the first pass already covered every L26-50 lesson that
    # had a usable N4-tagged anchor. Instead this batch picks 6 more
    # high-frequency N4 patterns from the 104 still-unused N4-tagged
    # bunpou entries (132 total, 28 used by the first pass): こと can/
    # sometimes, こと deciding/decided, なければ obligation, たら
    # conditional, はず certainty, and みたい/らしい casual impression +
    # hearsay — all genuinely core N4 grammar that just didn't happen to
    # land inside Lessons 26-50's own sequence (Minna spreads some of
    # these earlier, in Shokyuu II's first few lessons that overlap the
    # tail of Shokyuu I, or via drills rather than a dedicated lesson).
    #
    # Five of these twelve bunpou ids (koto_ga_dekiru, koto_ni_naru,
    # nakereba_ikenai, tara_dou, hazu_ga_nai) have zero literal token
    # match anywhere across all 255 N4 kaiwa dialogues — confirmed by
    # searching the whole pool, not just each pattern's own 3 canned
    # examples. Each is still included, paired with a sibling pattern
    # from the same family that DOES have a real match (koto_ga_aru,
    # koto_ni_suru, nakereba_naranai, tara, hazu_da respectively) — the
    # chapter's kaiwa_ids comes from the sibling with a real hit, same
    # "one dialogue can anchor a whole closely-related pair" precedent
    # the first pass already used for のに's two senses and そうだ
    # （様態）+てくる.
    dict(
        id="bab_n4_bisa_dan_kadang_terjadi",
        level="N4",
        title="Bisa Melakukan dan Kadang Terjadi",
        title_en="Being Able To, and Sometimes Happening",
        description="Pola ことができる (bisa/dapat melakukan) dan ことがある (kadang-kadang terjadi, atau pernah mengalami).",
        description_en="The ことができる pattern (being able to do something) and ことがある (sometimes happens, or has happened before).",
        kotoba_ids=["kotoba_konsep_umum_seikatsu"],
        kanji_ids=["kanji_omou", "kanji_kawaru"],
        bunpou_ids=["bunpou_koto_ga_dekiru", "bunpou_koto_ga_aru"],
        kaiwa_ids=["kaiwa_cerita_pengalaman_luar_negeri_n4"],
    ),
    dict(
        id="bab_n4_memutuskan_dan_ditetapkan",
        level="N4",
        title="Memutuskan dan Ditetapkan",
        title_en="Deciding, and Being Decided",
        description="Pola ことにする (memutuskan sendiri untuk ~) dan ことになる (telah ditetapkan/diputuskan bahwa ~).",
        description_en="The ことにする pattern (deciding for yourself to ~) and ことになる (it has been decided/settled that ~).",
        kotoba_ids=["kotoba_hari_bulan_kondo", "kotoba_konsep_umum_juubun", "kotoba_olahraga_undou"],
        kanji_ids=["kanji_karada", "kanji_ugoku", "kanji_hajimeru"],
        bunpou_ids=["bunpou_koto_ni_suru", "bunpou_koto_ni_naru"],
        kaiwa_ids=["kaiwa_pentingnya_pemanasan_n4"],
    ),
    dict(
        id="bab_n4_kewajiban_harus_melakukan",
        level="N4",
        title="Kewajiban: Harus Melakukan",
        title_en="Obligation: Having to Do Something",
        description="Pola なければいけない dan なければならない, dua cara menyatakan 'harus ~' (sinonim, yang kedua sedikit lebih formal).",
        description_en="The なければいけない and なければならない patterns, both meaning 'must ~' (near-synonyms, the second slightly more formal).",
        kotoba_ids=[],
        kanji_ids=["kanji_oshieru", "kanji_tooru"],
        bunpou_ids=["bunpou_nakereba_ikenai", "bunpou_nakereba_naranai"],
        kaiwa_ids=["kaiwa_proses_kartu_kredit_n4"],
    ),
    dict(
        id="bab_n4_pengandaian_dengan_tara",
        level="N4",
        title="Pengandaian dengan Tara",
        title_en="Conditionals with Tara",
        description="Bentuk kondisional たら ('jika/setelah ~'), dan たらどう untuk memberi saran.",
        description_en="The たら conditional form ('if/once ~'), and たらどう for giving a suggestion.",
        kotoba_ids=["kotoba_arah_lokasi_chikaku", "kotoba_ruangan_rumah_niwa"],
        kanji_ids=["kanji_hataraku", "kanji_chikai"],
        bunpou_ids=["bunpou_tara", "bunpou_tara_dou"],
        kaiwa_ids=["kaiwa_jelaskan_rencana_menikah_n4"],
    ),
    dict(
        id="bab_n4_seharusnya_dan_tidak_mungkin",
        level="N4",
        title="Seharusnya dan Tidak Mungkin",
        title_en="Should Be the Case, and Can't Possibly Be",
        description="Pola はずだ (seharusnya/pasti ~, berdasar logika) dan はずがない (tidak mungkin ~).",
        description_en="The はずだ pattern (should/must be ~, based on logic) and はずがない (there's no way ~).",
        kotoba_ids=["kotoba_bangunan_fasilitas_yoyaku", "kotoba_teknologi_gadget_meeru"],
        kanji_ids=["kanji_tsukau", "kanji_jibun"],
        bunpou_ids=["bunpou_hazu_da", "bunpou_hazu_ga_nai"],
        kaiwa_ids=["kaiwa_pesan_tiket_online_n4"],
    ),
    dict(
        id="bab_n4_kesan_dan_dugaan_dari_luar",
        level="N4",
        title="Kesan Kasual dan Kabar dari Luar",
        title_en="Casual Impressions and Outside Information",
        description="Pola みたいだ (kesan santai, mirip ようだ) dan らしい (dugaan berdasar apa yang didengar/dibaca dari luar).",
        description_en="The みたいだ pattern (a casual impression, similar to ようだ) and らしい (a guess based on outside information).",
        kotoba_ids=["kotoba_bangunan_fasilitas_uketsuke", "kotoba_hari_bulan_kondo"],
        kanji_ids=["kanji_karada", "kanji_motsu"],
        bunpou_ids=["bunpou_mitai_da", "bunpou_rashii"],
        kaiwa_ids=["kaiwa_gabung_klub_olahraga_n4"],
    ),
    # ---- N4 phase 2 (2026-08-04): +20 chapters, 57 patterns ----
    #
    # The first N4 pass took its 25 chapters straight from Minna no
    # Nihongo II's 25 lessons, which left 94 of the level's 134 patterns
    # untouched. These 20 chapters group functionally from that remainder
    # (the ように family, polite-request ladder, sonkeigo, causative,
    # third-person feelings, verb-phase compounds, question particles,
    # quoting, and so on) and include しか〜ない and てくださいませんか, the two
    # N4 points the So-matome cross-check found missing from the dataset.
    #
    # Kaiwa: 18 of 20 matched automatically; a hand-check of the
    # surrounding text rejected 5 as substring false positives (「指導教員に
    # なります」 is plain になる not お～になる; 「そうなんですね」 is not そうな;
    # 「広がっていく」 is 広がる not the がる suffix; 「間に合った」 is 間に合う;
    # 「予定が変わって」 is the bare noun). 13 verified links remain.
    dict(
        id="bab_n4_p2_batas",
        level="N4",
        title="Batas Waktu, Jumlah Sedikit, dan Hanya Segitu",
        title_en="Deadlines, Small Amounts, and Only That Much",
        description="Pola しか～ない, までに dan あまり～ない.",
        description_en="The しか～ない, までに and あまり～ない patterns.",
        kotoba_ids=["kotoba_jikan", "kotoba_hari_bulan_jikan"],
        kanji_ids=["kanji_ichi", "kanji_hito"],
        bunpou_ids=["bunpou_shika", "bunpou_made_ni", "bunpou_amari_nai"],
        kaiwa_ids=["kaiwa_pesan_acara_kantor_n4"],
    ),
    dict(
        id="bab_n4_p2_sedang_proses",
        level="N4",
        title="Sedang Berlangsung dan Baru Saja Selesai",
        title_en="In Progress, and Just Finished",
        description="Pola ているところ, たところ dan ていた.",
        description_en="The ているところ, たところ and ていた patterns.",
        kotoba_ids=["kotoba_kyou", "kotoba_jikan"],
        kanji_ids=["kanji_hi", "kanji_ji"],
        bunpou_ids=["bunpou_te_iru_tokoro", "bunpou_ta_tokoro", "bunpou_te_ita"],
        kaiwa_ids=["kaiwa_ajak_nonton_bioskop_n4"],
    ),
    dict(
        id="bab_n4_p2_youni",
        level="N4",
        title="Keluarga ように: Berusaha dan Menjadi Bisa",
        title_en="The ように Family: Trying To, and Coming To Be Able",
        description="Pola ようにする, ようになる dan ように / ような.",
        description_en="The ようにする, ようになる and ように / ような patterns.",
        kotoba_ids=["kotoba_hari_bulan_konkai", "kotoba_hari_bulan_kondo"],
        kanji_ids=["kanji_ji", "kanji_fun"],
        bunpou_ids=["bunpou_you_ni_suru", "bunpou_you_ni_naru", "bunpou_youni_youna"],
        kaiwa_ids=["kaiwa_cerita_kesalahan_dipelajari_n4"],
    ),
    dict(
        id="bab_n4_p2_minta_sopan",
        level="N4",
        title="Meminta dengan Sangat Sopan",
        title_en="Making a Very Polite Request",
        description="Pola てくださいませんか, ていただけませんか dan お～ください.",
        description_en="The てくださいませんか, ていただけませんか and お～ください patterns.",
        kotoba_ids=["kotoba_konsep_umum_kakunin", "kotoba_konsep_umum_chuumon"],
        kanji_ids=["kanji_ji", "kanji_fun"],
        bunpou_ids=["bunpou_te_kudasaimasen_ka", "bunpou_te_itadakemasen_ka", "bunpou_o_verb_kudasai"],
        kaiwa_ids=["kaiwa_pesan_alergi_n4"],
    ),
    dict(
        id="bab_n4_p2_sonkeigo",
        level="N4",
        title="Bahasa Hormat untuk Lawan Bicara",
        title_en="Honorific Language for the Listener",
        description="Pola お～になる dan なさる.",
        description_en="The お～になる and なさる patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_o_ni_naru", "bunpou_nasaru"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n4_p2_sopan_khusus",
        level="N4",
        title="Kata Sopan Khusus: いらっしゃる dan ございます",
        title_en="Special Polite Verbs: irassharu and gozaimasu",
        description="Pola いらっしゃる dan ございます.",
        description_en="The いらっしゃる and ございます patterns.",
        kotoba_ids=["kotoba_kazoku", "kotoba_kyoudai"],
        kanji_ids=["kanji_ichi", "kanji_hito"],
        bunpou_ids=["bunpou_irassharu", "bunpou_gozaimasu"],
        kaiwa_ids=["kaiwa_jelaskan_latar_keluarga_n4"],
    ),
    dict(
        id="bab_n4_p2_kausatif",
        level="N4",
        title="Dipaksa Melakukan, dan Meminta Izin",
        title_en="Being Made To Do, and Asking Permission",
        description="Pola させられる dan させてください.",
        description_en="The させられる and させてください patterns.",
        kotoba_ids=["kotoba_kinou", "kotoba_hari_bulan_kinou"],
        kanji_ids=["kanji_hi", "kanji_ji"],
        bunpou_ids=["bunpou_saserareru", "bunpou_sasete_kudasai"],
        kaiwa_ids=["kaiwa_komplain_produk_sopan_n4"],
    ),
    dict(
        id="bab_n4_p2_kelihatan",
        level="N4",
        title="Kelihatannya Begitu",
        title_en="It Looks That Way",
        description="Pola そうに / そうな, みたいな dan みたいに.",
        description_en="The そうに / そうな, みたいな and みたいに patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_souni_souna", "bunpou_mitai_na", "bunpou_mitai_ni"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n4_p2_perasaan_orang",
        level="N4",
        title="Menyebut Perasaan Orang Lain",
        title_en="Describing Someone Else’s Feelings",
        description="Pola がる / がっている, がり dan たがる.",
        description_en="The がる / がっている, がり and たがる patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_garu", "bunpou_gari", "bunpou_tagaru"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n4_p2_memberi_menerima",
        level="N4",
        title="Mencoba, Memberi, dan Menerima Kebaikan",
        title_en="Trying, Giving, and Receiving a Favour",
        description="Pola てみる, てもらう dan てやる.",
        description_en="The てみる, てもらう and てやる patterns.",
        kotoba_ids=["kotoba_kendaraan_densha", "kotoba_konsep_umum_seichou"],
        kanji_ids=["kanji_ichi", "kanji_hito"],
        bunpou_ids=["bunpou_te_miru", "bunpou_te_morau", "bunpou_te_yaru"],
        kaiwa_ids=["kaiwa_cerita_naik_sendiri_pertama_n4"],
    ),
    dict(
        id="bab_n4_p2_mulai_selesai",
        level="N4",
        title="Mulai dan Berhenti Melakukan",
        title_en="Starting and Finishing an Action",
        description="Pola 始める（はじめる）, 出す（だす）, 続ける（つづける） dan 終わる（おわる）.",
        description_en="The 始める（はじめる）, 出す（だす）, 続ける（つづける） and 終わる（おわる） patterns.",
        kotoba_ids=["kotoba_jikan", "kotoba_hari_bulan_mainichi"],
        kanji_ids=["kanji_ni", "kanji_hi"],
        bunpou_ids=["bunpou_hajimeru", "bunpou_dasu", "bunpou_tsuzukeru", "bunpou_owaru"],
        kaiwa_ids=["kaiwa_berhenti_hobi_lama_n4"],
    ),
    dict(
        id="bab_n4_p2_sulit",
        level="N4",
        title="Dua Macam Kesulitan: にくい dan づらい",
        title_en="Two Kinds of Difficulty: nikui and zurai",
        description="Pola にくい dan づらい.",
        description_en="The にくい and づらい patterns.",
        kotoba_ids=["kotoba_bangunan_fasilitas_annai", "kotoba_konsep_umum_kitai"],
        kanji_ids=["kanji_ji", "kanji_fun"],
        bunpou_ids=["bunpou_nikui", "bunpou_zurai"],
        kaiwa_ids=["kaiwa_saran_papan_informasi_n4"],
    ),
    dict(
        id="bab_n4_p2_rentang_waktu",
        level="N4",
        title="Selama, Di Suatu Saat, dan Sekitar",
        title_en="During, At Some Point Within, and Around",
        description="Pola 間（あいだ）, 間に（あいだに） dan 頃（ころ / ごろ）.",
        description_en="The 間（あいだ）, 間に（あいだに） and 頃（ころ / ごろ） patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_aida", "bunpou_aida_ni", "bunpou_koro_goro"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n4_p2_pengandaian",
        level="N4",
        title="Tiga Cara Mengandaikan",
        title_en="Three Ways to Suppose",
        description="Pola なら, と dan ても.",
        description_en="The なら, と and ても patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_nara", "bunpou_to2", "bunpou_temo"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n4_p2_partikel_tanya",
        level="N4",
        title="Partikel Tanya yang Lembut",
        title_en="Softer Question Particles",
        description="Pola かな, かしら dan かい.",
        description_en="The かな, かしら and かい patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_kana", "bunpou_kashira", "bunpou_kai"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n4_p2_menyampaikan",
        level="N4",
        title="Menyampaikan Pikiran dan Kabar",
        title_en="Reporting a Thought or What You Heard",
        description="Pola と思う（とおもう）, と聞いた（ときいた） dan と言われている（といわれている）.",
        description_en="The と思う（とおもう）, と聞いた（ときいた） and と言われている（といわれている） patterns.",
        kotoba_ids=["kotoba_hari_bulan_kondo", "kotoba_hari_bulan_saikin"],
        kanji_ids=["kanji_ji", "kanji_fun"],
        bunpou_ids=["bunpou_to_omou", "bunpou_to_kiita", "bunpou_to_iwarete_iru"],
        kaiwa_ids=["kaiwa_temu_teman_berubah_n4"],
    ),
    dict(
        id="bab_n4_p2_mengutip",
        level="N4",
        title="Mengutip dan Menamai",
        title_en="Quoting and Naming",
        description="Pola という, ということ dan って.",
        description_en="The という, ということ and って patterns.",
        kotoba_ids=["kotoba_hobi_aktivitas_ryouri", "kotoba_konsep_umum_ichibu"],
        kanji_ids=["kanji_ichi", "kanji_ji"],
        bunpou_ids=["bunpou_to_iu", "bunpou_to_iu_koto", "bunpou_tte"],
        kaiwa_ids=["kaiwa_komentar_perubahan_menu_n4"],
    ),
    dict(
        id="bab_n4_p2_keterangan",
        level="N4",
        title="Pasti, Tolong Sekali, dan Akhirnya",
        title_en="Surely, Do Please, and At Last",
        description="Pola きっと, ぜひ dan やっと.",
        description_en="The きっと, ぜひ and やっと patterns.",
        kotoba_ids=["kotoba_hobi_aktivitas_ryouri"],
        kanji_ids=["kanji_ji", "kanji_fun"],
        bunpou_ids=["bunpou_kitto", "bunpou_zehi", "bunpou_yatto"],
        kaiwa_ids=["kaiwa_rekomendasi_menu_ragu_n4"],
    ),
    dict(
        id="bab_n4_p2_penyangkalan",
        level="N4",
        title="Sama Sekali Tidak dan Tidak Kunjung",
        title_en="Not At All, and Not Yet Despite Trying",
        description="Pola 全然～ない（ぜんぜん～ない）, なかなか～ない dan そんなに.",
        description_en="The 全然～ない（ぜんぜん～ない）, なかなか～ない and そんなに patterns.",
        kotoba_ids=["kotoba_hobi_aktivitas_chousen", "kotoba_konsep_umum_ketsudan"],
        kanji_ids=["kanji_ji", "kanji_fun"],
        bunpou_ids=["bunpou_zenzen_nai", "bunpou_nakanaka_nai", "bunpou_sonna_ni"],
        kaiwa_ids=["kaiwa_jelaskan_alasan_berhenti_kerja_n4"],
    ),
    dict(
        id="bab_n4_p2_rencana",
        level="N4",
        title="Rencana, Meminta Saran, dan Menyadari",
        title_en="Plans, Asking for Advice, and Realising",
        description="Pola 予定だ（よていだ）, たらいいですか dan に気がつく.",
        description_en="The 予定だ（よていだ）, たらいいですか and に気がつく patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_yotei_da", "bunpou_tara_ii_desu_ka", "bunpou_ni_ki_ga_tsuku"],
        kaiwa_ids=[],
    ),
    # ---- N4 completion (2026-08-04): +14 chapters, 37 patterns ----
    #
    # Brings N4 to 100%. An automatic morpheme clusterer was tried first
    # and rejected: it produced chapters like "でも, または, ところ" whose
    # members share nothing. The tail of a level is adverbs, conjunctions
    # and particles that cohere only by function, which a script cannot
    # infer from surface form, so these groups are hand-authored.
    # kaiwa_ids=[] for the same reason as the N5 block.
    dict(
        id="bab_n4_full_waktu",
        level="N4",
        title="Keterangan Waktu: Nanti, Barusan, Tiba-tiba",
        title_en="Time Adverbs: Later, Just Now, Suddenly",
        description="Pola 後で, さっき, 急に dan おきに.",
        description_en="The 後で, さっき, 急に and おきに patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_ato_de", "bunpou_sakki", "bunpou_kyuu_ni", "bunpou_okini"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n4_full_perintah",
        level="N4",
        title="Menyuruh dan Melarang secara Langsung",
        title_en="Direct Commands and Prohibitions",
        description="Pola なさい dan な.",
        description_en="The なさい and な patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_nasai", "bunpou_na"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n4_full_retoris",
        level="N4",
        title="Bukankah Begitu? Penegasan Retoris",
        title_en="Isn’t It? Rhetorical Confirmation",
        description="Pola ではないか dan じゃないか.",
        description_en="The ではないか and じゃないか patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_dewa_nai_ka", "bunpou_ja_nai_ka"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n4_full_perlu",
        level="N4",
        title="Menyatakan Sesuatu Diperlukan",
        title_en="Saying Something Is Needed",
        description="Pola が必要 dan 必要がある.",
        description_en="The が必要 and 必要がある patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_ga_hitsuyou", "bunpou_hitsuyou_ga_aru"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n4_full_mengubah",
        level="N4",
        title="Membuat Sesuatu Menjadi Begitu",
        title_en="Making Something Become",
        description="Pola くする dan にする.",
        description_en="The くする and にする patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_ku_suru", "bunpou_ni_suru2"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n4_full_reaksi_te",
        level="N4",
        title="Reaksi Perasaan dengan Bentuk-Te",
        title_en="Emotional Reactions With the -Te Form",
        description="Pola てよかった, てすみません dan てほしい.",
        description_en="The てよかった, てすみません and てほしい patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_te_yokatta", "bunpou_te_sumimasen", "bunpou_te_hoshii"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n4_full_penghubung",
        level="N4",
        title="Kata Penghubung Antar Kalimat",
        title_en="Connectives Between Sentences",
        description="Pola それでも, それに dan または.",
        description_en="The それでも, それに and または patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_soredemo", "bunpou_sore_ni", "bunpou_matawa"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n4_full_menyebut_contoh",
        level="N4",
        title="Menyebutkan Contoh dan Sejenisnya",
        title_en="Giving Examples and the Like",
        description="Pola など, とか～とか dan でも.",
        description_en="The など, とか～とか and でも patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_nado", "bunpou_toka_toka", "bunpou_demo2"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n4_full_banding",
        level="N4",
        title="Membandingkan dan Menyebut yang Paling",
        title_en="Comparing, and Naming the Most",
        description="Pola より dan の中で.",
        description_en="The より and の中で patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_yori", "bunpou_no_naka_de2"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n4_full_indra_bahan",
        level="N4",
        title="Kesan Indra dan Asal Bahan",
        title_en="Sense Impressions and What Something Is Made Of",
        description="Pola がする dan から作る.",
        description_en="The がする and から作る patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_ga_suru", "bunpou_kara_tsukuru"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n4_full_keadaan",
        level="N4",
        title="Keadaan yang Tetap dan yang Terus Berlanjut",
        title_en="States That Stay, and States That Carry On",
        description="Pola まま dan ていく.",
        description_en="The まま and ていく patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_mama", "bunpou_te_iku"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n4_full_penekanan",
        level="N4",
        title="Menekankan Jumlah dan Kesesuaian Dugaan",
        title_en="Emphasising Quantity, and Living Up to Reputation",
        description="Pola も, ばかり dan さすが.",
        description_en="The も, ばかり and さすが patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_mo2", "bunpou_bakari", "bunpou_sasuga"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n4_full_merangkai",
        level="N4",
        title="Merangkai dan Menyimpulkan Kalimat",
        title_en="Linking Clauses and Summing Up",
        description="Pola て / で, は〜が… は dan と言ってもいい.",
        description_en="The て / で, は〜が… は and と言ってもいい patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_te_de", "bunpou_wa_ga_wa", "bunpou_to_itte_mo_ii"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n4_full_istilah",
        level="N4",
        title="Istilah Dasar Tata Bahasa",
        title_en="Basic Grammar Terms",
        description="Pola ところ, さ, 他動詞 & 自動詞 dan だけで.",
        description_en="The ところ, さ, 他動詞 & 自動詞 and だけで patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_tokoro", "bunpou_sa", "bunpou_tadoushi_jidoushi", "bunpou_dake_de"],
        kaiwa_ids=[],
    ),
]

# N3_CHAPTERS (order 57-81), first pass.
#
# Source: Speed Master N3-Bunpou (jlptsensei-adjacent commercial N3 grammar
# textbook, supplied by the user as a local PDF, no linear numbered-lesson
# TOC like Minna II had). Structure: Part 1 has 3 mini-stories (第一話 本を
# 買いに行く／第二話 部屋を探す／第三話 さくらの病気), each split into 3
# 場面 (scenes), each scene teaching ~20-24 grammar items across 会話/文章/
# プラス1-4 sub-sections, ~250 items total across all 9 scenes. There is no
# per-scene grammar-name TOC either (only a page-range table, はじめに
# p.3-4, もくじ p.5-6, この本の使い方 p.9, パート1の流れ overview table
# p.12) — the actual pattern names live inside each scene's own pages.
#
# Ordering method used here (since a page-by-page transcription of all
# ~250 items was out of scope for one pass): every N3 bunpou pattern
# already in bunpou_data.json (182 total) was searched as a literal
# substring across the book's full extracted text (pymupdf text layer,
# 153 pages by pymupdf's own count), restricted to page >= 13 (pages 3-9
# are はじめに/もくじ/JLPT-overview front matter, not scene content — the
# restriction changed nothing, confirming no false hits leaked in from the
# front matter). 85/182 patterns were found this way; sorting by first-hit
# page number recovers a real, textbook-grounded teaching order for those
# 85. The first-pass 25 chapters below use the first 50 of those 85 (pages
# 13-55, i.e. roughly all of 場面1-6 = 第一話 + 第二話) — the remaining 35
# found patterns (pages 59-151, 第三話 + パート2) plus the 97 N3 patterns
# with no literal hit in this book (many are compound/formal patterns this
# particular textbook doesn't happen to cover, e.g. に関して, によると, を
# 通じて) are a deliberate, documented gap for a later phase, mirroring
# Bab N4's own two-phase precedent.
#
# Cross-content matching mirrors N4's methodology exactly: each bunpou
# pattern's literal text was searched across the full N3 kaiwa dialogue
# pool (all 17 N3-tagged themes, 255 dialogues); kotoba_ids/kanji_ids were
# then picked from words/kanji that literally appear inside the matched
# kaiwa dialogue's own text (not just the bunpou entry's 3 canned
# examples). 13 of the 50 patterns had no literal hit anywhere in the N3
# kaiwa pool (te_hajimete, you_ga_nai, wake_da, o_hajime, beki_dewa_nai,
# nikakete2, to_iu_no_wa, to_ittemo, toori_ni, tate, you_to_shinai,
# ta_mono_da, koto_ni_natte_iru) — each is paired into a chapter with a
# sibling pattern that DOES have a real match, same "don't force it, pair
# with a sibling instead" rule N4 used. One kaiwa dialogue
# (kaiwa_jadi_wali_adik_n3) ended up genuinely double-matched (both まるで
# and せいで's only real hits land in that same dialogue) and is reused
# across two chapters (order 68 and 75) rather than forced onto an
# unrelated dialogue — left as-is, same "don't force it" reasoning.
N3_CHAPTERS = [
    dict(
        id="bab_n3_selagi_dan_berkat",
        level="N3",
        title="Selagi Masih dan Berkat Bantuan",
        title_en="While It's Still, and Thanks To",
        description="Pola うちに (melakukan sesuatu selagi kondisi masih sama) dan おかげで (berkat bantuan/sebab baik).",
        description_en="The うちに pattern (doing something while a condition still holds) and おかげで (thanks to a helpful cause).",
        kotoba_ids=["kotoba_hari_bulan_jikan", "kotoba_kendaraan_basu"],
        kanji_ids=["kanji_tsukau", "kanji_wakareru"],
        bunpou_ids=["bunpou_uchi_ni", "bunpou_okage_de"],
        kaiwa_ids=["kaiwa_rute_alternatif_gangguan_n3"],
    ),
    dict(
        id="bab_n3_penekanan_dan_peraturan",
        level="N3",
        title="Penekanan Kuat dan Peraturan Tertulis",
        title_en="Strong Emphasis and Written Rules",
        description="Partikel penekanan こそ (justru ~lah) dan こと sebagai peraturan tertulis (harus/dilarang ~).",
        description_en="The emphasis particle こそ (it's precisely ~) and こと as a written rule (must/must not ~).",
        kotoba_ids=["kotoba_hari_bulan_honjitsu", "kotoba_konsep_umum_kitai"],
        kanji_ids=["kanji_kata2", "kanji_shi2"],
        bunpou_ids=["bunpou_koso", "bunpou_koto2"],
        kaiwa_ids=["kaiwa_karyawan_baru_n3"],
    ),
    dict(
        id="bab_n3_tak_perlu_dan_sebisa_mungkin",
        level="N3",
        title="Tidak Perlu dan Sebisa Mungkin",
        title_en="No Need To, and As Much As Possible",
        description="Pola ことはない (tidak perlu ~) dan だけ setelah できる (sebisa/semampu mungkin).",
        description_en="The ことはない pattern (no need to ~) and だけ after できる (as much as one is able).",
        kotoba_ids=["kotoba_hobi_aktivitas_gaishoku", "kotoba_konsep_umum_ishiki"],
        kanji_ids=["kanji_karada", "kanji_kawaru"],
        bunpou_ids=["bunpou_koto_wa_nai", "bunpou_dake2"],
        kaiwa_ids=["kaiwa_alasan_vegetarian_n3"],
    ),
    dict(
        id="bab_n3_tanpa_sadar_dan_baru_setelah",
        level="N3",
        title="Tanpa Sadar dan Baru Setelah Mengalami",
        title_en="Without Meaning To, and Only After Experiencing",
        description="Pola つい (melakukan sesuatu tanpa sengaja) dan てはじめて (baru menyadari sesuatu setelah mengalaminya).",
        description_en="The つい pattern (doing something unintentionally) and てはじめて (only realizing something after experiencing it).",
        kotoba_ids=["kotoba_konsep_umum_rikai", "kotoba_konsep_umum_bunya"],
        kanji_ids=["kanji_omou", "kanji_fukai"],
        bunpou_ids=["bunpou_tsui", "bunpou_te_hajimete"],
        kaiwa_ids=["kaiwa_latar_belakang_pendidikan_n3"],
    ),
    dict(
        id="bab_n3_bukannya_tidak_dan_tentang",
        level="N3",
        title="Bukannya Tidak Mungkin, dan Tentang Sesuatu",
        title_en="It's Not That It's Impossible, and About Something",
        description="Pola ないことはない (penyangkalan ganda, menyiratkan sedikit kemungkinan) dan について (tentang/mengenai ~).",
        description_en="The ないことはない pattern (a double negative implying a slight possibility) and について (about/regarding ~).",
        kotoba_ids=["kotoba_konsep_umum_hikaku", "kotoba_konsep_umum_ryouhou"],
        kanji_ids=["kanji_do", "kanji_tsukau"],
        bunpou_ids=["bunpou_nai_koto_wa_nai", "bunpou_ni_tsuite"],
        kaiwa_ids=["kaiwa_beda_belanja_offline_online_n3"],
    ),
    dict(
        id="bab_n3_bagi_seseorang_dan_sepadan",
        level="N3",
        title="Bagi Seseorang, dan Sepadan Jumlahnya",
        title_en="For Someone, and About As Much As",
        description="Pola にとって (bagi ~, dari sudut pandang tertentu) dan ほど (sekitar/sepadan ~, perbandingan derajat/jumlah).",
        description_en="The にとって pattern (for ~, from a certain viewpoint) and ほど (about/as much as ~, a degree/quantity comparison).",
        kotoba_ids=["kotoba_konsep_umum_tsugou", "kotoba_konsep_umum_fukuzatsu"],
        kanji_ids=["kanji_koe", "kanji_tsukau"],
        bunpou_ids=["bunpou_ni_totte", "bunpou_hodo"],
        kaiwa_ids=["kaiwa_beda_telepon_pesan_n3"],
    ),
    dict(
        id="bab_n3_tak_ada_cara_dan_berusaha",
        level="N3",
        title="Tidak Ada Cara, dan Berusaha untuk",
        title_en="No Way To, and Trying To",
        description="Pola ようがない (tidak ada cara untuk ~) dan ようとする (berusaha/mencoba untuk ~).",
        description_en="The ようがない pattern (there's no way to ~) and ようとする (trying/attempting to ~).",
        kotoba_ids=["kotoba_konsep_umum_keiken", "kotoba_konsep_umum_kaiketsu"],
        kanji_ids=["kanji_karada", "kanji_in"],
        bunpou_ids=["bunpou_you_ga_nai", "bunpou_you_to_suru"],
        kaiwa_ids=["kaiwa_ketua_kelas_n3"],
    ),
    dict(
        id="bab_n3_semoga_dan_pantas_saja",
        level="N3",
        title="Semoga dan Pantas Saja",
        title_en="May It Be, and No Wonder",
        description="Pola ように di akhir kalimat (semoga/harapan) dan わけだ (pantas saja ~, kesimpulan logis).",
        description_en="The sentence-final ように pattern (a hope/wish) and わけだ (no wonder ~, a logical conclusion).",
        kotoba_ids=["kotoba_hobi_aktivitas_juujitsu", "kotoba_konsep_umum_kitai"],
        kanji_ids=["kanji_tanoshii", "kanji_zen2"],
        bunpou_ids=["bunpou_youni2", "bunpou_wake_da"],
        kaiwa_ids=["kaiwa_mahasiswa_pertukaran_n3"],
    ),
    dict(
        id="bab_n3_tapi_kasual_dan_mengingat",
        level="N3",
        title="Tapi (Kasual) dan Mengingat Kembali",
        title_en="But (Casual), and Recalling Something",
        description="Pola だけど (tetapi, versi kasual) dan っけ (bertanya pada diri sendiri untuk mengingat/mengonfirmasi sesuatu).",
        description_en="The だけど pattern (but, casual) and っけ (asking oneself to recall or confirm something).",
        kotoba_ids=["kotoba_bangunan_fasilitas_annai", "kotoba_hari_bulan_jikan"],
        kanji_ids=["kanji_tsukau", "kanji_omou"],
        bunpou_ids=["bunpou_dakedo", "bunpou_kke"],
        kaiwa_ids=["kaiwa_sistem_transfer_kereta_n3"],
    ),
    dict(
        id="bab_n3_sebagai_dan_harus",
        level="N3",
        title="Sebagai Peran, dan Harus (Kasual)",
        title_en="As a Role, and Must (Casual)",
        description="Pola として (sebagai ~) dan ないと (harus ~, kontraksi santai dari ないといけない).",
        description_en="The として pattern (as ~) and ないと (must ~, a casual contraction of ないといけない).",
        kotoba_ids=["kotoba_konsep_umum_ketsudan", "kotoba_konsep_umum_kaizen"],
        kanji_ids=["kanji_do", "kanji_kimeru"],
        bunpou_ids=["bunpou_to_shite", "bunpou_nai_to"],
        kaiwa_ids=["kaiwa_kepribadian_jujur_n3"],
    ),
    dict(
        id="bab_n3_cukup_saja_dan_berdasarkan",
        level="N3",
        title="Cukup Begitu Saja, dan Berdasarkan Sesuatu",
        title_en="It's Enough Just To, and Based On Something",
        description="Pola ばいい (cukup/asalkan ~ saja, saran minimal) dan ことから (berdasarkan/karena adanya ~, penyebab suatu kesimpulan).",
        description_en="The ばいい pattern (a minimal 'it's enough to just ~' suggestion) and ことから (based on/because of ~, the cause of a conclusion).",
        kotoba_ids=["kotoba_konsep_umum_shouhi", "kotoba_konsep_umum_keiken"],
        kanji_ids=["kanji_do", "kanji_mono"],
        bunpou_ids=["bunpou_ba_ii", "bunpou_koto_kara"],
        kaiwa_ids=["kaiwa_ditipu_saat_belanja_n3"],
    ),
    dict(
        id="bab_n3_seperti_dan_untuk_tujuan",
        level="N3",
        title="Seperti Sekali, dan Untuk Tujuan Tertentu",
        title_en="Just Like, and For a Specific Purpose",
        description="Pola まるで (perumpamaan kuat, seperti/bagaikan ~) dan には (untuk ~, tujuan; juga penekanan topik+waktu/tempat).",
        description_en="The まるで pattern (a strong comparison, just like ~) and には (for ~, a purpose; also emphasizing topic + time/place).",
        kotoba_ids=["kotoba_hari_bulan_jiki", "kotoba_hari_bulan_saikin"],
        kanji_ids=["kanji_otouto", "kanji_ani"],
        bunpou_ids=["bunpou_marude", "bunpou_ni_wa"],
        kaiwa_ids=["kaiwa_jadi_wali_adik_n3"],
    ),
    dict(
        id="bab_n3_demi_tujuan_dan_termasuk",
        level="N3",
        title="Demi Suatu Tujuan, dan Termasuk di Dalamnya",
        title_en="For the Sake Of, and Including",
        description="Pola ために (demi/untuk ~ tujuan, atau karena ~ sebab formal) dan をはじめ (termasuk ~ dan lain-lain, contoh utama dari suatu kelompok).",
        description_en="The ために pattern (for the sake of ~, or a formal because-of-~) and をはじめ (including ~ and others, a group's main example).",
        kotoba_ids=["kotoba_anggota_tubuh_shisei", "kotoba_hobi_aktivitas_chousen"],
        kanji_ids=["kanji_omou", "kanji_tsuyoi"],
        bunpou_ids=["bunpou_tame_ni", "bunpou_o_hajime"],
        kaiwa_ids=["kaiwa_rencana_jangka_panjang_n3"],
    ),
    dict(
        id="bab_n3_seharusnya_dan_seharusnya_tidak",
        level="N3",
        title="Seharusnya Melakukan, dan Seharusnya Tidak",
        title_en="Should Do, and Should Not Do",
        description="Pola べきだ (seharusnya ~, kewajiban moral) dan べきではない (seharusnya tidak ~).",
        description_en="The べきだ pattern (should ~, a moral obligation) and べきではない (should not ~).",
        kotoba_ids=["kotoba_kendaraan_densha", "kotoba_kendaraan_manin"],
        kanji_ids=["kanji_oto", "kanji_in"],
        bunpou_ids=["bunpou_beki_da", "bunpou_beki_dewa_nai"],
        kaiwa_ids=["kaiwa_etika_kereta_padat_n3"],
    ),
    dict(
        id="bab_n3_sementara_dan_aturan_berlaku",
        level="N3",
        title="Untuk Sementara, dan Sudah Menjadi Aturan",
        title_en="For the Time Being, and It's the Established Rule",
        description="Kata keterangan しばらく (sebentar, untuk sementara waktu) dan pola ことになっている (sudah ditetapkan/menjadi aturan bahwa ~).",
        description_en="The adverb しばらく (for a while, for the time being) and ことになっている (it's an established rule/arrangement that ~).",
        kotoba_ids=["kotoba_bangunan_fasilitas_kouji", "kotoba_hari_bulan_kyou"],
        kanji_ids=["kanji_tsukau", "kanji_omou"],
        bunpou_ids=["bunpou_shibaraku", "bunpou_koto_ni_natte_iru"],
        kaiwa_ids=["kaiwa_rute_biasa_ditutup_n3"],
    ),
    dict(
        id="bab_n3_berniat_tapi_gagal_dan_dengan_anggapan",
        level="N3",
        title="Sudah Berniat tapi Gagal, dan Berpura-pura",
        title_en="Had Intended To But Didn't, and Pretending To",
        description="Pola つもりだった (sebenarnya berniat ~ tapi tidak terlaksana) dan つもりで (dengan niat/anggapan seolah-olah ~).",
        description_en="The つもりだった pattern (had intended to ~ but it didn't happen) and つもりで (with the mindset/pretense of ~).",
        kotoba_ids=["kotoba_hari_bulan_kondo", "kotoba_konsep_umum_hontou"],
        kanji_ids=["kanji_do", "kanji_kimeru"],
        bunpou_ids=["bunpou_tsumori_datta", "bunpou_tsumori_de"],
        kaiwa_ids=["kaiwa_tidak_angkat_telepon_n3"],
    ),
    dict(
        id="bab_n3_setiap_kali_dan_karena_terlalu",
        level="N3",
        title="Setiap Kali, dan Karena Terlalu Berlebihan",
        title_en="Every Time, and Because of Too Much",
        description="Pola たびに (setiap kali ~) dan あまり (karena terlalu ~, menyatakan akibat berlebihan).",
        description_en="The たびに pattern (every time ~) and あまり (because of too much ~, an excessive result).",
        kotoba_ids=["kotoba_hari_bulan_jikan", "kotoba_konsep_umum_settoku"],
        kanji_ids=["kanji_kokoro", "kanji_motsu"],
        bunpou_ids=["bunpou_tabi_ni", "bunpou_amari"],
        kaiwa_ids=["kaiwa_pindah_jurusan_n3"],
    ),
    dict(
        id="bab_n3_mulai_melakukan_dan_dalam_hal",
        level="N3",
        title="Mulai Melakukan, dan Dalam Hal Keahlian",
        title_en="Starting To Do, and When It Comes To",
        description="Pola かける (mulai melakukan ~ tapi belum selesai) dan にかけて (dalam hal ~, keahlian/bidang tertentu).",
        description_en="The かける pattern (starting to ~ but not finished) and にかけて (when it comes to ~, a specific skill/field).",
        kotoba_ids=["kotoba_hari_bulan_kondo", "kotoba_konsep_umum_kansha"],
        kanji_ids=["kanji_do", "kanji_kokoro"],
        bunpou_ids=["bunpou_kakeru", "bunpou_nikakete2"],
        kaiwa_ids=["kaiwa_bantu_orang_stasiun_n3"],
    ),
    dict(
        id="bab_n3_definisi_dan_gara_gara",
        level="N3",
        title="Maksudnya Adalah, dan Gara-gara Sesuatu",
        title_en="What It Means Is, and Because Of (Negative)",
        description="Pola というのは (yang dimaksud dengan ~ adalah, definisi/penjelasan) dan せいで (gara-gara ~, akibat negatif).",
        description_en="The というのは pattern (what ~ means is, a definition/explanation) and せいで (because of ~, a negative result).",
        kotoba_ids=["kotoba_hari_bulan_jiki", "kotoba_hari_bulan_saikin"],
        kanji_ids=["kanji_otouto", "kanji_ani"],
        bunpou_ids=["bunpou_to_iu_no_wa", "bunpou_sei_de"],
        kaiwa_ids=["kaiwa_jadi_wali_adik_n3"],
    ),
    dict(
        id="bab_n3_bukan_berarti_dan_sekalipun",
        level="N3",
        title="Bukan Berarti, dan Sekalipun Begitu",
        title_en="It Doesn't Mean, and Even If",
        description="Pola わけではない (bukan berarti ~, penyangkalan parsial) dan たって (sekalipun/meskipun ~, versi kasual).",
        description_en="The わけではない pattern (it doesn't mean ~, a partial denial) and たって (even if/though ~, casual).",
        kotoba_ids=["kotoba_agama_budaya_bunka", "kotoba_cuaca_tenki"],
        kanji_ids=["kanji_do", "kanji_kaze"],
        bunpou_ids=["bunpou_wake_dewa_nai", "bunpou_tatte"],
        kaiwa_ids=["kaiwa_kepercayaan_tradisional_cuaca_n3"],
    ),
    dict(
        id="bab_n3_meski_disebut_dan_lebih_lanjut",
        level="N3",
        title="Meski Disebut Begitu, dan Lebih Lanjut Lagi",
        title_en="Even Though It's Called That, and Furthermore",
        description="Pola といっても (meski dikatakan ~, tapi kenyataannya tidak seberapa) dan さらに (lebih lanjut, semakin).",
        description_en="The といっても pattern (even though it's called ~, but in reality it's not much) and さらに (further, even more).",
        kotoba_ids=["kotoba_hari_bulan_jiki", "kotoba_hari_bulan_kondo"],
        kanji_ids=["kanji_do", "kanji_tsukau"],
        bunpou_ids=["bunpou_to_ittemo", "bunpou_sarani"],
        kaiwa_ids=["kaiwa_jenis_tiket_kereta_n3"],
    ),
    dict(
        id="bab_n3_bukan_hanya_dan_sesuai_dengan",
        level="N3",
        title="Bukan Hanya Itu, dan Sesuai dengan Yang Ada",
        title_en="Not Only That, and Just As It Is",
        description="Pola だけでなく (bukan hanya ~ tapi juga) dan とおりに (sesuai dengan ~, seperti yang ~).",
        description_en="The だけでなく pattern (not only ~ but also) and とおりに (as, according to ~).",
        kotoba_ids=["kotoba_bunga_tanaman_bara", "kotoba_konsep_umum_ishiki"],
        kanji_ids=["kanji_do", "kanji_karada"],
        bunpou_ids=["bunpou_dake_denaku", "bunpou_toori_ni"],
        kaiwa_ids=["kaiwa_pentingnya_nutrisi_atlet_n3"],
    ),
    dict(
        id="bab_n3_baru_saja_selesai_dan_tak_mau_berusaha",
        level="N3",
        title="Baru Saja Selesai Dibuat, dan Enggan Berusaha",
        title_en="Freshly Made, and Refusing to Try",
        description="Pola たて (baru saja selesai ~, segar/baru) dan ようとしない (tidak mau berusaha untuk ~, menolak/enggan).",
        description_en="The たて pattern (freshly ~, just finished) and ようとしない (won't even try to ~, refuses/reluctant).",
        kotoba_ids=["kotoba_arah_lokasi_basho", "kotoba_cara_memasak_kiru"],
        kanji_ids=["kanji_omou", "kanji_oboeru"],
        bunpou_ids=["bunpou_tate", "bunpou_doushitemo"],
        kaiwa_ids=["kaiwa_etika_telepon_tempat_umum_n3"],
    ),
    dict(
        id="bab_n3_mencari_persetujuan_dan_bagaimanapun_juga",
        level="N3",
        title="Mencari Persetujuan, dan Bagaimanapun Juga",
        title_en="Seeking Agreement, and No Matter What",
        description="Pola じゃない (bukankah begitu?, mencari persetujuan yang lebih lembut) dan ようとしない (tidak mau berusaha untuk ~, menolak/enggan).",
        description_en="The じゃない pattern (isn't it?, a gentler way to seek agreement) and ようとしない (won't even try to ~, refuses/reluctant).",
        kotoba_ids=["kotoba_konsep_umum_kankyou", "kotoba_konsep_umum_saisho"],
        kanji_ids=["kanji_omou", "kanji_suki2"],
        bunpou_ids=["bunpou_ja_nai2", "bunpou_you_to_shinai"],
        kaiwa_ids=["kaiwa_alasan_pindah_kota_n3"],
    ),
    dict(
        id="bab_n3_sebisa_mungkin_dan_kenangan_lama",
        level="N3",
        title="Sebisa Mungkin, dan Kenangan Kebiasaan Lama",
        title_en="As Much As Possible, and Nostalgic Old Habits",
        description="Kata keterangan なるべく (sebisa mungkin) dan pola たものだ (dulu sering ~, kenangan/kebiasaan masa lalu).",
        description_en="The adverb なるべく (as much as possible) and たものだ (used to ~, a nostalgic past memory/habit).",
        kotoba_ids=["kotoba_ekspresi_wajah_naku", "kotoba_hari_bulan_hiruma"],
        kanji_ids=["kanji_hiru", "kanji_omou"],
        bunpou_ids=["bunpou_narubeku", "bunpou_ta_mono_da"],
        kaiwa_ids=["kaiwa_nonton_sendirian_n3"],
    ),
    # ---- N3 phase 2 (2026-08-04): +20 chapters, 53 patterns ----
    #
    # N3 was the weakest level in the curriculum (27% of its patterns
    # covered) for a self-inflicted reason: the first pass read only pages
    # 13-55 of Speed Master and stopped there. With the full So-matome N3
    # book now available, chapters 1-15 below follow **its** six-week
    # syllabus for the 20 of its grammar points that were not yet in any
    # chapter, and 16-20 group functionally from the rest of the unused
    # pool (tendency suffixes, formal topic markers, "as X changes",
    # through/centred-on, and timing).
    #
    # This also lands the five patterns re-levelled or authored in the
    # So-matome cross-check earlier today (ことだ, ばかりか, ところだった,
    # その上, そのかわり) into real chapters, closing the gap that entry
    # explicitly left open.
    #
    # Kaiwa: 16 of 20 chapters matched automatically, but a hand-check of
    # the surrounding text rejected 7 as substring false positives — see
    # the REJECTED tuple in the session's run_n3.py for exactly what each
    # one actually matched (「昨日始まったばかりです」 is たばかり, 「すっきり」
    # is not っきり, 「実際に」 is not 際に, and so on). 9 verified links
    # remain; the other 11 chapters ship kaiwa_ids=[] on purpose.
    dict(
        id="bab_n3_p2_bakari",
        level="N3",
        title="Keluarga ばかり: Melulu dan Bukan Hanya",
        title_en="The ばかり Family: Nothing But, and Not Only",
        description="Pola ばかりで, ばかりでなく dan てばかりいる.",
        description_en="The ばかりで, ばかりでなく and てばかりいる patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_bakari_de", "bunpou_bakari_denaku", "bunpou_te_bakari_iru"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n3_p2_niyoru",
        level="N3",
        title="Oleh, Tergantung, dan Menurut Sumber",
        title_en="By, Depending On, and According To",
        description="Pola によって / による dan によると /によれば.",
        description_en="The によって / による and によると /によれば patterns.",
        kotoba_ids=["kotoba_hari_bulan_shuukan", "kotoba_hobi_aktivitas_shashin"],
        kanji_ids=["kanji_omou", "kanji_wakareru"],
        bunpou_ids=["bunpou_ni_yotte_niyoru", "bunpou_ni_yoru_to_ni_yoreba"],
        kaiwa_ids=["kaiwa_klaim_asuransi_barang_rusak_n3"],
    ),
    dict(
        id="bab_n3_p2_to_iu",
        level="N3",
        title="Menyebut Ulang dengan Kata Lain",
        title_en="Rephrasing and Reintroducing a Topic",
        description="Pola というより, と言えば（といえば） dan と言うと（というと）.",
        description_en="The というより, と言えば（といえば） and と言うと（というと） patterns.",
        kotoba_ids=["kotoba_hobi_aktivitas_gaishoku", "kotoba_konsep_umum_ishiki"],
        kanji_ids=["kanji_karada", "kanji_kawaru"],
        bunpou_ids=["bunpou_to_iu_yori", "bunpou_to_ieba", "bunpou_to_iu_to"],
        kaiwa_ids=["kaiwa_alasan_vegetarian_n3"],
    ),
    dict(
        id="bab_n3_p2_sebanyakpun",
        level="N3",
        title="Sebanyak Apa Pun, Tetap Saja",
        title_en="However Much, It Still Stands",
        description="Pola いくら～ても, どんなに～ても dan たとえ～ても.",
        description_en="The いくら～ても, どんなに～ても and たとえ～ても patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_ikura_temo", "bunpou_donnani_temo", "bunpou_tatoe_temo"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n3_p2_untuk_ukuran",
        level="N3",
        title="Untuk Ukurannya, di Luar Dugaan",
        title_en="For What It Is, Unexpectedly So",
        description="Pola にしては dan 割に（わりに）.",
        description_en="The にしては and 割に（わりに） patterns.",
        kotoba_ids=["kotoba_arah_lokasi_chuushin", "kotoba_bangunan_fasilitas_ekimae"],
        kanji_ids=["kanji_do", "kanji_kokoro"],
        bunpou_ids=["bunpou_ni_shite_wa", "bunpou_wari_ni"],
        kaiwa_ids=["kaiwa_rekomendasi_restoran_teman_n3"],
    ),
    dict(
        id="bab_n3_p2_mencela",
        level="N3",
        title="Padahal Begitu, Nada Mencela",
        title_en="Even Though, With a Critical Tone",
        description="Pola くせに dan ながらも.",
        description_en="The くせに and ながらも patterns.",
        kotoba_ids=["kotoba_kendaraan_touchaku", "kotoba_konsep_umum_taiou"],
        kanji_ids=["kanji_do", "kanji_atama"],
        bunpou_ids=["bunpou_kuse_ni", "bunpou_nagara_mo"],
        kaiwa_ids=["kaiwa_telepon_darurat_n3"],
    ),
    dict(
        id="bab_n3_p2_nasihat",
        level="N3",
        title="Nasihat Tegas dan Tidak Ada Pilihan",
        title_en="Firm Advice, and Having No Choice",
        description="Pola ことだ, しかない dan わけにはいかない.",
        description_en="The ことだ, しかない and わけにはいかない patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_koto_da", "bunpou_shika_nai", "bunpou_wake_ni_wa_ikanai"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n3_p2_menjelaskan",
        level="N3",
        title="Menyimpulkan dan Menjelaskan",
        title_en="Summing Up and Explaining",
        description="Pola つまり, すなわち dan なぜなら.",
        description_en="The つまり, すなわち and なぜなら patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_tsumari", "bunpou_sunawachi", "bunpou_nazenara"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n3_p2_bukan_hanya",
        level="N3",
        title="Bukan Hanya Itu, Ada Tambahannya",
        title_en="Not Only That, There Is More",
        description="Pola ばかりか, その上（そのうえ） dan はもちろん.",
        description_en="The ばかりか, その上（そのうえ） and はもちろん patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_bakari_ka", "bunpou_sono_ue", "bunpou_wa_mochiron"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n3_p2_sebaliknya",
        level="N3",
        title="Sebagai Gantinya, dan Ternyata Sebaliknya",
        title_en="In Exchange, and Yet Contrary to That",
        description="Pola そのかわり dan ところが.",
        description_en="The そのかわり and ところが patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_sono_kawari", "bunpou_tokoroga"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n3_p2_nyaris",
        level="N3",
        title="Nyaris Terjadi, dan Sepertinya Tidak Akan",
        title_en="A Near Miss, and an Unlikely Outcome",
        description="Pola ところだった dan そうもない /そうにない.",
        description_en="The ところだった and そうもない /そうにない patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_tokoro_datta", "bunpou_sou_mo_nai"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n3_p2_mustahil",
        level="N3",
        title="Tidak Mungkin, dan Belum Tentu",
        title_en="Impossible, and Not Necessarily",
        description="Pola わけがない, とは限らない（とはかぎらない） dan とても～ない.",
        description_en="The わけがない, とは限らない（とはかぎらない） and とても～ない patterns.",
        kotoba_ids=["kotoba_hobi_aktivitas_eiga", "kotoba_konsep_umum_kitai"],
        kanji_ids=["kanji_kokoro", "kanji_tsukuru"],
        bunpou_ids=["bunpou_wake_ga_nai", "bunpou_to_wa_kagiranai", "bunpou_totemo_nai"],
        kaiwa_ids=["kaiwa_adaptasi_novel_ke_film_n3"],
    ),
    dict(
        id="bab_n3_p2_jarang",
        level="N3",
        title="Jarang, Sama Sekali Tidak, dan Tidak Khususnya",
        title_en="Rarely, Never, and Not Particularly",
        description="Pola めったに～ない, 決して～ない（けっして～ない） dan 別に～ない（べつに～ない）.",
        description_en="The めったに～ない, 決して～ない（けっして～ない） and 別に～ない（べつに～ない） patterns.",
        kotoba_ids=["kotoba_konsep_umum_kekka", "kotoba_konsep_umum_shinrai"],
        kanji_ids=["kanji_kokoro", "kanji_yamai"],
        bunpou_ids=["bunpou_metta_ni_nai", "bunpou_kesshite_nai", "bunpou_betsuni_nai"],
        kaiwa_ids=["kaiwa_alasan_second_opinion_n3"],
    ),
    dict(
        id="bab_n3_p2_dibiarkan",
        level="N3",
        title="Hanya Sekali Itu, dan Dibiarkan Begitu Saja",
        title_en="Just That Once, and Left As It Is",
        description="Pola きり dan っぱなし.",
        description_en="The きり and っぱなし patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_kiri", "bunpou_ppanashi"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n3_p2_ganti_topik",
        level="N3",
        title="Mengalihkan Pembicaraan",
        title_en="Changing the Subject",
        description="Pola ところで dan さて.",
        description_en="The ところで and さて patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_tokorode", "bunpou_sate"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n3_p2_kecenderungan",
        level="N3",
        title="Cenderung, Agak, dan Terkesan",
        title_en="Prone To, Slightly, and Seeming",
        description="Pola がち, 気味（ぎみ） dan っぽい.",
        description_en="The がち, 気味（ぎみ） and っぽい patterns.",
        kotoba_ids=["kotoba_hari_bulan_inai", "kotoba_kendaraan_teiki"],
        kanji_ids=["kanji_do", "kanji_tsukau"],
        bunpou_ids=["bunpou_gachi", "bunpou_gimi", "bunpou_ppoi"],
        kaiwa_ids=["kaiwa_sistem_poin_member_n3"],
    ),
    dict(
        id="bab_n3_p2_topik_formal",
        level="N3",
        title="Menandai Topik secara Formal",
        title_en="Marking a Topic Formally",
        description="Pola に対して（にたいして）, に関する / に関して（にかんする / にかんして） dan において / における.",
        description_en="The に対して（にたいして）, に関する / に関して（にかんする / にかんして） and において / における patterns.",
        kotoba_ids=["kotoba_hari_bulan_kako", "kotoba_konsep_umum_kansha"],
        kanji_ids=["kanji_hikari", "kanji_omou"],
        bunpou_ids=["bunpou_ni_taishite", "bunpou_ni_kansuru", "bunpou_nioite_niokeru"],
        kaiwa_ids=["kaiwa_nilai_nilai_hidup_n3"],
    ),
    dict(
        id="bab_n3_p2_seiring",
        level="N3",
        title="Seiring Berubahnya Sesuatu",
        title_en="As One Thing Changes With Another",
        description="Pola につれて, にしたがって dan と共に（とともに）.",
        description_en="The につれて, にしたがって and と共に（とともに） patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_ni_tsurete", "bunpou_ni_shitagatte", "bunpou_to_tomo_ni"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n3_p2_melalui",
        level="N3",
        title="Melalui, Berpusat Pada, dan Dengan Sepenuh Hati",
        title_en="Through, Centred On, and Wholeheartedly",
        description="Pola を通じて / を通して（をつうじて / をとおして）, を中心に（をちゅうしんに） dan を込めて（をこめて）.",
        description_en="The を通じて / を通して（をつうじて / をとおして）, を中心に（をちゅうしんに） and を込めて（をこめて） patterns.",
        kotoba_ids=["kotoba_arah_lokasi_chuushin", "kotoba_hari_bulan_kikan"],
        kanji_ids=["kanji_kokoro", "kanji_tsukau"],
        bunpou_ids=["bunpou_o_tsuujite_o_tooshite", "bunpou_o_chuushin_ni", "bunpou_o_komete"],
        kaiwa_ids=["kaiwa_rencana_jr_pass_n3"],
    ),
    dict(
        id="bab_n3_p2_waktu_tepat",
        level="N3",
        title="Tepat Pada Saat Itu",
        title_en="At That Very Moment",
        description="Pola たとたん, 最中に（さいちゅうに） dan 際に（さいに）.",
        description_en="The たとたん, 最中に（さいちゅうに） and 際に（さいに） patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_ta_totan", "bunpou_saichuu_ni", "bunpou_sai_ni"],
        kaiwa_ids=[],
    ),
]

# N2_CHAPTERS (order 82-97), first pass.
#
# Source: two user-supplied PDFs were checked. "394081276-JLPT-Gokaku-
# Dekiru-N2.pdf" (合格できる日本語能力試験N2) turned out to be a pure
# mock-exam/practice-question book (言語知識・読解 + 聴解 sections, 問題
# 1-5 exam formats) with no linear grammar teaching order, so it wasn't
# usable as an ordering reference. "ebook-learn-and-practice-grammar-
# n2.pdf" is the one actually used: a "1日1文型" style book with a clean
# linear structure — 8 週 (weeks), each with 6 日目 (days) teaching one
# named grammar pattern each (48 patterns total) plus a 7th
# 実戦問題/practice day, page-numbered and explicitly listed in its 目次
# (p.4-5). Both PDFs are pure image scans (0 extractable characters via
# pymupdf) — read by rendering pages to PNG and reading them visually,
# same fallback already used for Speed Master's front matter.
#
# Ordering method: each of the 48 day-title phrases (e.g. "見た目はとも
# かく", "選手だっただけに") was checked against all 197 N2-tagged bunpou
# entries already in bunpou_data.json, first by literal substring search
# and then, for entries stored as "漢字表記（かな表記）" (parenthetical
# reading notation, common in this dataset's more formal N2/N1 patterns),
# by also trying the kanji-only and kana-only halves separately — the
# plain-substring pass alone under-matched badly on this level. 31 of the
# 48 days matched a genuine N2-tagged entry this way; the other 17 days'
# grammar point turned out to already exist in bunpou_data.json but
# tagged N3 (e.g. っぽい, さえ〜ば, としたら, にしたがって, どおり, わけだ,
# たとたん, だらけ, 一方だ, 向け, にかけて, がたい, ようがない, もあれば
# 〜もある, をこめて) — this particular book re-teaches several patterns
# Bab already covers at N3 depth, so those 17 were deliberately left out
# of the N2 pool rather than attaching an N3-tagged bunpou id to an N2
# chapter. The 31 real N2-tagged matches were paired 2-per-chapter in
# strict day order (one chapter, order 97, ends up a single-pattern
# chapter since 31 is odd) — the same "don't force it" rule as
# elsewhere, not a scope cut.
#
# Cross-content kaiwa matching used the same literal-search method as
# N3/N4 (all 17 N2-tagged kaiwa themes, 255 dialogues) but the yield was
# much lower here — only 9 of the 31 patterns' literal text turned up
# inside any N2 kaiwa dialogue, versus 38/50 for N3. N2 grammar here
# skews more formal/written (がたい, にあたって, ものがある, ざるを得ない)
# while the kaiwa dialogues are conversational, so the two don't overlap
# as naturally as N3/N4's more colloquial patterns did. Rather than force
# a mismatch, chapters without a real kaiwa hit ship with kaiwa_ids=[]
# (BabDetailScreen already hides the Percakapan section when empty), and
# their kotoba_ids/kanji_ids instead come from words/kanji that literally
# appear in the *bunpou entry's own* sentenceExamples — still real
# dataset content, just not cross-linked to a specific dialogue. 7 of the
# 16 chapters below are in this fallback state; documented here rather
# than silently thin.
N2_CHAPTERS = [
    dict(
        id="bab_n2_alasan_manja_dan_mengesampingkan",
        level="N2",
        title="Alasan Bernada Manja, dan Mengesampingkan Sesuatu",
        title_en="A Whiny Excuse, and Setting Something Aside",
        description="Pola もの/もん di akhir kalimat (alasan bernada manja/kekanakan) dan はともかく (terlepas dari ~, mengesampingkan untuk sementara).",
        description_en="The sentence-final もの/もん pattern (a whiny, childish excuse) and はともかく (setting ~ aside for now).",
        # Cleared 2026-08-04. The previous dialogue matched on 「安定して
        # はいたものの」 — that is ものの (bunpou_mono_no), a different N2
        # entry, not the sentence-final もの/もん excuse. はともかく does not
        # occur anywhere in the N2 dialogue pool, so there is no honest
        # replacement; falls back to the bunpou entries' sentenceExamples.
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_mono_mon", "bunpou_wa_tomokaku"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_tak_tertahankan_dan_situasi_mendesak",
        level="N2",
        title="Tak Tertahankan, dan Situasi Mendesak",
        title_en="Unbearably So, and an Urgent Situation",
        description="Pola てたまらない (sangat ~ sampai tak tertahankan) dan てはいられない (tidak bisa terus-menerus ~, harus segera bertindak).",
        description_en="The てたまらない pattern (unbearably ~) and てはいられない (can't keep on ~, must act now).",
        kotoba_ids=["kotoba_media_hiburan_manga"],
        kanji_ids=["kanji_hi4_n3"],
        bunpou_ids=["bunpou_te_tamaranai", "bunpou_te_wa_irarenai"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_sepadan_hasilnya_dan_tak_bisa",
        level="N2",
        title="Sepadan Hasilnya, dan Tidak Bisa Melakukan",
        title_en="Worth the Effort, and Unable To",
        description="Pola 甲斐がある (ada gunanya/sepadan hasilnya untuk ~) dan 得ない (tidak bisa ~, gaya formal/tertulis).",
        description_en="The 甲斐がある pattern (worth the effort for ~) and 得ない (unable to ~, a formal/written style).",
        # Cleared 2026-08-04. The previous dialogue matched on 「完璧とは
        # 言えないけど」 — that is the negative potential of 言える, not the
        # formal 得ない suffix. Every 得ない in the N2 pool is part of
        # ざるを得ない (a different entry, already linked at order 87), and
        # the only 甲斐 hit is the lexicalised noun やりがい rather than the
        # 甲斐がある pattern. No honest replacement exists.
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_kai_ga_aru", "bunpou_enai"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_selama_kondisi_dan_secara_teori",
        level="N2",
        title="Selama Kondisi Ini, dan Secara Teori",
        title_en="As Long As, and On Paper",
        description="Pola 限り (selama ~, sepanjang ~, batasan kondisi) dan の上では (secara ~, di atas kertas/teori meski kenyataannya beda).",
        description_en="The 限り pattern (as long as ~, a condition's limit) and の上では (on paper/in theory, even if reality differs).",
        kotoba_ids=["kotoba_arah_lokasi_tochuu", "kotoba_hobi_aktivitas_ongaku"],
        kanji_ids=["kanji_kei_n3", "kanji_chou_n3"],
        bunpou_ids=["bunpou_kagiri", "bunpou_no_ue_dewa"],
        kaiwa_ids=["kaiwa_kepadatan_jam_sibuk_n2"],
    ),
    dict(
        id="bab_n2_menanggapi_harapan_dan_sambil",
        level="N2",
        title="Menanggapi Harapan, dan Melakukan Sambil",
        title_en="Responding to Expectations, and Doing While",
        description="Pola に応えて (menanggapi/memenuhi ~, harapan/permintaan/dukungan) dan つつ (sambil ~, dua tindakan bersamaan, gaya formal).",
        description_en="The に応えて pattern (responding to ~, an expectation or request) and つつ (while ~, two simultaneous actions, formal style).",
        kotoba_ids=["kotoba_bangunan_fasilitas_yoyaku", "kotoba_hobi_aktivitas_ryouri"],
        kanji_ids=["kanji_sou_n3", "kanji_sen_n3"],
        bunpou_ids=["bunpou_ni_kotaete", "bunpou_tsutsu"],
        kaiwa_ids=["kaiwa_rayakan_momen_spesial_n2"],
    ),
    dict(
        id="bab_n2_terpaksa_harus_dan_dalam_rangka",
        level="N2",
        title="Terpaksa Harus, dan Dalam Rangka Sesuatu",
        title_en="Have No Choice But To, and In Preparation For",
        description="Pola ざるを得ない (terpaksa harus ~, tidak bisa tidak ~) dan にあたって (dalam rangka ~, menjelang momen penting).",
        description_en="The ざるを得ない pattern (have no choice but to ~) and にあたって (in preparation for/on the occasion of ~).",
        kotoba_ids=["kotoba_konsep_umum_keiken", "kotoba_obat_obatan_byouin"],
        kanji_ids=["kanji_kei_n3", "kanji_ka_n3"],
        bunpou_ids=["bunpou_zaru_o_enai", "bunpou_ni_atatte"],
        kaiwa_ids=["kaiwa_keracunan_makanan_n2"],
    ),
    dict(
        id="bab_n2_tentu_saja_begitu_dan_untung_masih",
        level="N2",
        title="Tentu Saja Begitu, dan Untung Masih Mendingan",
        title_en="Of Course, That's How They Are, and At Least It's Not Worse",
        description="Pola ことだから (karena orangnya memang begitu, tentu saja ~) dan だけましだ (untung masih ~, dibanding kemungkinan lebih buruk).",
        description_en="The ことだから pattern (of course, that's just how they are) and だけましだ (at least it's not as bad as it could be).",
        kotoba_ids=["kotoba_pekerjaan_kantor_chikoku"],
        kanji_ids=["kanji_men_n3", "kanji_yuu_n3"],
        bunpou_ids=["bunpou_koto_dakara", "bunpou_dake_mashi_da"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_justru_karena_dan_berdasarkan",
        level="N2",
        title="Justru Karena Itu, dan Berdasarkan Sesuatu",
        title_en="Precisely Because Of, and Based On",
        description="Pola だけに (justru karena ~, sehingga wajar atau hasilnya lebih terasa) dan に基づいて (berdasarkan ~).",
        description_en="The だけに pattern (precisely because ~, making the result more pronounced) and に基づいて (based on ~).",
        kotoba_ids=["kotoba_bangunan_fasilitas_annai", "kotoba_kendaraan_densha"],
        kanji_ids=["kanji_nai_n3", "kanji_sai_n3"],
        bunpou_ids=["bunpou_dake_ni", "bunpou_ni_motozuite"],
        kaiwa_ids=["kaiwa_sistem_tiket_rumit_n2"],
    ),
    dict(
        id="bab_n2_karena_sudah_dan_dari_sudut_pandang",
        level="N2",
        title="Karena Sudah Terlanjur, dan Dari Sudut Pandang",
        title_en="Now That It's Done, and From a Certain Viewpoint",
        description="Pola 以上は (karena sudah ~, maka wajar/harus) dan から見ると (kalau dilihat dari ~).",
        description_en="The 以上は pattern (now that ~, so it follows that) and から見ると (looking at it from ~).",
        kotoba_ids=["kotoba_angka_satuan_ijou", "kotoba_konsep_umum_saigo"],
        kanji_ids=["kanji_sai_n3", "kanji_yaku_n3"],
        bunpou_ids=["bunpou_ijou_wa", "bunpou_kara_miru_to"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_ragu_dua_pilihan_dan_sudah_pasti",
        level="N2",
        title="Ragu Antara Dua Pilihan, dan Sudah Pasti",
        title_en="Torn Between Two Choices, and Certainly So",
        description="Pola ようか〜まいか (apakah akan ~ atau tidak, keraguan dua pilihan) dan に決まっている (sudah pasti ~, keyakinan kuat penutur).",
        description_en="The ようか〜まいか pattern (torn between doing ~ or not) and に決まっている (it's certainly ~, a strong conviction).",
        kotoba_ids=[],
        kanji_ids=["kanji_hi4_n3", "kanji_mei2_n3"],
        bunpou_ids=["bunpou_you_ka_mai_ka", "bunpou_ni_kimatte_iru"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_seputar_topik_dan_tanpa_memandang",
        level="N2",
        title="Seputar Suatu Topik, dan Tanpa Memandang",
        title_en="Surrounding a Topic, and Regardless Of",
        description="Pola をめぐって (seputar ~, topik perdebatan/perselisihan) dan を問わず (tanpa memandang ~, usia/gender/dsb).",
        description_en="The をめぐって pattern (surrounding ~, a topic of debate) and を問わず (regardless of ~, age/gender/etc.).",
        kotoba_ids=["kotoba_bangunan_fasilitas_tochi", "kotoba_konsep_umum_seisaku"],
        kanji_ids=["kanji_sei_n3", "kanji_gi_n3"],
        bunpou_ids=["bunpou_o_megutte", "bunpou_o_towazu"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_memang_seharusnya_dan_kesan_mendalam",
        level="N2",
        title="Memang Seharusnya Begitu, dan Kesan Mendalam",
        title_en="That's How It Should Be, and a Deep Impression",
        description="Pola ものだ (memang seharusnya ~, norma umum/kebiasaan lampau) dan ものがある (ada sesuatu yang ~, kesan mendalam sulit dijelaskan).",
        description_en="The ものだ pattern (that's just how it should be, a general norm) and ものがある (there's a certain ~ quality, hard to put into words).",
        # Re-pointed 2026-08-04. The previous dialogue
        # (kaiwa_keluhkan_pelayanan_sopan_n2) was matched on 「態度が悪かった
        # ものだから」 — that is bunpou_mono_dakara, a *different* N2 entry
        # that is not in this chapter. Neither ものだ nor ものがある appeared
        # anywhere in it. This one has 「意外と寂しさは感じないものだよ」, a
        # textbook general-truth ものだ.
        kotoba_ids=["kotoba_arah_lokasi_kyori", "kotoba_arah_lokasi_tochuu"],
        kanji_ids=["kanji_tou_n3", "kanji_shu2_n3"],
        bunpou_ids=["bunpou_mono_da", "bunpou_mono_ga_aru"],
        kaiwa_ids=["kaiwa_mengemudi_jarak_jauh_sendirian_n2"],
    ),
    dict(
        id="bab_n2_berdasarkan_acuan_dan_padahal_begitu",
        level="N2",
        title="Berdasarkan Suatu Acuan, dan Padahal Begitu",
        title_en="Based On a Reference, and Despite That",
        description="Pola をもとに (berdasarkan pada ~, sebagai bahan/acuan dasar) dan それなのに (padahal begitu, tapi tetap saja ~).",
        description_en="The をもとに pattern (based on ~, as a reference) and それなのに (despite that, yet still ~).",
        kotoba_ids=["kotoba_konsep_umum_kekka", "kotoba_konsep_umum_keikaku"],
        kanji_ids=["kanji_sai3_n3", "kanji_ken2_n3"],
        bunpou_ids=["bunpou_o_moto_ni", "bunpou_sore_na_noni"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_jadi_teringat_dan_alasan_informal",
        level="N2",
        title="Jadi Teringat, dan Alasan Bernada Informal",
        title_en="That Reminds Me, and a Casual Reason",
        description="Pola そう言えば (ngomong-ngomong, jadi teringat sesuatu terkait topik) dan だって (habisnya~/soalnya~, alasan informal).",
        description_en="The そう言えば pattern (that reminds me, speaking of which) and だって (because~, a casual excuse).",
        # Cleared 2026-08-04. The previous dialogue was matched on
        # 「始めたんだって？」, which is だって in its hearsay-confirmation
        # sense ("I heard you started?"), not the "habisnya/soalnya" excuse
        # sense this chapter's entry defines; そう言えば did not appear at
        # all. A scan of the whole N2 dialogue pool found no occurrence of
        # そう言えば anywhere, so there is no honest replacement — this ships
        # empty and falls back to the bunpou entries' own sentenceExamples.
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_sou_ieba", "bunpou_datte"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_menyimpulkan_dan_pengecualian_kecil",
        level="N2",
        title="Menyimpulkan Sesuatu, dan Pengecualian Kecil",
        title_en="Drawing a Conclusion, and a Small Exception",
        description="Pola ということは (berarti ~, menyimpulkan dari informasi yang diberikan) dan もっとも (meski begitu, menambahkan pengecualian kecil).",
        description_en="The ということは pattern (that means ~, drawing a conclusion) and もっとも (that said, adding a small exception).",
        kotoba_ids=["kotoba_konsep_umum_henji", "kotoba_perabot_rumah_denki"],
        kanji_ids=["kanji_hi4_n3", "kanji_yaku_n3"],
        bunpou_ids=["bunpou_to_iu_koto_wa", "bunpou_mottomo"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_ditambah_lagi",
        level="N2",
        title="Ditambah Lagi Hal yang Tidak Diinginkan",
        title_en="On Top of That",
        description="Pola おまけに (ditambah lagi, apalagi — menambahkan hal buruk/mengejutkan pada apa yang sudah terjadi).",
        description_en="The おまけに pattern (on top of that — adding a bad or surprising extra on top of what already happened).",
        kotoba_ids=["kotoba_pakaian_aksesori_saifu", "kotoba_teknologi_gadget_keitai"],
        kanji_ids=["kanji_zai_n3", "kanji_mei2_n3"],
        bunpou_ids=["bunpou_omake_ni"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_phase2_01",
        level="N2",
        title="Pada Akhirnya Setelah Proses Panjang",
        title_en="At Last After a Long Process",
        description="Pola あげく (pada akhirnya, setelah proses panjang/melelahkan) dan 末に (pada akhirnya, setelah melalui proses).",
        description_en="The あげく pattern (at last, after a long process) and 末に (finally, after going through).",
        kotoba_ids=["kotoba_konsep_umum_saigo", "kotoba_hari_bulan_ashita"],
        kanji_ids=["kanji_sai_n3", "kanji_hi_n2"],
        bunpou_ids=["bunpou_ageku", "bunpou_sue_ni"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_phase2_02",
        level="N2",
        title="ばかり: Terus-menerus/Hanya",
        title_en="ばかり: Continuously/Only",
        description="Pola ばかり2 (melulu/hanya melakukan ~ saja) dan ばかりだ (hanya tinggal semakin ~ saja).",
        description_en="The ばかり2 pattern (keeps only doing ~) and ばかりだ (just keeps getting more ~).",
        kotoba_ids=["kotoba_hobi_aktivitas_katsudou", "kotoba_konsep_umum_joudan"],
        kanji_ids=["kanji_katsu_n3", "kanji_dan_n3"],
        bunpou_ids=["bunpou_bakari2", "bunpou_bakari_da"],
        kaiwa_ids=[],
    ),
    dict(
        # Reworked 2026-08-04: this chapter used to pair ばかりか with
        # ばかりに, but ばかりか moved down to N3 in the So-matome syllabus
        # cross-check, which would have left an N3 pattern inside an N2
        # chapter. Re-themed around "a reason and the result it brings"
        # using two unused N2 entries, so the chapter stays level-pure and
        # still hangs together.
        id="bab_n2_phase2_03",
        level="N2",
        title="Alasan dan Akibat yang Ditimbulkannya",
        title_en="A Reason and the Result It Brings",
        description="Pola ばかりに (hanya gara-gara ~, akibat buruk tak terduga), ものだから (habisnya ~, alasan yang agak membela diri), dan せいか (mungkin karena ~, dugaan penyebab).",
        description_en="The ばかりに pattern (only because of ~, an unexpected bad result), ものだから (because ~, a slightly defensive excuse), and せいか (perhaps because ~, a tentative cause).",
        kotoba_ids=["kotoba_konsep_umum_kangei", "kotoba_bangunan_fasilitas_annai"],
        kanji_ids=["kanji_gei_n3"],
        bunpou_ids=["bunpou_bakari_ni", "bunpou_mono_dakara", "bunpou_sei_ka"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_phase2_04",
        level="N2",
        title="Sama Sekali Tidak ~",
        title_en="Not at All ~",
        description="Pola ちっとも～ない (sama sekali tidak ~, penekanan kuat) dan 全く～ない (sama sekali tidak ~, netral/formal).",
        description_en="The ちっとも～ない pattern (not one bit ~, strong emphasis) and 全く～ない (not at all ~, neutral/formal).",
        kotoba_ids=["kotoba_hari_bulan_ashita"],
        kanji_ids=["kanji_shi_n3", "kanji_tei_n3"],
        bunpou_ids=["bunpou_chittomo_nai", "bunpou_mattaku_nai"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_phase2_05",
        level="N2",
        title="どころ Variants: Tidak Layak/Malah",
        title_en="どころ Variants: Not Suitable/Rather",
        description="Pola どころではない (bukan saatnya untuk ~) dan どころか (jangankan ~, bahkan malah ~).",
        description_en="The どころではない pattern (it's not the time to ~) and どころか (let alone ~, rather the opposite).",
        kotoba_ids=[],
        kanji_ids=["kanji_nou_n3"],
        bunpou_ids=["bunpou_dokoro_dewa_nai", "bunpou_dokoro_ka"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_phase2_06",
        level="N2",
        title="Sementara/Untuk Jaga-jaga",
        title_en="Seems/For Now",
        description="Pola どうやら (sepertinya, kelihatannya berdasarkan tanda) dan 一応 (sementara ini, untuk jaga-jaga).",
        description_en="The どうやら pattern (apparently, it seems) and 一応 (tentatively, for safety's sake).",
        kotoba_ids=["kotoba_hari_bulan_ichiji"],
        kanji_ids=["kanji_kyou_n3", "kanji_ji_n3"],
        bunpou_ids=["bunpou_douyara", "bunpou_ichiou"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_phase2_07",
        level="N2",
        title="Likelihood: Pasrah/Mungkin",
        title_en="Likelihood: Resigned/Might",
        description="Pola どうせ (toh, bagaimanapun juga, nada pasrah) dan かねない (bisa jadi, berpotensi hal negatif).",
        description_en="The どうせ pattern (anyway, resigned tone) and かねない (might, could potentially happen).",
        kotoba_ids=["kotoba_konsep_umum_riyuu"],
        kanji_ids=["kanji_ren_n2"],
        bunpou_ids=["bunpou_douse", "bunpou_kanenai"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_phase2_08",
        level="N2",
        title="から: Justru Karena/Karena Sudah",
        title_en="から: Precisely Because/Since",
        description="Pola からこそ (justru karena ~, penekanan kuat) dan からには (karena sudah ~, maka tentu).",
        description_en="The からこそ pattern (precisely because ~, strong emphasis) and からには (since we already ~, then surely).",
        kotoba_ids=[],
        kanji_ids=["kanji_kou_n3", "kanji_gi_n3"],
        bunpou_ids=["bunpou_kara_koso", "bunpou_kara_niwa"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_phase2_09",
        level="N2",
        title="Kontras: Meski/Malah",
        title_en="Contrast: Despite/Rather",
        description="Pola からと言って (meski begitu, bukan berarti ~) dan かえって (malah, sebaliknya).",
        description_en="The からと言って pattern (despite that, doesn't mean ~) and かえって (rather, on the contrary).",
        kotoba_ids=[],
        kanji_ids=["kanji_han_n3", "kanji_hou_n3"],
        bunpou_ids=["bunpou_kara_to_itte", "bunpou_kaette"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_phase2_10",
        level="N2",
        title="ない Variants: Jika Tidak/Tanpa Perlu",
        title_en="ない Variants: If Not/Without",
        description="Pola ないことには～ない (kalau tidak ~ dulu, maka tidak akan ~) dan なくて済む (tidak perlu ~, cukup tanpa ~).",
        description_en="The ないことには～ない pattern (if not ~ first, then can't ~) and なくて済む (don't need to ~, can get by without).",
        kotoba_ids=["kotoba_konsep_umum_kyouryoku"],
        kanji_ids=["kanji_kyou_n3", "kanji_koku_n3"],
        bunpou_ids=["bunpou_nai_koto_niwa_nai", "bunpou_nakute_sumu"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_phase2_11",
        level="N2",
        title="Tidak Lain Hanyalah/Tidak Lebih Dari",
        title_en="Nothing But/No More Than",
        description="Pola にほかならない (tidak lain adalah ~, penegasan kuat) dan に過ぎない (tidak lebih dari sekadar ~).",
        description_en="The にほかならない pattern (nothing but ~, strong assertion) and に過ぎない (no more than ~).",
        kotoba_ids=["kotoba_bangunan_fasilitas_kaigishitsu"],
        kanji_ids=["kanji_kai_n3", "kanji_shi_n2"],
        bunpou_ids=["bunpou_ni_hoka_naranai", "bunpou_ni_suginai"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_phase2_12",
        level="N2",
        title="かぎり: Bukan Hanya/Paling Baik",
        title_en="かぎり: Not Limited To/Best",
        description="Pola に限らず (bukan hanya terbatas pada ~, tidak hanya) dan に限る (paling baik adalah ~, rekomendasi terbaik).",
        description_en="The に限らず pattern (not just limited to ~) and に限る (the best is ~, top recommendation).",
        kotoba_ids=["kotoba_konsep_umum_ketsudan"],
        kanji_ids=["kanji_you_n3"],
        bunpou_ids=["bunpou_ni_kagirazu", "bunpou_ni_kagiru"],
        kaiwa_ids=[],
    ),
    # ---- N2 phase 3 (2026-08-04): +20 chapters, 51 patterns ----
    #
    # Dataset-internal like phase 2, grouped by shared function: the
    # trigger/turning-point set, formal "in accordance with" markers,
    # regardless-of, viewpoint markers, concessives, "it does not mean
    # that far", norms and prohibitions, and the summarising connectives.
    #
    # Kaiwa: 12 of 20 matched automatically, 4 rejected by hand as
    # substring false positives (「何かきっかけがあったの？」 is the bare noun;
    # 「交換に応じてもらえた」 is the verb 応じる; 「長距離移動に限っては」 is a
    # different sense of 限って; 「大事にすればいい」 is にする + ば). 8 verified
    # links remain.
    dict(
        id="bab_n2_p3_sejak_momen",
        level="N2",
        title="Berawal dari Satu Momen",
        title_en="Starting From One Moment",
        description="Pola がきっかけで / をきっかけに, を契機に（をけいきに） dan て以来（ていらい）.",
        description_en="The がきっかけで / をきっかけに, を契機に（をけいきに） and て以来（ていらい） patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_kikkake_de", "bunpou_o_keiki_ni", "bunpou_te_irai"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_p3_menjelang",
        level="N2",
        title="Menjelang dan Mendahului Peristiwa Penting",
        title_en="On the Eve Of, and Ahead Of",
        description="Pola に際して（にさいして） dan に先立ち（にさきだち）.",
        description_en="The に際して（にさいして） and に先立ち（にさきだち） patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_ni_saishite", "bunpou_ni_sakidachi"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_p3_seiring_luas",
        level="N2",
        title="Seiring Berjalannya dan Sepanjang Rentangnya",
        title_en="Along With, and Across the Whole Span",
        description="Pola に伴って（にともなって） dan にわたって.",
        description_en="The に伴って（にともなって） and にわたって patterns.",
        kotoba_ids=["kotoba_kazoku", "kotoba_hari_bulan_izen"],
        kanji_ids=["kanji_ren_n3", "kanji_tai_n3"],
        bunpou_ids=["bunpou_ni_tomonatte", "bunpou_ni_watatte"],
        kaiwa_ids=["kaiwa_dampak_smartphone_komunikasi_n2"],
    ),
    dict(
        id="bab_n2_p3_sesuai",
        level="N2",
        title="Sesuai dengan Aturan dan Keadaan",
        title_en="In Accordance With Rules and Circumstances",
        description="Pola に応じて（におうじて） dan に沿って（にそって）.",
        description_en="The に応じて（におうじて） and に沿って（にそって） patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_ni_oujite", "bunpou_ni_sotte"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_p3_tanpa_pandang",
        level="N2",
        title="Tanpa Memandang dan Tidak Terbatas Pada",
        title_en="Regardless Of, and Not Limited To",
        description="Pola に関わらず（にかかわらず）, にも関わらず（にもかかわらず） dan を除いて（をのぞいて）.",
        description_en="The に関わらず（にかかわらず）, にも関わらず（にもかかわらず） and を除いて（をのぞいて） patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_ni_kakawarazu", "bunpou_ni_mo_kakawarazu", "bunpou_o_nozoite"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_p3_justru_saat",
        level="N2",
        title="Justru Pada Saat Itu, dan Berkaitan Dengannya",
        title_en="Precisely at That Time, and Bearing On It",
        description="Pola に限って（にかぎって） dan に関わる（にかかわる）.",
        description_en="The に限って（にかぎって） and に関わる（にかかわる） patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_ni_kagitte", "bunpou_ni_kakawaru"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_p3_penegasan_kuat",
        level="N2",
        title="Penegasan yang Tidak Terbantahkan",
        title_en="Assertions That Admit No Doubt",
        description="Pola に相違ない（にそういない） dan でしかない.",
        description_en="The に相違ない（にそういない） and でしかない patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_ni_soui_nai", "bunpou_de_shika_nai"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_p3_sebaiknya",
        level="N2",
        title="Tidak Ada yang Lebih Baik, dan Paling Baik Begitu",
        title_en="Nothing Better Than, and Best Of All",
        description="Pola に越したことはない（にこしたことはない）, よりほかない dan はもとより.",
        description_en="The に越したことはない（にこしたことはない）, よりほかない and はもとより patterns.",
        kotoba_ids=["kotoba_konsep_umum_kachi", "kotoba_konsep_umum_hontou"],
        kanji_ids=["kanji_tou_n3", "kanji_hou_n3"],
        bunpou_ids=["bunpou_ni_koshita_koto_wa_nai", "bunpou_yori_hoka_nai", "bunpou_wa_motoyori"],
        kaiwa_ids=["kaiwa_asuransi_pengiriman_n2"],
    ),
    dict(
        id="bab_n2_p3_ditambah",
        level="N2",
        title="Ditambah Lagi, dan Bukan Hanya Itu",
        title_en="In Addition, and Not Merely That",
        description="Pola に加えて（にくわえて）, のみならず dan しかも.",
        description_en="The に加えて（にくわえて）, のみならず and しかも patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_ni_kuwaete", "bunpou_nomi_narazu", "bunpou_shikamo"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_p3_menolak_halus",
        level="N2",
        title="Menolak dengan Halus, dan Berpotensi Buruk",
        title_en="Declining Gently, and Risking the Worst",
        description="Pola かねる dan 恐れがある（おそれがある）.",
        description_en="The かねる and 恐れがある（おそれがある） patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_kaneru", "bunpou_osore_ga_aru"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_p3_tak_tertahan",
        level="N2",
        title="Tak Tertahankan dan Tak Bisa Tidak",
        title_en="Unbearable, and Impossible Not To",
        description="Pola てならない dan ないではいられない.",
        description_en="The てならない and ないではいられない patterns.",
        kotoba_ids=["kotoba_hari_bulan_saikin", "kotoba_hobi_aktivitas_ryokou"],
        kanji_ids=["kanji_tei_n3", "kanji_sai_n3"],
        bunpou_ids=["bunpou_te_naranai", "bunpou_nai_dewa_irarenai"],
        kaiwa_ids=["kaiwa_tekanan_sosmed_berlibur_n2"],
    ),
    dict(
        id="bab_n2_p3_sudut_pandang",
        level="N2",
        title="Dilihat dari Sudut Pandang Tertentu",
        title_en="Seen From a Particular Standpoint",
        description="Pola から言うと（からいうと）, からすると / からすれば dan にしたら / にすれば.",
        description_en="The から言うと（からいうと）, からすると / からすれば and にしたら / にすれば patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_kara_iu_to", "bunpou_kara_suru_to", "bunpou_ni_shitara_ni_sureba"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_p3_satu_contoh",
        level="N2",
        title="Cukup dari Satu Contoh Saja",
        title_en="Judging From a Single Example",
        description="Pola からして dan ところを見ると.",
        description_en="The からして and ところを見ると patterns.",
        kotoba_ids=["kotoba_bangunan_fasilitas_gakkou", "kotoba_konsep_umum_keikou"],
        kanji_ids=["kanji_shi_n3", "kanji_tou_n3"],
        bunpou_ids=["bunpou_kara_shite", "bunpou_tokoro_o_miru_to"],
        kaiwa_ids=["kaiwa_kesenjangan_pendidikan_kota_desa_n2"],
    ),
    dict(
        id="bab_n2_p3_sekalipun",
        level="N2",
        title="Sekalipun Begitu, Hasilnya Sama",
        title_en="Even So, the Result Is the Same",
        description="Pola にせよ/ にしろ, としても dan にしても～にしても.",
        description_en="The にせよ/ にしろ, としても and にしても～にしても patterns.",
        kotoba_ids=["kotoba_anggota_tubuh_onaka", "kotoba_kendaraan_densha"],
        kanji_ids=["kanji_yuu_n3", "kanji_seki_n3"],
        bunpou_ids=["bunpou_ni_seyo_ni_shiro", "bunpou_to_shitemo", "bunpou_ni_shitemo_ni_shitemo"],
        kaiwa_ids=["kaiwa_etika_di_dalam_kereta_n2"],
    ),
    dict(
        id="bab_n2_p3_bukan_berarti",
        level="N2",
        title="Bukan Berarti Sejauh Itu",
        title_en="It Does Not Mean That Far",
        description="Pola ことにはならない, というものではない dan なくはない / なくもない.",
        description_en="The ことにはならない, というものではない and なくはない / なくもない patterns.",
        kotoba_ids=["kotoba_konsep_umum_rikai", "kotoba_konsep_umum_hontou"],
        kanji_ids=["kanji_tou_n3", "kanji_you_n3"],
        bunpou_ids=["bunpou_koto_niwa_naranai", "bunpou_to_iu_mono_dewa_nai", "bunpou_naku_wa_nai"],
        kaiwa_ids=["kaiwa_tidak_suka_voice_note_n2"],
    ),
    dict(
        id="bab_n2_p3_semestinya",
        level="N2",
        title="Memang Sudah Semestinya Begitu",
        title_en="That Is Only Natural",
        description="Pola も当然だ（もとうぜんだ）, て当然だ dan のももっともだ.",
        description_en="The も当然だ（もとうぜんだ）, て当然だ and のももっともだ patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_mo_touzen_da", "bunpou_te_touzen_da", "bunpou_no_mo_mottomo_da"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_p3_tidak_boleh",
        level="N2",
        title="Larangan dan Norma yang Berlaku",
        title_en="Prohibitions and Social Norms",
        description="Pola てはならない dan ものではない.",
        description_en="The てはならない and ものではない patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_te_wa_naranai", "bunpou_mono_dewa_nai"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_p3_kalau_terus",
        level="N2",
        title="Kalau Terus Begitu, Akibatnya Buruk",
        title_en="If This Keeps Up, It Ends Badly",
        description="Pola ていては, ては / では dan ようでは.",
        description_en="The ていては, ては / では and ようでは patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_te_ite_wa", "bunpou_tewa_dewa", "bunpou_you_dewa"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n2_p3_sampai_rela",
        level="N2",
        title="Sampai Rela Melakukan Sejauh Itu",
        title_en="Going So Far As To",
        description="Pola てまで, てでも dan てこそ.",
        description_en="The てまで, てでも and てこそ patterns.",
        kotoba_ids=["kotoba_angka_satuan_ijou", "kotoba_hobi_aktivitas_ryouri"],
        kanji_ids=["kanji_tai_n3", "kanji_tou_n3"],
        bunpou_ids=["bunpou_te_made", "bunpou_te_demo", "bunpou_te_koso"],
        kaiwa_ids=["kaiwa_restoran_mewah_overpriced_n2"],
    ),
    dict(
        id="bab_n2_p3_merangkum",
        level="N2",
        title="Merangkum dan Menambahkan Keterangan",
        title_en="Summing Up and Adding a Note",
        description="Pola 要するに, ちなみに dan なお.",
        description_en="The 要するに, ちなみに and なお patterns.",
        kotoba_ids=["kotoba_arah_lokasi_houkou", "kotoba_hari_bulan_jizen"],
        kanji_ids=["kanji_tai_n3", "kanji_tou_n3"],
        bunpou_ids=["bunpou_you_suru_ni", "bunpou_chinami_ni", "bunpou_nao"],
        kaiwa_ids=["kaiwa_sering_tersesat_meski_gps_n2"],
    ),
]

# N1 chapters, first pass (2026-08-04). Continues the global `order`
# sequence from N2's 109 (order=110..129) — see the N4 comment above for
# why `order` is global across levels rather than per-level.
#
# Sequenced against 『日本語総まとめ N1 文法』(Nihongo So-matome N1 Bunpo,
# 155-page scan supplied by the user). Like the N2 ebook, it is organised
# 第N週 (week) x N日目 (day): 8 weeks x 6 grammar days = 48 grammar points,
# with day 7 of each week being a practice test rather than new grammar.
# Only the *teaching sequence* was taken from the book — i.e. the factual
# list of which grammar point is introduced on which week/day. No example
# sentence, explanation, or exercise from the book was copied; every
# entry's teaching content comes from this project's own already-authored
# `bunpou_data.json`. Same discipline used for the N3 (Speed Master) and
# N2 (learn-and-practice ebook) passes above.
#
# 6 of the book's 48 points are already tagged at an earlier level in this
# project's dataset and were therefore skipped here rather than pulled
# into an N1 chapter (same "don't force it" / level-purity rule the N4
# comment documents): ことだから (W1D3) and ようか～まいか (W2D3) are N2;
# そうもない (W5D2), つもりで (W6D2) and ながらも (W6D3) are N3;
# に越したことはない (W8D3) is N2. So-matome re-teaches them at N1 as
# revision, which is a textbook choice, not a re-levelling of the pattern.
#
# 5 further N1 patterns were added from the *week titles* themselves,
# which in this book are themed sentences that each demonstrate one more
# grammar point beyond the six day-titles: までもなく (W3), なくして (W4),
# ずにはすまない (W5), にも増して (W6), に～を重ねて (W7). W1's てこそ is
# N2-tagged and W8's はどうあれ has no dataset entry, so neither was used.
#
# 42 day-title + 5 week-title = 47 N1-tagged patterns, grouped 2-3 per
# chapter *within* each book week so a chapter never straddles two weeks
# of the source sequence. That yields 20 chapters with no orphan
# single-pattern chapter (pairing 2-by-2 would have left 6 of them).
#
# kaiwa_ids were resolved by scanning all 255 N1 dialogues for one whose
# text literally contains one of the chapter's patterns, then picking
# kotoba/kanji whose word/character literally appears in that same
# dialogue — the literal-overlap discipline documented for N4/N3/N2.
# Only 11 of 20 chapters found a match: N1 grammar is heavily formal and
# written (べからず, いかんにかかわらず, を前提として), while the kaiwa pool is
# conversational, so most of these patterns genuinely never occur there.
# The other 9 ship with kaiwa_ids=[] deliberately — the detail screen
# falls back to the bunpou entry's own sentenceExamples, same as the 7
# N2 chapters in the same situation. Two kaiwa ids repeat across
# chapters (kaiwa_beban_ekspektasi_nama_gelar_n1 on 114/123,
# kaiwa_bangun_ulang_diri_setelah_kehilangan_n1 on 117/129) because no
# second dialogue matched those patterns at all; N3 already has the same
# repeat (kaiwa_jadi_wali_adik_n3 on orders 68 and 75).
#
# This covers So-matome's full 8-week N1 grammar syllabus but only 47 of
# the project's 253 N1 bunpou patterns — the remaining 206 are a later
# expansion pass, the same shape as N2's 16 -> 28 phase 2.
N1_CHAPTERS = [
    dict(
        id="bab_n1_w1_a",
        level="N1",
        title="Justru Menegaskan, dan Dengan Anggapan Tertentu",
        title_en="Emphatic Affirmation, and On the Premise That",
        description="Pola こそすれ dan ものとして.",
        description_en="The こそすれ and ものとして patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_koso_sure", "bunpou_mono_to_shite"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_w1_b",
        level="N1",
        title="Menurut Saya, Melihat Tanda, dan Sekalipun Sudah",
        title_en="In My View, Judging by Signs, and Even If Done",
        description="Pola に言わせれば（にいわせれば）, とみると, dan たところで.",
        description_en="The に言わせれば（にいわせれば）, とみると, and たところで patterns.",
        kotoba_ids=["kotoba_jikan", "kotoba_angka_satuan_ijou"],
        kanji_ids=["kanji_hei2_n2", "kanji_kai3_n2"],
        bunpou_ids=["bunpou_ni_iwasereba", "bunpou_to_miru_to", "bunpou_ta_tokoro_de"],
        kaiwa_ids=["kaiwa_jati_diri_sulit_dijawab_n1"],
    ),
    dict(
        id="bab_n1_w2_a",
        level="N1",
        title="Sesuai Kemampuan Sendiri, dan Terlepas Apa Pun",
        title_en="In One's Own Way, and No Matter What",
        description="Pola なりに / なりの dan ようが / ようと.",
        description_en="The なりに / なりの and ようが / ようと patterns.",
        kotoba_ids=["kotoba_jikan", "kotoba_hari_bulan_jikan"],
        kanji_ids=["kanji_gan_n2", "kanji_nou3_n2"],
        bunpou_ids=["bunpou_nari_ni", "bunpou_you_ga"],
        kaiwa_ids=["kaiwa_berdamai_versi_diri_masa_lalu_n1"],
    ),
    dict(
        id="bab_n1_w2_b",
        level="N1",
        title="Menyebut Beberapa Aspek, Bergantian, dan Ketidakpastian",
        title_en="Listing Aspects, Alternating, and Uncertainty",
        description="Pola といい～といい, つ～つ, dan のやら / ものやら / ことやら.",
        description_en="The といい～といい, つ～つ, and のやら / ものやら / ことやら patterns.",
        # kaiwa/kotoba/kanji cleared 2026-08-04: the original match was a
        # false positive (「思い出せるといいね」 is と + いい, not the
        # といい～といい listing pattern). See the phase-2 comment below.
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_to_ii_to_ii", "bunpou_tsu_tsu", "bunpou_no_yara"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_w3_a",
        level="N1",
        title="Meski Tidak Sampai, dan Sebagai Batas Akhir",
        title_en="Even If Not Fully, and As the Final Limit",
        description="Pola ないまでも dan を限りに（をかぎりに）.",
        description_en="The ないまでも and を限りに（をかぎりに） patterns.",
        kotoba_ids=["kotoba_keluarga_hubungan_chounan", "kotoba_konsep_umum_kitai"],
        kanji_ids=["kanji_i3_n2", "kanji_kan6_n2"],
        bunpou_ids=["bunpou_nai_mademo", "bunpou_o_kagiri_ni"],
        kaiwa_ids=["kaiwa_beban_ekspektasi_nama_gelar_n1"],
    ),
    dict(
        id="bab_n1_w3_b",
        level="N1",
        title="Konsesi Formal, dan Dengan Cara Resmi",
        title_en="Formal Concession, and By Formal Means",
        description="Pola といえども dan をもって / をもちまして.",
        description_en="The といえども and をもって / をもちまして patterns.",
        kotoba_ids=["kotoba_arah_lokasi_keshiki", "kotoba_hari_bulan_jiki"],
        kanji_ids=["kanji_jun2_n2", "kanji_zou3_n2"],
        bunpou_ids=["bunpou_to_iedomo", "bunpou_o_motte"],
        kaiwa_ids=["kaiwa_filosofi_hidup_lewat_penderitaan_n1"],
    ),
    dict(
        id="bab_n1_w3_c",
        level="N1",
        title="Dugaan Meleset, Sekalian, dan Tak Perlu Dikatakan",
        title_en="A Wrong Guess, While At It, and Needless to Say",
        description="Pola かと思いきや（かとおもいきや）, がてら, dan までもない / までもなく.",
        description_en="The かと思いきや（かとおもいきや）, がてら, and までもない / までもなく patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_ka_to_omoikiya", "bunpou_gatera", "bunpou_made_mo_nai"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_w4_a",
        level="N1",
        title="Penyesalan Padahal Seharusnya, dan Bahkan Pun",
        title_en="Regret Over What Should Have Been, and Even",
        description="Pola ものを dan すら / ですら.",
        description_en="The ものを and すら / ですら patterns.",
        # Cleared 2026-08-04: 「大きなものを失った」 is the object particle を
        # after もの, not the ものを regret pattern. False positive.
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_mono_o", "bunpou_sura"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_w4_b",
        level="N1",
        title="Mencakup Seluruhnya, dan Dalam Situasi Khusus",
        title_en="Encompassing All, and In a Particular Situation",
        description="Pola ぐるみ dan にあって.",
        description_en="The ぐるみ and にあって patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_gurumi", "bunpou_ni_atte"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_w4_c",
        level="N1",
        title="Keunikan Khas, Harapan Kuat, dan Prasyarat Mutlak",
        title_en="Distinctive Uniqueness, Strong Hope, and an Essential Prerequisite",
        description="Pola ならでは, ないものか / ないものだろうか, dan なくしては.",
        description_en="The ならでは, ないものか / ないものだろうか, and なくしては patterns.",
        kotoba_ids=["kotoba_konsep_umum_eikyou", "kotoba_konsep_umum_hyougen"],
        kanji_ids=["kanji_shou4_n2", "kanji_ko_n2"],
        bunpou_ids=["bunpou_naradewa", "bunpou_nai_mono_ka", "bunpou_nakushite_wa"],
        kaiwa_ids=["kaiwa_peran_bahasa_bentuk_pikiran_n1"],
    ),
    dict(
        id="bab_n1_w5_a",
        level="N1",
        title="Tidak Cukup Hanya Dengan, dan Perumpamaan Klasik",
        title_en="Not Settled by That Alone, and a Classical Simile",
        description="Pola では済まない（ではすまない） dan ごとき / ごとく / ごとし.",
        description_en="The では済まない（ではすまない） and ごとき / ごとく / ごとし patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_dewa_sumanai", "bunpou_gotoki"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_w5_b",
        level="N1",
        title="Tanpa Memandang Bagaimanapun, dan Tidak Bergantung Pada",
        title_en="Regardless of How, and Not Depending On",
        description="Pola いかんにかかわらず / いかんによらず / いかんをとわず dan によらず.",
        description_en="The いかんにかかわらず / いかんによらず / いかんをとわず and によらず patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_ikan_ni_kakawarazu", "bunpou_ni_yorazu"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_w5_c",
        level="N1",
        title="Larangan Tegas, dan Kewajiban Tak Terhindarkan",
        title_en="A Firm Prohibition, and an Unavoidable Obligation",
        description="Pola べからず / べからざる dan ずには済まない / ないでは済まない.",
        description_en="The べからず / べからざる and ずには済まない / ないでは済まない patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_bekarazu", "bunpou_zu_niwa_sumanai"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_w6_a",
        level="N1",
        title="Sesuai Kondisi Nyata, dan Sebab Formal",
        title_en="In Line With Reality, and a Formal Cause",
        description="Pola に即して（にそくして） dan ゆえに.",
        description_en="The に即して（にそくして） and ゆえに patterns.",
        kotoba_ids=["kotoba_keluarga_hubungan_chounan", "kotoba_konsep_umum_kitai"],
        kanji_ids=["kanji_i3_n2", "kanji_kan6_n2"],
        bunpou_ids=["bunpou_ni_sokushite", "bunpou_yue_ni"],
        kaiwa_ids=["kaiwa_beban_ekspektasi_nama_gelar_n1"],
    ),
    dict(
        id="bab_n1_w6_b",
        level="N1",
        title="Dua Tujuan Sekaligus, Berlandaskan Premis, dan Melebihi",
        title_en="Two Aims at Once, On a Premise, and Surpassing",
        description="Pola を兼ねて（をかねて）, を前提として（をぜんていとして）, dan にも増して（にもまして）.",
        description_en="The を兼ねて（をかねて）, を前提として（をぜんていとして）, and にも増して（にもまして） patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_o_kanete", "bunpou_o_zentei_to_shite", "bunpou_ni_mo_mashite"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_w7_a",
        level="N1",
        title="Penekanan Lewat Pengulangan, dan Bahkan Sekadar",
        title_en="Emphasis by Repetition, and Not Even",
        description="Pola に (pengulangan kata kerja yang sama) dan だに / だにしない.",
        description_en="The に pattern (repeating the same verb) and だに / だにしない.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_ni2", "bunpou_dani"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_w7_b",
        level="N1",
        title="Cara dan Gaya, dan Tidak Tahan Untuk",
        title_en="Manner and Style, and Unbearable To",
        description="Pola ぶり / っぷり dan に耐える / に耐えない（にたえる / にたえない）.",
        description_en="The ぶり / っぷり and に耐える / に耐えない（にたえる / にたえない） patterns.",
        # Cleared 2026-08-04: 「絶対に耐えられない」 — the に belongs to 絶対に,
        # not to the に耐える pattern. False positive.
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_buri_ppuri", "bunpou_ni_taeru"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_w7_c",
        level="N1",
        title="Sama Sekali Bukan, Tidak Perlu Sampai, dan Usaha Berulang",
        title_en="Not At All, No Need To, and Repeated Effort",
        description="Pola でも何でもない / くも何ともない, には及ばない（にはおよばない）, dan に～を重ねて（に～をかさねて）.",
        description_en="The でも何でもない / くも何ともない, には及ばない（にはおよばない）, and に～を重ねて（に～をかさねて） patterns.",
        # Cleared 2026-08-04: 「親切を重ねてこそ」 has を重ねて but not the
        # に～を重ねて frame the pattern actually needs. Too weak to keep.
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_demo_nandemo_nai", "bunpou_niwa_oyobanai", "bunpou_ni_o_kasanete"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_w8_a",
        level="N1",
        title="Kalau Itu Lain Cerita, dan Harapan Tak Henti",
        title_en="That Would Be Another Story, and Unceasing Wishes",
        description="Pola ならいざしらず / はいざしらず dan てやまない.",
        description_en="The ならいざしらず / はいざしらず and てやまない patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_nara_iza_shirazu", "bunpou_te_yamanai"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_w8_b",
        level="N1",
        title="Terpaksa Keadaan, Perasaan Mendalam, dan Menyangkal Premis",
        title_en="Forced by Circumstance, Deep Feeling, and Denying a Premise",
        description="Pola を余儀なくされる（をよぎなくされる）, の至り（のいたり）, dan ではあるまいし.",
        description_en="The を余儀なくされる（をよぎなくされる）, の至り（のいたり）, and ではあるまいし patterns.",
        kotoba_ids=["kotoba_arah_lokasi_keshiki", "kotoba_hari_bulan_izen"],
        kanji_ids=["kanji_ka_n1", "kanji_gi2_n1"],
        bunpou_ids=["bunpou_o_yogi_naku_sareru", "bunpou_no_itari", "bunpou_dewa_arumaishi"],
        kaiwa_ids=["kaiwa_bangun_ulang_diri_setelah_kehilangan_n1"],
    ),

    # ---- N1 phase 2 (2026-08-04): orders 130-154 ----
    #
    # So-matome's 8-week syllabus is fully consumed by phase 1 above, so
    # this batch has **no external reference at all** — patterns are drawn
    # from the project's own remaining N1 pool and grouped by shared
    # grammatical function, the same dataset-internal method used for N2's
    # 16 -> 28 expansion. 67 patterns across 25 chapters, 2-3 per chapter,
    # every group a genuine functional family (べく trio, the "the moment X
    # happens" trio, the four に至る forms split across two chapters by
    # sense, the "worth it" vs "not worth making a fuss over" pair of
    # chapters, and so on) rather than an arbitrary slice of the list.
    #
    # **A false-positive class was found and fixed while building this.**
    # The cross-content matcher used by the N4/N3/N2/N1-phase-1 passes
    # tested `pattern_surface in dialogue_text`, which is unsafe for
    # Japanese: many N1 grammar surfaces are also substrings of ordinary
    # conjugations. On this batch's first run, 4 of 8 "matches" were
    # spurious — 選びたかった matched びた, ただの matched だの, 便利であれば
    # matched であれ, and 言いようがない (an N3 pattern!) matched ようが.
    # The matcher now (a) refuses needles shorter than 3 characters unless
    # they carry an explicit guard rule, (b) supports forbidden
    # preceding/following characters per needle, and (c) prints the
    # surrounding text of every surviving match so it can be eyeballed
    # before being committed. All 4 matches kept below were verified that
    # way: 「そこに至るまでの過程」, 「あの辛い時期を経て」, 「便利さをよそに」,
    # 「忘れようにも忘れられなかった」.
    #
    # Re-auditing phase 1 (orders 110-129) with the same context check
    # found 4 of its 11 matches were spurious too, and those were cleared
    # in place above — see the inline comments on orders 113, 117, 126 and
    # 127. Phase 1's real hit rate was therefore 7/20, not 11/20.
    #
    # Only 4 of these 25 chapters found a kaiwa match. That is expected
    # and not a defect: this batch is deliberately the most literary and
    # formal end of N1 (べからず-adjacent registers, 羽目になる, をものともせず,
    # の極み), which conversational dialogue simply does not contain. Nine
    # chapters here search nothing at all because no needle for their
    # patterns can be made unambiguous — びる/ぶる/めく are the clearest
    # case, being one- and two-kana verb suffixes. Those ship
    # `kaiwa_ids=[]` deliberately and the detail screen falls back to each
    # bunpou entry's own sentenceExamples.
    #
    # Running total after this batch: 45 N1 chapters, 114 of 253 N1
    # patterns. 139 patterns remain for a later phase 3.
    dict(
        id="bab_n1_p2_beku",
        level="N1",
        title="Tujuan dan Kemustahilan Bergaya Formal",
        title_en="Formal Purpose and Impossibility",
        description="Pola べく, べくもない, dan べくして.",
        description_en="The べく, べくもない, and べくして patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_beku", "bunpou_beku_mo_nai", "bunpou_bekushite"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_p2_kesan_luar",
        level="N1",
        title="Terlihat Seperti: びる, ぶる, めく",
        title_en="Looking the Part: biru, buru, meku",
        description="Pola びる / びて / びた, ぶる / ぶって / ぶった, dan めく.",
        description_en="The びる / びて / びた, ぶる / ぶって / ぶった, and めく patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_biru", "bunpou_buru", "bunpou_meku"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_p2_kesan_negatif",
        level="N1",
        title="Kesan Negatif dari Luar: じみた dan がましい",
        title_en="Negative Impressions: jimita and gamashii",
        description="Pola じみた dan がましい.",
        description_en="The じみた and がましい patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_jimita", "bunpou_gamashii"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_p2_begitu_langsung",
        level="N1",
        title="Begitu Terjadi, Langsung Saja",
        title_en="The Moment It Happens",
        description="Pola が早いか（がはやいか）, や否や（やいなや）, dan なり.",
        description_en="The が早いか（がはやいか）, や否や（やいなや）, and なり patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_ga_hayai_ka", "bunpou_ya_ina_ya", "bunpou_nari"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_p2_reaksi_cepat",
        level="N1",
        title="Reaksi Seketika Setelah Melihat",
        title_en="Reacting Instantly on Sight",
        description="Pola そばから dan と見るや（とみるや）.",
        description_en="The そばから and と見るや（とみるや） patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_soba_kara", "bunpou_to_miru_ya"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_p2_menyebut_keluhan",
        level="N1",
        title="Menyebutkan Beberapa Hal dengan Nada Mengeluh",
        title_en="Listing Things With a Complaint",
        description="Pola だの～だの, なり～なり, dan やれ～やれ.",
        description_en="The だの～だの, なり～なり, and やれ～やれ patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_dano_dano", "bunpou_nari_nari", "bunpou_yare_yare"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_p2_menyebut_semua",
        level="N1",
        title="Menyebutkan Semuanya Tanpa Kecuali",
        title_en="Listing Everything Without Exception",
        description="Pola といわず～といわず, わ〜わで, dan わ.",
        description_en="The といわず～といわず, わ〜わで, and わ patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_to_iwazu_to_iwazu", "bunpou_wa_wa_de", "bunpou_wa2"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_p2_de_are",
        level="N1",
        title="Apa Pun Itu: であれ",
        title_en="Whatever It May Be: de are",
        description="Pola であれ / であろうと dan であれ～であれ.",
        description_en="The であれ / であろうと and であれ～であれ patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_de_are", "bunpou_de_are_de_are"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_p2_apapun_jenisnya",
        level="N1",
        title="Apa Pun Jenisnya, dan Bagaimanapun Juga",
        title_en="Whatever the Kind, and In Any Case",
        description="Pola いかなる dan いずれにしても / いずれにしろ / いずれにせよ.",
        description_en="The いかなる and いずれにしても / いずれにしろ / いずれにせよ patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_ikanaru", "bunpou_izure_ni_shitemo"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_p2_terlepas_pilihan",
        level="N1",
        title="Terlepas dari Pilihan Apa Pun",
        title_en="Regardless of the Choice",
        description="Pola ようが～ようが / ようと～ようと, ようと～まいと / ようが～まいが, dan はどうであれ.",
        description_en="The ようが～ようが / ようと～ようと, ようと～まいと / ようが～まいが, and はどうであれ patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_you_ga_you_ga", "bunpou_you_to_mai_to", "bunpou_wa_dou_de_are"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_p2_puncak_tingkat",
        level="N1",
        title="Mencapai Puncak Tingkatan",
        title_en="Reaching the Utmost Degree",
        description="Pola 極まる / 極まりない（きわまる / きわまりない）, の極み（のきわみ）, dan この上ない（このうえない）.",
        description_en="The 極まる / 極まりない, の極み, and この上ない patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_kiwamaru", "bunpou_no_kiwami", "bunpou_kono_ue_nai"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_p2_luar_biasa_emosi",
        level="N1",
        title="Ungkapan Emosi yang Luar Biasa Kuat",
        title_en="Expressing Overwhelming Emotion",
        description="Pola 限りだ（かぎりだ）, といったらない, dan のなんのって.",
        description_en="The 限りだ（かぎりだ）, といったらない, and のなんのって patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_kagiri_da", "bunpou_to_ittara_nai", "bunpou_no_nan_no_tte"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_p2_sampai_mencapai",
        level="N1",
        title="Sampai Mencapai, dan Sampai ke Detail Terkecil",
        title_en="Culminating In, and Down to the Last Detail",
        description="Pola に至る / に至った（にいたる / にいたった） dan に至るまで（にいたるまで）.",
        description_en="The に至る / に至った and に至るまで patterns.",
        kotoba_ids=["kotoba_angka_satuan_ijou", "kotoba_konsep_umum_kekka"],
        kanji_ids=["kanji_ketsu_n2", "kanji_hi_n2"],
        bunpou_ids=["bunpou_ni_itaru", "bunpou_ni_itaru_made"],
        kaiwa_ids=["kaiwa_kesenjangan_pencapaian_puas_batin_n1"],
    ),
    dict(
        id="bab_n1_p2_bahkan_sampai",
        level="N1",
        title="Bahkan Sampai Tahap Itu Pun",
        title_en="Even at That Stage",
        description="Pola に至っても（にいたっても） dan に至っては（にいたっては）.",
        description_en="The に至っても and に至っては patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_ni_itattemo", "bunpou_ni_itatte_wa"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_p2_layak_pantas",
        level="N1",
        title="Layak dan Pantas Mendapatkan",
        title_en="Worthy and Deserving",
        description="Pola に値する（にあたいする）, に足る（にたる）, dan に足らない（にたらない）.",
        description_en="The に値する, に足る, and に足らない patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_ni_atai_suru", "bunpou_ni_taru", "bunpou_ni_taranai"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_p2_tak_perlu_dibesarkan",
        level="N1",
        title="Tidak Perlu Dibesar-besarkan",
        title_en="Not Worth Making a Fuss Over",
        description="Pola には当たらない（にはあたらない）, ほどのことではない, dan うちに入らない（うちにはいらない）.",
        description_en="The には当たらない, ほどのことではない, and うちに入らない patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=[
            "bunpou_niwa_ataranai",
            "bunpou_hodo_no_koto_dewa_nai",
            "bunpou_uchi_ni_hairanai",
        ],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_p2_titik_balik",
        level="N1",
        title="Titik Awal dan Titik Balik",
        title_en="Starting Points and Turning Points",
        description="Pola を皮切りに（をかわきりに）, を機に（をきに）, dan を境に（をさかいに）.",
        description_en="The を皮切りに, を機に, and を境に patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_o_kawakiri_ni", "bunpou_o_ki_ni", "bunpou_o_sakai_ni"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_p2_melalui_menjelang",
        level="N1",
        title="Melalui Proses, dan Menjelang Peristiwa",
        title_en="Through a Process, and On the Eve Of",
        description="Pola を経て（をへて） dan を控えて（をひかえて）.",
        description_en="The を経て and を控えて patterns.",
        kotoba_ids=["kotoba_arah_lokasi_keshiki", "kotoba_hari_bulan_jiki"],
        kanji_ids=["kanji_jun2_n2", "kanji_zou3_n2"],
        bunpou_ids=["bunpou_o_hete", "bunpou_o_hikaete"],
        kaiwa_ids=["kaiwa_filosofi_hidup_lewat_penderitaan_n1"],
    ),
    dict(
        id="bab_n1_p2_tanpa_peduli",
        level="N1",
        title="Tanpa Memedulikan Rintangan",
        title_en="Undeterred by Obstacles",
        description="Pola をよそに, を顧みず（をかえりみず）, dan をものともせずに.",
        description_en="The をよそに, を顧みず, and をものともせずに patterns.",
        kotoba_ids=["kotoba_angka_satuan_ijou", "kotoba_hari_bulan_izen"],
        kanji_ids=["kanji_kyou2_n2", "kanji_shuu2_n2"],
        bunpou_ids=["bunpou_o_yoso_ni", "bunpou_o_kaerimizu", "bunpou_o_mono_tomo_sezu_ni"],
        kaiwa_ids=["kaiwa_dilema_etis_pilihan_makanan_n1"],
    ),
    dict(
        id="bab_n1_p2_menerobos",
        level="N1",
        title="Menerobos Halangan, dan Mengabaikan Sepenuhnya",
        title_en="Pushing Through, and Setting Aside Entirely",
        description="Pola を押して / を押し切って（をおして / をおしきって） dan はそっちのけで / をそっちのけで.",
        description_en="The を押して / を押し切って and はそっちのけで / をそっちのけで patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_o_oshite", "bunpou_wa_socchinoke_de"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_p2_berdalih",
        level="N1",
        title="Berdalih dan Menyalahgunakan Alasan",
        title_en="Using a Pretext and Abusing an Excuse",
        description="Pola をいいことに, にかこつけて, dan にかまけて.",
        description_en="The をいいことに, にかこつけて, and にかまけて patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_o_ii_koto_ni", "bunpou_ni_kakotsukete", "bunpou_ni_kamakete"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_p2_berlandaskan",
        level="N1",
        title="Berlandaskan Aturan dan Pertimbangan",
        title_en="Grounded in Rules and Considerations",
        description="Pola を踏まえて（をふまえて）, に則って（にのっとって）, dan に照らして（にてらして）.",
        description_en="The を踏まえて, に則って, and に照らして patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_o_fumaete", "bunpou_ni_nottotte", "bunpou_ni_terashite"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_p2_akhir_buruk",
        level="N1",
        title="Berakhir dengan Keadaan Buruk",
        title_en="Ending Up in a Bad State",
        description="Pola 羽目になる（はめになる）, 始末だ（しまつだ）, dan たら最後（たらさいご）.",
        description_en="The 羽目になる, 始末だ, and たら最後 patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_hame_ni_naru", "bunpou_shimatsu_da", "bunpou_tara_saigo"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_p2_kesempatan_hilang",
        level="N1",
        title="Kesempatan yang Terlewat Begitu Saja",
        title_en="Opportunities Missed Entirely",
        description="Pola そびれる, 損なう / 損ねる（そこなう / そこねる）, dan ずじまい.",
        description_en="The そびれる, 損なう / 損ねる, and ずじまい patterns.",
        kotoba_ids=[],
        kanji_ids=[],
        bunpou_ids=["bunpou_sobireru", "bunpou_sokonau", "bunpou_zu_jimai"],
        kaiwa_ids=[],
    ),
    dict(
        id="bab_n1_p2_tak_ada_cara",
        level="N1",
        title="Tidak Ada Cara Sama Sekali",
        title_en="No Way Out At All",
        description="Pola 術がない（すべがない）, どうにも～ない, dan ようにも～ない.",
        description_en="The 術がない, どうにも～ない, and ようにも～ない patterns.",
        kotoba_ids=["kotoba_hari_bulan_kako", "kotoba_hobi_aktivitas_eiga"],
        kanji_ids=["kanji_shi7_n2", "kanji_kyou_n1"],
        bunpou_ids=["bunpou_sube_ga_nai", "bunpou_dou_nimo_nai", "bunpou_you_ni_mo_nai"],
        kaiwa_ids=["kaiwa_belajar_maafkan_diri_lewat_film_n1"],
    ),
]
