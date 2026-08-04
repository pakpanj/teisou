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
        order=1,
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
        order=2,
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
        order=3,
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
        order=4,
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
        order=5,
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
        order=6,
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
        order=7,
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
        order=8,
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
        order=9,
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
        order=10,
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
        order=11,
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
        order=12,
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
        order=13,
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
        order=14,
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
        order=15,
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
        order=16,
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
        order=17,
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
        order=18,
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
        order=19,
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
        order=20,
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
        order=21,
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
        order=22,
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
        order=23,
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
        order=24,
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
        order=25,
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
        order=26,
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
        order=27,
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
        order=28,
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
        order=29,
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
        order=30,
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
        order=31,
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
        order=32,
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
        order=33,
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
        order=34,
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
        order=35,
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
        order=36,
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
        order=37,
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
        order=38,
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
        order=39,
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
        order=40,
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
        order=41,
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
        order=42,
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
        order=43,
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
        order=44,
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
        order=45,
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
        order=46,
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
        order=47,
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
        order=48,
        level="N4",
        title="Kabar Dengar dan Dugaan",
        title_en="Hearsay and Inference",
        description="Pola そうだ（伝聞） untuk mengutip kabar dari sumber lain, dan ようだ untuk dugaan berdasar bukti.",
        description_en="The そうだ（伝聞） pattern for quoting news from another source, and ようだ for an evidence-based guess.",
        kotoba_ids=["kotoba_cuaca_hare", "kotoba_hari_bulan_saikin"],
        kanji_ids=["kanji_asa", "kanji_oriru"],
        bunpou_ids=["bunpou_souda_denbun", "bunpou_you_da"],
        kaiwa_ids=["kaiwa_keluh_cuaca_tidak_menentu_n4"],
    ),
    dict(
        id="bab_n4_bentuk_kausatif",
        order=49,
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
        order=50,
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
        order=51,
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
        order=52,
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
        order=53,
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
        order=54,
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
        order=55,
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
        order=56,
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
        order=57,
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
        order=58,
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
        order=59,
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
        order=60,
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
        order=61,
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
        order=62,
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
        order=63,
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
        order=64,
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
        order=65,
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
        order=66,
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
        order=67,
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
        order=68,
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
        order=69,
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
        order=70,
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
        order=71,
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
        order=72,
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
        order=73,
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
        order=74,
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
        order=75,
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
        order=76,
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
        order=77,
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
        order=78,
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
        order=79,
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
        order=80,
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
        order=81,
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
]
