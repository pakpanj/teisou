# Prompt gambar ikon clan Teisou

Satu berkas per preset, disimpan di `assets/clan_icons/{id}.png`. Nama
berkas **harus** persis sama dengan `id` di `ClanIconPresets.all`
(`lib/core/constants/clan_icons.dart`) — kalau tidak, aplikasi diam-diam
jatuh ke emoji dan tidak ada yang error.

**Revisi**: set ini menggantikan versi pertama (12 lencana bertema
campuran perisai/bintang/piala yang generik) dengan 20 motif yang
**benar-benar khas budaya Jepang** — beberapa di antaranya (daruma, ema,
hamaya, koi) memang sudah membawa makna "semangat mencapai tujuan" di
budaya Jepang sendiri, cocok untuk aplikasi belajar.

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
python scripts/prepare_clan_icon.py "C:/Teisou asset/clan_icons/crest_torii.png" crest_torii
python scripts/prepare_clan_icon.py "C:/Teisou asset/clan_icons/"*.png   # nama dari nama berkas
```

Skrip itu membaca sendiri warna latar tiap gambar (generator jarang persis
mengeluarkan hex yang diminta), memotong bercak nyasar, lalu memusatkan
badge-nya ke kanvas persegi. Skrip akan memperingatkan kalau hasilnya
kurang dari 5% berpiksel padat — itu tandanya warna latar salah terbaca,
bukan tandanya gambarnya jelek.

**Setiap gambar adalah badge lingkaran utuh dengan latar pastelnya sendiri
sudah "dibakar" ke dalam gambar** — sama seperti set avatar `neko_circles`
yang sudah dipakai aplikasi ini. Jadi bukan ikon transparan tanpa latar
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
> viewed large. Represent the motif accurately and respectfully as a real
> Japanese cultural object/symbol — simplified for the kawaii style, but
> recognisable, not a generic invented shape.
>
> Palette: warm, soft, and friendly — pull from this app's existing pastel
> palette (coral `#F4667A`, cream, soft blue, soft green, soft gold) for
> the circle's background, while the motif itself can use its own
> traditionally accurate colours (e.g. vermillion torii, red-and-white
> daruma) rendered in the same soft pastel-friendly saturation as the rest
> of the app — never harsh neon, never dark/somber.
>
> Composition: square 1024×1024 image, circular badge centred with a
> small even margin, everything OUTSIDE the circle solid flat magenta
> `#FF00DC` (see "Baca ini dulu" above — this gets keyed out, it is not
> part of the final art). No text, no letters, no watermark, no border
> around the whole canvas, no drop shadow.

---

## 20 preset

Setiap poin di bawah menggantikan kalimat "Interior motif" pada gaya
bersama di atas.

### 1. `crest_torii`
> Interior motif: a Shinto shrine torii gate — two upright pillars and
> two horizontal crossbars, the classic vermillion-red colour, seen
> straight-on, no building behind it.

### 2. `crest_sakura`
> Interior motif: a small cluster of three five-petal cherry blossoms
> (sakura) on a short curved branch, soft pink petals with a tiny darker
> pink centre on each.

### 3. `crest_fuji`
> Interior motif: Mount Fuji's iconic silhouette — a wide, gently sloped
> cone with a flat-topped snow cap, soft blue-grey body and white snow
> line, no other landscape elements.

### 4. `crest_koi`
> Interior motif: a single koi carp swimming in a gentle curve, orange
> and white patches with a few small black accents, long flowing fins and
> tail — the fish that swims upstream, a Japanese symbol of perseverance.

### 5. `crest_daruma`
> Interior motif: a Daruma doll — round, bottom-heavy red body that can't
> tip over, white oval face, bold black eyebrows and moustache, no pupils
> in the eyes (tradition: one eye is filled in when a goal is set, the
> other when it's achieved — fitting for a study app).

### 6. `crest_manekineko`
> Interior motif: a maneki-neko "beckoning cat" figurine, sitting upright,
> one front paw raised in the beckoning gesture, white fur, a red collar
> with a small gold bell, calm friendly expression.

### 7. `crest_orizuru`
> Interior motif: a single origami paper crane (orizuru) — angular,
> precisely folded paper-crane silhouette, soft pastel paper colour with
> visible fold-crease lines, wings spread.

### 8. `crest_sensu`
> Interior motif: an open folding fan (sensu), spread into a wide arc,
> with a simple painted pattern (a few sakura petals or a soft gradient)
> across the pleated paper, wooden ribs visible at the base.

### 9. `crest_kokeshi`
> Interior motif: a kokeshi doll — a simple cylindrical wooden body with
> no arms or legs, a round head, a painted simple face, and a floral
> pattern painted on the body like a kimono.

### 10. `crest_lantern`
> Interior motif: a round Japanese paper lantern (chōchin) hanging from a
> short cord at the top, warm coral-red with soft horizontal rib lines, a
> simple round finial on top and bottom.

### 11. `crest_koinobori`
> Interior motif: a single koinobori carp-shaped windsock/streamer,
> caught mid-flow as if blowing in the wind, colourful horizontal stripe
> bands (e.g. red and white), open mouth at the front where it would
> catch the wind, tapering to a point at the tail.

### 12. `crest_tanuki`
> Interior motif: a tanuki (Japanese raccoon dog) in the classic folklore
> statue pose — round belly, wide friendly eyes, a straw hat tipped on
> its head, a single leaf resting on top of the hat.

### 13. `crest_kitsune`
> Interior motif: a kitsune fox mask (the kind worn at Inari shrine
> festivals) — a stylised white fox face mask with red markings around
> the eyes and pointed ears, worn front-facing rather than a live animal.

### 14. `crest_uchiwa`
> Interior motif: a round rigid uchiwa fan — a flat paddle-shaped fan
> (not folding) with a short handle, a simple painted pattern like a
> single sakura branch or a soft wave pattern across its round face.

### 15. `crest_temari`
> Interior motif: a temari thread ball — a perfect sphere wrapped in
> colourful embroidered thread forming a symmetrical geometric pattern
> (bands, stars, or diamonds) in two or three soft pastel thread colours.

### 16. `crest_kabuto`
> Interior motif: a samurai kabuto helmet, seen from the front — the
> rounded helmet bowl, a crescent-moon-shaped frontal ornament (maedate)
> rising from the top, simplified and rounded for a friendly, non-fierce
> read rather than a fearsome warrior helmet.

### 17. `crest_ema`
> Interior motif: a wooden ema wish plaque — a small pentagon-shaped
> (house-roof-topped) wooden board hanging from a cord, with a simple
> painted symbol on its face (e.g. a small torii or sakura) and its
> bottom edge left blank as if waiting for a wish to be written on it.

### 18. `crest_hamaya`
> Interior motif: a hamaya ceremonial arrow — a decorative New Year's
> arrow with feather fletching at one end and a simple wrapped grip,
> shown diagonally, said to ward off bad luck for the year ahead.

### 19. `crest_ginkgo`
> Interior motif: a single ginkgo leaf — the distinctive fan shape with a
> small notch at the top centre, rendered in a warm golden-yellow, fine
> radiating vein lines suggested simply.

### 20. `crest_ume`
> Interior motif: a small cluster of ume (plum) blossoms on a bare dark
> branch — five rounded petals per flower (rounder and simpler than the
> sakura's petals above), soft white-to-pink colouring — the flower that
> blooms in the cold before spring, a symbol of perseverance through
> hardship.

---

## Setelah gambarnya jadi

```bash
python scripts/prepare_clan_icon.py "C:/Teisou asset/clan_icons/"*.png
```

Cek hasilnya di `assets/clan_icons/` — 20 berkas, satu per `id` di atas —
sebelum menjalankan aplikasi. Tidak perlu perubahan kode apa pun: `Clan`
sudah membaca ulang gambar lewat `ClanIconArt`, yang otomatis memakai PNG
begitu file dengan nama yang cocok muncul di folder itu, dan tetap jatuh
ke emoji kalau belum ada.
