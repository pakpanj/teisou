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
# V1 (this batch): 5 proof-of-concept N5 chapters, hand-picked from content
# already authored in past sessions — not the full curriculum. Expanding to
# more N5 chapters and then N4-N1 is future-session work, same "batch 1 of
# many" shape as this project's other content rollouts (Dokkai, Dictionary).
#
# Chapter order is a deliberate teaching sequence, not just a list order —
# "bab_bentuk_te_dan_minta_tolong" (chapter 3) exists specifically to teach
# -te form conjugation *before* "bab_di_sekolah" (chapter 4), which already
# used the ~てください pattern without ever explaining how to build a -te
# form. If a future chapter needs a grammar/vocab prerequisite that doesn't
# exist yet, add the prerequisite as its own chapter earlier in the
# sequence rather than assuming the learner already knows it.

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
]
