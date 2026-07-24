import '../../data/models/app_language.dart';

/// English translations for Kotoba's category + group names, keyed by the
/// Indonesian string already in `_categories.json` (the dataset itself
/// stays Indonesian-authored — see `AppStrings`' doc comment for why: this
/// is presentation-layer translation of a fixed, small, closed set of
/// labels, not the open-ended per-word content `AppStrings` deliberately
/// excludes). Falls back to the Indonesian string itself if a key is
/// somehow missing, so an unmapped/future category never renders blank.
class KotobaCategoryI18n {
  KotobaCategoryI18n._();

  static const Map<String, String> _groupEn = {
    'Alam & Lingkungan': 'Nature & Environment',
    'Makanan & Minuman': 'Food & Drink',
    'Manusia & Sosial': 'People & Society',
    'Pendidikan & Pekerjaan': 'Education & Work',
    'Tempat & Transportasi': 'Places & Transportation',
    'Tubuh & Kesehatan': 'Body & Health',
    'Waktu & Angka': 'Time & Numbers',
  };

  static const Map<String, String> _nameEn = {
    'Ikan': 'Fish',
    'Hewan Darat': 'Land Animals',
    'Burung': 'Birds',
    'Serangga': 'Insects',
    'Pohon': 'Trees',
    'Bunga & Tanaman': 'Flowers & Plants',
    'Buah': 'Fruits',
    'Sayuran': 'Vegetables',
    'Cuaca': 'Weather',
    'Bencana Alam': 'Natural Disasters',
    'Makanan Jepang': 'Japanese Food',
    'Makanan Indonesia': 'Indonesian Food',
    'Makanan Barat': 'Western Food',
    'Minuman': 'Drinks',
    'Bumbu & Rempah': 'Herbs & Spices',
    'Peralatan Masak': 'Cooking Equipment',
    'Cara Memasak': 'Cooking Methods',
    'Anggota Tubuh': 'Body Parts',
    'Penyakit & Gejala': 'Illness & Symptoms',
    'Obat-obatan': 'Medicine',
    'Olahraga': 'Sports',
    'Perasaan & Emosi': 'Feelings & Emotions',
    'Ekspresi Wajah': 'Facial Expressions',
    'Ruangan di Rumah': 'Rooms in the House',
    'Perabot Rumah': 'Furniture',
    'Bangunan & Fasilitas': 'Buildings & Facilities',
    'Kendaraan': 'Vehicles',
    'Arah & Lokasi': 'Direction & Location',
    'Negara & Kota': 'Countries & Cities',
    'Profesi': 'Professions',
    'Keluarga & Hubungan': 'Family & Relationships',
    'Pakaian & Aksesori': 'Clothing & Accessories',
    'Hobi & Aktivitas': 'Hobbies & Activities',
    'Agama & Budaya': 'Religion & Culture',
    'Perayaan & Hari Besar': 'Celebrations & Holidays',
    'Konsep Umum': 'General Concepts',
    'Alat Tulis & Perlengkapan Sekolah': 'Stationery & School Supplies',
    'Mata Pelajaran': 'School Subjects',
    'Pekerjaan & Kantor': 'Office Work',
    'Teknologi & Gadget': 'Technology & Gadgets',
    'Media & Hiburan': 'Media & Entertainment',
    'Hari & Bulan': 'Days & Months',
    'Musim': 'Seasons',
    'Angka & Satuan': 'Numbers & Units',
    'Warna': 'Colors',
    'Bentuk': 'Shapes',
  };

  static String group(String indonesian, AppLanguage language) =>
      language == AppLanguage.english
          ? (_groupEn[indonesian] ?? indonesian)
          : indonesian;

  static String name(String indonesian, AppLanguage language) =>
      language == AppLanguage.english
          ? (_nameEn[indonesian] ?? indonesian)
          : indonesian;
}
