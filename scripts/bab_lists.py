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
# 25 proof-of-concept N5 chapters so far, hand-picked from content already
# authored in past sessions — not the full curriculum. Expanding to more N5
# chapters and then N4-N1 is future-session work, same "batch 1 of many"
# shape as this project's other content rollouts (Dokkai, Dictionary).
#
# REORDER PASS (2026-08-03), grammar-difficulty tiers sourced from the real
# Minna no Nihongo Shokyuu I book (359-page scan, "Minna nihongo 1.pdf" in
# the user's Downloads folder — read directly, page by page, structure only,
# nothing reproduced) plus general SLA sequencing guidance (sentence
# structure -> particles -> basic verb/adjective forms -> compound patterns;
# vocab+grammar learned together, not vocab-first). The user asked for this
# explicitly: 70% weight on Minna's own lesson order, 30% on outside
# references, used only to confirm Minna's order is sound, not to override
# it. Every one of Minna's 25 real lessons was identified from the scan:
# L1 copula (da/desu, wa, mo, no, san) -> L2 demonstratives (kore/sore/are)
# -> L3 location words (koko/soko/asoko) -> L4 time (nan-ji, kara/made) ->
# L5 dates (itsu) -> L6 counters/age -> L7 agemasu/moraimasu -> L8
# adjectives (i/na + totemo/amari) -> L9 wakarimasu + jouzu/heta -> L10
# arimasu/imasu + ue/shita -> L11 counting -> L12 comparison -> L13 purpose
# of movement -> L14 -te + -te kudasai -> L15 -te imasu -> L16-19 more -te
# patterns -> L20-25 plain/casual form and beyond (N4-adjacent, out of this
# app's current N5 Bab scope).
#
# This pass ONLY reordered the 25 existing chapters (changed `order`, moved
# dict blocks to match, fixed two description strings that referenced
# relative position) — it did NOT author any new grammar content. Real
# content gaps surfaced by comparing against Minna's actual lesson list
# (demonstratives kore/sore/are, location words koko/soko/asoko, the -nai
# negative form, agemasu/moraimasu, comparison, full counters) are NOT
# fixed here — none of those grammar points exist in bunpou_data.json yet,
# so no existing chapter could be pointed at them. That's real, larger,
# future work (new Bunpou entries first, then new Bab chapters) — noted
# here so it isn't lost, not attempted in this pass.
#
# Each of the 25 chapters below was assigned a tier by its OWN hardest
# bunpou_ids entry (not its easiest), matched to the closest real Minna
# lesson number above, then ordered within each tier by theme proximity to
# neighboring chapters:
#   tier L1  (copula)              -> menyapa, pekerjaan, negara_dan_asal,
#                                      ulang_tahun_dan_umur
#   tier L10 (arimasu/imasu)       -> keluarga, hewan_peliharaan, di_rumah,
#                                      di_rumah_sakit
#   tier L8  (totemo, standalone)  -> cuaca_dan_basa_basi
#   tier L4  (kara/made/ni_e/de)   -> menanyakan_arah, stasiun_dan_
#                                      transportasi, hari_dan_jadwal,
#                                      rencana_liburan
#   tier L8+ (donna/no_ga_suki)    -> olahraga, warna, musim, bioskop
#   tier ~L13 (o_kudasai/ga_hoshii)-> belanja, di_restoran, angka_dan_uang,
#                                      buah_dan_sayuran
#   tier L14  (-te / -te kudasai)  -> bentuk_te_dan_minta_tolong,
#                                      di_sekolah, telepon
#   tier L15  (-te imasu)          -> kegiatan_sehari_hari (last: needs the
#                                      -te form chapter above it, same as
#                                      before this pass, just now much
#                                      later overall since -te forms are
#                                      genuinely one of the more advanced
#                                      structures in the beginner tier, not
#                                      an early one — the original order had
#                                      this cluster at position 3, far too
#                                      early relative to existence/time/
#                                      particle chapters that a real
#                                      beginner course covers first)
#
# Chapter order is still a deliberate teaching sequence, not just a list
# order — "bab_bentuk_te_dan_minta_tolong" exists specifically to teach -te
# form conjugation *before* "bab_di_sekolah", which already uses the
# ~てください pattern without ever explaining how to build a -te form (that
# dependency survived the reorder unchanged: the two chapters are still
# consecutive). If a future chapter needs a grammar/vocab prerequisite that
# doesn't exist yet, add the prerequisite as its own chapter earlier in the
# sequence rather than assuming the learner already knows it.
#
# Known deferred gap, NOT fixed yet (deliberately, per explicit user
# request to keep making Bab progress before reorganizing Bunpou): several
# real N5 Bunpou patterns (bunpou_masen_ka, bunpou_mashou, bunpou_mashou_ka,
# bunpou_ni_iku, bunpou_tai, bunpou_kata) require deriving a verb's ~masu
# stem, and — same as the -te form gap chapter fixed — nothing in this
# dataset teaches ~masu-form conjugation either. None of the 25 chapters
# use these patterns for exactly that reason. Before authoring a future
# chapter that needs any of them (very likely for invitation/politeness-
# themed chapters — "Mengajak" is a natural future target), either add a
# ~masu-form conjugation entry first (mirroring bunpou_te_kei's fix) or
# keep avoiding these six patterns.
#
# CROSS-CONTENT SYNC PASS (2026-08-03, earlier the same day as the reorder
# above): the user caught a real design flaw by hand — tapping ともだち
# (the original vocab pick for the greetings chapter) opened its own
# pre-authored example sentence ("友達と遊びます。"), which uses と and a
# ~ます verb, NEITHER of which that chapter actually teaches, and the word
# never appeared in that chapter's だ/です・は・か examples or its Kaiwa
# dialogue either — three lists sitting side by side with zero lexical
# overlap, not an integrated lesson. Every chapter's `kotoba_ids` below was
# re-audited against that same test: does this word's own `word`/`kanji`
# literally appear inside the chapter's chosen `bunpou_ids`' sentenceExamples
# or `kaiwa_ids`' dialogue lines? Words that failed were swapped for a
# different real, already-existing Kotoba entry that DOES appear in that
# same text (found by searching the *entire* Kotoba dataset for a literal
# substring match, not just the original source category) — e.g. the
# greetings chapter's ともだち became 学生, since 学生 is literally what both
# だ/です's own example ("私は学生です。") and the Kaiwa dialogue itself
# already say. For tightly closed sets that are pedagogically worth
# teaching as a whole (numbers, colors, days, seasons, cardinal
# directions), the full set was kept and a genuinely-matching word added on
# top rather than gutting the set for sync's sake — a deliberate judgment
# call, not an oversight if a handful of members in those sets still don't
# literally appear verbatim. Re-run this same audit (see the sync-check
# scripts used for this pass, not checked in — regenerate by extracting
# sentenceExamples/dialogue text per chapter and substring-matching against
# the full Kotoba dataset) after adding any future chapter, rather than
# picking vocab by theme alone.

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
        id="bab_keluarga_dan_teman",
        order=5,
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
        order=6,
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
        order=7,
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
        order=8,
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
        id="bab_cuaca_dan_basa_basi",
        order=9,
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
        order=10,
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
        order=11,
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
        order=12,
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
        order=13,
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
        id="bab_olahraga",
        order=14,
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
        order=15,
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
        order=16,
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
        order=17,
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
        id="bab_belanja",
        order=18,
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
        order=19,
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
        order=20,
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
        order=21,
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
        order=22,
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
        order=23,
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
        order=24,
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
        order=25,
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
