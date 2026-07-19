# Canonical Dokkai (reading comprehension) scope — the single source of
# truth generate_dokkai_seed.py imports, mirroring kaiwa_lists.py's
# locked-list + LEVEL_META pattern.
#
# This is a first, deliberately small pass: a handful of N5 passages to
# prove the Ujian architecture end-to-end (level picker -> passage list ->
# passage + questions -> score), not a full N5-N1 content rollout. N4-N1
# are locked here as not-yet-authored levels — same "schema ready, content
# is a separate later pass" shape as Kaiwa's N4-N1 levels before they were
# authored.

N5_TITLES = [
    "Surat dari Sahabat Pena",
    "Papan Pengumuman di Sekolah",
    "Jadwal Harian Yuki",
]

LEVEL_META = {
    "n5": ("N5", True),
    "n4": ("N4", False),
    "n3": ("N3", False),
    "n2": ("N2", False),
    "n1": ("N1", False),
}
