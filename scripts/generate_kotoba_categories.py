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
        ("burung", "Burung", "🐦", True, 14),
        ("serangga", "Serangga", "🐛", True, 13),
        ("pohon", "Pohon", "🌳", True, 8),
        ("bunga_tanaman", "Bunga & Tanaman", "🌸", True, 11),
        ("buah", "Buah", "🍎", True, 14),
        ("sayuran", "Sayuran", "🥬", True, 14),
        ("cuaca", "Cuaca", "⛅", True, 23),
        ("bencana_alam", "Bencana Alam", "🌪️", True, 18),
    ],
    "Makanan & Minuman": [
        ("makanan_jepang", "Makanan Jepang", "🍱", True, 17),
        ("makanan_indonesia", "Makanan Indonesia", "🍛", True, 7),
        ("makanan_barat", "Makanan Barat", "🍔", True, 14),
        ("minuman", "Minuman", "🥤", True, 14),
        ("bumbu_rempah", "Bumbu & Rempah", "🧂", True, 13),
        ("peralatan_masak", "Peralatan Masak", "🍳", True, 14),
        ("cara_memasak", "Cara Memasak", "🔥", True, 10),
    ],
    "Tubuh & Kesehatan": [
        ("anggota_tubuh", "Anggota Tubuh", "🖐️", True, 30),
        ("penyakit_gejala", "Penyakit & Gejala", "🤒", True, 35),
        ("obat_obatan", "Obat-obatan", "💊", True, 27),
        ("olahraga", "Olahraga", "⚽", True, 26),
        ("perasaan_emosi", "Perasaan & Emosi", "😊", True, 59),
        ("ekspresi_wajah", "Ekspresi Wajah", "😮", True, 10),
    ],
    "Tempat & Transportasi": [
        ("ruangan_rumah", "Ruangan di Rumah", "🚪", True, 20),
        ("perabot_rumah", "Perabot Rumah", "🛋️", True, 21),
        ("bangunan_fasilitas", "Bangunan & Fasilitas", "🏢", True, 73),
        ("kendaraan", "Kendaraan", "🚗", True, 41),
        ("arah_lokasi", "Arah & Lokasi", "🧭", True, 40),
        ("negara_kota", "Negara & Kota", "🗺️", True, 55),
    ],
    "Manusia & Sosial": [
        ("profesi", "Profesi", "👨‍⚕️", True, 46),
        ("keluarga_hubungan", "Keluarga & Hubungan", "👪", True, 54),
        ("pakaian_aksesori", "Pakaian & Aksesori", "👕", True, 24),
        ("hobi_aktivitas", "Hobi & Aktivitas", "🎨", True, 36),
        ("agama_budaya", "Agama & Budaya", "⛩️", True, 17),
        ("perayaan_haribesar", "Perayaan & Hari Besar", "🎉", True, 18),
        # New category (2026-07-20, sixth batch) — see the docstring on
        # CATEGORIES["konsep_umum"] in generate_kotoba_manusia_sosial.py
        # for why this exists as its own category rather than being
        # folded into an existing real-world-themed one.
        ("konsep_umum", "Konsep Umum", "💭", True, 416),
    ],
    "Pendidikan & Pekerjaan": [
        ("alat_tulis_sekolah", "Alat Tulis & Perlengkapan Sekolah", "✏️", True, 21),
        ("mata_pelajaran", "Mata Pelajaran", "📖", True, 69),
        ("pekerjaan_kantor", "Pekerjaan & Kantor", "💼", True, 118),
        ("teknologi_gadget", "Teknologi & Gadget", "💻", True, 39),
        ("media_hiburan", "Media & Hiburan", "📺", True, 28),
    ],
    "Waktu & Angka": [
        ("hari_bulan", "Hari & Bulan", "📅", True, 79),
        ("musim", "Musim", "🍂", True, 5),
        ("angka_satuan", "Angka & Satuan", "🔢", True, 20),
        ("warna", "Warna", "🌈", True, 11),
        ("bentuk", "Bentuk", "🔷", True, 10),
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
