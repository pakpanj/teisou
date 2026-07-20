"""Splice scripts/reference/n3_web_batch.py's 92 words into the right
generate_kotoba_*.py files as new tuples. Run from teisou project root:
python scripts/reference/apply_n3_batch.py
"""
import json
import re
import sys

sys.path.insert(0, "scripts/reference")
from n3_web_batch import N3_WORDS  # noqa: E402
from hiragana_romaji import to_romaji  # noqa: E402

CATEGORY_TO_SCRIPT = {
    "cuaca": "generate_kotoba_alam.py", "bencana_alam": "generate_kotoba_alam.py",
    "bunga_tanaman": "generate_kotoba_alam.py",
    "minuman": "generate_kotoba_makanan_minuman.py",
    "makanan_jepang": "generate_kotoba_makanan_minuman.py",
    "bumbu_rempah": "generate_kotoba_makanan_minuman.py",
    "peralatan_masak": "generate_kotoba_makanan_minuman.py",
    "anggota_tubuh": "generate_kotoba_tubuh_kesehatan.py",
    "penyakit_gejala": "generate_kotoba_tubuh_kesehatan.py",
    "obat_obatan": "generate_kotoba_tubuh_kesehatan.py",
    "olahraga": "generate_kotoba_tubuh_kesehatan.py",
    "perasaan_emosi": "generate_kotoba_tubuh_kesehatan.py",
    "ekspresi_wajah": "generate_kotoba_tubuh_kesehatan.py",
    "ruangan_rumah": "generate_kotoba_tempat_transportasi.py",
    "perabot_rumah": "generate_kotoba_tempat_transportasi.py",
    "bangunan_fasilitas": "generate_kotoba_tempat_transportasi.py",
    "kendaraan": "generate_kotoba_tempat_transportasi.py",
    "arah_lokasi": "generate_kotoba_tempat_transportasi.py",
    "negara_kota": "generate_kotoba_tempat_transportasi.py",
    "profesi": "generate_kotoba_manusia_sosial.py",
    "keluarga_hubungan": "generate_kotoba_manusia_sosial.py",
    "pakaian_aksesori": "generate_kotoba_manusia_sosial.py",
    "hobi_aktivitas": "generate_kotoba_manusia_sosial.py",
    "agama_budaya": "generate_kotoba_manusia_sosial.py",
    "perayaan_haribesar": "generate_kotoba_manusia_sosial.py",
    "konsep_umum": "generate_kotoba_manusia_sosial.py",
    "alat_tulis_sekolah": "generate_kotoba_pendidikan_pekerjaan.py",
    "mata_pelajaran": "generate_kotoba_pendidikan_pekerjaan.py",
    "pekerjaan_kantor": "generate_kotoba_pendidikan_pekerjaan.py",
    "teknologi_gadget": "generate_kotoba_pendidikan_pekerjaan.py",
    "media_hiburan": "generate_kotoba_pendidikan_pekerjaan.py",
    "hari_bulan": "generate_kotoba_waktu_angka.py",
    "musim": "generate_kotoba_waktu_angka.py",
    "angka_satuan": "generate_kotoba_waktu_angka.py",
    "warna": "generate_kotoba_waktu_angka.py",
    "bentuk": "generate_kotoba_waktu_angka.py",
}
TWELVE_FIELD_SCRIPTS = {
    "generate_kotoba_waktu_angka.py", "generate_kotoba_tempat_transportasi.py",
    "generate_kotoba_manusia_sosial.py", "generate_kotoba_pendidikan_pekerjaan.py",
    "generate_kotoba_tubuh_kesehatan.py",
}


def existing_ids():
    import glob
    ids = set()
    for f in glob.glob("assets/data/kotoba/*.json"):
        if "_categories" in f:
            continue
        for e in json.load(open(f, encoding="utf-8")):
            ids.add(e["id"])
    return ids


def build_tuples():
    ids = existing_ids()
    used_suffixes_by_category = {}
    out = {}
    for kanji, reading, meaning, cat, ex_ja, ex_ro, ex_id in N3_WORDS:
        romaji = to_romaji(reading)
        base_suffix = romaji
        suffix = base_suffix
        used = used_suffixes_by_category.setdefault(cat, set())
        counter = 2
        candidate_id = f"kotoba_{cat}_{suffix}"
        while suffix in used or candidate_id in ids:
            suffix = f"{base_suffix}{counter}"
            candidate_id = f"kotoba_{cat}_{suffix}"
            counter += 1
        used.add(suffix)

        kanji_lit = json.dumps(kanji, ensure_ascii=False)
        reading_lit = json.dumps(reading, ensure_ascii=False)
        romaji_lit = json.dumps(romaji, ensure_ascii=False)
        meaning_lit = json.dumps(meaning, ensure_ascii=False)
        ex_ja_lit = json.dumps(ex_ja, ensure_ascii=False)
        ex_ro_lit = json.dumps(ex_ro, ensure_ascii=False)
        ex_id_lit = json.dumps(ex_id, ensure_ascii=False)

        script = CATEGORY_TO_SCRIPT[cat]
        if script in TWELVE_FIELD_SCRIPTS:
            tup = (
                f'        ("{suffix}", {kanji_lit}, {reading_lit}, {romaji_lit}, {meaning_lit}, '
                f'"N3", "noun", {kanji_lit}, {romaji_lit}, {kanji_lit}, {romaji_lit}, [\n'
                f'            ({ex_ja_lit}, {ex_ro_lit}, {ex_id_lit}),\n'
                f'        ]),\n'
            )
        else:
            tup = (
                f'        ("{suffix}", {kanji_lit}, {reading_lit}, {romaji_lit}, {meaning_lit}, "N3", [\n'
                f'            ({ex_ja_lit}, {ex_ro_lit}, {ex_id_lit}),\n'
                f'        ]),\n'
            )
        out.setdefault(cat, []).append(tup)
    return out


def insert_into_scripts(tuples_by_cat):
    by_script = {}
    for cat, tups in tuples_by_cat.items():
        script = CATEGORY_TO_SCRIPT[cat]
        by_script.setdefault(script, {})[cat] = tups

    for script, cats in by_script.items():
        path = f"scripts/{script}"
        with open(path, encoding="utf-8") as f:
            lines = f.readlines()
        for cat, tups in cats.items():
            start_pat = re.compile(rf'^\s*"{re.escape(cat)}":\s*[\[(]')
            start_idx = next(i for i, l in enumerate(lines) if start_pat.match(l))
            close_pat = re.compile(r"^\s{4}\]\)?,\s*$")
            end_idx = next(i for i in range(start_idx + 1, len(lines)) if close_pat.match(lines[i]))
            insertion = "".join(tups)
            lines[end_idx:end_idx] = [insertion]
        with open(path, "w", encoding="utf-8") as f:
            f.writelines(lines)
        print(f"Updated {path}: inserted into {list(cats.keys())}")


if __name__ == "__main__":
    tuples_by_cat = build_tuples()
    for cat, tups in sorted(tuples_by_cat.items()):
        print(cat, len(tups))
    insert_into_scripts(tuples_by_cat)
