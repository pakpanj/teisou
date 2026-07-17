# Canonical Kaiwa scenario/dialogue scope — the single source of truth
# generate_kaiwa_seed.py imports to know which themes/dialogues to write
# full content for, mirroring how particle_lists.py / bunpou_grammar_lists.py
# / kanji_char_lists.py lock their own module's scope.
#
# Kaiwa is organized in two layers: JLPT level (N5-N1, LEVEL_META below) ->
# scenario theme (Perkenalan, Di Restoran, ...) -> dialogue. Themes are
# still situational/thematic, not graded by grammar difficulty on their
# own — the level is what determines the vocabulary/grammar ceiling used
# within a theme's dialogues, not the theme's subject matter itself (e.g.
# "Di Restoran" could exist at N5 with simple ordering phrases, or in
# principle at a higher level with more nuanced language — this dataset
# currently only has N5 content, so that distinction is theoretical for
# now, not yet exercised).
#
# All content authored so far is N5. N4-N1 are locked in LEVEL_META as
# not-yet-authored levels — the level layer exists in the schema from day
# one, but there is deliberately no separate "PLANNED_LEVELS" list the way
# PLANNED_CATEGORIES works for themes, since a level with zero themes is
# already unambiguous (LEVEL_META entry present, available=False).

PERKENALAN_TITLES = [
    "Berkenalan dengan Teman Baru",
    "Menyapa di Pagi Hari",
    "Menanyakan Asal Negara",
    "Bertukar Nomor Telepon",
    "Menanyakan Umur",
    "Memperkenalkan Diri di Kelas Baru",
    "Menanyakan Pekerjaan",
    "Berkenalan di Pesta",
    "Menanyakan Alamat Rumah",
    "Berpisah Setelah Kenalan",
]

RESTORAN_TITLES = [
    "Memesan Makanan di Restoran",
    "Meminta Bill / Membayar",
    "Menanyakan Menu Rekomendasi",
    "Memesan Minuman Tambahan",
    "Meminta Meja untuk Empat Orang",
    "Menanyakan Alergi Makanan",
    "Memesan Makanan Pedas",
    "Meminta Kotak untuk Dibawa Pulang",
    "Memuji Masakan ke Pelayan",
    "Reservasi Meja Lewat Telepon",
]

STASIUN_TITLES = [
    "Membeli Tiket Kereta",
    "Menanyakan Peron/Jalur",
    "Menanyakan Jadwal Kereta",
    "Naik Kereta yang Salah",
    "Menanyakan Kereta Ekspres",
    "Kehilangan Barang di Kereta",
    "Membeli Kartu Kereta Isi Ulang",
    "Menanyakan Pintu Keluar Stasiun",
    "Naik Kereta Saat Jam Sibuk",
    "Bertanya Stasiun Transit",
]

BELANJA_TITLES = [
    "Menanyakan Harga Barang",
    "Mencoba Baju di Toko",
    "Membayar di Kasir",
    "Meminta Diskon",
    "Menukar Barang yang Rusak",
    "Mencari Ukuran yang Pas",
    "Membandingkan Dua Barang",
    "Bertanya Jam Buka Toko",
    "Membeli Oleh-oleh",
    "Membeli Barang Elektronik",
]

ARAH_JALAN_TITLES = [
    "Menanyakan Jalan ke Stasiun",
    "Menanyakan Jalan ke Toilet Umum",
    "Menanyakan Jarak Tempuh",
    "Menanyakan Jalan ke Rumah Sakit",
    "Tersesat di Kota Baru",
    "Menanyakan Arah dengan Peta",
    "Menanyakan Jalan ke Supermarket",
    "Menanyakan Naik Kendaraan Apa",
    "Menanyakan Jalan Pintas",
    "Berterima Kasih Setelah Diberi Arah",
]

SEKOLAH_TITLES = [
    "Menyapa Guru di Kelas",
    "Menanyakan Pekerjaan Rumah (PR)",
    "Meminjam Alat Tulis",
    "Bertanya Jadwal Pelajaran",
    "Meminta Izin ke Toilet",
    "Terlambat Masuk Kelas",
    "Mengajak Belajar Kelompok",
    "Menanyakan Nilai Ujian",
    "Membolos Karena Sakit",
    "Berpisah di Akhir Semester",
]

CUACA_BASA_BASI_TITLES = [
    "Membicarakan Cuaca",
    "Menanyakan Kegiatan Akhir Pekan",
    "Berpamitan",
    "Membicarakan Musim Favorit",
    "Basa-basi Menunggu Bus",
    "Menanyakan Kabar Setelah Lama Tidak Bertemu",
    "Membicarakan Rencana Malam Ini",
    "Basa-basi Tentang Pekerjaan Rumah Tangga",
    "Membicarakan Berita Terkini",
    "Menyapa Tetangga Baru",
]

RUMAH_SAKIT_TITLES = [
    "Menjelaskan Sakit ke Dokter",
    "Membuat Janji Temu",
    "Membeli Obat di Apotek",
    "Menjelaskan Gejala Flu",
    "Menanyakan Efek Samping Obat",
    "Kontrol Setelah Sakit",
    "Mengantar Keluarga Berobat",
    "Menanyakan Biaya Berobat",
    "Cedera Ringan Saat Olahraga",
    "Memeriksa Kesehatan Rutin",
]

HOBI_TITLES = [
    "Menanyakan Hobi Teman",
    "Mengajak Bermain Bersama",
    "Membicarakan Musik Favorit",
    "Membicarakan Film Favorit",
    "Belajar Hobi Baru",
    "Mengoleksi Sesuatu",
    "Membicarakan Buku yang Sedang Dibaca",
    "Ikut Klub Hobi",
    "Berbagi Foto Hasil Hobi",
    "Mengajak Ikut Komunitas Hobi",
]

TELEPON_TITLES = [
    "Menerima Telepon",
    "Menelepon Teman",
    "Meninggalkan Pesan",
    "Menelepon Layanan Pelanggan",
    "Salah Sambung Telepon",
    "Menelepon untuk Membatalkan Janji",
    "Menelepon Orang Tua",
    "Menutup Telepon dengan Sopan",
    "Telepon Terputus",
    "Menelepon untuk Mengucapkan Selamat",
]

TRANSPORTASI_TITLES = [
    "Naik Bus",
    "Memanggil Taksi",
    "Menanyakan Ongkos",
    "Naik Kereta Bawah Tanah",
    "Menyewa Sepeda",
    "Naik Pesawat",
    "Ketinggalan Bus",
    "Menanyakan Jam Terakhir Transportasi",
    "Naik Ojek/Ride Sharing",
    "Menanyakan Rute Terbaik",
]

KANTOR_POS_TITLES = [
    "Mengirim Surat",
    "Mengirim Paket",
    "Membeli Perangko",
    "Mengambil Paket yang Tertahan",
    "Menanyakan Lama Pengiriman",
    "Mengirim Uang Lewat Pos",
    "Membuka Kotak Pos",
    "Komplain Paket Rusak",
    "Mengirim Barang Internasional",
    "Menanyakan Asuransi Pengiriman",
]

LIBURAN_TITLES = [
    "Membicarakan Rencana Liburan",
    "Mengajak Berlibur Bersama",
    "Cerita Setelah Liburan",
]

KELUARGA_TITLES = [
    "Memperkenalkan Anggota Keluarga",
    "Menanyakan Jumlah Saudara",
    "Membicarakan Pekerjaan Orang Tua",
]

BANK_TITLES = [
    "Membuka Rekening",
    "Menukar Uang",
    "Menarik Uang di ATM",
]

OLAHRAGA_TITLES = [
    "Mengajak Olahraga Bersama",
    "Menanyakan Olahraga Favorit",
    "Menonton Pertandingan",
]

BIOSKOP_TITLES = [
    "Membeli Tiket Bioskop",
    "Memilih Kursi",
    "Membicarakan Film Setelah Nonton",
]

# category_id -> (display name, icon emoji, JLPT level key)
CATEGORY_META = {
    "perkenalan": ("Perkenalan", "👋", "N5"),
    "restoran": ("Di Restoran", "🍽️", "N5"),
    "stasiun": ("Di Stasiun", "🚉", "N5"),
    "belanja": ("Belanja", "🛍️", "N5"),
    "arah_jalan": ("Menanyakan Arah", "🧭", "N5"),
    "sekolah": ("Di Sekolah", "🏫", "N5"),
    "cuaca_basa_basi": ("Cuaca & Basa-basi", "☁️", "N5"),
    "rumah_sakit": ("Di Rumah Sakit", "🏥", "N5"),
    "hobi": ("Hobi", "🎨", "N5"),
    "telepon": ("Telepon", "☎️", "N5"),
    "transportasi": ("Transportasi", "🚌", "N5"),
    "kantor_pos": ("Di Kantor Pos", "📮", "N5"),
    "liburan": ("Rencana Liburan", "🏖️", "N5"),
    "keluarga": ("Keluarga", "👨‍👩‍👧", "N5"),
    "bank": ("Di Bank", "🏦", "N5"),
    "olahraga": ("Olahraga", "⚽", "N5"),
    "bioskop": ("Di Bioskop", "🎬", "N5"),
}

# category_id -> locked dialogue title list, for themes with real content.
AVAILABLE_CATEGORIES = {
    "perkenalan": PERKENALAN_TITLES,
    "restoran": RESTORAN_TITLES,
    "stasiun": STASIUN_TITLES,
    "belanja": BELANJA_TITLES,
    "arah_jalan": ARAH_JALAN_TITLES,
    "sekolah": SEKOLAH_TITLES,
    "cuaca_basa_basi": CUACA_BASA_BASI_TITLES,
    "rumah_sakit": RUMAH_SAKIT_TITLES,
    "hobi": HOBI_TITLES,
    "telepon": TELEPON_TITLES,
    "transportasi": TRANSPORTASI_TITLES,
    "kantor_pos": KANTOR_POS_TITLES,
    "liburan": LIBURAN_TITLES,
    "keluarga": KELUARGA_TITLES,
    "bank": BANK_TITLES,
    "olahraga": OLAHRAGA_TITLES,
    "bioskop": BIOSKOP_TITLES,
}

# (id, display name, icon emoji) for themes with no dataset yet —
# registered in _categories.json as available: False. Empty for now.
PLANNED_CATEGORIES = []

# level_id -> (display name, available)
LEVEL_META = {
    "N5": ("N5", True),
    "N4": ("N4", False),
    "N3": ("N3", False),
    "N2": ("N2", False),
    "N1": ("N1", False),
}

_ALL_TITLE_LISTS = {
    "PERKENALAN_TITLES": PERKENALAN_TITLES,
    "RESTORAN_TITLES": RESTORAN_TITLES,
    "STASIUN_TITLES": STASIUN_TITLES,
    "BELANJA_TITLES": BELANJA_TITLES,
    "ARAH_JALAN_TITLES": ARAH_JALAN_TITLES,
    "SEKOLAH_TITLES": SEKOLAH_TITLES,
    "CUACA_BASA_BASI_TITLES": CUACA_BASA_BASI_TITLES,
    "RUMAH_SAKIT_TITLES": RUMAH_SAKIT_TITLES,
    "HOBI_TITLES": HOBI_TITLES,
    "TELEPON_TITLES": TELEPON_TITLES,
    "TRANSPORTASI_TITLES": TRANSPORTASI_TITLES,
    "KANTOR_POS_TITLES": KANTOR_POS_TITLES,
    "LIBURAN_TITLES": LIBURAN_TITLES,
    "KELUARGA_TITLES": KELUARGA_TITLES,
    "BANK_TITLES": BANK_TITLES,
    "OLAHRAGA_TITLES": OLAHRAGA_TITLES,
    "BIOSKOP_TITLES": BIOSKOP_TITLES,
}
for _name, _titles in _ALL_TITLE_LISTS.items():
    assert len(_titles) >= 3, f"{_name} should have at least 3 dialogues, has {len(_titles)}"
    assert len(_titles) == len(set(_titles)), f"duplicate title in {_name}"

assert set(CATEGORY_META.keys()) == set(AVAILABLE_CATEGORIES.keys()), (
    "CATEGORY_META and AVAILABLE_CATEGORIES must cover exactly the same theme ids"
)

_planned_ids = [c[0] for c in PLANNED_CATEGORIES]
assert len(_planned_ids) == len(set(_planned_ids)), "duplicate id in PLANNED_CATEGORIES"
assert set(_planned_ids).isdisjoint(AVAILABLE_CATEGORIES.keys()), (
    "a planned category id collides with an available one"
)

assert set(LEVEL_META.keys()) == {"N5", "N4", "N3", "N2", "N1"}, "LEVEL_META must cover all 5 JLPT levels"
_used_levels = {level for _, _, level in CATEGORY_META.values()}
assert _used_levels.issubset(LEVEL_META.keys()), "a theme references an unknown level"
