"""Locked title lists for Choukai (listening comprehension).

Mirrors dokkai_lists.py. The generator cross-checks the authored clips
against these so a title can't silently drift or duplicate.

Choukai has no recorded-audio pipeline: each clip's `audioText` is spoken
by `ttsServiceProvider`, and is deliberately never shown on screen during
the exam — only played — then revealed on the result screen for review.
That is why a clip needs no asset from anyone; it is pure text authoring.

Clip shapes follow the four things the real JLPT listening paper does:
  - task comprehension  (a conversation, then "what will X do next?")
  - point comprehension (listen for one specific detail)
  - gist               ("what is this person mainly talking about?")
  - quick response     (one line, pick the natural reply)
N5 keeps to school, family and daily-life settings, since the app's
audience is children.
"""

LEVEL_META = [
    ("N5", "N5"),
    ("N4", "N4"),
    ("N3", "N3"),
    ("N2", "N2"),
    ("N1", "N1"),
]

N5_TITLES = [
    "Jam Berapa Sekarang",
    "Mencari Buku di Kelas",
    "Sarapan Pagi Ini",
    "Berapa Harganya",
    "Hari Apa Ulang Tahunmu",
    "Di Mana Tasnya",
    "Pergi ke Sekolah Naik Apa",
    "Cuaca Hari Ini",
    "Berapa Orang Keluargamu",
    "Warna Payung Siapa",
    "Bertemu di Depan Stasiun",
    "Makanan yang Tidak Disukai",
    "Meminjam Pensil",
    "Nomor Telepon Teman",
    "Hewan Peliharaan di Rumah",
    "Pekerjaan Rumah Belum Selesai",
    "Membeli Minuman",
    "Sakit Perut di Sekolah",
    "Rencana Hari Minggu",
    "Kelas Dimulai Jam Berapa",
]

N4_TITLES = [
    "Batal Pergi karena Hujan",
    "Salah Turun Halte",
    "Meminta Tolong Menjaga Adik",
    "Barang Tertinggal di Kereta",
    "Memilih Hadiah untuk Guru",
    "Janji yang Harus Diundur",
    "Cara ke Perpustakaan Kota",
    "Lupa Membawa Dompet",
    "Memesan Meja di Restoran",
    "Mengembalikan Buku Terlambat",
    "Kelas Tambahan Sepulang Sekolah",
    "Menanyakan Jam Buka Toko",
    "Teman yang Pindah Sekolah",
    "Membantu Ibu Berbelanja",
    "Kehujanan di Tengah Jalan",
    "Menyiapkan Acara Kelas",
    "Sepeda yang Rusak",
    "Memilih Klub di Sekolah",
    "Menelepon karena Terlambat",
    "Rencana Piknik Bersama",
]

N3_TITLES = [
    "Alasan Memilih Jurusan",
    "Keluhan tentang Tetangga Berisik",
    "Menawar Harga di Pasar",
    "Kesalahpahaman dengan Teman",
    "Wawancara Kerja Paruh Waktu",
    "Membandingkan Dua Apartemen",
    "Pengumuman Perubahan Jadwal",
    "Meminta Maaf atas Kelalaian",
    "Memilih Tempat Liburan",
    "Diskusi Tugas Kelompok",
    "Mengurus Kartu yang Hilang",
    "Menolak Ajakan dengan Sopan",
    "Membicarakan Rencana Masa Depan",
    "Komplain Barang Rusak",
    "Menjelaskan Cara Memakai Alat",
    "Perubahan Kebiasaan Makan",
    "Pindah ke Kota Lain",
    "Menanyakan Syarat Pendaftaran",
    "Kesulitan Mengatur Waktu",
    "Menyampaikan Pesan dari Orang Lain",
]

N2_TITLES = []
N1_TITLES = []

for _name, _titles in [
    ("N5", N5_TITLES), ("N4", N4_TITLES), ("N3", N3_TITLES),
    ("N2", N2_TITLES), ("N1", N1_TITLES),
]:
    assert len(set(_titles)) == len(_titles), "duplicate title in %s" % _name
