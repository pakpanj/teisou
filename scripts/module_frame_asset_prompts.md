# Prompt aset dasar modul — Teisou

Lima aset dasar yang dipakai ulang di **semua** modul (Kurikulum/Bab,
Bunpou, Partikel, Kaiwa, Dokkai, Choukai) — dibuat langsung dari prompt,
bukan crop dari mockup ChatGPT lagi. Sekali jadi, dipakai di mana-mana.

---

## Baca ini dulu — kegagalan `frame_mascot_bubble` yang sudah terjadi

Percobaan pertama untuk prompt #4 gagal: generatornya menggambar scene
utuh (Fuji, torii, pagoda, langit gradasi) dengan bubble-nya cuma
ditempel di depan — bukan bubble sendirian di latar magenta polos.
Kemungkinan besar itu terjadi karena baris "gentle Japanese motifs
only: sakura, torii, pagoda, mountain..." di character sheet di bawah
kebablasan dianggap berlaku untuk *semua* prompt, padahal itu cuma
untuk prompt #1 (banner).

Jadi setiap prompt selain #1 sekarang punya baris **ISOLASI** tebal di
awalnya — tempel baris itu paling depan, sebelum deskripsi bentuknya,
supaya generator nggak menambahkan pemandangan apa pun.

**Latar magenta rata `#FF00DC`**, sama seperti aset-aset sebelumnya —
generator gambar hampir semuanya tidak bisa menghasilkan alpha asli, jadi
latar magenta lalu dipotong bersih setelahnya lewat skrip.

**Tiga dari lima aset ini (#3, #4, #5) harus "nine-patch friendly"** —
artinya kotak/bubble/lingkarannya dipasang di kartu yang ukurannya
beda-beda tergantung isi, jadi gambarnya nanti diregangkan (stretch) di
tengah, bukan ditampilkan di satu ukuran tetap. Supaya hasil regangannya
nggak kelihatan aneh, border/hiasan di pinggirnya **harus tipis, rata,
dan berulang** — bukan motif besar yang cuma pas di satu ukuran. Detail
teknisnya saya jelaskan per-prompt di bawah.

---

## Character sheet — tempel di setiap prompt di bawah

> Soft cel-shaded flat illustration style, matching a children's Japanese-
> learning app. Every shape uses a clean, even outline in dark plum/maroon
> `#5A2A3A`, never pure black. Colour palette restricted to: coral red
> `#F4667A`, sky blue `#4F97F4`, warm amber `#E8B84B`, soft pink `#FCE9EC`,
> soft blue `#E8F0FE`, cream `#FCEEDB`, green `#4CAF6E`, white, and the
> outline plum — pick only 1-2 accents per asset as instructed below.
>
> No gradient mesh, no photographic texture, no drop shadow outside the
> art itself. Gentle Japanese motifs only: sakura blossoms, torii gates,
> pagodas, gentle mountain silhouettes, seigaiha wave patterns — kawaii-
> adjacent, warm, welcoming, never scary or ornate/cluttered.
>
> Background: solid flat magenta `#FF00DC`, completely uniform, no
> gradient, no pattern. No text, no letters, no watermark.

---

## 1. `bg_module_header` — banner header modul

Menggantikan crop mockup yang saya pakai sekarang (Fuji + torii + pagoda)
dengan versi yang benar-benar dirancang, bukan potongan.

> Canvas: wide banner, 1600×420. Composition: a soft pastel sky gradient
> from pale blue (top) into pale pink (bottom), with Mt. Fuji centred-left
> (snow cap visible), a torii gate silhouette on the right third, a small
> pagoda silhouette further right, low sakura branches drooping in from
> the top-right corner with a few falling petals, and a thin seigaiha
> wave pattern strip along the very bottom edge. Everything at low
> opacity/pastel tone so it reads as a quiet backdrop, not a busy scene —
> nothing in the composition should be bold or high-contrast enough to
> compete with text/icons placed on top of it later. Leave the left 40%
> of the banner relatively open (just sky + a little of the mountain) —
> that's where a screen title sits on top of this art.

---

## 2. `frame_module_title` — bingkai judul modul

Bingkai/plakat kecil di belakang judul layar (misalnya "Bab", "Kaiwa",
"Bunpou") — ukuran tetap, bukan yang meregang, jadi didesain untuk satu
baris judul pendek (1-2 kata).

> ISOLATED ASSET — the plaque frame is the entire image. Do NOT draw
> Mt. Fuji, torii gates, pagodas, sky, clouds, mountains, or any
> background landscape anywhere in this canvas — only flat magenta
> behind the plaque shape itself, nothing else.
>
> Canvas: 900×220. A gentle ornamental plaque/signboard shape, rounded
> rectangle with a soft double-line border in coral red, a single small
> sakura blossom sitting at each of the two top corners, and a thin gold
> `#E8B84B` accent line running just inside the coral border. The centre
> of the plaque is a flat, very pale cream `#FCEEDB` fill with **no
> texture and no detail** — that's where title text gets placed on top
> afterward, so it must stay completely plain and readable-behind-dark-
> text. No character, no scene, just the frame itself.

---

## 3. `frame_card_box` — bingkai kotak kartu (nine-patch)

Bingkai dekoratif buat kartu-kartu daftar (kartu level, kartu modul) yang
tingginya berubah-ubah tergantung isi.

> ISOLATED ASSET — the card border is the entire image. Do NOT draw
> Mt. Fuji, torii gates, pagodas, sky, clouds, mountains, or any
> background landscape anywhere in this canvas — only flat magenta
> outside the card shape itself, nothing else.
>
> Canvas: 300×300 (square — a square source is easiest to slice evenly on
> all four sides for stretching later). A simple rounded-rectangle card
> outline, coral red double-line border about 14px thick running evenly
> around all four edges, with **one small sakura blossom corner
> ornament repeated identically in all four corners** (top-left, top-
> right, bottom-left, bottom-right — the exact same flower motif in every
> corner, not four different ones). The middle 60% of the canvas (the
> area inside the border, away from the corners) must be **completely
> flat and empty** — solid pale pink `#FCE9EC` fill, absolutely no
> texture, no gradient, no pattern — because that middle region gets
> stretched to fit cards of different heights, and any detail there would
> smear when stretched. Only the outer ~20% border band and the four
> corner flowers should carry any linework.

---

## 4. `frame_mascot_bubble` — bingkai balon teks maskot

Menggantikan kotak putih polos di belakang ucapan maskot (`MascotGuideBubble`)
dengan balon kertas washi yang lebih terasa buatan tangan, juga
nine-patch karena panjang pesan berubah-ubah.

**Update — percobaan kedua berhasil isolasinya** (bubble sendirian di
magenta, tidak ada scene lagi), tapi hasilnya polos tanpa bunga sama
sekali. Itu karena prompt sebelumnya sengaja bilang "no corner
ornaments" — kekhawatirannya waktu itu adalah bunga di pojok bisa ikut
rusak pas gambarnya diregangkan (nine-patch). Ternyata itu kekhawatiran
yang salah: di teknik nine-patch, **pojok gambar tidak pernah ikut
meregang** — yang meregang cuma pita tepi (kiri/kanan/atas/bawah) dan
bagian tengah. Jadi bunga di pojok aman-aman saja, sama seperti
`frame_card_box` di prompt #3 yang dari awal memang sudah punya bunga di
pojok. Versi di bawah ini sudah menambahkan itu — generate ulang pakai
versi ini.

> ISOLATED ASSET — the speech bubble is the entire image, floating alone
> on flat magenta. Do NOT draw Mt. Fuji, torii gates, pagodas, sky
> gradients, clouds, mountains, or any background landscape anywhere in
> this canvas. If you can see anything in the image other than the
> bubble shape, its four corner flowers, and the flat magenta behind it,
> that is wrong — remove it.
>
> Canvas: 300×220. A soft rounded speech-bubble shape (like a paper/washi
> note), pale cream `#FCEEDB` fill, with a thin, even coral-red single-
> line border about 8px thick running around the rounded rectangle, and
> a small triangular speech-bubble tail pointing out from the bottom-left
> corner (where the mascot character sits beside it in the app). **One
> small sakura blossom sitting right at each of the two top corners
> only** (top-left and top-right) — identical flowers, small enough that
> each one stays fully within roughly the outer 15% of the canvas at
> that corner and does not extend along the straight edges. The bottom
> two corners stay plain (one of them has the speech tail instead). The
> straight border segments between the corners, and the entire interior,
> must stay completely flat and plain — no texture, no pattern — since
> those are the parts that get stretched when the bubble grows for a
> longer message.

---

## 5. `frame_level_badge` — bingkai lingkaran level (N5, N4, dst.)

Cincin/wreath di sekeliling badge bulat "N5"/"N4"/dst. yang dipakai di
daftar level Bab/Bunpou/Partikel/Kaiwa/Dokkai/Choukai — beda dari
`xp_level_badge.png` yang sudah ada (itu khusus kartu XP di Home),
ini punya nama sendiri supaya bisa direvisi terpisah kalau perlu.

> ISOLATED ASSET — the ring is the entire image, floating alone on flat
> magenta. Do NOT draw Mt. Fuji, torii gates, pagodas, sky, clouds,
> mountains, or any background landscape anywhere in this canvas — only
> flat magenta outside the ring shape itself, nothing else.
>
> Canvas: 300×300 (square). A circular wreath of small sakura blossoms
> and leaves running around the rim of a circle, matching a school
> achievement-badge look — identical in spirit to a laurel wreath but
> made of sakura flowers instead of leaves. The centre of the circle
> (inside the wreath ring) is a flat, empty pale pink `#FCE9EC` fill with
> **no texture, no number, no text, no character** — that's where the
> app draws its own level label ("N5", etc.) on top afterward. Keep the
> wreath ring itself fairly thin relative to the circle's diameter, so
> the empty centre stays large enough for a two-character label to sit
> comfortably.

---

## Setelah gambarnya jadi

1. Simpan 5 file dengan nama persis: `bg_module_header.png`,
   `frame_module_title.png`, `frame_card_box.png`,
   `frame_mascot_bubble.png`, `frame_level_badge.png`.
2. Kirim ke saya — saya potong latar magenta, dan untuk #3/#4/#5 saya
   pasang pakai `Image.asset(..., centerSlice: ...)` Flutter (fitur
   nine-patch bawaan) supaya border-nya tetap tajam sementara bagian
   tengahnya meregang mengikuti ukuran kartu/bubble — jadi border yang
   kamu gambar di #3/#4/#5 **harus** benar-benar rata dan berulang
   seperti diminta di atas, atau hasil regangannya akan terlihat
   pecah/aneh.
3. Kalau ada yang hasilnya kurang pas, sebutkan nomornya saja — saya bisa
   revisi prompt itu sendiri tanpa mengulang semuanya.

**Catatan jujur soal #3, #4, #5**: teknik nine-patch ini butuh border
yang generator gambarnya benar-benar presisi rata di keempat sisi (atau,
untuk #5, rata sekeliling lingkaran). Kalau hasil generate-nya sedikit
tidak simetris (garisnya lebih tebal di satu sisi, misalnya), saya akan
lihat dulu sebelum pasang dan kasih tahu kalau perlu di-generate ulang —
daripada dipasang langsung dan hasilnya malah terlihat pecah di kartu
yang tinggi.
