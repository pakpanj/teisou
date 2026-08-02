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
# 13 proof-of-concept N5 chapters so far, hand-picked from content already
# authored in past sessions — not the full curriculum. Expanding to more N5
# chapters and then N4-N1 is future-session work, same "batch 1 of many"
# shape as this project's other content rollouts (Dokkai, Dictionary).
#
# Chapter order is a deliberate teaching sequence, not just a list order —
# "bab_bentuk_te_dan_minta_tolong" (chapter 3) exists specifically to teach
# -te form conjugation *before* "bab_di_sekolah" (chapter 4), which already
# used the ~てください pattern without ever explaining how to build a -te
# form. If a future chapter needs a grammar/vocab prerequisite that doesn't
# exist yet, add the prerequisite as its own chapter earlier in the
# sequence rather than assuming the learner already knows it.
#
# Known deferred gap, NOT fixed yet (deliberately, per explicit user
# request to keep making Bab progress before reorganizing Bunpou): several
# real N5 Bunpou patterns (bunpou_masen_ka, bunpou_mashou, bunpou_mashou_ka,
# bunpou_ni_iku, bunpou_tai, bunpou_kata) require deriving a verb's ~masu
# stem, and — same as the -te form gap chapter 3 fixed — nothing in this
# dataset teaches ~masu-form conjugation either. None of chapters 6-9 use
# these patterns for exactly that reason. Before authoring a future chapter
# that needs any of them (very likely for invitation/politeness-themed
# chapters — "Mengajak" or "Rencana Liburan" are the natural next targets),
# either add a ~masu-form conjugation entry first (mirroring bunpou_te_kei's
# fix) or keep avoiding these six patterns.

N5_CHAPTERS = [
    dict(
        id="bab_menyapa_dan_berkenalan",
        order=1,
        level="N5",
        title="Menyapa dan Berkenalan",
        title_en="Greetings and Introductions",
        description="Ucapan dasar dan cara memperkenalkan diri ke teman baru.",
        description_en="Basic phrases and how to introduce yourself to a new friend.",
        kotoba_ids=["kotoba_keluarga_hubungan_tomodachi"],
        bunpou_ids=["bunpou_da_desu", "bunpou_wa", "bunpou_ka"],
        particle_ids=["particle_wa", "particle_ka"],
        kaiwa_ids=["kaiwa_kenalan_teman_baru"],
    ),
    dict(
        id="bab_keluarga_dan_teman",
        order=2,
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
            "kotoba_keluarga_hubungan_ane",
            "kotoba_keluarga_hubungan_otouto",
            "kotoba_keluarga_hubungan_imouto",
        ],
        bunpou_ids=["bunpou_ga_imasu", "bunpou_mo"],
        particle_ids=["particle_no", "particle_mo"],
        kaiwa_ids=["kaiwa_kenalkan_keluarga"],
    ),
    dict(
        id="bab_bentuk_te_dan_minta_tolong",
        order=3,
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
            "kotoba_hobi_aktivitas_souji",
            "kotoba_hobi_aktivitas_sentaku",
        ],
        bunpou_ids=["bunpou_te_kei", "bunpou_te_kudasai"],
        particle_ids=["particle_o"],
        kaiwa_ids=["kaiwa_bantuan_koper"],
    ),
    dict(
        id="bab_di_sekolah",
        order=4,
        level="N5",
        title="Di Sekolah",
        title_en="At School",
        description="Alat tulis, mata pelajaran, dan percakapan sehari-hari di sekolah.",
        description_en="School supplies, subjects, and everyday classroom conversation.",
        kotoba_ids=[
            "kotoba_alat_tulis_sekolah_enpitsu",
            "kotoba_alat_tulis_sekolah_nooto",
            "kotoba_alat_tulis_sekolah_hon",
            "kotoba_mata_pelajaran_nihongo",
            "kotoba_mata_pelajaran_eigo",
        ],
        bunpou_ids=["bunpou_te_kudasai", "bunpou_ga_arimasu"],
        particle_ids=["particle_ga", "particle_o"],
        kaiwa_ids=["kaiwa_pinjam_alat_tulis"],
    ),
    dict(
        id="bab_belanja",
        order=5,
        level="N5",
        title="Belanja",
        title_en="Shopping",
        description="Kosakata pakaian dan cara meminta atau membeli barang di toko.",
        description_en="Clothing vocabulary and how to ask for or buy things at a shop.",
        kotoba_ids=[
            "kotoba_pakaian_aksesori_fuku",
            "kotoba_pakaian_aksesori_kutsu",
            "kotoba_pakaian_aksesori_saifu",
        ],
        bunpou_ids=["bunpou_o_kudasai", "bunpou_ga_hoshii"],
        particle_ids=["particle_o", "particle_ga"],
        kaiwa_ids=["kaiwa_coba_baju"],
    ),
    dict(
        id="bab_kegiatan_sehari_hari",
        order=6,
        level="N5",
        title="Kegiatan Sehari-hari",
        title_en="Daily Activities",
        description=(
            "Menceritakan kegiatan yang sedang dilakukan, memakai bentuk -te "
            "dari bab sebelumnya."
        ),
        description_en=(
            "Talking about activities in progress, building on the -te form "
            "from the previous chapter."
        ),
        kotoba_ids=[
            "kotoba_hobi_aktivitas_sanpo",
            "kotoba_hobi_aktivitas_ongaku",
            "kotoba_hobi_aktivitas_eiga",
        ],
        bunpou_ids=["bunpou_te_iru", "bunpou_totemo"],
        particle_ids=["particle_o"],
        kaiwa_ids=["kaiwa_tanya_hobi"],
    ),
    dict(
        id="bab_di_restoran",
        order=7,
        level="N5",
        title="Di Restoran",
        title_en="At a Restaurant",
        description="Kosakata makanan/minuman dan cara memesan di restoran.",
        description_en="Food/drink vocabulary and how to order at a restaurant.",
        kotoba_ids=[
            "kotoba_makanan_jepang_ramen",
            "kotoba_makanan_barat_piza",
            "kotoba_minuman_mizu",
            "kotoba_minuman_koohii",
        ],
        bunpou_ids=["bunpou_o_kudasai", "bunpou_ga_arimasu", "bunpou_totemo"],
        particle_ids=["particle_o", "particle_ga"],
        kaiwa_ids=["kaiwa_pesan_makanan"],
    ),
    dict(
        id="bab_menanyakan_arah",
        order=8,
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
        ],
        bunpou_ids=["bunpou_ni_e", "bunpou_made"],
        particle_ids=["particle_ni", "particle_made"],
        kaiwa_ids=["kaiwa_jalan_ke_stasiun"],
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
        id="bab_stasiun_dan_transportasi",
        order=10,
        level="N5",
        title="Stasiun dan Transportasi",
        title_en="Station and Transportation",
        description="Kosakata kendaraan dan cara membeli tiket di stasiun.",
        description_en="Vehicle vocabulary and how to buy a ticket at the station.",
        kotoba_ids=[
            "kotoba_kendaraan_kuruma",
            "kotoba_kendaraan_densha",
            "kotoba_kendaraan_basu",
            "kotoba_kendaraan_jitensha",
        ],
        bunpou_ids=["bunpou_de", "bunpou_kara"],
        particle_ids=["particle_de", "particle_kara"],
        kaiwa_ids=["kaiwa_beli_tiket"],
    ),
    dict(
        id="bab_di_rumah_sakit",
        order=11,
        level="N5",
        title="Di Rumah Sakit",
        title_en="At the Hospital",
        description="Kosakata bagian tubuh dan cara menjelaskan sakit ke dokter.",
        description_en="Body-part vocabulary and how to describe pain to a doctor.",
        kotoba_ids=[
            "kotoba_obat_obatan_byouin",
            "kotoba_obat_obatan_isha",
            "kotoba_penyakit_gejala_itai",
            "kotoba_anggota_tubuh_atama",
        ],
        bunpou_ids=["bunpou_ga", "bunpou_totemo"],
        particle_ids=["particle_ga"],
        kaiwa_ids=["kaiwa_jelaskan_sakit"],
    ),
    dict(
        id="bab_olahraga",
        order=12,
        level="N5",
        title="Olahraga",
        title_en="Sports",
        description="Kosakata olahraga dan cara mengatakan olahraga favorit.",
        description_en="Sports vocabulary and how to say your favorite sport.",
        kotoba_ids=[
            "kotoba_olahraga_supootsu",
            "kotoba_olahraga_sakkaa",
        ],
        bunpou_ids=["bunpou_no_ga_suki", "bunpou_totemo"],
        particle_ids=["particle_o"],
        kaiwa_ids=["kaiwa_olahraga_favorit"],
    ),
    dict(
        id="bab_bioskop",
        order=13,
        level="N5",
        title="Bioskop",
        title_en="Cinema",
        description="Membicarakan film dan jenis film favorit.",
        description_en="Talking about movies and favorite kinds of films.",
        kotoba_ids=[
            "kotoba_media_hiburan_terebi",
            "kotoba_hobi_aktivitas_eiga",
        ],
        bunpou_ids=["bunpou_donna", "bunpou_no_ga_suki"],
        particle_ids=["particle_ga"],
        kaiwa_ids=["kaiwa_cerita_film"],
    ),
]
