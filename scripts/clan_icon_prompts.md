# Prompt gambar ikon clan Teisou

Satu berkas per preset, disimpan di `assets/clan_icons/{id}.png`. Nama
berkas **harus** persis sama dengan `id` di `ClanIconPresets.all`
(`lib/core/constants/clan_icons.dart`) — kalau tidak, aplikasi diam-diam
jatuh ke emoji dan tidak ada yang error.

---

## Baca ini dulu

**Minta latar magenta rata, jangan minta transparan.** Generator gambar
hampir semuanya tidak bisa menghasilkan alpha sungguhan — kalau diminta
transparan, mereka *menggambar* kotak-kotak abu-abu yang melambangkan
transparansi sebagai piksel biasa, dan kotak-kotak itu ikut masuk ke
aplikasi. Ini sudah pernah terjadi persis begini pada maskot aplikasi ini
(lihat `scripts/mascot_prompts.md`).

Karena itu setiap prompt di bawah meminta **latar magenta rata `#FF00DC`**
di LUAR lingkaran badge — warna itu tidak ada di mana pun pada palet
pastel aplikasi ini, jadi bisa dipotong bersih setelahnya:

```bash
python scripts/prepare_clan_icon.py "C:/Teisou asset/clan_icons/crest_shield.png" crest_shield
python scripts/prepare_clan_icon.py "C:/Teisou asset/clan_icons/"*.png   # nama dari nama berkas
```

Skrip itu membaca sendiri warna latar tiap gambar (generator jarang persis
mengeluarkan hex yang diminta), memotong bercak nyasar, lalu memusatkan
badge-nya ke kanvas persegi. Skrip akan memperingatkan kalau hasilnya
kurang dari 5% berpiksel padat — itu tandanya warna latar salah terbaca,
bukan tandanya gambarnya jelek.

**Setiap gambar adalah badge lingkaran utuh dengan latar pastelnya sendiri
sudah "dibakar" ke dalam gambar** — sama seperti set avatar `neko_circles`
yang sudah dipakai aplikasi ini (`AvatarPreset`'s sendiri sudah
menyebutkan ini: "every image is already a complete circular illustration
with its own backdrop baked in"). Jadi bukan ikon transparan tanpa latar
sama sekali — magenta di prompt hanya untuk area DI LUAR lingkaran badge,
supaya sudut-sudut persegi bisa dipotong jadi transparan, sementara
lingkaran badge-nya sendiri tetap solid dengan warna pastelnya sendiri.

---

## Gaya bersama — tempel di setiap prompt

> A kawaii sticker-style circular badge/crest icon, flat cel-shaded
> illustration, centred inside a solid pastel-coloured circle that fills
> most of the square canvas — the circle itself is the badge's own
> background, not a separate frame.
>
> The circle is outlined with the same thick, even dark-plum / maroon
> line (not black) used throughout this app's mascot character — see
> `scripts/mascot_prompts.md`'s character sheet for the exact outline
> style to match.
>
> Interior motif: flat vector-like shapes, soft simple shading, no
> gradient mesh, no texture, no photorealism, no fine detail that would
> disappear at small sizes (this renders as small as 32px in the app) —
> bold and legible like a phone-app icon, not an illustration meant to be
> viewed large.
>
> Palette: warm, soft, and friendly — pull from this app's existing pastel
> palette (coral `#F4667A`, cream, soft blue, soft green, soft gold) for
> the circle's background and the motif, never harsh saturated primary
> colours, never anything dark/aggressive/militaristic despite some
> motifs below being "crest"-shaped — this is for a children's language-
> learning app, a clan badge should read as cheerful, not as a gang
> emblem or a war shield.
>
> Composition: square 1024×1024 image, circular badge centred with a
> small even margin, everything OUTSIDE the circle solid flat magenta
> `#FF00DC` (see "Baca ini dulu" above — this gets keyed out, it is not
> part of the final art). No text, no letters, no watermark, no border
> around the whole canvas, no drop shadow.

---

## 12 preset

Setiap poin di bawah menggantikan kalimat "Interior motif" pada gaya
bersama di atas.

### 1. `crest_shield`
> Interior motif: a small rounded, friendly-shaped shield (soft corners,
> not a sharp military shield) with a single five-petal sakura flower
> centred on it in a contrasting pastel colour.

### 2. `crest_flag`
> Interior motif: a small triangular pennant flag on a short flagpole,
> gently waving, in a warm gold/coral colour with a simple star cut-out
> near its centre.

### 3. `crest_star`
> Interior motif: one large rounded five-point star with a soft sparkle
> (two small crossed light-rays) beside its top point.

### 4. `crest_trophy`
> Interior motif: a small chibi-proportioned trophy cup with two curved
> handles and a short round base, in a warm gold colour.

### 5. `crest_book`
> Interior motif: a small open book seen from the front, pages a soft
> cream colour, cover a contrasting pastel colour, with one tiny sakura
> petal resting on the open pages.

### 6. `crest_torii`
> Interior motif: a simple, friendly-proportioned torii gate (the two
> upright posts and two crossbars, no building behind it) in a soft
> coral-red, silhouetted against the badge's own pastel background.

### 7. `crest_sakura`
> Interior motif: a small cluster of three five-petal sakura blossoms on
> a short curved branch, soft pink petals with a tiny darker pink centre
> on each.

### 8. `crest_fox`
> Interior motif: a cute chibi fox face only (not a full body), large
> round eyes, small triangular ears, soft orange-and-cream fur, matching
> the same big-eyed kawaii proportions as this app's cat mascot.

### 9. `crest_owl`
> Interior motif: a cute chibi owl face/front-view only, large round
> eyes, small pointed ear-tufts, soft brown-and-cream feather pattern
> suggested with two or three simple curved lines, not fine detail.

### 10. `crest_dragon`
> Interior motif: a cute chibi Eastern dragon face only (front-facing,
> not a full serpentine body), round friendly eyes (not fierce), small
> whiskers, soft jade-green colour, two small rounded horns — playful and
> auspicious, not intimidating.

### 11. `crest_lantern`
> Interior motif: a small round Japanese paper lantern (chōchin) hanging
> from a short cord at the top, warm coral-red with soft horizontal rib
> lines, a simple round finial on top and bottom.

### 12. `crest_wave`
> Interior motif: a single simplified, rounded Japanese-style ocean wave
> (soft rounded curl, not sharp Hokusai-style points), soft blue with a
> lighter foam-coloured crest, friendly rather than dramatic.

---

## Setelah gambarnya jadi

```bash
python scripts/prepare_clan_icon.py "C:/Teisou asset/clan_icons/"*.png
```

Cek hasilnya di `assets/clan_icons/` — 12 berkas, satu per `id` di atas —
sebelum menjalankan aplikasi. Tidak perlu perubahan kode apa pun: `Clan`
sudah membaca ulang gambar lewat `ClanIconArt`, yang otomatis memakai PNG
begitu file dengan nama yang cocok muncul di folder itu, dan tetap jatuh
ke emoji kalau belum ada.
