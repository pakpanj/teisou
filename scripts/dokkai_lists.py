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

# N4-N1 initial seed (10 each) — every level now has real starting
# content instead of zero; deepening toward the ~100/level target
# continues in future sessions/phases, same as N5's own rollout.
N4_TITLES = [
    "Hasil Wawancara Kerja",
    "Peringatan Topan",
    "Ulasan Restoran",
    "Blog Perjalanan",
    "Esai Pendapat tentang Media Sosial",
    "Ulasan Produk",
    "Surat Keluhan",
    "Balasan Undangan",
    "Pengumuman Pindah Alamat",
    "Artikel Tips Kesehatan",
    "Pengumuman Perpustakaan Baru Dibuka",
    "Resep Sederhana",
    "Pengalaman Hari Pertama Kerja",
    "Panduan Naik Kereta",
    "Iklan Kursus Bahasa",
    "Email Konfirmasi Reservasi",
    "Blog tentang Hobi Baru",
    "Pengumuman Perbaikan Jalan",
    "Surat dari Anak yang Kuliah di Luar Negeri",
    "Artikel tentang Manfaat Olahraga",
]

N3_TITLES = [
    "Artikel Koran tentang Lingkungan",
    "Memo Tempat Kerja tentang Perubahan Sistem",
    "Esai Perbandingan Budaya",
    "Petunjuk Penggunaan Alat",
    "Esai Kesadaran Lingkungan",
    "Artikel Kesehatan",
    "Artikel Tren Teknologi",
    "Teks Sejarah Singkat",
    "Memo Rapat Kerja",
    "Cerita Pertukaran Budaya Internasional",
    "Artikel tentang Kebiasaan Makan Sehat",
    "Esai tentang Perubahan Musim",
    "Panduan Etika Bisnis di Jepang",
    "Artikel tentang Perkembangan Kota",
    "Pengalaman Kegiatan Sukarelawan",
    "Perbandingan Media Tradisional dan Digital",
    "Esai tentang Persahabatan",
    "Panduan Prosedur Darurat",
    "Artikel tentang Tren Pariwisata",
    "Cerita tentang Mengatasi Kegagalan",
]

N2_TITLES = [
    "Laporan Manajemen Perusahaan",
    "Editorial Sosial",
    "Penjelasan Ilmiah",
    "Esai tentang Karier dan Kehidupan",
    "Berita Ekonomi",
    "Analisis Budaya",
    "Pengembangan Karier",
    "Kebijakan Medis",
    "Strategi Perusahaan",
    "Esai tentang Pendidikan",
    "Laporan Riset Pasar",
    "Editorial tentang Pendidikan Anak",
    "Artikel tentang Inovasi Teknologi Ramah Lingkungan",
    "Esai tentang Keseimbangan Kerja dan Kehidupan",
    "Analisis Tren Konsumen",
    "Artikel tentang Diplomasi Budaya",
    "Esai tentang Warisan Keluarga",
    "Laporan tentang Perubahan Demografi",
    "Artikel tentang Etika Bisnis Global",
    "Esai tentang Definisi Kesuksesan",
]

N1_TITLES = [
    "Esai tentang Kehilangan",
    "Esai tentang Ketidakkekalan Waktu",
    "Kritik Sosial",
    "Surat Formal Perkenalan Bisnis",
    "Esai tentang Proses Kemandirian",
    "Kajian Sejarah Mendalam",
    "Refleksi tentang Pemaafan Diri",
    "Diskusi Filosofis tentang Etika Sains",
    "Kritik Seni Sastra",
    "Kajian Perubahan Sosial",
    "Esai tentang Makna Kebebasan",
    "Refleksi tentang Warisan Budaya yang Hilang",
    "Kritik tentang Konsumerisme Modern",
    "Diskusi tentang Hubungan Manusia dan Alam",
    "Diskusi tentang Bahasa dan Identitas",
    "Refleksi tentang Perjalanan Hidup",
    "Esai tentang Keheningan dan Kebijaksanaan",
    "Kritik Sastra Klasik",
    "Esai tentang Batas Antara Realita dan Ilusi",
    "Refleksi Filosofis tentang Kematian dan Kehidupan",
]

LEVEL_META = {
    "n5": ("N5", True),
    "n4": ("N4", True),
    "n3": ("N3", True),
    "n2": ("N2", True),
    "n1": ("N1", True),
}
