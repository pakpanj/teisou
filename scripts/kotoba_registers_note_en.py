# English translations for the 20 locked note-suffix templates found in
# KotobaEntry.registers values across all 46 categories (5,046 register
# sub-fields total: 3,277 are pure "{japanese} ({romaji})" with zero
# Indonesian text and need no translation; the remaining 1,769 append an
# explanatory note after an em-dash " — " separator, drawn from exactly
# these 20 templates — see CLAUDE.md's `_registers()` helper note for why
# the wording is this regular: every group script builds register text
# from one of a small set of fixed sentence shapes, never free text.
#
# scripts/apply_kotoba_registers_en.py applies this as a template
# substitution (split on " — ", translate only the suffix, keep the
# "{japanese} ({romaji})" prefix untouched) rather than translating each
# of the 1,769 full strings by hand — the prefix never needs translation
# since it's already language-neutral (Japanese script + romaji).

NOTE_EN = {
    "tidak ada bentuk keigo khusus untuk kata benda ini":
        "no special keigo form for this noun",
    "kesopanan ada di kalimat, mis. '~です' / '~があります'":
        "politeness lives in the sentence, e.g. '~です' / '~があります'",
    "tidak ada bentuk keigo khusus untuk nama makanan":
        "no special keigo form for food names",
    "tidak ada bentuk keigo khusus untuk istilah cuaca":
        "no special keigo form for weather terms",
    "tidak ada bentuk keigo khusus untuk nama hewan darat":
        "no special keigo form for land animal names",
    "tidak ada bentuk keigo khusus untuk kata sifat ini":
        "no special keigo form for this adjective",
    "tidak ada bentuk keigo khusus untuk istilah bencana alam":
        "no special keigo form for natural disaster terms",
    "tidak ada bentuk keigo khusus untuk nama buah":
        "no special keigo form for fruit names",
    "tidak ada bentuk keigo khusus untuk nama burung":
        "no special keigo form for bird names",
    "tidak ada bentuk keigo khusus untuk nama minuman":
        "no special keigo form for drink names",
    "tidak ada bentuk keigo khusus untuk nama alat masak":
        "no special keigo form for cooking tool names",
    "tidak ada bentuk keigo khusus untuk nama sayuran":
        "no special keigo form for vegetable names",
    "tidak ada bentuk keigo khusus untuk nama bumbu":
        "no special keigo form for seasoning names",
    "tidak ada bentuk keigo khusus untuk nama serangga":
        "no special keigo form for insect names",
    "tidak ada bentuk keigo khusus untuk nama bunga atau tanaman":
        "no special keigo form for flower or plant names",
    "tidak ada bentuk keigo khusus untuk kata kerja ini":
        "no special keigo form for this verb",
    "tidak ada bentuk keigo khusus untuk kata kerja memasak ini":
        "no special keigo form for this cooking verb",
    "kesopanan ada di kalimat, mis. '~を食べます'":
        "politeness lives in the sentence, e.g. '~を食べます'",
    "tidak ada bentuk keigo khusus untuk nama ikan":
        "no special keigo form for fish names",
    "tidak ada bentuk keigo khusus untuk nama pohon":
        "no special keigo form for tree names",
}
