import json

# Metadata for all 45 planned Kotoba vocab categories (Batch 6), grouped by
# theme per the project roadmap. `available` categories have a real word
# list at assets/data/kotoba/{id}.json (see generate_kotoba_<category>.py
# scripts); the rest are placeholders so the category grid can show them
# with a "Segera" badge instead of just omitting them. Re-run this script
# after adding a new category's dataset to flip its `available` flag and
# fill in the real `wordCount`.
#
# Each tuple: (id, name, icon, available, wordCount)
GROUPS = {
    "Alam & Lingkungan": [
        # Fase 1 (Batch 6): all 10 kategori grup ini punya dataset nyata di
        # assets/data/kotoba/{id}.json — lihat generate_kotoba_ikan.py dan
        # generate_kotoba_alam.py.
        ("ikan", "Ikan", "🐟", True, 8),
        ("hewan_darat", "Hewan Darat", "🐾", True, 22),
        ("burung", "Burung", "🐦", True, 13),
        ("serangga", "Serangga", "🐛", True, 13),
        ("pohon", "Pohon", "🌳", True, 8),
        ("bunga_tanaman", "Bunga & Tanaman", "🌸", True, 9),
        ("buah", "Buah", "🍎", True, 14),
        ("sayuran", "Sayuran", "🥬", True, 14),
        ("cuaca", "Cuaca", "⛅", True, 12),
        ("bencana_alam", "Bencana Alam", "🌪️", True, 11),
    ],
    "Makanan & Minuman": [
        ("makanan_jepang", "Makanan Jepang", "🍱", True, 15),
        ("makanan_indonesia", "Makanan Indonesia", "🍛", True, 7),
        ("makanan_barat", "Makanan Barat", "🍔", True, 14),
        ("minuman", "Minuman", "🥤", True, 12),
        ("bumbu_rempah", "Bumbu & Rempah", "🧂", True, 12),
        ("peralatan_masak", "Peralatan Masak", "🍳", True, 12),
        ("cara_memasak", "Cara Memasak", "🔥", True, 10),
    ],
    "Tubuh & Kesehatan": [
        ("anggota_tubuh", "Anggota Tubuh", "🖐️", True, 17),
        ("penyakit_gejala", "Penyakit & Gejala", "🤒", True, 11),
        ("obat_obatan", "Obat-obatan", "💊", True, 10),
        ("olahraga", "Olahraga", "⚽", True, 12),
        ("perasaan_emosi", "Perasaan & Emosi", "😊", True, 10),
        ("ekspresi_wajah", "Ekspresi Wajah", "😮", True, 8),
    ],
    "Tempat & Transportasi": [
        ("ruangan_rumah", "Ruangan di Rumah", "🚪", True, 11),
        ("perabot_rumah", "Perabot Rumah", "🛋️", True, 11),
        ("bangunan_fasilitas", "Bangunan & Fasilitas", "🏢", True, 11),
        ("kendaraan", "Kendaraan", "🚗", True, 10),
        ("arah_lokasi", "Arah & Lokasi", "🧭", True, 11),
        ("negara_kota", "Negara & Kota", "🗺️", True, 11),
    ],
    "Manusia & Sosial": [
        ("profesi", "Profesi", "👨‍⚕️", True, 12),
        ("keluarga_hubungan", "Keluarga & Hubungan", "👪", True, 14),
        ("pakaian_aksesori", "Pakaian & Aksesori", "👕", True, 12),
        ("hobi_aktivitas", "Hobi & Aktivitas", "🎨", True, 12),
        ("agama_budaya", "Agama & Budaya", "⛩️", True, 10),
        ("perayaan_haribesar", "Perayaan & Hari Besar", "🎉", True, 11),
    ],
    "Pendidikan & Pekerjaan": [
        ("alat_tulis_sekolah", "Alat Tulis & Perlengkapan Sekolah", "✏️", False, None),
        ("mata_pelajaran", "Mata Pelajaran", "📖", False, None),
        ("pekerjaan_kantor", "Pekerjaan & Kantor", "💼", False, None),
        ("teknologi_gadget", "Teknologi & Gadget", "💻", False, None),
        ("media_hiburan", "Media & Hiburan", "📺", False, None),
    ],
    "Waktu & Angka": [
        ("hari_bulan", "Hari & Bulan", "📅", False, None),
        ("musim", "Musim", "🍂", False, None),
        ("angka_satuan", "Angka & Satuan", "🔢", False, None),
        ("warna", "Warna", "🌈", False, None),
        ("bentuk", "Bentuk", "🔷", False, None),
    ],
}


def build_entries():
    entries = []
    for group, categories in GROUPS.items():
        for cat_id, name, icon, available, word_count in categories:
            entry = {
                "id": cat_id,
                "name": name,
                "group": group,
                "icon": icon,
                "available": available,
            }
            if word_count is not None:
                entry["wordCount"] = word_count
            entries.append(entry)
    return entries


def main():
    data = build_entries()
    with open("assets/data/kotoba/_categories.json", "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    available = sum(1 for e in data if e["available"])
    print(f"Wrote {len(data)} categories ({available} available, {len(data) - available} segera).")


if __name__ == "__main__":
    main()
