# Canonical Dokkai (reading comprehension) scope — the single source of
# truth generate_dokkai_seed.py imports, mirroring kaiwa_lists.py's
# locked-list + LEVEL_META pattern.
#
# 2026-07-20: user asked to bring Dokkai to full parity across N5-N1,
# target ~100 passages per level (~500 total) — this is a genuine
# multi-session content rollout, same shape as Kaiwa's N4-N1 expansion
# (which took several phased sessions to reach 1700 dialogues). N5
# phase 1 below brings N5 from 3 to 20 passages. N4-N1 remain locked as
# not-yet-authored levels until their own phases start.

N5_TITLES = [
    "Surat dari Sahabat Pena",
    "Papan Pengumuman di Sekolah",
    "Jadwal Harian Yuki",
    "Memo dari Ibu",
    "Ramalan Cuaca Hari Ini",
    "Aturan Perpustakaan",
    "Iklan Lowongan Kerja Paruh Waktu",
    "Rencana Perjalanan Kelas",
    "Pengumuman Menu Baru Restoran",
    "Surat dari Teman Lama",
    "Pengumuman di Stasiun",
    "Pengumuman Kelas Tambahan",
    "Buku Harian Tanaka",
    "Peraturan Taman Kota",
    "Pengumuman Pindah Rumah",
    "Jam Buka Rumah Sakit",
    "Undangan Pesta Ulang Tahun",
    "Diskon Supermarket Akhir Pekan",
    "Liburan Keluarga ke Laut",
    "Perubahan Jadwal Sekolah",
]

LEVEL_META = {
    "n5": ("N5", True),
    "n4": ("N4", False),
    "n3": ("N3", False),
    "n2": ("N2", False),
    "n1": ("N1", False),
}
