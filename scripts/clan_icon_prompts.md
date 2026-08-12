# Prompt gambar ikon clan Teisou

Satu berkas per preset, disimpan di `assets/clan_icons/{id}.png`. Nama
berkas **harus** persis sama dengan `id` di `ClanIconPresets.all`
(`lib/core/constants/clan_icons.dart`) — kalau tidak, aplikasi diam-diam
jatuh ke emoji dan tidak ada yang error.

**Revisi ke-2**: set ini menggantikan versi kawaii-illustration
sebelumnya (bentuk motif digambar penuh dengan shading/gradasi ringan)
dengan gaya **kamon** (紋, lambang keluarga/klan tradisional Jepang) —
siluet padat, garis tegas, simetris — tapi dengan palet pastel hangat
milik aplikasi ini, bukan hitam-putih aslinya. Referensi gaya: lambang
pohon cemara bergaya mon yang ditunjukkan user, monokrom tebal dan
sangat simetris — arahnya dipertahankan, warnanya yang diubah supaya
tidak terasa "berat/dewasa" seperti mon asli.

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
pastel aplikasi ini, jadi gampang dibedakan dan dihapus manual setelahnya
(tidak ada script Python untuk ini — cukup pakai tool hapus-background
apa pun yang biasa dipakai: Photopea/GIMP "select by color" lalu delete,
remove.bg, atau fitur edit bawaan Gemini sendiri). Simpan hasilnya persegi
(disarankan 1024×1024) sebagai `assets/clan_icons/{id}.png`.

**Setiap gambar adalah badge lingkaran utuh dengan latar pastelnya sendiri
sudah "dibakar" ke dalam gambar** — sama seperti set avatar `neko_circles`
yang sudah dipakai aplikasi ini. Jadi bukan ikon transparan tanpa latar
sama sekali — magenta di prompt hanya untuk area DI LUAR lingkaran badge,
supaya sudut-sudut persegi bisa dipotong jadi transparan, sementara
lingkaran badge-nya sendiri tetap solid dengan warna pastelnya sendiri.

---

## Gaya bersama — tempel di setiap prompt

> A traditional Japanese kamon (family/clan crest) rendered as a flat
> circular emblem — bold, solid, highly symmetrical silhouette artwork,
> centred inside a circular badge that fills most of the square canvas.
> Think of a real kamon medallion (a stencil-like, single-colour crest
> silhouette on a plain background) redrawn in this app's own soft pastel
> palette instead of the traditional black-on-white.
>
> The badge is two-tone, exactly like a real kamon: the circle's interior
> is one solid soft pastel colour (its "field"), and the motif sits on top
> as a single solid silhouette shape in ONE contrasting pastel-friendly
> colour — no gradients inside the motif, no internal shading, no
> multi-colour illustration. Pick colours from this app's palette (coral
> `#F4667A`, cream, soft blue, soft green, soft gold) for the field, and a
> deeper but still soft tone (dusty rose, muted teal, warm ochre, dusty
> plum) for the motif silhouette, so the two read clearly apart.
>
> The circle is outlined with the same thick, even dark-plum / maroon
> line (not black) used throughout this app's mascot character — see
> `scripts/mascot_prompts.md`'s character sheet for the exact outline
> style to match. This is the only "line" in the whole image; the motif
> itself must be a filled silhouette, not an outlined drawing.
>
> Interior motif: absolutely flat solid silhouette shape only — no
> gradient, no shading, no texture, no photorealism, no internal detail
> lines cutting through the silhouette (real kamon achieve detail only
> through the outline of the shape itself, like a paper cut-out or a
> rubber stamp, never by drawing lines on top of a filled area). Strong
> bilateral or radial symmetry, the defining trait of a real kamon —
> where the source object isn't naturally symmetric on its own, stylise
> it into a symmetric arrangement (e.g. two or three mirrored copies
> arranged in a small circle or fan, the way real mon turn a single
> flower, leaf, or animal into a balanced crest). Bold and legible at
> small sizes (this renders as small as 32px in the app) — simplify
> toward a clean geometric silhouette rather than an illustrated scene.
> Represent the motif accurately and respectfully as a real Japanese
> cultural object/symbol — simplified into crest form, but recognisable,
> not a generic invented shape.
>
> Composition: square 1024×1024 image, circular badge centred with a
> small even margin, everything OUTSIDE the circle solid flat magenta
> `#FF00DC` (see "Baca ini dulu" above — this gets keyed out, it is not
> part of the final art). No text, no letters, no watermark, no border
> around the whole canvas, no drop shadow.

---

## 20 preset

Setiap poin di bawah menggantikan kalimat "Interior motif" pada gaya
bersama di atas. Kalau sebuah motif aslinya tidak simetris (misalnya satu
ekor ikan koi), instruksinya sudah minta itu diubah jadi susunan simetris
ala kamon (dua ikan koi saling berhadap-hadapan membentuk lingkaran, dsb)
— bukan digambar apa adanya.

### 1. `crest_torii`
> Interior motif: a Shinto shrine torii gate silhouette, seen straight-on
> — two upright pillars and two horizontal crossbars, already naturally
> symmetric left-to-right, rendered as one flat solid silhouette shape.

### 2. `crest_sakura`
> Interior motif: a single stylised five-petal cherry blossom (sakura)
> crest, viewed face-on like a real kamon flower crest — radially
> symmetric, all five petals identical, a small circular centre, rendered
> as one flat solid silhouette shape (the classic "crest flower"
> composition, not a branch or cluster).

### 3. `crest_fuji`
> Interior motif: Mount Fuji's silhouette, seen straight-on — a wide,
> gently sloped, perfectly symmetric cone with a flat-topped snow cap
> notch, rendered as one flat solid silhouette shape (the snow cap can be
> the field colour showing through as a simple triangular notch, the rest
> solid).

### 4. `crest_koi`
> Interior motif: two koi carp mirrored nose-to-tail in a circular
> "futatsu-goi" arrangement (a real traditional kamon composition), each
> fish a simple curved solid silhouette with a few small fin notches — no
> internal patterning, one flat solid silhouette shape overall.

### 5. `crest_daruma`
> Interior motif: a Daruma doll silhouette, seen straight-on — round,
> bottom-heavy body shape with a simple oval face area distinguished only
> by the field colour showing through (not drawn detail), naturally
> symmetric left-to-right, rendered as one flat solid silhouette shape.

### 6. `crest_manekineko`
> Interior motif: a maneki-neko "beckoning cat" silhouette, sitting
> upright and facing forward, one paw raised — simplified to a clean
> front-facing cat silhouette (the raised paw breaks perfect symmetry
> slightly, same as a real kamon cat crest would allow), rendered as one
> flat solid silhouette shape.

### 7. `crest_orizuru`
> Interior motif: a single origami paper crane (orizuru) silhouette, seen
> from directly above/behind with wings fully spread — naturally
> symmetric left-to-right in this pose, angular folded-paper silhouette,
> rendered as one flat solid silhouette shape.

### 8. `crest_sensu`
> Interior motif: an open folding fan (sensu) silhouette, spread into a
> symmetric wide arc with visible fold-crease lines radiating from the
> base as the only internal detail (crease lines shown as thin gaps of
> field colour, not drawn strokes), rendered as one flat solid silhouette
> shape.

### 9. `crest_kokeshi`
> Interior motif: a kokeshi doll silhouette, seen straight-on — a simple
> cylindrical body with a round head, naturally symmetric left-to-right,
> rendered as one flat solid silhouette shape with no painted face or
> pattern detail (kamon crests never include painted facial features).

### 10. `crest_lantern`
> Interior motif: a round Japanese paper lantern (chōchin) silhouette,
> hanging from a short cord at the top — naturally symmetric, ribbed
> horizontal lines shown as thin gaps of field colour, rendered as one
> flat solid silhouette shape.

### 11. `crest_koinobori`
> Interior motif: three koinobori carp-shaped windsocks arranged in a
> pinwheel/rosette, radiating outward from a shared central point with
> three-way rotational symmetry (the way real kamon arrange three
> identical elements into a balanced "mitsu" rosette, like a pinwheel
> with three blades) — each windsock a simple tapering cone shape with a
> round open ring at its inner end (where it would catch the wind) and a
> pointed, notched swallow-tail at its outer end, clearly distinct from a
> plain fish shape, no internal patterning, rendered as one flat solid
> silhouette shape overall.

### 12. `crest_tanuki`
> Interior motif: a tanuki (Japanese raccoon dog) silhouette, simplified
> to its essential rounded shape — a plump pot-belly body standing
> upright and facing forward, two small round ears on top of its head, a
> simple triangular straw hat resting flat and centred on its head, its
> tail hidden straight down behind the body rather than to one side, arms
> held straight at its sides (no sake bottle, ledger, or other held
> objects) — a clean, naturally symmetric left-to-right silhouette,
> rendered as one flat solid silhouette shape with no painted facial
> detail.

### 13. `crest_kitsune`
> Interior motif: a kitsune fox mask silhouette (the kind worn at Inari
> shrine festivals), seen straight-on — pointed ears, naturally symmetric
> left-to-right, rendered as one flat solid silhouette shape, eye/marking
> shapes shown as cut-outs of field colour rather than drawn lines.

### 14. `crest_uchiwa`
> Interior motif: a round rigid uchiwa fan silhouette with a short
> handle at the bottom — naturally symmetric, rendered as one flat solid
> silhouette shape with no painted pattern on its face.

### 15. `crest_temari`
> Interior motif: a temari thread ball silhouette — a perfect circle
> divided by a simple radially symmetric geometric pattern (evenly spaced
> spokes or a star, the way real temari thread patterns are built), shown
> as cut-out gaps of field colour rather than drawn lines, rendered as one
> flat solid silhouette shape.

### 16. `crest_kabuto`
> Interior motif: a samurai kabuto helmet silhouette, seen straight-on —
> the rounded helmet bowl with a crescent-moon-shaped frontal ornament
> (maedate) rising from the top, naturally symmetric left-to-right,
> rendered as one flat solid silhouette shape, simplified and rounded for
> a friendly, non-fierce read.

### 17. `crest_ema`
> Interior motif: a wooden ema wish plaque silhouette — a pentagon shape
> (house-roof-topped), naturally symmetric left-to-right, with a small
> simple symbol (e.g. a torii) shown as a cut-out gap of field colour near
> the top, rendered as one flat solid silhouette shape.

### 18. `crest_hamaya`
> Interior motif: two hamaya ceremonial arrows crossed in an X to form a
> symmetric crest (a real traditional crossed-arrow kamon composition),
> feather fletching at each of the four outer ends, rendered as one flat
> solid silhouette shape.

### 19. `crest_ginkgo`
> Interior motif: a single stylised ginkgo leaf, its fan shape rendered
> perfectly bilaterally symmetric around its centre notch — the classic
> "ichō crest" composition — as one flat solid silhouette shape, vein
> lines (if any) shown as thin cut-out gaps of field colour, not drawn
> lines.

### 20. `crest_ume`
> Interior motif: a single stylised ume (plum) blossom crest, viewed
> face-on with five rounded, simple petals evenly spaced around a small
> circular centre (rounder and plainer than a cherry-blossom petal, with
> no notch at the petal tip) — radially symmetric, rendered as one flat
> solid silhouette shape.

---

## Setelah gambarnya jadi

Hapus latar magenta-nya manual (lihat "Baca ini dulu" di atas), lalu taruh
langsung di `assets/clan_icons/{id}.png` — 20 berkas, satu per `id` di
atas. Tidak perlu perubahan kode apa pun: `Clan` sudah membaca ulang
gambar lewat `ClanIconArt`, yang otomatis memakai PNG begitu file dengan
nama yang cocok muncul di folder itu, dan tetap jatuh ke emoji kalau
belum ada.
